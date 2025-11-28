import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/metro_data_provider.dart';
import '../../widgets/custom_metro_map.dart';
import '../../widgets/enhanced_report_modal.dart';
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
                    _showReportModal(context, station: station);
                  },
                  onTrainTap: (train) {
                    _showReportModal(context, train: train);
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

  void _showReportModal(
    BuildContext context, {
    StationModel? station,
    TrainModel? train,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnhancedReportModal(
        station: station,
        train: train,
      ),
    );
  }
}

