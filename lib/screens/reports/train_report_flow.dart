import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/station_model.dart';
import '../../services/simplified_report_service.dart';
import '../../services/location_service.dart';
import 'eta_validation_screen.dart';

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
  // Ocupación (obligatorio)
  int? _crowdLevel; // 1-5
  
  // Estado (opcional)
  String? _trainStatus; // 'normal' | 'slow' | 'stopped' | null
  
  // ETA bucket (opcional pero recomendado)
  String? _etaBucket; // '1-2' | '3-5' | '6-8' | '9+' | 'unknown' | null
  
  final SimplifiedReportService _reportService = SimplifiedReportService();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('REPORTAR TREN'),
        subtitle: Text('Estación: ${widget.station.nombre}'),
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
          
          const Text(
            '¿Cuánto falta para el próximo tren? (recomendado)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Esto ayuda a calibrar el sistema',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
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
                'Te preguntaremos si el tren realmente llegó',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }
  
  bool _canSubmit() {
    return _crowdLevel != null && !_isSubmitting;
  }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            '¿Estado del tren?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildStatusOption('normal', '🚇 NORMAL', 'Velocidad usual', Colors.blue),
          const SizedBox(height: 12),
          _buildStatusOption('slow', '🐌 LENTO', 'Menos de 20 km/h', Colors.orange),
          const SizedBox(height: 12),
          _buildStatusOption('stopped', '🛑 DETENIDO', 'Parado en vía', Colors.red),
          const SizedBox(height: 12),
          _buildStatusOption('express', '⚡ EXPRESS', 'No para en todas', Colors.purple),
          
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canContinueStep1() ? _goToStep2 : null,
              child: const Text('SIGUIENTE'),
            ),
          ),
          
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.stars, color: Colors.blue),
                SizedBox(width: 8),
                Text('Puntos base: +20'),
              ],
            ),
          ),
        ],
      ),
    );
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

      final reportId = await _reportService.createTrainReport(
        stationId: widget.station.id,
        crowdLevel: _crowdLevel!,
        trainStatus: _trainStatus, // Opcional
        etaBucket: _etaBucket, // Opcional
        trainLine: widget.station.linea,
        userPosition: position, // Opcional
      );

      if (!mounted) return;

      // Si necesita validación, mostrar mensaje y volver
      if (_etaBucket != null && _etaBucket != 'unknown') {
        Navigator.popUntil(context, (route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reporte enviado. Te avisaremos en unos minutos para validar si el tren llegó.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        // Si no necesita validación, volver al mapa
        Navigator.popUntil(context, (route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte enviado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
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
