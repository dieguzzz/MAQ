import 'package:geolocator/geolocator.dart';
import '../models/train_model.dart';
import '../models/station_model.dart';
import 'schedule_service.dart';

/// Servicio para validar tiempos estimados reportados por usuarios
class TimeEstimationService {
  // Margen de error aceptable en minutos (±2 minutos)
  static const int errorMarginMinutes = 2;
  
  // Velocidad promedio del metro en km/h (aproximadamente 30 km/h)
  static const double averageSpeedKmh = 30.0;
  
  // Tiempo promedio de parada en estación en minutos
  static const double averageStopTimeMinutes = 0.5;

  // Ponderación para combinar horario base con cálculo de distancia
  static const double scheduleWeight = 0.7; // 70% horario base
  static const double distanceWeight = 0.3; // 30% cálculo de distancia

  /// Calcula el tiempo estimado de llegada de un tren a una estación
  /// Combina horario base con cálculo de distancia (promedio ponderado)
  /// Retorna el tiempo en minutos
  /// Versión síncrona que usa tiempo base sin aprendizaje (para compatibilidad)
  int calculateEstimatedArrivalTime(
    TrainModel train,
    StationModel station, {
    double? mlAdjustment, // Ajuste futuro del algoritmo de ML (opcional)
  }) {
    final currentTime = DateTime.now();
    
    // Obtener tiempo base del horario según la hora del día (versión síncrona)
    final scheduleBaseTime = ScheduleService.getEstimatedArrivalTimeSync(
      station.id,
      station.linea,
      currentTime,
    );

    // Calcular tiempo basado en distancia entre tren y estación
    final distance = Geolocator.distanceBetween(
      train.ubicacionActual.latitude,
      train.ubicacionActual.longitude,
      station.ubicacion.latitude,
      station.ubicacion.longitude,
    );

    // Convertir distancia de metros a kilómetros
    final distanceKm = distance / 1000.0;

    // Calcular tiempo de viaje basado en velocidad
    // Si el tren está detenido o tiene velocidad 0, usar velocidad promedio
    final speedKmh = train.velocidad > 0 ? train.velocidad : averageSpeedKmh;
    
    // Tiempo de viaje en horas
    final travelTimeHours = distanceKm / speedKmh;
    
    // Convertir a minutos y agregar tiempo de parada
    final distanceBasedMinutes = (travelTimeHours * 60).round() + averageStopTimeMinutes.round();

    // Aplicar ajuste ML si se proporciona
    final adjustedBaseTime = mlAdjustment != null
        ? (scheduleBaseTime + mlAdjustment).round()
        : scheduleBaseTime;

    // Combinar horario base (70%) con cálculo de distancia (30%)
    final combinedTime = (adjustedBaseTime * scheduleWeight + 
                         distanceBasedMinutes * distanceWeight).round();

    // Asegurar que el tiempo mínimo sea 1 minuto
    return combinedTime < 1 ? 1 : combinedTime;
  }
  
  /// Versión asíncrona que usa aprendizaje (para uso futuro)
  Future<int> calculateEstimatedArrivalTimeAsync(
    TrainModel train,
    StationModel station, {
    double? mlAdjustment,
  }) async {
    final currentTime = DateTime.now();
    
    // Obtener tiempo base con aprendizaje
    final scheduleBaseTime = await ScheduleService.getEstimatedArrivalTime(
      station.id,
      station.linea,
      currentTime,
    );

    // Calcular tiempo basado en distancia entre tren y estación
    final distance = Geolocator.distanceBetween(
      train.ubicacionActual.latitude,
      train.ubicacionActual.longitude,
      station.ubicacion.latitude,
      station.ubicacion.longitude,
    );

    // Convertir distancia de metros a kilómetros
    final distanceKm = distance / 1000.0;

    // Calcular tiempo de viaje basado en velocidad
    final speedKmh = train.velocidad > 0 ? train.velocidad : averageSpeedKmh;
    final travelTimeHours = distanceKm / speedKmh;
    final distanceBasedMinutes = (travelTimeHours * 60).round() + averageStopTimeMinutes.round();

    // Combinar horario base (70%) con cálculo de distancia (30%)
    final combinedTime = (scheduleBaseTime * scheduleWeight + 
                         distanceBasedMinutes * distanceWeight).round();

    // Asegurar que el tiempo mínimo sea 1 minuto
    return combinedTime < 1 ? 1 : combinedTime;
  }

  /// Valida si el tiempo reportado por el usuario es razonable
  /// Compara el tiempo reportado con el tiempo calculado
  /// Retorna true si está dentro del margen de error aceptable
  bool validateReportedTime(
    int reportedMinutes,
    TrainModel train,
    StationModel station,
  ) {
    final calculatedMinutes = calculateEstimatedArrivalTime(train, station);
    
    // Calcular diferencia absoluta
    final difference = (reportedMinutes - calculatedMinutes).abs();
    
    // Validar si está dentro del margen de error
    final isValid = difference <= errorMarginMinutes;
    
    print('⏱️ Validación de tiempo estimado:');
    print('   Tiempo reportado: $reportedMinutes minutos');
    print('   Tiempo calculado: $calculatedMinutes minutos');
    print('   Diferencia: $difference minutos');
    print('   Margen de error: ±$errorMarginMinutes minutos');
    print('   Válido: $isValid');
    
    return isValid;
  }

  /// Obtiene información detallada sobre la validación
  Map<String, dynamic> getValidationDetails(
    int reportedMinutes,
    TrainModel train,
    StationModel station,
  ) {
    final calculatedMinutes = calculateEstimatedArrivalTime(train, station);
    final difference = (reportedMinutes - calculatedMinutes).abs();
    final isValid = difference <= errorMarginMinutes;
    
    return {
      'reportedMinutes': reportedMinutes,
      'calculatedMinutes': calculatedMinutes,
      'difference': difference,
      'isValid': isValid,
      'errorMargin': errorMarginMinutes,
    };
  }
}

