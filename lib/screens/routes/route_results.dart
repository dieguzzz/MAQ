import 'package:flutter/material.dart';
import '../../models/route_model.dart';
import '../../models/station_model.dart';

class RouteResults extends StatelessWidget {
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
  Widget build(BuildContext context) {
    Color estadoColor;
    IconData estadoIcon;

    switch (route.estadoRuta) {
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
                            route.getEstadoTexto(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: estadoColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tiempo estimado: ${route.tiempoEstimado} minutos',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

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
                    _buildStationInfo('Origen', origen),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildStationInfo('Destino', destino),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botón para ver en mapa
            ElevatedButton.icon(
              onPressed: () {
                // Navegar al mapa con la ruta resaltada
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.map),
              label: const Text('Ver en Mapa'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
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

