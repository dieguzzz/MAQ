import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/route_model.dart';
import '../../models/station_model.dart';
import '../../services/route_calculation_service.dart';
import '../../providers/metro_data_provider.dart';
import '../../theme/metro_theme.dart';
import '../home/map_widget.dart';
import '../../widgets/custom_metro_map.dart';

class RouteResults extends StatefulWidget {
  final RouteModel route;
  final StationModel origen;
  final StationModel destino;

  const RouteResults({
    super.key,
    required this.route,
    required this.origen,
    required this.destino,
  });

  @override
  State<RouteResults> createState() => _RouteResultsState();
}

class _RouteResultsState extends State<RouteResults> {
  bool _showCustomMap = false;
  List<StationModel>? _routeStations;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateRouteStations();
    });
  }

  void _calculateRouteStations() {
    final metroProvider = Provider.of<MetroDataProvider>(context, listen: false);
    setState(() {
      _routeStations = RouteCalculationService.calculateRoute(
        widget.origen,
        widget.destino,
        metroProvider.stations,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    Color estadoColor;
    IconData estadoIcon;

    switch (widget.route.estadoRuta) {
      case EstadoRuta.optima:
        estadoColor = MetroColors.stateNormal;
        estadoIcon = Icons.check_circle;
        break;
      case EstadoRuta.congestionada:
        estadoColor = MetroColors.stateModerate;
        estadoIcon = Icons.warning;
        break;
      case EstadoRuta.interrumpida:
        estadoColor = MetroColors.stateCritical;
        estadoIcon = Icons.error;
        break;
    }

    final tieneTransbordo = widget.origen.linea != widget.destino.linea;
    final lineasUsadas = _getLineasUsadas();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu Ruta'),
        actions: [
          IconButton(
            icon: Icon(_showCustomMap ? Icons.map : Icons.train),
            onPressed: () {
              setState(() {
                _showCustomMap = !_showCustomMap;
              });
            },
            tooltip: _showCustomMap ? 'Ver Google Maps' : 'Ver Mapa del Metro',
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna izquierda: Tu Ruta (limitada en ancho)
          Container(
            width: 320,
            padding: const EdgeInsets.all(16.0),
            color: MetroColors.white,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tu ruta',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Origen
                  _buildStationStep(
                    'Origen',
                    widget.origen,
                    isFirst: true,
                  ),
                  
                  // Transbordo (si aplica)
                  if (tieneTransbordo && _routeStations != null) ...[
                    const SizedBox(height: 12),
                    _buildTransferStep(),
                    const SizedBox(height: 12),
                  ],
                  
                  // Estaciones intermedias
                  if (_routeStations != null && _routeStations!.length > 2) ...[
                    ..._routeStations!.sublist(1, _routeStations!.length - 1).asMap().entries.map((entry) {
                      return _buildStationStep(
                        'Estación ${entry.key + 1}',
                        entry.value,
                        showLine: true,
                      );
                    }),
                    const SizedBox(height: 12),
                  ],
                  
                  // Destino
                  _buildStationStep(
                    'Destino',
                    widget.destino,
                    isLast: true,
                  ),
                ],
              ),
            ),
          ),
          
          // Columna derecha: Estado, Líneas y Mapa
          Expanded(
            child: Column(
              children: [
                // Header con Estado y Líneas
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: MetroColors.white,
                  child: Row(
                    children: [
                      // Box 1: Estado
                      Expanded(
                        child: Card(
                          color: estadoColor.withValues(alpha: 0.1),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(estadoIcon, color: estadoColor, size: 32),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        widget.route.getEstadoTexto(),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: estadoColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tiempo: ${widget.route.tiempoEstimado} min',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Box 2: Líneas
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Líneas',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (lineasUsadas.isNotEmpty) ...[
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: lineasUsadas.map((linea) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: linea == 'linea1' 
                                            ? Colors.blue[100] 
                                            : Colors.orange[100],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.train,
                                              size: 14,
                                              color: linea == 'linea1' 
                                                ? Colors.blue[700] 
                                                : Colors.orange[700],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              linea == 'linea1' ? 'Línea 1' : 'Línea 2',
                                              style: TextStyle(
                                                color: linea == 'linea1' 
                                                  ? Colors.blue[700] 
                                                  : Colors.orange[700],
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ] else ...[
                                  Text(
                                    'No disponible',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Mapa (expandido, más grande)
                Expanded(
                  child: Consumer<MetroDataProvider>(
                    builder: (context, metroProvider, child) {
                      if (_showCustomMap) {
                        return CustomMetroMap(
                          stations: metroProvider.stations,
                          trains: [], // No mostrar trenes en el mapa de rutas
                          highlightedRoute: _routeStations,
                          onStationTap: (station) {
                            // Mostrar detalles de estación
                          },
                        );
                      } else {
                        return MapWidget(
                          highlightedRoute: _routeStations,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Métodos auxiliares
  List<String> _getLineasUsadas() {
    final lineas = <String>{};
    if (_routeStations != null) {
      for (var station in _routeStations!) {
        lineas.add(station.linea);
      }
    }
    return lineas.toList();
  }

  StationModel? _findTransferStation() {
    if (_routeStations == null) return null;
    
    // Buscar San Miguelito en la ruta
    for (var station in _routeStations!) {
      if (station.nombre.toLowerCase().contains('san miguelito')) {
        return station;
      }
    }
    return null;
  }

  Widget _buildStationStep(
    String label,
    StationModel station, {
    bool isFirst = false,
    bool isLast = false,
    bool showLine = false,
  }) {
    final lineColor = station.linea == 'linea1' 
      ? Colors.blue[700]! 
      : Colors.orange[700]!;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: lineColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  isFirst ? 'O' : isLast ? 'D' : '•',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isFirst || isLast ? 16 : 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    station.nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (showLine) ...[
                    const SizedBox(height: 4),
                    Text(
                      station.linea == 'linea1' ? 'Línea 1' : 'Línea 2',
                      style: TextStyle(
                        fontSize: 12,
                        color: lineColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferStep() {
    final transferStation = _findTransferStation();
    final stationName = transferStation?.nombre ?? 'San Miguelito';
    
    return Card(
      color: Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.swap_horiz, color: Colors.amber[700], size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transbordo',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stationName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cambia de línea aquí',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
