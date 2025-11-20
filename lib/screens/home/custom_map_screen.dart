import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/metro_data_provider.dart';
import '../../widgets/custom_metro_map.dart';
import '../../models/station_model.dart';
import '../../models/train_model.dart';

class CustomMapScreen extends StatelessWidget {
  const CustomMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MetroPTY - Estado en Tiempo Real'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<MetroDataProvider>(context, listen: false).loadData();
            },
          ),
        ],
      ),
      body: Consumer<MetroDataProvider>(
        builder: (context, metroProvider, child) {
          if (metroProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Mapa personalizado
              Expanded(
                child: CustomMetroMap(
                  stations: metroProvider.stations,
                  trains: metroProvider.trains,
                  onStationTap: (station) {
                    _showStationDetails(context, station);
                  },
                  onTrainTap: (train) {
                    _showTrainDetails(context, train);
                  },
                ),
              ),
              // Leyenda
              _buildLegend(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Leyenda',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegendItem('🟢', 'Normal', Colors.green),
              const SizedBox(width: 16),
              _buildLegendItem('🟡', 'Moderado', Colors.orange),
              const SizedBox(width: 16),
              _buildLegendItem('🔴', 'Lleno', Colors.red),
              const SizedBox(width: 16),
              _buildLegendItem('⚫', 'Cerrado', Colors.grey),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegendItem('🚇', 'Normal', Colors.blue),
              const SizedBox(width: 16),
              _buildLegendItem('🚇', 'Lento', Colors.orange),
              const SizedBox(width: 16),
              _buildLegendItem('🚇', 'Detenido', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String emoji, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }

  void _showStationDetails(BuildContext context, StationModel station) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              station.nombre,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Línea: ${station.linea}'),
            const SizedBox(height: 8),
            Text('Estado: ${station.getAglomeracionTexto()}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navegar a pantalla de reporte
              },
              child: const Text('Reportar Estado'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTrainDetails(BuildContext context, TrainModel train) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tren ${train.linea}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Dirección: ${train.direccion == DireccionTren.norte ? "Norte" : "Sur"}'),
            const SizedBox(height: 8),
            Text('Velocidad: ${train.velocidad.toStringAsFixed(0)} km/h'),
            const SizedBox(height: 8),
            Text('Estado: ${train.getAglomeracionTexto()}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navegar a pantalla de reporte
              },
              child: const Text('Reportar Estado'),
            ),
          ],
        ),
      ),
    );
  }
}

