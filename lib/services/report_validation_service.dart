import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../services/firebase_service.dart';

class ReportValidationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

  /// Verifica si el usuario puede reportar (anti-spam)
  /// - Máximo 10 reportes por hora
  /// - No reportar misma estación en 5 minutos
  Future<bool> canUserReport(String userId, String? objetivoId) async {
    try {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));

      // Verificar límite de reportes por hora
      final recentReportsSnapshot = await _firestore
          .collection('reports')
          .where('usuario_id', isEqualTo: userId)
          .where('creado_en', isGreaterThan: Timestamp.fromDate(oneHourAgo))
          .get();

      if (recentReportsSnapshot.docs.length >= 10) {
        return false; // Límite de spam alcanzado
      }

      // Verificar si ya reportó esta estación/tren recientemente
      if (objetivoId != null) {
        final recentSameTargetSnapshot = await _firestore
            .collection('reports')
            .where('usuario_id', isEqualTo: userId)
            .where('objetivo_id', isEqualTo: objetivoId)
            .where('creado_en', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
            .get();

        if (recentSameTargetSnapshot.docs.isNotEmpty) {
          return false; // Ya reportó esta estación/tren recientemente
        }
      }

      return true;
    } catch (e) {
      print('Error validating report permission: $e');
      return false; // En caso de error, denegar por seguridad
    }
  }

  /// Valida que el usuario esté cerca de la ubicación del reporte
  /// Máximo 1 km de distancia
  bool isValidReportLocation(
    Position? userLocation,
    GeoPoint targetLocation,
  ) {
    if (userLocation == null) {
      return false; // Sin ubicación del usuario
    }

    final distance = Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      targetLocation.latitude,
      targetLocation.longitude,
    );

    // Máximo 1 km (1000 metros)
    return distance <= 1000;
  }

  /// Verifica si el usuario ya reportó recientemente para esta estación/tren
  Future<bool> hasRecentReportForStation(
    String userId,
    String objetivoId,
  ) async {
    try {
      final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));

      final recentReportsSnapshot = await _firestore
          .collection('reports')
          .where('usuario_id', isEqualTo: userId)
          .where('objetivo_id', isEqualTo: objetivoId)
          .where('creado_en', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
          .limit(1)
          .get();

      return recentReportsSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking recent report: $e');
      return false;
    }
  }

  /// Obtiene el mensaje de error de validación
  Future<String?> getValidationErrorMessage(
    String userId,
    String? objetivoId,
    Position? userLocation,
    GeoPoint? targetLocation,
  ) async {
    final canReport = await canUserReport(userId, objetivoId);
    if (!canReport) {
      // Verificar cuál es el problema específico
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      final recentReportsSnapshot = await _firestore
          .collection('reports')
          .where('usuario_id', isEqualTo: userId)
          .where('creado_en', isGreaterThan: Timestamp.fromDate(oneHourAgo))
          .get();

      if (recentReportsSnapshot.docs.length >= 10) {
        return 'Has alcanzado el límite de reportes por hora (10). Intenta más tarde.';
      }

      if (objetivoId != null && await hasRecentReportForStation(userId, objetivoId)) {
        return 'Ya reportaste esta estación/tren recientemente. Espera 5 minutos.';
      }

      return 'No puedes reportar en este momento.';
    }

    if (userLocation != null && targetLocation != null) {
      final isValid = isValidReportLocation(userLocation, targetLocation);
      if (!isValid) {
        return 'Debes estar a menos de 1 km de la estación/tren para reportar.';
      }
    }

    return null; // Sin errores
  }
}

