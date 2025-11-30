import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../services/admin_learning_service.dart';
import '../../theme/metro_theme.dart';

/// Widget para visualizar el rendimiento del modelo de aprendizaje
class ModelPerformanceWidget extends StatefulWidget {
  const ModelPerformanceWidget({super.key});

  @override
  State<ModelPerformanceWidget> createState() => _ModelPerformanceWidgetState();
}

class _ModelPerformanceWidgetState extends State<ModelPerformanceWidget> {
  Map<String, dynamic>? _cachedMetrics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final adminService = AdminLearningService();
      final metrics = await adminService.calculateCurrentMetrics();
      setState(() {
        _cachedMetrics = metrics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Usar métricas calculadas directamente desde los reportes
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null && _cachedMetrics == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: MetroColors.stateCritical),
              const SizedBox(height: 8),
              Text(
                'Error al calcular métricas: $_error',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loadMetrics,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _cachedMetrics;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📈 Rendimiento del Modelo',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadMetrics,
                  tooltip: 'Recalcular métricas',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (data != null) ...[
              _buildAccuracyChart(data, theme),
              const SizedBox(height: 16),
              _buildLearningProgress(data, theme),
              const SizedBox(height: 16),
              _buildDataQuality(data, theme),
              const SizedBox(height: 16),
              _buildStationPerformance(data, theme),
            ] else
              const Text('No hay datos disponibles'),
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracyChart(Map<String, dynamic> data, ThemeData theme) {
    final accuracy = (data['average_accuracy'] ?? 0.0).toDouble();
    final totalReports = data['total_learning_reports'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Precisión Promedio',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: accuracy / 100.0,
                backgroundColor: MetroColors.grayMedium,
                valueColor: AlwaysStoppedAnimation<Color>(
                  accuracy >= 80
                      ? MetroColors.stateNormal
                      : accuracy >= 60
                          ? MetroColors.stateModerate
                          : MetroColors.stateCritical,
                ),
                minHeight: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${accuracy.toStringAsFixed(1)}%',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Basado en $totalReports reportes',
          style: theme.textTheme.bodySmall?.copyWith(
            color: MetroColors.grayDark,
          ),
        ),
      ],
    );
  }

  Widget _buildLearningProgress(Map<String, dynamic> data, ThemeData theme) {
    final progress = (data['learning_progress'] ?? 0.0).toDouble();
    final velocity = (data['learning_velocity'] ?? 0.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progreso de Aprendizaje',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress / 100.0,
          backgroundColor: MetroColors.grayMedium,
          valueColor: const AlwaysStoppedAnimation<Color>(MetroColors.green),
          minHeight: 16,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${progress.toStringAsFixed(1)}%',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              velocity >= 0
                  ? '📈 +${velocity.toStringAsFixed(2)}% por día'
                  : '📉 ${velocity.toStringAsFixed(2)}% por día',
              style: theme.textTheme.bodySmall?.copyWith(
                color: velocity >= 0 ? MetroColors.green : MetroColors.stateCritical,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDataQuality(Map<String, dynamic> data, ThemeData theme) {
    final quality = (data['data_quality_score'] ?? 0.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Calidad de Datos',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: quality,
                backgroundColor: MetroColors.grayMedium,
                valueColor: AlwaysStoppedAnimation<Color>(
                  quality >= 0.8
                      ? MetroColors.stateNormal
                      : quality >= 0.6
                          ? MetroColors.stateModerate
                          : MetroColors.stateCritical,
                ),
                minHeight: 16,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${(quality * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStationPerformance(Map<String, dynamic> data, ThemeData theme) {
    final bestStations = (data['best_performing_stations'] as List<dynamic>?) ?? [];
    final worstStations = (data['worst_performing_stations'] as List<dynamic>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rendimiento por Estación',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (bestStations.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✅ Mejores',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: MetroColors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...bestStations.take(3).map((stationId) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            stationId.toString(),
                            style: theme.textTheme.bodySmall,
                          ),
                        )),
                  ],
                ),
              ),
              if (worstStations.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ Necesitan Mejora',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: MetroColors.stateCritical,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...worstStations.take(3).map((stationId) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              stationId.toString(),
                              style: theme.textTheme.bodySmall,
                            ),
                          )),
                    ],
                  ),
                ),
            ],
          ),
        ] else
          Text(
            'No hay suficientes datos',
            style: theme.textTheme.bodySmall?.copyWith(
              color: MetroColors.grayDark,
            ),
          ),
      ],
    );
  }
}

