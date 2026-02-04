import 'package:flutter/material.dart';
import '../../models/test_scenario_model.dart';
import '../../services/admin_learning_service.dart';
import '../../theme/metro_theme.dart';

/// Widget para ejecutar escenarios de prueba predefinidos
class TestScenariosWidget extends StatefulWidget {
  const TestScenariosWidget({super.key});

  @override
  State<TestScenariosWidget> createState() => _TestScenariosWidgetState();
}

class _TestScenariosWidgetState extends State<TestScenariosWidget> {
  final AdminLearningService _adminService = AdminLearningService();
  bool _isRunning = false;
  String? _lastResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scenarios = TestScenarios.getAllScenarios();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🧪 Escenarios de Prueba',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ejecuta escenarios predefinidos para probar el sistema',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: MetroColors.grayDark,
              ),
            ),
            const SizedBox(height: 16),
            ...scenarios.map((scenario) => _buildScenarioCard(
                  context,
                  scenario,
                  theme,
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRunning ? null : () => _runAllScenarios(context),
                icon: _isRunning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_isRunning
                    ? 'Ejecutando...'
                    : 'Ejecutar Todos los Escenarios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MetroColors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            if (_lastResult != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MetroColors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: MetroColors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _lastResult!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: MetroColors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioCard(
    BuildContext context,
    TestScenario scenario,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: MetroColors.grayLight,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scenario.nombre,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        scenario.aprendizajeEsperado,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: MetroColors.grayDark,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      _isRunning ? null : () => _runScenario(context, scenario),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MetroColors.energyOrange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(100, 36),
                  ),
                  child: const Text('Ejecutar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip(
                  'Estación',
                  scenario.estacionId,
                  theme,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  'Estimado',
                  '${scenario.tiempoEstimadoMostrado} min',
                  theme,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  'Retraso',
                  '${scenario.retrasoMinutos} min',
                  theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: MetroColors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 11,
        ),
      ),
    );
  }

  Future<void> _runScenario(BuildContext context, TestScenario scenario) async {
    setState(() {
      _isRunning = true;
      _lastResult = null;
    });

    try {
      await _adminService.runTestScenario(scenario.id);

      if (context.mounted) {
        setState(() {
          _isRunning = false;
          _lastResult = 'Escenario "${scenario.nombre}" ejecutado exitosamente';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Escenario "${scenario.nombre}" ejecutado'),
            backgroundColor: MetroColors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        setState(() {
          _isRunning = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: MetroColors.stateCritical,
          ),
        );
      }
    }
  }

  Future<void> _runAllScenarios(BuildContext context) async {
    setState(() {
      _isRunning = true;
      _lastResult = null;
    });

    try {
      await _adminService.runTestBatch();

      if (context.mounted) {
        final allScenarioIds = TestScenarios.getAllScenarioIds();
        setState(() {
          _isRunning = false;
          _lastResult =
              'Todos los escenarios (${allScenarioIds.length}) ejecutados exitosamente';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todos los escenarios ejecutados'),
            backgroundColor: MetroColors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        setState(() {
          _isRunning = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: MetroColors.stateCritical,
          ),
        );
      }
    }
  }
}
