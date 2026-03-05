import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/route_model.dart';
import '../../models/station_model.dart';
import '../../services/location/route_calculation_service.dart';
import '../../providers/metro_data_provider.dart';
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
    final metroProvider =
        Provider.of<MetroDataProvider>(context, listen: false);
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
        estadoColor = Colors.green;
        estadoIcon = Icons.check_circle;
        break;
      case EstadoRuta.congestionada:
        estadoColor = Colors.orange;
        estadoIcon = Icons.warning;
        break;
      case EstadoRuta.interrumpida:
        estadoColor = Colors.red;
        estadoIcon = Icons.error;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados de Ruta'),
        actions: [
          // Botón para cambiar entre mapas
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
      body: Column(
        children: [
          // Panel superior con información de la ruta
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Estado de la ruta
                Card(
                  color: estadoColor.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(estadoIcon, color: estadoColor, size: 48),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.route.getEstadoTexto(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: estadoColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tiempo estimado: ${widget.route.tiempoEstimado} minutos',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Información de estaciones
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ruta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStationInfo('Origen', widget.origen),
                        if (_routeStations != null &&
                            _routeStations!.length > 2) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${_routeStations!.length - 2} estaciones intermedias',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        _buildStationInfo('Destino', widget.destino),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Mapa con la ruta resaltada
          Expanded(
            child: Consumer<MetroDataProvider>(
              builder: (context, metroProvider, child) {
                if (_showCustomMap) {
                  return CustomMetroMap(
                    stations: metroProvider.stations,
                    trains: metroProvider.trains,
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
    );
  }

  Widget _buildStationInfo(String label, StationModel station) {
    return Row(
      children: [
        Icon(
          Icons.train,
          color: station.linea == 'linea1' ? Colors.blue : Colors.orange,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
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
            ],
          ),
        ),
      ],
    );
  }
}
