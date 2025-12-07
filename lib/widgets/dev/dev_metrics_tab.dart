import 'package:flutter/material.dart';
import '../../services/dev_service.dart';

/// Tab de métricas en tiempo real para el panel de desarrollador
class DevMetricsTab extends StatelessWidget {
  const DevMetricsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: DevService.getRealtimeMetrics(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {
          'accuracy': 0.0,
          'todayReports': 0,
          'learningSpeed': 0.0,
          'accuracyHistory': [],
          'problemStations': [],
        };

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Métricas de precisión
              _buildMetricCard(
                context,
                '🎯 Precisión del Modelo',
                '${(data['accuracy'] as num).toStringAsFixed(1)}%',
                'Basado en últimos 100 reportes',
                Colors.blue,
              ),
              
              _buildMetricCard(
                context,
                '📈 Reportes de Hoy',
                '${data['todayReports']}',
                'Simulados + reales',
                Colors.green,
              ),
              
              _buildMetricCard(
                context,
                '⚡ Velocidad de Aprendizaje',
                '${(data['learningSpeed'] as num).toStringAsFixed(1)}%',
                'Mejora por cada 100 reportes',
                Colors.orange,
              ),
              
              // Gráfico simple
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📊 Evolución de Precisión',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: _buildSimpleChart(
                        (data['accuracyHistory'] as List?)?.cast<num>() ?? [],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Estaciones problemáticas
              if (data['problemStations'] != null && 
                  (data['problemStations'] as List).isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[900]!.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🚨 Estaciones Críticas',
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      ...(data['problemStations'] as List).map<Widget>((station) => 
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• ${station['name']}: +${station['avgDelay']}min',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ).toList(),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    Color color,
  ) {
    return Card(
      color: Colors.grey[800],
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.analytics, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleChart(List<num> history) {
    if (history.isEmpty) {
      return const Center(
        child: Text(
          'No hay datos disponibles',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return CustomPaint(
      painter: _ChartPainter(history),
      child: Container(),
    );
  }
}

/// Painter para dibujar el gráfico simple
class _ChartPainter extends CustomPainter {
  final List<num> data;

  _ChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final maxValue = data.reduce((a, b) => a > b ? a : b).toDouble();
    final minValue = data.reduce((a, b) => a < b ? a : b).toDouble();
    final range = maxValue - minValue;
    final normalizedRange = range > 0 ? range : 100.0;

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedY = ((data[i].toDouble() - minValue) / normalizedRange) * size.height;
      final y = size.height - normalizedY;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

