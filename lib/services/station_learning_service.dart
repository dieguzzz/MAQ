import '../models/learning_data_model.dart';
import '../models/station_knowledge_model.dart';
import 'learning_storage_service.dart';

/// Servicio que maneja el aprendizaje de las estaciones
class StationLearningService {
  static const double defaultLearningRate = 0.1; // 10% de peso al nuevo dato
  static const double hourlyLearningRate = 0.15; // 15% para patrones por hora (aprende más rápido)
  final LearningStorageService _storageService = LearningStorageService();

  /// Procesa un reporte y actualiza el conocimiento de la estación
  Future<void> learnFromReport(LearningData data) async {
    // Cargar conocimiento actual de la estación
    StationKnowledge? knowledge = await _storageService.loadStationKnowledge(data.stationId);
    
    // Si no existe, crear uno nuevo
    if (knowledge == null) {
      knowledge = StationKnowledge(stationId: data.stationId);
    }

    // Actualizar conocimiento
    _updateKnowledge(knowledge, data);

    // Guardar conocimiento actualizado
    await _storageService.saveStationKnowledge(knowledge);
  }

  /// Actualiza el conocimiento basado en un reporte
  void _updateKnowledge(StationKnowledge knowledge, LearningData data) {
    // 1. Actualizar retraso promedio con moving average
    knowledge.averageDelay = updateMovingAverage(
      knowledge.averageDelay,
      data.delayMinutes.toDouble(),
      learningRate: defaultLearningRate,
    );

    // 2. Actualizar patrón por hora específica
    final hour = data.timeContext.arrivalTime.hour;
    knowledge.updatePatternForHour(hour, data.delayMinutes.toDouble(), hourlyLearningRate);

    // 3. Actualizar confiabilidad
    knowledge.reliabilityScore = _calculateNewReliability(knowledge, data);

    // 4. Incrementar contador de reportes
    knowledge.totalReports++;

    // 5. Actualizar timestamp
    knowledge.lastUpdated = DateTime.now();
  }

  /// Actualiza un promedio usando moving average con learning rate
  static double updateMovingAverage(
    double currentAverage,
    double newValue,
    {double learningRate = defaultLearningRate}
  ) {
    // Fórmula: newAvg = oldAvg * (1 - rate) + newValue * rate
    return currentAverage * (1 - learningRate) + newValue * learningRate;
  }

  /// Calcula la nueva confiabilidad basada en el reporte
  double _calculateNewReliability(StationKnowledge knowledge, LearningData data) {
    // La confiabilidad aumenta con más reportes
    // También considera la calidad del dato (confidence)
    
    final baseReliability = knowledge.reliabilityScore;
    final reportQuality = data.confidence;
    final reportsCount = knowledge.totalReports;
    
    // Más reportes = más confiable (hasta un máximo)
    final reportsFactor = (reportsCount / (reportsCount + 10)).clamp(0.0, 1.0);
    
    // Combinar factores
    final newReliability = (baseReliability * 0.7) + (reportQuality * 0.2) + (reportsFactor * 0.1);
    
    return newReliability.clamp(0.0, 1.0);
  }

  /// Calcula el ajuste aprendido para una estación en un momento específico
  Future<double> calculateLearnedAdjustment(String stationId, DateTime currentTime) async {
    final knowledge = await _storageService.loadStationKnowledge(stationId);
    
    if (knowledge == null || knowledge.totalReports == 0) {
      return 0.0; // Sin aprendizaje aún
    }

    double adjustment = 0.0;

    // A. Retraso promedio de la estación (60% del peso)
    adjustment += knowledge.averageDelay * 0.6;

    // B. Patrón específico por hora (30% del peso)
    final hour = currentTime.hour;
    final hourlyPattern = knowledge.getPatternForHour(hour);
    adjustment += hourlyPattern * 0.3;

    // C. Factores externos (10% del peso) - Por ahora 0, se puede expandir después
    // adjustment += _getExternalFactors(stationId, currentTime) * 0.1;

    return adjustment;
  }

  /// Obtiene el conocimiento de una estación
  Future<StationKnowledge?> getStationKnowledge(String stationId) async {
    return await _storageService.loadStationKnowledge(stationId);
  }

  /// Obtiene todos los conocimientos de estaciones
  Future<Map<String, StationKnowledge>> getAllStationsKnowledge() async {
    return await _storageService.getAllStationsKnowledge();
  }
}

