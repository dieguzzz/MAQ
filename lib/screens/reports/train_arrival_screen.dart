import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/station_model.dart';
import '../../models/simplified_report_model.dart';
import '../../services/simplified_report_service.dart';
import '../../services/eta_arrival_service.dart';
import '../../services/location_service.dart';
import '../../widgets/train_arrival_animation.dart';

/// Pantalla para completar reporte de llegada del tren
class TrainArrivalScreen extends StatefulWidget {
  final StationModel station;
  final SimplifiedReportModel? pendingReport; // Si hay reporte pendiente con ETA

  const TrainArrivalScreen({
    super.key,
    required this.station,
    this.pendingReport,
  });

  @override
  State<TrainArrivalScreen> createState() => _TrainArrivalScreenState();
}

class _TrainArrivalScreenState extends State<TrainArrivalScreen> {
  // Ocupación (obligatorio)
  int? _crowdLevel; // 1-5
  
  // Estado (opcional)
  String? _trainStatus; // 'normal' | 'slow' | 'stopped' | null
  
  final SimplifiedReportService _reportService = SimplifiedReportService();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final hasPendingReport = widget.pendingReport != null;
    final points = hasPendingReport ? 30 : 15;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('YA LLEGÓ EL METRO'),
            Text(
              'Estación: ${widget.station.nombre}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasPendingReport)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Completando tu reporte de ETA. Ganarás $points puntos.',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reporte directo de llegada. Ganarás $points puntos.',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),
            
            const Text(
              '¿Cómo venía el tren?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildCrowdOption(1, '🟢 VACÍO', 'Asientos libres', Colors.green),
            const SizedBox(height: 12),
            _buildCrowdOption(2, '🟡 MODERADO', 'De pie cómodo', Colors.orange),
            const SizedBox(height: 12),
            _buildCrowdOption(3, '🔴 LLENO', 'Apretado', Colors.red),
            const SizedBox(height: 12),
            _buildCrowdOption(4, '💀 SARDINA', 'Extremo', Colors.purple),
            
            const SizedBox(height: 32),
            
            const Text(
              'Estado del tren (opcional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Si notaste algo especial',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildStatusOption('normal', '🚇 NORMAL', 'Velocidad usual', Colors.blue),
            const SizedBox(height: 12),
            _buildStatusOption('slow', '🐌 LENTO', 'Menos de 20 km/h', Colors.orange),
            const SizedBox(height: 12),
            _buildStatusOption('stopped', '🛑 DETENIDO', 'Parado en vía', Colors.red),
            
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
                    : Text(
                        'CONFIRMAR LLEGADA (+$points puntos)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  bool _canSubmit() {
    return _crowdLevel != null && !_isSubmitting;
  }

  Widget _buildCrowdOption(int level, String emoji, String subtitle, Color color) {
    final isSelected = _crowdLevel == level;
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? color.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () => setState(() => _crowdLevel = level),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Expanded(child: Text('$emoji $subtitle')),
              if (isSelected) const Icon(Icons.check_circle, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOption(String status, String emoji, String subtitle, Color color) {
    final isSelected = _trainStatus == status;
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? color.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () => setState(() => _trainStatus = status),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
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
      // Capturar hora exacta de llegada
      final arrivalTime = DateTime.now();

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

      final points = widget.pendingReport != null ? 30 : 15;

      if (widget.pendingReport != null) {
        // Actualizar reporte existente
        await _reportService.updateTrainReportOnArrival(
          reportId: widget.pendingReport!.id,
          arrivalTime: arrivalTime,
          crowdLevel: _crowdLevel,
          trainStatus: _trainStatus,
        );
      } else {
        // Nuevo sistema: arrival tap agrega señal fuerte al ETA Group (sin reporte suelto).
        final arrivalService = EtaArrivalService();
        final result = await arrivalService.submitArrivalTap(
          stationId: widget.station.id,
          userPosition: position,
        );

        if (!result.success) {
          throw Exception('No se pudo confirmar: ${result.reason}');
        }
      }

      if (!mounted) return;

      // Mostrar animación de tren
      TrainArrivalAnimation.show(
        context,
        points: points,
        onComplete: () {
          // Cerrar esta pantalla y volver al mapa
          if (mounted) {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _isSubmitting = false);
    }
  }
}

