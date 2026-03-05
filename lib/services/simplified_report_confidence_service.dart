import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/simplified_report_model.dart';
import 'firebase_service.dart';

/// Resultado del cálculo de confianza con razones explicables
class ConfidenceResult {
  final double confidence;
  final List<String> reasons;

  ConfidenceResult({
    required this.confidence,
    required this.reasons,
  });
}

/// Servicio para calcular confianza de reportes simplificados
/// Usa fórmula mejorada con antigüedad en minutos, confirmaciones no lineales,
/// validación de panel digital, y manejo justo de usuarios nuevos
class SimplifiedReportConfidenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

  /// Calcula la confianza de un reporte con fórmula mejorada
  /// Retorna ConfidenceResult con confidence (0.0-1.0) y reasons explicables
  Future<ConfidenceResult> calculateConfidence(
      SimplifiedReportModel report) async {
    double confidence = 0.0;
    List<String> reasons = [];

    // 1. Precisión del usuario (0-0.4) con manejo de nuevos
    final user = await _firebaseService.getUser(report.userId);
    double userPrecision = 0.0;
    if (user != null) {
      // Obtener total de reportes del usuario
      final userReportsCount = await _getUserReportsCount(report.userId);

      if (userReportsCount < 5) {
        // Usuario nuevo: usar suavizado (Bayesian prior)
        final verifiedCount = await _getVerifiedReportsCount(report.userId);
        userPrecision = ((verifiedCount + 3) / (userReportsCount + 5)) * 100;
        reasons.add('new_user');
      } else {
        userPrecision = user.precision;
        if (userPrecision >= 85) {
          reasons.add('high_precision_author');
        }
      }
      confidence += (userPrecision / 100.0) * 0.4;
    } else {
      // Si no hay usuario, usar precisión neutral (60%)
      userPrecision = 60.0;
      confidence += 0.24; // 60% * 0.4
      reasons.add('new_user');
    }

    // 2. Confirmaciones (0-0.3) - Curva no lineal
    double confirmScore = 0.0;
    if (report.confirmations == 0) {
      confirmScore = 0.0;
    } else if (report.confirmations == 1) {
      confirmScore = 0.10;
    } else if (report.confirmations == 2) {
      confirmScore = 0.20;
    } else {
      confirmScore = 0.30; // 3+
      reasons.add('3_confirms');
    }

    confidence += confirmScore;

    // 3. Panel digital (0-0.2) - Con validación
    if (report.isPanelTime == true) {
      // Validar que realmente viene del panel
      final isValidPanel = await _validatePanelSource(report);
      if (isValidPanel) {
        confidence += 0.2;
        reasons.add('panel');
      }
    }

    // 4. Frescura (0-0.1) - En minutos
    final ageMinutes = DateTime.now().difference(report.createdAt).inMinutes;
    if (ageMinutes <= 2) {
      confidence += 0.10;
      reasons.add('fresh');
    } else if (ageMinutes <= 5) {
      confidence += 0.07;
    } else if (ageMinutes <= 10) {
      confidence += 0.03;
    }
    // >10 min: +0.00

    return ConfidenceResult(
      confidence: confidence.clamp(0.0, 1.0),
      reasons: reasons,
    );
  }

  /// Actualiza la confianza de un reporte en Firestore
  Future<void> updateReportConfidence(String reportId) async {
    try {
      final reportDoc =
          await _firestore.collection('reports').doc(reportId).get();
      if (!reportDoc.exists) {
        print('Reporte no encontrado: $reportId');
        return;
      }

      final report = SimplifiedReportModel.fromFirestore(reportDoc);
      final result = await calculateConfidence(report);

      await _firestore.collection('reports').doc(reportId).update({
        'confidence': result.confidence,
        'confidenceReasons': result.reasons,
      });

      print(
          '✅ Confianza actualizada para reporte $reportId: ${result.confidence.toStringAsFixed(2)} (${result.reasons.join(", ")})');
    } catch (e) {
      print('Error actualizando confianza del reporte $reportId: $e');
    }
  }

  /// Obtiene el conteo total de reportes del usuario
  Future<int> _getUserReportsCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('userId', isEqualTo: userId)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Error obteniendo conteo de reportes del usuario: $e');
      return 0;
    }
  }

  /// Obtiene el conteo de reportes verificados del usuario
  /// Un reporte se considera verificado si tiene 3+ confirmaciones
  Future<int> _getVerifiedReportsCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('userId', isEqualTo: userId)
          .get();

      int verifiedCount = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final confirmations = data['confirmations'] as int? ?? 0;
        if (confirmations >= 3) {
          verifiedCount++;
        }
      }
      return verifiedCount;
    } catch (e) {
      print('Error obteniendo reportes verificados del usuario: $e');
      return 0;
    }
  }

  /// Valida que el reporte realmente viene del panel digital
  /// Verifica geofence si hay userLocation disponible
  Future<bool> _validatePanelSource(SimplifiedReportModel report) async {
    // Si no hay userLocation, no podemos validar geofence
    // Por ahora, confiar en el flag pero en el futuro se puede mejorar
    if (report.userLocation == null) {
      // Sin ubicación, no podemos validar, pero confiamos en el flag
      return true;
    }

    try {
      // Obtener estación
      final stationDoc =
          await _firestore.collection('stations').doc(report.stationId).get();
      if (!stationDoc.exists) {
        return false;
      }

      final stationData = stationDoc.data()!;
      final stationLocation = stationData['ubicacion'] as GeoPoint?;
      if (stationLocation == null) {
        return false;
      }

      // Calcular distancia
      final distance = Geolocator.distanceBetween(
        report.userLocation!.latitude,
        report.userLocation!.longitude,
        stationLocation.latitude,
        stationLocation.longitude,
      );

      // Debe estar dentro de 200m de la estación para considerar válido
      return distance <= 200;
    } catch (e) {
      print('Error validando panel source: $e');
      // En caso de error, confiar en el flag
      return true;
    }
  }

  /// Calcula confianza agregada para una lista de reportes.
  ///
  /// Usado por StationStatusAggregator y TrainStatusAggregator como
  /// fuente única de verdad para confianza de datos agregados.
  ///
  /// Componentes (máx 1.0):
  /// - Cantidad de reportes (0-0.4): más reportes = más confianza
  /// - Confirmaciones totales (0-0.3): curva no-lineal por total
  /// - Frescura promedio (0-0.3): reportes recientes pesan más
  static double calculateAggregatedConfidence(
      List<SimplifiedReportModel> reports) {
    if (reports.isEmpty) return 0.0;

    // 1. Cantidad de reportes (máximo 0.4)
    final reportCountScore = (reports.length / 10.0).clamp(0.0, 0.4);

    // 2. Confirmaciones totales (máximo 0.3) - curva no-lineal
    final totalConfirmations = reports.fold<int>(
      0,
      (total, r) => total + r.confirmations,
    );
    double confirmationScore;
    if (totalConfirmations == 0) {
      confirmationScore = 0.0;
    } else if (totalConfirmations <= 2) {
      confirmationScore = 0.10;
    } else if (totalConfirmations <= 5) {
      confirmationScore = 0.20;
    } else {
      confirmationScore = 0.30;
    }

    // 3. Frescura promedio (máximo 0.3)
    final now = DateTime.now();
    double recencyScore = 0.0;
    for (final report in reports) {
      final ageMinutes = now.difference(report.createdAt).inMinutes;
      final weight = (30 - ageMinutes.clamp(0, 30)) / 30.0;
      recencyScore += weight;
    }
    recencyScore = (recencyScore / reports.length).clamp(0.0, 0.3);

    return (reportCountScore + confirmationScore + recencyScore)
        .clamp(0.0, 1.0);
  }

  /// Obtiene el nivel de confianza como texto legible
  static String getConfidenceLevel(double confidence) {
    if (confidence >= 0.7) return 'Alta';
    if (confidence >= 0.4) return 'Media';
    return 'Baja';
  }

  /// Obtiene el color para el nivel de confianza
  static Color getConfidenceColor(double confidence) {
    if (confidence >= 0.7) return Colors.green;
    if (confidence >= 0.4) return Colors.orange;
    return Colors.red;
  }

  /// Genera texto explicativo de las razones de confianza
  static String getConfidenceExplanation(List<String> reasons) {
    if (reasons.isEmpty) {
      return 'Confianza basada en datos básicos';
    }

    final explanations = <String>[];
    if (reasons.contains('panel')) {
      explanations.add('Panel Digital');
    }
    if (reasons.contains('3_confirms')) {
      explanations.add('3+ confirmaciones');
    }
    if (reasons.contains('fresh')) {
      explanations.add('Reporte reciente');
    }
    if (reasons.contains('high_precision_author')) {
      explanations.add('Autor con alta precisión');
    }
    if (reasons.contains('new_user')) {
      explanations.add('Usuario nuevo');
    }

    return explanations.join(' + ');
  }
}
