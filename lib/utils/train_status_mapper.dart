import '../models/train_model.dart';

/// Utilidad para mapear datos de reportes simplificados a estados de tren
class TrainStatusMapper {
  /// Mapea trainStatus y trainCrowd a EstadoTren
  /// 
  /// Lógica:
  /// - 'normal' → EstadoTren.normal
  /// - 'slow' → EstadoTren.retrasado
  /// - 'stopped' → EstadoTren.detenido
  static EstadoTren? mapTrainStatusToEstado({
    String? trainStatus,
    int? trainCrowd,
  }) {
    if (trainStatus == null) return null;

    switch (trainStatus) {
      case 'normal':
        return EstadoTren.normal;
      case 'slow':
        return EstadoTren.retrasado;
      case 'stopped':
        return EstadoTren.detenido;
      default:
        return null;
    }
  }

  /// Mapea trainCrowd a aglomeracion (1-5)
  /// Si es null, retorna null
  static int? mapToAglomeracion(int? trainCrowd) {
    if (trainCrowd == null) return null;
    // Asegurar que esté en rango 1-5
    return trainCrowd.clamp(1, 5);
  }

  /// Calcula confidence string ('high'/'medium'/'low') desde número (0.0-1.0)
  static String? calculateConfidenceString(double? confidence) {
    if (confidence == null) return null;
    
    if (confidence >= 0.7) {
      return 'high';
    } else if (confidence >= 0.4) {
      return 'medium';
    } else {
      return 'low';
    }
  }

  /// Convierte estadoTren string a enum
  static EstadoTren parseEstadoTren(String estado) {
    switch (estado) {
      case 'retrasado':
        return EstadoTren.retrasado;
      case 'detenido':
        return EstadoTren.detenido;
      default:
        return EstadoTren.normal;
    }
  }

  /// Convierte estadoTren enum a string
  static String estadoTrenToString(EstadoTren estado) {
    switch (estado) {
      case EstadoTren.retrasado:
        return 'retrasado';
      case EstadoTren.detenido:
        return 'detenido';
      default:
        return 'normal';
    }
  }
}

