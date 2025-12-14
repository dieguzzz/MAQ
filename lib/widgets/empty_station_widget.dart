import 'package:flutter/material.dart';
import '../models/station_model.dart';

class EmptyStationWidget extends StatelessWidget {
  final StationModel station;
  final VoidCallback onReport;

  const EmptyStationWidget({
    super.key,
    required this.station,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, size: 64, color: Colors.orange),
          const SizedBox(height: 16),
          const Text(
            '🚫 SIN DATOS RECIENTES',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Esta estación aún no tiene información en tiempo real.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            '¡SÉ EL PRIMERO EN REPORTAR!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Como FUNDADOR, ganas:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('🎯 100 puntos extras'),
          Text('🏆 Badge "Pionero ${station.nombre}"'),
          const Text('📈 Mejoras la app para todos'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onReport,
            icon: const Icon(Icons.add_alert),
            label: const Text('REPORTAR ESTADO'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
