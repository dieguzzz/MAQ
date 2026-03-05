import 'package:flutter/material.dart';
import '../../services/core/dev_service.dart';
import '../../core/logger.dart';

/// Tab de ajustes para el panel de desarrollador
class DevSettingsTab extends StatefulWidget {
  const DevSettingsTab({super.key});

  @override
  State<DevSettingsTab> createState() => _DevSettingsTabState();
}

class _DevSettingsTabState extends State<DevSettingsTab> {
  double _learningRate = 0.1;
  double _baseScheduleWeight = 0.7;
  double _learningWeight = 0.3;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await DevService.getSettings();
      setState(() {
        _learningRate = settings['learningRate'] ?? 0.1;
        _baseScheduleWeight = settings['baseScheduleWeight'] ?? 0.7;
        _learningWeight = settings['learningWeight'] ?? 0.3;
      });
    } catch (e) {
      AppLogger.error('Error cargando ajustes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await DevService.saveSettings(
        learningRate: _learningRate,
        baseScheduleWeight: _baseScheduleWeight,
        learningWeight: _learningWeight,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Ajustes guardados'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _resetModel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reiniciar Modelo'),
        content: const Text(
          '¿Estás seguro de que quieres reiniciar el modelo? Esto eliminará todo el aprendizaje acumulado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);
    try {
      await DevService.resetModel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Modelo reiniciado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚙️ Parámetros del Algoritmo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // Tasa de aprendizaje
          Card(
            color: Colors.grey[800],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📚 Tasa de Aprendizaje',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _learningRate,
                    min: 0.01,
                    max: 0.5,
                    divisions: 49,
                    label: _learningRate.toStringAsFixed(2),
                    onChanged: (value) => setState(() => _learningRate = value),
                  ),
                  Text(
                    '${(_learningRate * 100).toStringAsFixed(0)}% - Más alto = aprende más rápido pero es menos estable',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // Pesos del modelo
          Card(
            color: Colors.grey[800],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚖️ Pesos del Modelo',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'Horario Base',
                              style: TextStyle(color: Colors.white70),
                            ),
                            Slider(
                              value: _baseScheduleWeight,
                              min: 0.0,
                              max: 1.0,
                              onChanged: (value) {
                                setState(() {
                                  _baseScheduleWeight = value;
                                  _learningWeight = 1.0 - value;
                                });
                              },
                            ),
                            Text(
                              '${(_baseScheduleWeight * 100).toInt()}%',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'Aprendizaje',
                              style: TextStyle(color: Colors.white70),
                            ),
                            Slider(
                              value: _learningWeight,
                              min: 0.0,
                              max: 1.0,
                              onChanged: (value) {
                                setState(() {
                                  _learningWeight = value;
                                  _baseScheduleWeight = 1.0 - value;
                                });
                              },
                            ),
                            Text(
                              '${(_learningWeight * 100).toInt()}%',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Botones de control
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reiniciar Modelo'),
                  onPressed: _isSaving ? null : _resetModel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[800],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Ajustes'),
                  onPressed: _isSaving ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
