/// Enum para identificar el tipo de franja horaria
enum TimeSlot {
  peak,    // Hora pico
  normal,  // Hora normal
  valle,   // Hora valle
}

/// Servicio para manejar horarios base predeterminados del metro
class ScheduleService {
  // Horarios de operación
  static const int morningPeakStart = 6; // 6:00 AM
  static const int morningPeakEnd = 9; // 9:00 AM
  static const int eveningPeakStart = 17; // 5:00 PM
  static const int eveningPeakEnd = 19; // 7:00 PM
  
  // Tiempos base en minutos por franja horaria
  static const int peakBaseMin = 4; // Tiempo mínimo en hora pico
  static const int peakBaseMax = 6; // Tiempo máximo en hora pico
  static const int normalBaseMin = 3; // Tiempo mínimo en hora normal
  static const int normalBaseMax = 5; // Tiempo máximo en hora normal
  static const int valleBaseMin = 5; // Tiempo mínimo en hora valle
  static const int valleBaseMax = 7; // Tiempo máximo en hora valle

  /// Identifica el tipo de franja horaria según la hora del día
  static TimeSlot getTimeSlot(DateTime dateTime) {
    final hour = dateTime.hour;
    
    // Hora pico matutina: 6:00 - 9:00
    if (hour >= morningPeakStart && hour < morningPeakEnd) {
      return TimeSlot.peak;
    }
    
    // Hora pico vespertina: 17:00 - 19:00
    if (hour >= eveningPeakStart && hour < eveningPeakEnd) {
      return TimeSlot.peak;
    }
    
    // Hora normal: 9:00 - 17:00
    if (hour >= morningPeakEnd && hour < eveningPeakStart) {
      return TimeSlot.normal;
    }
    
    // Hora valle: 19:00 - 6:00
    return TimeSlot.valle;
  }

  /// Obtiene el tiempo base en minutos según la franja horaria
  /// Usa el promedio entre min y max como valor base
  static int _getBaseTimeForSlot(TimeSlot slot) {
    switch (slot) {
      case TimeSlot.peak:
        return ((peakBaseMin + peakBaseMax) / 2).round();
      case TimeSlot.normal:
        return ((normalBaseMin + normalBaseMax) / 2).round();
      case TimeSlot.valle:
        return ((valleBaseMin + valleBaseMax) / 2).round();
    }
  }

  /// Obtiene el tiempo base de horario para una estación y línea específica
  /// Por ahora, retorna un valor general basado en la hora del día
  /// En futuras fases, esto puede ajustarse por estación específica
  static int getBaseScheduleTime(
    String stationId,
    String linea,
    DateTime currentTime,
  ) {
    final slot = getTimeSlot(currentTime);
    return _getBaseTimeForSlot(slot);
  }

  /// Obtiene el tiempo estimado de llegada combinando horario base con ajustes futuros
  /// Por ahora, solo retorna el horario base
  /// En futuras fases, se combinará con ajustes de ML
  static int getEstimatedArrivalTime(
    String stationId,
    String linea,
    DateTime currentTime, {
    double? mlAdjustment, // Ajuste futuro del algoritmo de ML (opcional)
  }) {
    final baseTime = getBaseScheduleTime(stationId, linea, currentTime);
    
    // Por ahora, solo retornamos el tiempo base
    // En futuras fases, se aplicará el ajuste de ML:
    // return (baseTime + (mlAdjustment ?? 0.0)).round();
    
    return baseTime;
  }

  /// Verifica si es hora pico (útil para bonus en gamificación)
  static bool isPeakHour(DateTime dateTime) {
    return getTimeSlot(dateTime) == TimeSlot.peak;
  }

  /// Verifica si es hora crítica (hora pico)
  static bool isCriticalHour(DateTime dateTime) {
    return isPeakHour(dateTime);
  }

  /// Obtiene el nombre de la franja horaria para mostrar en UI
  static String getTimeSlotName(DateTime dateTime) {
    switch (getTimeSlot(dateTime)) {
      case TimeSlot.peak:
        return 'Hora Pico';
      case TimeSlot.normal:
        return 'Hora Normal';
      case TimeSlot.valle:
        return 'Hora Valle';
    }
  }
}

