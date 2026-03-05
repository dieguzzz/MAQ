import 'package:flutter/material.dart';
import '../../models/station_model.dart';
import '../../services/core/dev_service.dart';
import '../../services/core/firebase_service.dart';
import '../../core/logger.dart';

/// Tab de simulación para el panel de desarrollador
class DevSimulationTab extends StatefulWidget {
  const DevSimulationTab({super.key});

  @override
  State<DevSimulationTab> createState() => _DevSimulationTabState();
}

class _DevSimulationTabState extends State<DevSimulationTab> {
  final FirebaseService _firebaseService = FirebaseService();
  List<StationModel> _stations = [];
  String? _selectedStationId;
  int _simulationCount = 10;
  bool _isSimulating = false;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    try {
      final stations = await _firebaseService.getStations();
      setState(() {
        _stations = stations;
        if (stations.isNotEmpty && _selectedStationId == null) {
          _selectedStationId = stations.first.id;
        }
      });
    } catch (e) {
      AppLogger.error('Error cargando estaciones: $e');
    }
  }

  Future<void> _simulateOnTimeArrival() async {
    if (_selectedStationId == null) {
      _showError('Por favor selecciona una estación');
      return;
    }

    setState(() => _isSimulating = true);
    try {
      await DevService.simulateArrivalReport(
        stationId: _selectedStationId!,
        delayMinutes: 0,
        onTime: true,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Llegada puntual simulada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSimulating = false);
      }
    }
  }

  Future<void> _simulateDelay() async {
    if (_selectedStationId == null) {
      _showError('Por favor selecciona una estación');
      return;
    }

    // Mostrar diálogo para ingresar minutos de retraso
    final delayController = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simular Retraso'),
        content: TextField(
          controller: delayController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Minutos de retraso',
            hintText: 'Ej: 5',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final delay = int.tryParse(delayController.text);
              if (delay != null && delay >= 0) {
                Navigator.of(context).pop(delay);
              }
            },
            child: const Text('Simular'),
          ),
        ],
      ),
    );

    if (result == null) return;

    setState(() => _isSimulating = true);
    try {
      await DevService.simulateArrivalReport(
        stationId: _selectedStationId!,
        delayMinutes: result,
        onTime: false,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Retraso de $result minutos simulado'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSimulating = false);
      }
    }
  }

  Future<void> _runMassSimulation() async {
    if (_stations.isEmpty) {
      _showError('No hay estaciones disponibles');
      return;
    }

    setState(() => _isSimulating = true);
    try {
      await DevService.runMassSimulation(_simulationCount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $_simulationCount reportes simulados'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSimulating = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🚇 Simular Reportes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Selector de estación
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Estación',
              labelStyle: const TextStyle(color: Colors.white70),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[800],
            ),
            style: const TextStyle(color: Colors.white),
            initialValue: _selectedStationId,
            items: _stations
                .map((station) => DropdownMenuItem(
                      value: station.id,
                      child: Text(
                        station.nombre,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedStationId = value),
          ),

          const SizedBox(height: 12),

          // Simular llegada a tiempo
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle),
            label: const Text('Simular Llegada Puntual'),
            onPressed: _isSimulating ? null : _simulateOnTimeArrival,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),

          const SizedBox(height: 8),

          // Simular retraso
          ElevatedButton.icon(
            icon: const Icon(Icons.schedule),
            label: const Text('Simular Retraso'),
            onPressed: _isSimulating ? null : _simulateDelay,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),

          const SizedBox(height: 12),

          // Simulación masiva
          Card(
            color: Colors.grey[800],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 Simulación Masiva',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _simulationCount.toDouble(),
                    min: 1,
                    max: 100,
                    divisions: 99,
                    label: '$_simulationCount reportes',
                    onChanged: (value) =>
                        setState(() => _simulationCount = value.toInt()),
                  ),
                  ElevatedButton(
                    onPressed: _isSimulating ? null : _runMassSimulation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    child: Text(
                      _isSimulating
                          ? 'Generando...'
                          : 'Generar $_simulationCount reportes aleatorios',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
