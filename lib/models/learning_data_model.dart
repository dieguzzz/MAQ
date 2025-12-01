import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de datos para un reporte de aprendizaje
class LearningData {
  final String stationId;
  final int expectedArrival; // Tiempo que mostramos al usuario (en minutos)
  final DateTime actualArrival; // Tiempo real de llegada
  final int delayMinutes; // Diferencia en minutos (puede ser negativo si llegó antes)
  final TimeContext timeContext; // Contexto temporal
  final double confidence; // Calidad del dato (0.0-1.0)

  LearningData({
    required this.stationId,
    required this.expectedArrival,
    required this.actualArrival,
    required this.delayMinutes,
    required this.timeContext,
    this.confidence = 1.0,
  });

  /// Crea un LearningData desde un Map (para almacenamiento)
  factory LearningData.fromMap(Map<String, dynamic> map) {
    return LearningData(
      stationId: map['stationId'] as String,
      expectedArrival: map['expectedArrival'] as int,
      actualArrival: (map['actualArrival'] as Timestamp).toDate(),
      delayMinutes: map['delayMinutes'] as int,
      timeContext: TimeContext.fromMap(map['timeContext'] as Map<String, dynamic>),
      confidence: (map['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// Convierte a Map para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'stationId': stationId,
      'expectedArrival': expectedArrival,
      'actualArrival': Timestamp.fromDate(actualArrival),
      'delayMinutes': delayMinutes,
      'timeContext': timeContext.toMap(),
      'confidence': confidence,
    };
  }
}

/// Contexto temporal del reporte
class TimeContext {
  final DateTime arrivalTime; // Hora exacta de llegada
  final int dayOfWeek; // 1 (Lunes) - 7 (Domingo)
  final bool isWeekend; // Fin de semana?
  final bool isHoliday; // Día feriado?
  final String timeSlot; // "peak_am", "normal", "valle"

  TimeContext({
    required this.arrivalTime,
    required this.dayOfWeek,
    required this.isWeekend,
    required this.isHoliday,
    required this.timeSlot,
  });

  /// Crea un TimeContext desde la fecha actual
  factory TimeContext.fromDateTime(DateTime dateTime) {
    final dayOfWeek = dateTime.weekday; // 1 = Monday, 7 = Sunday
    final isWeekend = dayOfWeek == 6 || dayOfWeek == 7;
    final hour = dateTime.hour;
    
    // Determinar timeSlot
    String timeSlot;
    if (hour >= 7 && hour <= 9) {
      timeSlot = 'peak_am'; // Hora pico mañana
    } else if (hour >= 17 && hour <= 19) {
      timeSlot = 'peak_pm'; // Hora pico tarde
    } else {
      timeSlot = 'normal'; // Hora normal
    }
    
    return TimeContext(
      arrivalTime: dateTime,
      dayOfWeek: dayOfWeek,
      isWeekend: isWeekend,
      isHoliday: false, // Por ahora asumimos que no es feriado
      timeSlot: timeSlot,
    );
  }

  /// Crea un TimeContext desde un Map
  factory TimeContext.fromMap(Map<String, dynamic> map) {
    return TimeContext(
      arrivalTime: (map['arrivalTime'] as Timestamp).toDate(),
      dayOfWeek: map['dayOfWeek'] as int,
      isWeekend: map['isWeekend'] as bool,
      isHoliday: map['isHoliday'] as bool,
      timeSlot: map['timeSlot'] as String,
    );
  }

  /// Convierte a Map
  Map<String, dynamic> toMap() {
    return {
      'arrivalTime': Timestamp.fromDate(arrivalTime),
      'dayOfWeek': dayOfWeek,
      'isWeekend': isWeekend,
      'isHoliday': isHoliday,
      'timeSlot': timeSlot,
    };
  }
}

