import '../models/station_model.dart';

/// Utilidad para mapear datos de reportes simplificados a estado de estación
class StationStatusMapper {
  /// Mapea stationOperational + stationCrowd a estadoActual
  ///
  /// Lógica:
  /// - 'yes' + crowdLevel 1-2 → 'normal'
  /// - 'yes' + crowdLevel 3 → 'moderado'
  /// - 'yes' + crowdLevel 4-5 → 'lleno'
  /// - 'partial' → 'moderado'
  /// - 'no' → 'cerrado'
  static EstadoEstacion? mapToEstadoActual({
    String? stationOperational,
    int? stationCrowd,
  }) {
    if (stationOperational == null) return null;

    switch (stationOperational) {
      case 'no':
        return EstadoEstacion.cerrado;
      case 'partial':
        return EstadoEstacion.moderado;
      case 'yes':
        if (stationCrowd == null) {
          return EstadoEstacion.normal; // Por defecto si no hay crowd
        }
        if (stationCrowd <= 2) {
          return EstadoEstacion.normal;
        } else if (stationCrowd == 3) {
          return EstadoEstacion.moderado;
        } else {
          // stationCrowd >= 4
          return EstadoEstacion.lleno;
        }
      default:
        return null;
    }
  }

  /// Mapea stationCrowd a aglomeracion (1-5)
  /// Si es null, retorna null
  static int? mapToAglomeracion(int? stationCrowd) {
    if (stationCrowd == null) return null;
    // Asegurar que esté en rango 1-5
    return stationCrowd.clamp(1, 5);
  }

  /// Calcula confidence string ('high'/'medium'/'low') desde número (0.0-1.0)
  static String? mapToConfidenceString(double? confidence) {
    if (confidence == null) return null;

    if (confidence >= 0.7) {
      return 'high';
    } else if (confidence >= 0.4) {
      return 'medium';
    } else {
      return 'low';
    }
  }

  /// Convierte estadoActual string a enum
  static EstadoEstacion parseEstadoEstacion(String estado) {
    switch (estado) {
      case 'moderado':
        return EstadoEstacion.moderado;
      case 'lleno':
        return EstadoEstacion.lleno;
      case 'cerrado':
        return EstadoEstacion.cerrado;
      default:
        return EstadoEstacion.normal;
    }
  }

  /// Convierte estadoActual enum a string
  static String estadoEstacionToString(EstadoEstacion estado) {
    switch (estado) {
      case EstadoEstacion.moderado:
        return 'moderado';
      case EstadoEstacion.lleno:
        return 'lleno';
      case EstadoEstacion.cerrado:
        return 'cerrado';
      default:
        return 'normal';
    }
  }
}
