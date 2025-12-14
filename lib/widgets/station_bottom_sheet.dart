import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/station_model.dart';
import '../models/enhanced_report_model.dart';
import '../services/enhanced_report_service.dart';
import '../screens/reports/station_report_flow.dart';
import '../screens/reports/train_report_flow.dart';

/// Bottom Sheet mejorado para mostrar información de estación
class StationBottomSheet extends StatelessWidget {
  final StationModel station;
  final List<EnhancedReportModel>? recentReports;

  const StationBottomSheet({
    super.key,
    required this.station,
    this.recentReports,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.train, size: 32, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                station.nombre,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Línea ${station.linea}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Estado actual
                      _buildStatusCard(context),
                      const SizedBox(height: 16),

                      // Próximos trenes
                      _buildUpcomingTrains(context),
                      const SizedBox(height: 16),

                      // Botones de acción (dos botones grandes separados)
                      _buildActionButtons(context),
                      const SizedBox(height: 16),

                      // Últimos reportes
                      if (recentReports != null && recentReports!.isNotEmpty)
                        _buildRecentReports(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final confidence = station.confidence ?? 'low';
    final isEstimated = station.isEstimated ?? false;
    final estadoTexto = _getEstadoTexto(station.estadoActual);
    final confianzaTexto = _getConfianzaTexto(confidence, isEstimated);

    return Card(
      color: _getEstadoColor(station.estadoActual).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estado actual:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  estadoTexto,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getConfianzaColor(confidence),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    confianzaTexto,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingTrains(BuildContext context) {
    // TODO: Obtener datos reales de próximos trenes
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Próximos trenes:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildTrainInfo('L1', '~3 min', '2 usuarios confirman', Colors.green),
            const SizedBox(height: 8),
            _buildTrainInfo('L2', '~6 min', 'baja confianza', Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainInfo(String linea, String tiempo, String info, Color color) {
    return Row(
      children: [
        Icon(Icons.train, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          'Próximo tren $linea:',
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(width: 8),
        Text(
          '⏰ $tiempo',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '($info)',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Botón A: Reportar ESTACIÓN (grande, destacado)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StationReportFlowScreen(
                    station: station,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add_alert, size: 28),
            label: const Text(
              'REPORTAR ESTACIÓN',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Botón B: Reportar TREN (grande, destacado)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TrainReportFlowScreen(
                    station: station,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.train, size: 28),
            label: const Text(
              'REPORTAR TREN',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentReports(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Últimos reportes:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...recentReports!.take(3).map((report) => _buildReportItem(report)),
      ],
    );
  }

  Widget _buildReportItem(EnhancedReportModel report) {
    final minutos = DateTime.now().difference(report.createdAt).inMinutes;
    final estado = report.stationData?.operational ?? 'yes';
    final emoji = estado == 'yes' ? '🟢' : estado == 'partial' ? '🟡' : '🔴';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Usuario: $emoji ${_getEstadoTextoFromOperational(estado)} ($minutos min)',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _getEstadoTexto(EstadoEstacion estado) {
    switch (estado) {
      case EstadoEstacion.normal:
        return '🟢 NORMAL';
      case EstadoEstacion.moderado:
        return '🟡 MODERADA';
      case EstadoEstacion.lleno:
        return '🔴 LLENA';
      case EstadoEstacion.cerrado:
        return '🚫 CERRADA';
    }
  }

  String _getEstadoTextoFromOperational(String operational) {
    switch (operational) {
      case 'yes':
        return 'Normal';
      case 'partial':
        return 'Parcial';
      case 'no':
        return 'Cerrada';
      default:
        return 'Desconocido';
    }
  }

  String _getConfianzaTexto(String confidence, bool isEstimated) {
    if (isEstimated) return '📊 ESTIMADO';
    switch (confidence) {
      case 'high':
        return '🟢 ALTA CONFIANZA';
      case 'medium':
        return '🟡 MEDIA CONFIANZA';
      default:
        return '🔴 BAJA CONFIANZA';
    }
  }

  Color _getEstadoColor(EstadoEstacion estado) {
    switch (estado) {
      case EstadoEstacion.normal:
        return Colors.green;
      case EstadoEstacion.moderado:
        return Colors.orange;
      case EstadoEstacion.lleno:
        return Colors.red;
      case EstadoEstacion.cerrado:
        return Colors.grey;
    }
  }

  Color _getConfianzaColor(String confidence) {
    switch (confidence) {
      case 'high':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
}
