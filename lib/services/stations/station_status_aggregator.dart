import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/simplified_report_model.dart';
import '../../models/station_model.dart';
import '../../utils/station_status_mapper.dart';
import '../reports/simplified_report_service.dart';

/// Servicio para agregar múltiples reportes y calcular el estado de una estación
class StationStatusAggregator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SimplifiedReportService _reportService = SimplifiedReportService();

  /// Actualiza el estado de una estación basado en reportes activos recientes
  ///
  /// Obtiene reportes de los últimos 30 minutos y calcula:
  /// - estadoActual: consenso de múltiples reportes
  /// - aglomeracion: promedio de stationCrowd
  /// - confidence: basado en cantidad de reportes y confirmaciones
  Future<void> updateStationFromReports(String stationId) async {
    try {
      // Obtener reportes activos de los últimos 30 minutos
      final thirtyMinutesAgo =
          DateTime.now().subtract(const Duration(minutes: 30));
      final reports = await _reportService.getRecentStationReports(
        stationId,
        since: thirtyMinutesAgo,
      );

      // Filtrar solo reportes de estación activos
      final stationReports = reports
          .where((r) => r.scope == 'station' && r.status == 'active')
          .where((r) => r.stationOperational != null || r.stationCrowd != null)
          .toList();

      if (stationReports.isEmpty) {
        // No hay reportes recientes, no actualizar
        return;
      }

      // Calcular estado agregado
      final aggregatedState = _calculateAggregatedState(stationReports);
      final aggregatedCrowd = _calculateAggregatedCrowd(stationReports);
      final confidence = _calculateConfidence(stationReports);

      // Actualizar estación en Firestore
      await _updateStationInFirestore(
        stationId,
        aggregatedState,
        aggregatedCrowd,
        confidence,
      );
    } catch (e) {
      print('Error updating station from reports: $e');
      rethrow;
    }
  }

  /// Calcula el estado agregado basado en múltiples reportes
  ///
  /// Lógica:
  /// - 1 reporte: usar ese estado
  /// - 2-4 reportes: usar moda (más común)
  /// - 5+ reportes: usar promedio ponderado por confirmaciones
  EstadoEstacion? _calculateAggregatedState(
      List<SimplifiedReportModel> reports) {
    if (reports.isEmpty) return null;

    // Mapear cada reporte a estadoActual
    final estados = reports
        .map((r) => StationStatusMapper.mapToEstadoActual(
              stationOperational: r.stationOperational,
              stationCrowd: r.stationCrowd,
            ))
        .whereType<EstadoEstacion>()
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
  EstadoEstacion _getMostCommonEstado(List<EstadoEstacion> estados) {
    final counts = <EstadoEstacion, int>{};
    for (final estado in estados) {
      counts[estado] = (counts[estado] ?? 0) + 1;
    }

    EstadoEstacion? mostCommon;
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
  EstadoEstacion _getWeightedAverageEstado(
    List<SimplifiedReportModel> reports,
    List<EstadoEstacion> estados,
  ) {
    final weights = <EstadoEstacion, double>{};

    for (int i = 0; i < reports.length && i < estados.length; i++) {
      final report = reports[i];
      final estado = estados[i];
      // Peso = 1 + confirmaciones (reportes con más confirmaciones pesan más)
      final weight = 1.0 + (report.confirmations * 0.5);
      weights[estado] = (weights[estado] ?? 0.0) + weight;
    }

    EstadoEstacion? maxWeightEstado;
    double maxWeight = 0.0;
    for (final entry in weights.entries) {
      if (entry.value > maxWeight) {
        maxWeight = entry.value;
        maxWeightEstado = entry.key;
      }
    }

    return maxWeightEstado ?? estados.first;
  }

  /// Calcula aglomeracion como promedio de stationCrowd
  int _calculateAggregatedCrowd(List<SimplifiedReportModel> reports) {
    final crowdLevels = reports
        .where((r) => r.stationCrowd != null)
        .map((r) => r.stationCrowd!)
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

  /// Actualiza la estación en Firestore con los valores calculados
  Future<void> _updateStationInFirestore(
    String stationId,
    EstadoEstacion? estadoActual,
    int aglomeracion,
    double confidence,
  ) async {
    if (estadoActual == null) return;

    final updateData = <String, dynamic>{
      'estado_actual': StationStatusMapper.estadoEstacionToString(estadoActual),
      'aglomeracion': aglomeracion,
      'confidence': StationStatusMapper.mapToConfidenceString(confidence),
      'ultima_actualizacion': FieldValue.serverTimestamp(),
      'is_estimated': false, // Datos basados en reportes reales
    };

    await _firestore.collection('stations').doc(stationId).update(updateData);
  }
}
