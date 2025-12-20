import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../services/enhanced_report_service.dart';

/// Pantalla de validación ETA para confirmar si el tren llegó
class ETAValidationScreen extends StatefulWidget {
  final String reportId;
  final String stationName;

  const ETAValidationScreen({
    super.key,
    required this.reportId,
    required this.stationName,
  });

  @override
  State<ETAValidationScreen> createState() => _ETAValidationScreenState();
}

class _ETAValidationScreenState extends State<ETAValidationScreen> {
  final EnhancedReportService _reportService = EnhancedReportService();
  Timer? _countdownTimer;
  int _secondsRemaining = 240; // 4 minutos por defecto
  bool _isLoading = true;
  DateTime? _selectedArrivalTime;

  @override
  void initState() {
    super.initState();
    _loadReportDetails();
  }

  Future<void> _loadReportDetails() async {
    try {
      final report = await _reportService.getReport(widget.reportId);
      if (report != null && mounted) {
        setState(() {
          // Calcular tiempo restante basado en la ventana de validación
          final now = DateTime.now();
          final windowEnd = report.trainData?.etaExpectedAt;
          if (windowEnd != null) {
            final remaining = windowEnd.difference(now).inSeconds;
            _secondsRemaining = remaining > 0 ? remaining : 0;
          }
          _isLoading = false;
        });
        _startCountdown();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando reporte: $e')),
        );
      }
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0 && mounted) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        _handleExpiration();
      }
    });
  }

  Future<void> _handleExpiration() async {
    // Automáticamente marcar como "no puedo confirmar"
    await _submitValidation('cant_confirm');
  }

  Future<void> _submitValidation(String result, {DateTime? actualArrival}) async {
    try {
      final response = await _reportService.submitETAValidation(
        reportId: widget.reportId,
        validationResult: result,
        actualArrivalTime: actualArrival ?? _selectedArrivalTime,
      );

      if (mounted) {
        _countdownTimer?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ValidationSuccessScreen(
              points: response['pointsAwarded'] ?? 0,
              accuracy: response['accuracy'] ?? 'unknown',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validar Llegada'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.train, size: 48, color: Colors.blue),
                    const SizedBox(height: 8),
                    Text(
                      widget.stationName,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '¿Ya llegó el tren?',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Tiempo restante
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Tiempo para responder:',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _secondsRemaining / 240,
                    backgroundColor: Colors.grey[300],
                    color: _secondsRemaining > 60 ? Colors.green : Colors.orange,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Opciones de respuesta
            Expanded(
              child: ListView(
                children: [
                  // Opción 1: Sí, llegó
                  _buildOptionCard(
                    icon: Icons.check_circle,
                    iconColor: Colors.green,
                    title: 'SÍ, LLEGÓ',
                    subtitle: 'El tren llegó dentro del tiempo estimado',
                    points: '+30 puntos',
                    onTap: () => _showArrivalTimePicker(),
                  ),

                  const SizedBox(height: 16),

                  // Opción 2: Aún no llega
                  _buildOptionCard(
                    icon: Icons.schedule,
                    iconColor: Colors.orange,
                    title: 'AÚN NO LLEGA',
                    subtitle: 'Corregir la estimación de tiempo',
                    points: '+15 puntos',
                    onTap: () => _submitValidation('not_arrived'),
                  ),

                  const SizedBox(height: 16),

                  // Opción 3: No puedo confirmar
                  _buildOptionCard(
                    icon: Icons.exit_to_app,
                    iconColor: Colors.grey,
                    title: 'ME FUI / NO PUEDO',
                    subtitle: 'Sin penalización',
                    points: '0 puntos',
                    onTap: () => _submitValidation('cant_confirm'),
                  ),
                ],
              ),
            ),

            // Información de puntos
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Tu validación ayuda a calibrar el sistema para todos los usuarios.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String points,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 36, color: iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  points,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showArrivalTimePicker() {
    final now = DateTime.now();

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '¿A qué hora exactamente llegó?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: now,
                minuteInterval: 1,
                use24hFormat: true,
                onDateTimeChanged: (DateTime newTime) {
                  _selectedArrivalTime = newTime;
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _submitValidation('arrived', actualArrival: _selectedArrivalTime);
                    },
                    child: const Text('Confirmar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cómo funciona la validación?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Reportaste cuánto faltaba para el tren'),
            SizedBox(height: 8),
            Text('2. Ahora confirmas si realmente llegó'),
            SizedBox(height: 8),
            Text('3. Tu respuesta calibra el sistema'),
            SizedBox(height: 8),
            Text('4. Ganas puntos por ayudar'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

/// Pantalla de éxito después de validar
class ValidationSuccessScreen extends StatelessWidget {
  final int points;
  final String accuracy;

  const ValidationSuccessScreen({
    super.key,
    required this.points,
    required this.accuracy,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                '✅ Validación Enviada',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Puntos ganados:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '+$points puntos',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    if (accuracy != 'unknown')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Precisión: $accuracy',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  child: const Text('VOLVER AL MAPA'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
