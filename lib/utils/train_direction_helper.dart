import '../models/train_model.dart';

/// Helper para mapear direcciones de trenes a nombres de destino según la línea
class TrainDirectionHelper {
  /// Obtiene el nombre de destino según la línea y dirección
  static String getDestinationName(String linea, DireccionTren direccion) {
    if (linea == 'linea1') {
      return direccion == DireccionTren.norte ? 'Villa Zaita' : 'Albrook';
    } else { // linea2
      return direccion == DireccionTren.norte ? 'Nuevo Tocumen' : 'Paraíso';
    }
  }

  /// Obtiene las direcciones disponibles para una línea
  static List<String> getAvailableDirections(String linea) {
    if (linea == 'linea1') {
      return ['Villa Zaita', 'Albrook'];
    } else { // linea2
      return ['Nuevo Tocumen', 'Paraíso'];
    }
  }

  /// Convierte nombre de destino a DireccionTren
  static DireccionTren? destinationToDirection(String linea, String destinationName) {
    if (linea == 'linea1') {
      if (destinationName == 'Villa Zaita') return DireccionTren.norte;
      if (destinationName == 'Albrook') return DireccionTren.sur;
    } else { // linea2
      if (destinationName == 'Nuevo Tocumen') return DireccionTren.norte;
      if (destinationName == 'Paraíso') return DireccionTren.sur;
    }
    return null;
  }
}

