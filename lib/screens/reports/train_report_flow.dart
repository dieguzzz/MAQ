import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/station_model.dart';
import '../../services/simplified_report_service.dart';
import '../../services/location_service.dart';
import '../../widgets/points_reward_animation.dart';

/// Flujo de reporte de tren (simplificado - todo en una pantalla)
class TrainReportFlowScreen extends StatefulWidget {
  final StationModel station;

  const TrainReportFlowScreen({
    super.key,
    required this.station,
  });

  @override
  State<TrainReportFlowScreen> createState() => _TrainReportFlowScreenState();
}

class _TrainReportFlowScreenState extends State<TrainReportFlowScreen> {
  // ETA bucket (obligatorio)
  String? _etaBucket; // '1-2' | '3-5' | '6-8' | '9+' | 'unknown' | null
  
  final SimplifiedReportService _reportService = SimplifiedReportService();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('REPORTAR TREN'),
            Text(
              'Estación: ${widget.station.nombre}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: _buildSingleScreen(),
    );
  }

  Widget _buildSingleScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Cuánto falta para el próximo tren?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Esto ayuda a calibrar el sistema',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _buildEtaOption('1-2', '🕐 1-2 MINUTOS', ''),
          const SizedBox(height: 12),
          _buildEtaOption('3-5', '🕑 3-5 MINUTOS', ''),
          const SizedBox(height: 12),
          _buildEtaOption('6-8', '🕒 6-8 MINUTOS', ''),
          const SizedBox(height: 12),
          _buildEtaOption('9+', '🕓 9+ MINUTOS', ''),
          const SizedBox(height: 12),
          _buildEtaOption('unknown', '🤷 NO SÉ', ''),
          
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSubmit() ? _submitReport : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'ENVIAR REPORTE',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.stars, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Puntos base: +20'),
                  ],
                ),
                if (_etaBucket != null && _etaBucket != 'unknown')
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('+10 puntos por estimar tiempo'),
                  ),
              ],
            ),
          ),
          
          if (_etaBucket != null && _etaBucket != 'unknown')
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'Cuando el tren llegue, usa el botón "Ya llegó el metro" para completar tu reporte',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }
  
  bool _canSubmit() {
    return _etaBucket != null && !_isSubmitting;
  }

  Widget _buildEtaOption(String bucket, String emoji, String subtitle) {
    final isSelected = _etaBucket == bucket;
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.blue.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () => setState(() => _etaBucket = bucket),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(emoji.split(' ')[0], style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Expanded(child: Text(emoji)),
              if (isSelected) const Icon(Icons.check_circle, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (!_canSubmit()) return;

    setState(() => _isSubmitting = true);

    try {
      // Intentar obtener ubicación (opcional)
      Position? position;
      try {
        final locationService = LocationService();
        final status = await locationService.checkLocationStatus();
        if (status.hasPermission) {
          position = await locationService.getCurrentPosition();
        }
      } catch (e) {
        print('No se pudo obtener ubicación: $e');
      }

      await _reportService.createTrainReport(
        stationId: widget.station.id,
        crowdLevel: null, // Se completará cuando llegue el tren
        trainStatus: null, // Se completará cuando llegue el tren
        etaBucket: _etaBucket!,
        trainLine: widget.station.linea,
        userPosition: position, // Opcional
      );

      if (!mounted) return;

      // Calcular puntos ganados: 20 base + 10 si hay ETA
      final totalPoints = 20 + ((_etaBucket != null && _etaBucket != 'unknown') ? 10 : 0);
      
      // Mostrar animación de puntos ganados
      PointsRewardHelper.showCreateReportPoints(context, points: totalPoints);
      
      // Esperar un momento para que se vea la animación
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Volver al mapa
      Navigator.popUntil(context, (route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reporte enviado. Usa el botón "Ya llegó el metro" cuando el tren llegue.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
