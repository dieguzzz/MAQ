import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/learning_data_model.dart';
import '../../models/station_knowledge_model.dart';
import '../../models/station_model.dart';
import '../../services/station_learning_service.dart';
import '../../providers/metro_data_provider.dart';

/// Panel de demostración del algoritmo de aprendizaje
class LearningDemoPanel extends StatefulWidget {
  const LearningDemoPanel({super.key});

  @override
  State<LearningDemoPanel> createState() => _LearningDemoPanelState();
}

class _LearningDemoPanelState extends State<LearningDemoPanel> {
  final StationLearningService _learningService = StationLearningService();
  final TextEditingController _expectedTimeController = TextEditingController();
  final TextEditingController _actualTimeController = TextEditingController();
  
  String? _selectedStationId;
  StationKnowledge? _currentKnowledge;
  bool _isLoading = false;
  String? _lastResult;

  @override
  void dispose() {
    _expectedTimeController.dispose();
    _actualTimeController.dispose();
    super.dispose();
  }

  Future<void> _loadStationKnowledge() async {
    if (_selectedStationId == null) return;
    
    setState(() {
      _isLoading = true;
    });

    final knowledge = await _learningService.getStationKnowledge(_selectedStationId!);
    
    setState(() {
      _currentKnowledge = knowledge;
      _isLoading = false;
    });
  }

  Future<void> _simulateReport() async {
    if (_selectedStationId == null) {
      _showSnackBar('Por favor selecciona una estación', Colors.orange);
      return;
    }

    final expectedTimeStr = _expectedTimeController.text.trim();
    final actualTimeStr = _actualTimeController.text.trim();

    if (expectedTimeStr.isEmpty || actualTimeStr.isEmpty) {
      _showSnackBar('Por favor completa ambos tiempos', Colors.orange);
      return;
    }

    final expectedTime = int.tryParse(expectedTimeStr);
    final actualTime = int.tryParse(actualTimeStr);

    if (expectedTime == null || actualTime == null) {
      _showSnackBar('Los tiempos deben ser números válidos', Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Crear LearningData
      final now = DateTime.now();
      final delayMinutes = actualTime - expectedTime;
      
      final learningData = LearningData(
        stationId: _selectedStationId!,
        expectedArrival: expectedTime,
        actualArrival: now,
        delayMinutes: delayMinutes,
        timeContext: TimeContext.fromDateTime(now),
        confidence: 1.0,
      );

      // Procesar aprendizaje
      await _learningService.learnFromReport(learningData);

      // Recargar conocimiento actualizado
      await _loadStationKnowledge();

      // Calcular nueva predicción
      final adjustment = await _learningService.calculateLearnedAdjustment(
        _selectedStationId!,
        now,
      );

      final newPrediction = expectedTime + adjustment.round();

      setState(() {
        _isLoading = false;
        _lastResult = 'Reporte procesado!\n'
            'Delay: ${delayMinutes > 0 ? '+' : ''}$delayMinutes min\n'
            'Nueva predicción: $newPrediction min (antes: $expectedTime min)';
      });

      _showSnackBar('Reporte simulado exitosamente', Colors.green);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Panel Demo - Algoritmo de Aprendizaje'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sección 1: Ingresar Reporte de Prueba
            _buildReportInputSection(),
            const SizedBox(height: 24),
            
            // Sección 2: Estado Actual de la Estación
            _buildStationStatusSection(),
            const SizedBox(height: 24),
            
            // Sección 3: Cálculo de Nueva Predicción
            _buildPredictionSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildReportInputSection() {
    final metroProvider = Provider.of<MetroDataProvider>(context);
    final stations = metroProvider.stations;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Ingresar Reporte de Prueba',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Dropdown de estaciones
            DropdownButtonFormField<String>(
              value: _selectedStationId,
              decoration: const InputDecoration(
                labelText: 'Estación',
                border: OutlineInputBorder(),
              ),
              items: stations.map((station) {
                return DropdownMenuItem(
                  value: station.id,
                  child: Text(station.nombre),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStationId = value;
                  _currentKnowledge = null;
                });
                _loadStationKnowledge();
              },
            ),
            const SizedBox(height: 16),
            
            // Campo tiempo esperado
            TextField(
              controller: _expectedTimeController,
              decoration: const InputDecoration(
                labelText: 'Tiempo esperado mostrado (minutos)',
                border: OutlineInputBorder(),
                hintText: 'Ej: 5',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            // Campo tiempo real
            TextField(
              controller: _actualTimeController,
              decoration: const InputDecoration(
                labelText: 'Tiempo real de llegada (minutos)',
                border: OutlineInputBorder(),
                hintText: 'Ej: 8',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            // Botón simular
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _simulateReport,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: const Text('Simular Reporte'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationStatusSection() {
    if (_selectedStationId == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Selecciona una estación para ver su estado',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_currentKnowledge == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📈 Estado Actual de la Estación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Sin datos de aprendizaje aún',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📈 Estado Actual de la Estación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Retraso promedio
            _buildInfoRow(
              'Retraso promedio:',
              '${_currentKnowledge!.averageDelay.toStringAsFixed(2)} min',
            ),
            const SizedBox(height: 8),
            
            // Reportes recibidos
            _buildInfoRow(
              'Reportes recibidos:',
              '${_currentKnowledge!.totalReports}',
            ),
            const SizedBox(height: 8),
            
            // Confiabilidad
            _buildInfoRow(
              'Confiabilidad:',
              '${(_currentKnowledge!.reliabilityScore * 100).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 16),
            
            // Patrones por hora
            if (_currentKnowledge!.hourlyPatterns.isNotEmpty) ...[
              const Text(
                'Patrones por hora:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildHourlyPatternsTable(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildHourlyPatternsTable() {
    final patterns = _currentKnowledge!.hourlyPatterns;
    final sortedHours = patterns.keys.toList()..sort();

    if (sortedHours.isEmpty) {
      return Text(
        'Sin patrones por hora aún',
        style: TextStyle(color: Colors.grey[600]),
      );
    }

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
      },
      children: [
        const TableRow(
          children: [
            Text('Hora', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Retraso (min)', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        ...sortedHours.map((hour) {
          return TableRow(
            children: [
              Text('$hour:00'),
              Text('${patterns[hour]!.toStringAsFixed(2)}'),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildPredictionSection() {
    if (_selectedStationId == null || _currentKnowledge == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔮 Cálculo de Nueva Predicción',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            if (_lastResult != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  _lastResult!,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ] else ...[
              Text(
                'Simula un reporte para ver la nueva predicción',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

