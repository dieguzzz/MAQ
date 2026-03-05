import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/simplified_report_model.dart';
import '../../models/train_model.dart';
import '../../utils/train_status_mapper.dart';
import '../../core/logger.dart';

/// Servicio para agregar múltiples reportes y calcular el estado de un tren
class TrainStatusAggregator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Actualiza el estado de un tren basado en reportes activos recientes
  ///
  /// Obtiene reportes de los últimos 30 minutos y calcula:
  /// - estado: consenso de múltiples reportes (normal/retrasado/detenido)
  /// - aglomeracion: promedio de trainCrowd
  /// - confidence: basado en cantidad de reportes y confirmaciones
  Future<void> updateTrainFromReports(String trainId) async {
    try {
      // Obtener reportes activos de los últimos 30 minutos
      // Nota: Los reportes de trenes están asociados a stationId, no trainId directamente
      // Necesitamos buscar reportes que mencionen este tren específico
      // Por ahora, usaremos una estrategia diferente: buscar por trainLine y direction
      // TODO: Mejorar cuando tengamos trainId en los reportes

      final thirtyMinutesAgo =
          DateTime.now().subtract(const Duration(minutes: 30));

      // Obtener todos los reportes de trenes activos recientes
      final allTrainReports = await _getRecentTrainReports(thirtyMinutesAgo);

      // Filtrar reportes que correspondan a este tren
      // Por ahora, asumimos que trainId puede estar en trainLine o necesitamos otra estrategia
      // Por simplicidad, usaremos todos los reportes de trenes recientes
      // En producción, esto debería filtrarse mejor
      final trainReports = allTrainReports
          .where((r) => r.scope == 'train' && r.status == 'active')
          .where((r) => r.trainStatus != null || r.trainCrowd != null)
          .toList();

      if (trainReports.isEmpty) {
        // No hay reportes recientes, no actualizar
        return;
      }

      // Calcular estado agregado
      final aggregatedState = _calculateAggregatedState(trainReports);
      final aggregatedCrowd = _calculateAggregatedCrowd(trainReports);
      final confidence = _calculateConfidence(trainReports);

      // Actualizar tren en Firestore
      await _updateTrainInFirestore(
        trainId,
        aggregatedState,
        aggregatedCrowd,
        confidence,
      );
    } catch (e) {
      AppLogger.error('Error updating train from reports: $e');
      rethrow;
    }
  }

  /// Obtiene reportes recientes de trenes (helper)
  Future<List<SimplifiedReportModel>> _getRecentTrainReports(
      DateTime since) async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('scope', isEqualTo: 'train')
          .where('status', isEqualTo: 'active')
          .get();

      final reports = snapshot.docs
          .map((doc) => SimplifiedReportModel.fromFirestore(doc))
          .where((report) => report.createdAt.isAfter(since))
          .toList();

      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reports;
    } catch (e) {
      AppLogger.error('Error getting recent train reports: $e');
      return [];
    }
  }

  /// Calcula el estado agregado basado en múltiples reportes
  ///
  /// Lógica:
  /// - 1 reporte: usar ese estado
  /// - 2-4 reportes: usar moda (más común)
  /// - 5+ reportes: usar promedio ponderado por confirmaciones
  EstadoTren? _calculateAggregatedState(List<SimplifiedReportModel> reports) {
    if (reports.isEmpty) return null;

    // Mapear cada reporte a EstadoTren
    final estados = reports
        .map((r) => TrainStatusMapper.mapTrainStatusToEstado(
              trainStatus: r.trainStatus,
              trainCrowd: r.trainCrowd,
            ))
        .whereType<EstadoTren>()
        .toList();

    if (estados.isEmpty) return null;

    if (estados.length == 1) {
      // Un solo reporte: usar ese estado
      return estados.first;
    } else if (estados.length <= 4) {
      // 2-4 reportes: usar moda (más común)
      return _getMostCommonEstado(estados);
    } else {
      // 5+ reportes: usar promedio ponderado por confirmaciones
      return _getWeightedAverageEstado(reports, estados);
    }
  }

  /// Obtiene el estado más común (moda)
  EstadoTren _getMostCommonEstado(List<EstadoTren> estados) {
    final counts = <EstadoTren, int>{};
    for (final estado in estados) {
      counts[estado] = (counts[estado] ?? 0) + 1;
    }

    EstadoTren? mostCommon;
    int maxCount = 0;
    for (final entry in counts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostCommon = entry.key;
      }
    }

    return mostCommon ?? estados.first;
  }

  /// Calcula promedio ponderado por confirmaciones
  EstadoTren _getWeightedAverageEstado(
    List<SimplifiedReportModel> reports,
    List<EstadoTren> estados,
  ) {
    final weights = <EstadoTren, double>{};

    for (int i = 0; i < reports.length && i < estados.length; i++) {
      final report = reports[i];
      final estado = estados[i];
      // Peso = 1 + confirmaciones (reportes con más confirmaciones pesan más)
      final weight = 1.0 + (report.confirmations * 0.5);
      weights[estado] = (weights[estado] ?? 0.0) + weight;
    }

    EstadoTren? maxWeightEstado;
    double maxWeight = 0.0;
    for (final entry in weights.entries) {
      if (entry.value > maxWeight) {
        maxWeight = entry.value;
        maxWeightEstado = entry.key;
      }
    }

    return maxWeightEstado ?? estados.first;
  }

  /// Calcula aglomeracion como promedio de trainCrowd
  int _calculateAggregatedCrowd(List<SimplifiedReportModel> reports) {
    final crowdLevels = reports
        .where((r) => r.trainCrowd != null)
        .map((r) => r.trainCrowd!)
        .toList();

    if (crowdLevels.isEmpty) {
      return 1; // Por defecto
    }

    final average = crowdLevels.reduce((a, b) => a + b) / crowdLevels.length;
    return average.round().clamp(1, 5);
  }

  /// Calcula confidence basado en:
  /// - Cantidad de reportes (más reportes = más confianza)
  /// - Confirmaciones totales (más confirmaciones = más confianza)
  /// - Antigüedad de reportes (reportes más recientes pesan más)
  double _calculateConfidence(List<SimplifiedReportModel> reports) {
    if (reports.isEmpty) return 0.0;

    // Base: cantidad de reportes (máximo 0.4)
    final reportCountScore = (reports.length / 10.0).clamp(0.0, 0.4);

    // Confirmaciones totales (máximo 0.3)
    final totalConfirmations = reports.fold<int>(
      0,
      (total, r) => total + r.confirmations,
    );
    final confirmationScore = (totalConfirmations / 20.0).clamp(0.0, 0.3);

    // Antigüedad: reportes más recientes pesan más (máximo 0.3)
    final now = DateTime.now();
    double recencyScore = 0.0;
    for (final report in reports) {
      final ageMinutes = now.difference(report.createdAt).inMinutes;
      // Reportes más recientes (menos minutos) tienen más peso
      final weight = (30 - ageMinutes.clamp(0, 30)) / 30.0;
      recencyScore += weight;
    }
    recencyScore = (recencyScore / reports.length).clamp(0.0, 0.3);

    return (reportCountScore + confirmationScore + recencyScore)
        .clamp(0.0, 1.0);
  }

  /// Actualiza el tren en Firestore con los valores calculados
  Future<void> _updateTrainInFirestore(
    String trainId,
    EstadoTren? estado,
    int aglomeracion,
    double confidence,
  ) async {
    if (estado == null) return;

    final updateData = <String, dynamic>{
      'estado': TrainStatusMapper.estadoTrenToString(estado),
      'aglomeracion': aglomeracion,
      'confidence': TrainStatusMapper.calculateConfidenceString(confidence),
      'ultima_actualizacion': FieldValue.serverTimestamp(),
      'is_estimated': false, // Datos basados en reportes reales
    };

    await _firestore.collection('trains').doc(trainId).update(updateData);
  }
}
