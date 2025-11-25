import '../models/station_model.dart';
import '../utils/metro_data.dart';

/// Servicio para calcular rutas entre estaciones
class RouteCalculationService {
  /// Calcula las estaciones intermedias entre origen y destino
  /// Retorna una lista de estaciones que incluye origen, estaciones intermedias y destino
  static List<StationModel> calculateRoute(
    StationModel origen,
    StationModel destino,
    List<StationModel> allStations,
  ) {
    // Si están en la misma línea, calcular ruta directa
    if (origen.linea == destino.linea) {
      return _calculateDirectRoute(origen, destino, allStations);
    }

    // Si están en líneas diferentes, buscar estación de conexión
    // La estación de conexión es "San Miguelito" (existe en ambas líneas)
    StationModel? connectionStation;
    
    try {
      // Buscar la estación de San Miguelito en la línea del origen
      connectionStation = allStations.firstWhere(
        (s) => s.linea == origen.linea && 
               (s.id == 'l1_san_miguelito' || s.id == 'l2_san_miguelito' || 
                s.nombre.toLowerCase().contains('san miguelito')),
      );
    } catch (e) {
      // Si no se encuentra, buscar cualquier San Miguelito
      try {
        connectionStation = allStations.firstWhere(
          (s) => s.nombre.toLowerCase().contains('san miguelito'),
        );
      } catch (e2) {
        // Si no hay estación de conexión, retornar solo origen y destino
        return [origen, destino];
      }
    }

    // Calcular ruta desde origen hasta conexión
    final routeToConnection = _calculateDirectRoute(
      origen,
      connectionStation,
      allStations,
    );

    // Buscar la estación de San Miguelito en la línea del destino
    StationModel? connectionStationDest;
    try {
      connectionStationDest = allStations.firstWhere(
        (s) => s.linea == destino.linea && 
               (s.id == 'l1_san_miguelito' || s.id == 'l2_san_miguelito' || 
                s.nombre.toLowerCase().contains('san miguelito')),
      );
    } catch (e) {
      connectionStationDest = connectionStation;
    }

    // Calcular ruta desde conexión hasta destino
    final routeFromConnection = _calculateDirectRoute(
      connectionStationDest,
      destino,
      allStations,
    );

    // Combinar rutas (evitar duplicar la estación de conexión)
    final combinedRoute = <StationModel>[
      ...routeToConnection,
      ...routeFromConnection.skip(1), // Saltar la estación de conexión duplicada
    ];

    return combinedRoute;
  }

  /// Calcula la ruta directa entre dos estaciones de la misma línea
  static List<StationModel> _calculateDirectRoute(
    StationModel origen,
    StationModel destino,
    List<StationModel> allStations,
  ) {
    // Obtener el orden correcto de las estaciones según los datos estáticos
    final staticStations = origen.linea == 'linea1'
        ? MetroData.getLinea1Stations()
        : MetroData.getLinea2Stations();

    // Crear un mapa de ID a índice para ordenar
    final orderMap = <String, int>{};
    for (int i = 0; i < staticStations.length; i++) {
      orderMap[staticStations[i].id] = i;
    }

    // Obtener estaciones de la línea y ordenarlas
    final lineStations = allStations
        .where((s) => s.linea == origen.linea)
        .toList()
      ..sort((a, b) {
        final orderA = orderMap[a.id] ?? 999;
        final orderB = orderMap[b.id] ?? 999;
        return orderA.compareTo(orderB);
      });

    // Encontrar índices de origen y destino
    final origenIndex = lineStations.indexWhere((s) => s.id == origen.id);
    final destinoIndex = lineStations.indexWhere((s) => s.id == destino.id);

    if (origenIndex == -1 || destinoIndex == -1) {
      // Si no se encuentran, retornar solo origen y destino
      return [origen, destino];
    }

    // Determinar dirección y obtener estaciones intermedias
    if (origenIndex < destinoIndex) {
      // Movimiento hacia adelante (norte para línea 1, este para línea 2)
      return lineStations.sublist(origenIndex, destinoIndex + 1);
    } else {
      // Movimiento hacia atrás (sur para línea 1, oeste para línea 2)
      return lineStations.sublist(destinoIndex, origenIndex + 1).reversed.toList();
    }
  }

  /// Calcula el tiempo estimado de la ruta en minutos
  static int calculateEstimatedTime(List<StationModel> route) {
    // Asumir 2 minutos por estación (tiempo promedio entre estaciones)
    // Restar 1 porque el número de segmentos es menor que el número de estaciones
    final segments = route.length > 1 ? route.length - 1 : 1;
    return segments * 2;
  }
}

