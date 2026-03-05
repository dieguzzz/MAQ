import 'dart:convert';

/// Modelo de conocimiento aprendido por estación
class StationKnowledge {
  final String stationId;
  double averageDelay; // Retraso promedio aprendido (en minutos)
  final Map<int, double> hourlyPatterns; // Patrones por hora (0-23)
  double reliabilityScore; // Confiabilidad (0.0-1.0)
  int totalReports; // Cantidad de reportes recibidos
  DateTime lastUpdated; // Última actualización

  StationKnowledge({
    required this.stationId,
    this.averageDelay = 0.0,
    Map<int, double>? hourlyPatterns,
    this.reliabilityScore = 0.5, // Empieza con confianza media
    this.totalReports = 0,
    DateTime? lastUpdated,
  })  : hourlyPatterns = hourlyPatterns ?? {},
        lastUpdated = lastUpdated ?? DateTime.now();

  /// Crea un StationKnowledge desde un Map (JSON)
  factory StationKnowledge.fromMap(Map<String, dynamic> map) {
    final hourlyPatternsMap =
        map['hourlyPatterns'] as Map<String, dynamic>? ?? {};
    final hourlyPatterns = <int, double>{};

    hourlyPatternsMap.forEach((key, value) {
      hourlyPatterns[int.parse(key)] = (value as num).toDouble();
    });

    return StationKnowledge(
      stationId: map['stationId'] as String,
      averageDelay: (map['averageDelay'] as num?)?.toDouble() ?? 0.0,
      hourlyPatterns: hourlyPatterns,
      reliabilityScore: (map['reliabilityScore'] as num?)?.toDouble() ?? 0.5,
      totalReports: map['totalReports'] as int? ?? 0,
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.parse(map['lastUpdated'] as String)
          : DateTime.now(),
    );
  }

  /// Convierte a Map para almacenamiento JSON
  Map<String, dynamic> toMap() {
    final hourlyPatternsMap = <String, double>{};
    hourlyPatterns.forEach((key, value) {
      hourlyPatternsMap[key.toString()] = value;
    });

    return {
      'stationId': stationId,
      'averageDelay': averageDelay,
      'hourlyPatterns': hourlyPatternsMap,
      'reliabilityScore': reliabilityScore,
      'totalReports': totalReports,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Convierte a JSON string
  String toJson() {
    return jsonEncode(toMap());
  }

  /// Crea desde JSON string
  factory StationKnowledge.fromJson(String json) {
    return StationKnowledge.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }

  /// Obtiene el patrón para una hora específica
  double getPatternForHour(int hour) {
    return hourlyPatterns[hour] ?? 0.0;
  }

  /// Actualiza el patrón para una hora específica
  void updatePatternForHour(int hour, double delay, double learningRate) {
    final currentPattern = hourlyPatterns[hour] ?? 0.0;
    hourlyPatterns[hour] =
        currentPattern * (1 - learningRate) + delay * learningRate;
  }
}
