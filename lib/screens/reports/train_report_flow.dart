import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/station_model.dart';
import '../../services/enhanced_report_service.dart';
import '../../providers/location_provider.dart';
import 'eta_validation_screen.dart';

/// Flujo de reporte de tren (3 pasos)
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
  int _currentStep = 0;
  
  // Paso 1: Estado del tren
  int? _crowdLevel; // 1-5
  String? _trainStatus; // 'normal' | 'slow' | 'stopped' | 'express'
  
  // Paso 2: Estimación de tiempo
  String? _etaBucket; // '<1' | '1-2' | '3-5' | '6-10' | '10+' | 'unknown'
  
  final EnhancedReportService _reportService = EnhancedReportService();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('REPORTAR TREN VISTO'),
        subtitle: Text('${_currentStep + 1} de 3'),
      ),
      body: _currentStep == 0
          ? _buildStep1()
          : _currentStep == 1
              ? _buildStep2()
              : _buildStep3(),
    );
  }

  Widget _buildStep1() {
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

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estás en: ${widget.station.nombre}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            'Línea: ${widget.station.linea}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          const Text(
            '¿Cuánto crees que falta para que llegue el PRÓXIMO tren?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildEtaOption('<1', '⏱️ <1 MIN', 'Ya está llegando'),
          const SizedBox(height: 12),
          _buildEtaOption('1-2', '🕐 1-2 MINUTOS', ''),
          const SizedBox(height: 12),
          _buildEtaOption('3-5', '🕑 3-5 MINUTOS', ''),
          const SizedBox(height: 12),
          _buildEtaOption('6-10', '🕒 6-10 MINUTOS', ''),
          const SizedBox(height: 12),
          _buildEtaOption('10+', '🕓 10+ MINUTOS', ''),
          const SizedBox(height: 12),
          _buildEtaOption('unknown', '🤷 NO SÉ / NO VI', ''),
          
          const SizedBox(height: 32),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _goToStep1,
                  child: const Text('ATRÁS'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _etaBucket != null ? _goToStep3 : null,
                  child: const Text('SIGUIENTE'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          if (_etaBucket != null && _etaBucket != 'unknown')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.stars, color: Colors.green),
                  SizedBox(width: 8),
                  Text('+10 puntos extra por estimar'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    final needsValidation = _etaBucket != null && _etaBucket != 'unknown';
    final timingConfig = {
      '<1': {'wait': 1, 'window': 2},
      '1-2': {'wait': 2, 'window': 4},
      '3-5': {'wait': 3, 'window': 6},
      '6-10': {'wait': 5, 'window': 10},
      '10+': {'wait': 8, 'window': 15},
    };
    
    final config = timingConfig[_etaBucket] ?? {'wait': 3, 'window': 6};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎯 VALIDACIÓN AUTOMÁTICA',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (needsValidation) ...[
            const Text(
              '¡Perfecto! En breve te preguntaremos si el tren realmente llegó.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              '📅 Te avisaremos en:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '⏰ ${config['wait']} minutos (si dijiste ${_etaBucket})',
              style: const TextStyle(fontSize: 14),
            ),
          ] else ...[
            const Text(
              'Reporte enviado sin validación de tiempo.',
              style: TextStyle(fontSize: 16),
            ),
          ],
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GANARÁS:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('✅ 20 puntos ahora'),
                if (needsValidation) ...[
                  const Text('✅ +30 si confirmas llegada'),
                  const Text('✅ +10 si tu estimación fue exacta'),
                ],
                const SizedBox(height: 8),
                Text(
                  '🎯 TOTAL POSIBLE: ${needsValidation ? 60 : 20} puntos',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('ENVIAR REPORTE'),
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'La validación ayuda a calibrar todo el sistema. ¡Gracias!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
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

  bool _canContinueStep1() {
    return _crowdLevel != null && _trainStatus != null;
  }

  void _goToStep1() => setState(() => _currentStep = 0);
  void _goToStep2() => setState(() => _currentStep = 1);
  void _goToStep3() => setState(() => _currentStep = 2);

  Future<void> _submitReport() async {
    if (!_canContinueStep1() || _etaBucket == null) return;

    setState(() => _isSubmitting = true);

    try {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      final position = locationProvider.currentPosition;
      
      if (position == null) {
        throw Exception('Ubicación no disponible');
      }

      final geoPoint = GeoPoint(position.latitude, position.longitude);
      final accuracy = position.accuracy;

      final reportId = await _reportService.createTrainReport(
        stationId: widget.station.id,
        crowdLevel: _crowdLevel!,
        trainStatus: _trainStatus!,
        etaBucket: _etaBucket!,
        userLocation: geoPoint,
        accuracy: accuracy,
      );

      if (!mounted) return;

      // Si necesita validación, navegar a pantalla de validación
      if (_etaBucket != 'unknown') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ETAValidationScreen(
              reportId: reportId,
              stationName: widget.station.nombre,
            ),
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
