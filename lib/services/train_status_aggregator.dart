import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/simplified_report_model.dart';
import '../models/train_model.dart';
import '../utils/train_status_mapper.dart';
import 'simplified_report_confidence_service.dart';

/// Servicio para agregar múltiples reportes y calcular el estado de un tren
class TrainStatusAggregator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Note: SimplifiedReportService removed as using direct Firestore queries

  /// Actualiza el estado de un tren basado en reportes activos recientes.
  ///
  /// Filtra reportes por [trainLine] (ej: 'linea1') y opcionalmente por
  /// [direction] ('A'|'B') para evitar mezclar datos de distintas direcciones.
  ///
  /// Calcula:
  /// - estado: consenso de múltiples reportes (normal/retrasado/detenido)
  /// - aglomeracion: promedio de trainCrowd
  /// - confidence: basado en cantidad de reportes y confirmaciones
  Future<void> updateTrainFromReports(
    String trainId, {
    String? trainLine,
    String? direction,
  }) async {
    try {
      final thirtyMinutesAgo =
          DateTime.now().subtract(const Duration(minutes: 30));

      // Obtener reportes activos recientes, filtrados por línea si se provee
      final allTrainReports =
          await _getRecentTrainReports(thirtyMinutesAgo, trainLine: trainLine);

      // Filtrar por dirección y campos válidos
      final trainReports = allTrainReports
          .where((r) => r.scope == 'train' && r.status == 'active')
          .where((r) => r.trainStatus != null || r.trainCrowd != null)
          .where((r) {
        // Si se especifica dirección, filtrar por ella
        if (direction != null && r.direction != null) {
          return r.direction == direction;
        }
        return true;
      }).toList();

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
      print('Error updating train from reports: $e');
      rethrow;
    }
  }

  /// Obtiene reportes recientes de trenes, opcionalmente filtrados por línea.
  Future<List<SimplifiedReportModel>> _getRecentTrainReports(
    DateTime since, {
    String? trainLine,
  }) async {
    try {
      Query query = _firestore
          .collection('reports')
          .where('scope', isEqualTo: 'train')
          .where('status', isEqualTo: 'active');

      // Filtrar por línea en Firestore si se provee (reduce datos transferidos)
      if (trainLine != null) {
        query = query.where('trainLine', isEqualTo: trainLine);
      }

      final snapshot = await query.get();

      final reports = snapshot.docs
          .map((doc) =>
              SimplifiedReportModel.fromFirestore(doc as DocumentSnapshot))
          .where((report) => report.createdAt.isAfter(since))
          .toList();

      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reports;
    } catch (e) {
      print('Error getting recent train reports: $e');
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

  /// Delega al servicio central de confianza para consistencia con
  /// StationStatusAggregator y la UI.
  double _calculateConfidence(List<SimplifiedReportModel> reports) {
    return SimplifiedReportConfidenceService.calculateAggregatedConfidence(
        reports);
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
