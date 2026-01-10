import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/metro_data_provider.dart';
import '../../widgets/custom_metro_map.dart';
import '../../widgets/train_time_report_flow_widget.dart';
import '../../widgets/station_report_sheet.dart';
import '../../widgets/station_coordinates_log.dart';
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
              // Log de coordenadas (solo en modo test)
              const StationCoordinatesLog(),
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
    if (station != null) {
      // Para estaciones: mostrar StationReportSheet con deslizamiento
      final metroProvider =
          Provider.of<MetroDataProvider>(context, listen: false);
      final trains =
          metroProvider.trains.where((t) => t.linea == station.linea).toList();

      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => StationReportSheet(
          station: station,
          trains: trains.isNotEmpty ? trains : null,
        ),
      );
    } else if (train != null) {
      // Para trenes: abrir pantalla de reporte de tren
      final metroProvider =
          Provider.of<MetroDataProvider>(context, listen: false);
      final stations = metroProvider.stations;

      // Buscar una estación de la misma línea
      StationModel? station;
      if (stations.isNotEmpty) {
        station = stations.firstWhere(
          (s) => s.linea == train.linea,
          orElse: () => stations.first,
        );
      }

      if (station != null) {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: TrainTimeReportFlowWidget(
                  station: station!,
                  scrollController: scrollController,
                ),
              );
            },
          ),
        );
      }
    }
  }
}
