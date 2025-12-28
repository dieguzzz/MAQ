import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../models/station_model.dart';
import '../services/train_time_report_service.dart';
import '../services/location_service.dart';
import '../utils/train_direction_helper.dart';
import '../widgets/points_reward_animation.dart';
import '../theme/metro_theme.dart';

/// Widget de flujo para reportar tiempos de tren desde la pantalla de la estación
class TrainTimeReportFlowWidget extends StatefulWidget {
  final StationModel station;
  final ScrollController? scrollController;

  const TrainTimeReportFlowWidget({
    super.key,
    required this.station,
    this.scrollController,
  });

  @override
  State<TrainTimeReportFlowWidget> createState() => _TrainTimeReportFlowWidgetState();
}

class _TrainTimeReportFlowWidgetState extends State<TrainTimeReportFlowWidget> {
  late PageController _pageController;
  int _currentPage = 0;

  // Estado del formulario
  String? _selectedDirection; // Nombre de destino: 'Villa Zaita', 'Albrook', etc.
  String? _nextTrainRange; // '0-1', '2', '3', '4', '5', '5+', 'no-appears'
  String? _followingTrainRange; // '3-4', '5-6', '7-8', '10+', 'not-seen' (opcional)

  final TrainTimeReportService _reportService = TrainTimeReportService();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _checkLocationAndProximity();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Verifica ubicación y proximidad a la estación (en segundo plano, sin bloquear UI)
  Future<void> _checkLocationAndProximity() async {
    // Verificar en segundo plano sin bloquear la UI
    try {
      final locationService = LocationService();
      
      // Intentar obtener permisos (solicitará si están denegados)
      final hasPermission = await locationService.checkLocationPermission();
      
      if (hasPermission) {
        final position = await locationService.getCurrentPosition();
        if (position != null) {
          final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            widget.station.ubicacion.latitude,
            widget.station.ubicacion.longitude,
          );

          // Si está fuera de 150 metros, mostrar advertencia pero permitir continuar
          if (distance > 150) {
            print('Advertencia: Usuario fuera de la estación (${distance.toStringAsFixed(0)}m)');
          }
        }
      }
    } catch (e) {
      print('Error verificando ubicación: $e');
    }
    // No cambiar _isCheckingLocation, la UI ya está visible
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header con título y progreso
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Próximos trenes',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: MetroColors.grayDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${_currentPage + 1} de 3',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: MetroColors.grayDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.station.nombre,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MetroColors.grayDark.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              // Indicadores de página
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PageIndicator(isActive: _currentPage == 0),
                  const SizedBox(width: 8),
                  _PageIndicator(isActive: _currentPage == 1),
                  const SizedBox(width: 8),
                  _PageIndicator(isActive: _currentPage == 2),
                ],
              ),
            ],
          ),
        ),
        // Contenido con PageView
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              _buildPage1(), // Dirección
              _buildPage2(), // Próximo tren
              _buildPage3(), // Siguiente tren (opcional) + confirmación
            ],
          ),
        ),
      ],
    );
  }

  // Página 1: ¿Hacia dónde vas?
  Widget _buildPage1() {
    final directions = TrainDirectionHelper.getAvailableDirections(widget.station.linea);

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '1. ¿Hacia dónde vas?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: MetroColors.grayDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona la dirección del tren que estás esperando',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: MetroColors.grayMedium,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          ...directions.map((direction) => _buildDirectionCard(
            direction: direction,
            isSelected: _selectedDirection == direction,
            onTap: () {
              setState(() => _selectedDirection = direction);
            },
          )),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedDirection != null
                  ? () {
                      HapticFeedback.lightImpact();
                      _nextPage();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: MetroColors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'SIGUIENTE',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Página 2: ¿En cuántos minutos llega el próximo tren?
  Widget _buildPage2() {
    final timeRanges = [
      {'value': '0-1', 'label': '0-1 min', 'color': Colors.green},
      {'value': '2', 'label': '2 min', 'color': Colors.green},
      {'value': '3', 'label': '3 min', 'color': Colors.orange},
      {'value': '4', 'label': '4 min', 'color': Colors.orange},
      {'value': '5', 'label': '5 min', 'color': Colors.orange},
      {'value': '5+', 'label': '5+ min', 'color': Colors.red},
      {'value': 'no-appears', 'label': 'No aparece / No llegó', 'color': Colors.grey},
    ];

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '2. ¿En cuántos minutos llega el próximo tren?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: MetroColors.grayDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Copia exactamente lo que ves en la pantalla de la estación',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: MetroColors.grayMedium,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          ...timeRanges.map((range) {
            final isSelected = _nextTrainRange == range['value'];
            final color = range['color'] as Color;
            return _buildTimeOptionCard(
              label: range['label'] as String,
              isSelected: isSelected,
              color: color,
              onTap: () {
                setState(() => _nextTrainRange = range['value'] as String);
              },
            );
          }),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _previousPage();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('ANTERIOR'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _nextTrainRange != null
                      ? () {
                          HapticFeedback.lightImpact();
                          _nextPage();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: MetroColors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'SIGUIENTE',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Página 3: ¿Y el siguiente tren? (opcional) + confirmación
  Widget _buildPage3() {
    const followingRanges = [
      {'value': '3-4', 'label': '3-4 min'},
      {'value': '5-6', 'label': '5-6 min'},
      {'value': '7-8', 'label': '7-8 min'},
      {'value': '10+', 'label': '10+ min'},
      {'value': 'not-seen', 'label': 'No lo vi'},
    ];

    const basePoints = 10;
    final followingBonus = _followingTrainRange != null ? 5 : 0;
    final totalPoints = basePoints + followingBonus;

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '3. ¿Y el siguiente tren? (opcional)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: MetroColors.grayDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Si también viste el tiempo del siguiente tren, compártelo',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: MetroColors.grayMedium,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          ...followingRanges.map((range) {
            final isSelected = _followingTrainRange == range['value'];
            return _buildTimeOptionCard(
              label: range['label'] as String,
              isSelected: isSelected,
              color: Colors.blue,
              onTap: () {
                setState(() {
                  if (_followingTrainRange == range['value']) {
                    _followingTrainRange = null; // Deseleccionar
                  } else {
                    _followingTrainRange = range['value'] as String;
                  }
                });
              },
            );
          }),
          const SizedBox(height: 24),
          // Resumen antes de enviar
          if (_selectedDirection != null && _nextTrainRange != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vas a reportar:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _buildSummaryText(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 24),
          // Puntos
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green[50]!,
                  Colors.green[100]!.withValues(alpha: 0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Ganas: +$totalPoints puntos',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canSubmit() && !_isSubmitting
                  ? () {
                      HapticFeedback.mediumImpact();
                      _submitReport();
                    }
                  : null,
              icon: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              label: _isSubmitting
                  ? const SizedBox.shrink()
                  : const Text(
                      'ENVIAR REPORTE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: MetroColors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDirectionCard({
    required String direction,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1.0 - (value * 0.02),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          MetroColors.blue.withValues(alpha: 0.15),
                          MetroColors.blue.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: !isSelected ? Colors.grey[50] : null,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? MetroColors.blue.withValues(alpha: 0.5)
                      : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: MetroColors.blue.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  const Text('🚇', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      direction,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? MetroColors.blue : Colors.grey[800],
                      ),
                    ),
                  ),
                  AnimatedScale(
                    scale: isSelected ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.elasticOut,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: MetroColors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.grey[100],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? color : Colors.grey[800],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeOptionCard({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    // Mapear label a icono
    IconData icon = Icons.access_time;
    if (label.contains('min')) {
      icon = Icons.schedule;
    } else if (label.contains('No')) {
      icon = Icons.cancel;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1.0 - (value * 0.02),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.15),
                          color.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: !isSelected ? Colors.grey[50] : null,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? color.withValues(alpha: 0.5)
                      : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isSelected ? color : Colors.grey[600],
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? color : Colors.grey[800],
                      ),
                    ),
                  ),
                  AnimatedScale(
                    scale: isSelected ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.elasticOut,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _buildSummaryText() {
    final parts = <String>[];
    
    // Dirección
    if (_selectedDirection != null) {
      parts.add('🚇 $_selectedDirection');
    }
    
    // Próximo tren
    if (_nextTrainRange != null) {
      parts.add('Próximo: ${_getNextTrainLabel()}');
    }
    
    // Siguiente tren (si existe)
    if (_followingTrainRange != null) {
      parts.add('Siguiente: ${_getFollowingTrainLabel()}');
    }
    
    return parts.join(' • ');
  }

  String _getNextTrainLabel() {
    if (_nextTrainRange == null) return '';
    final labels = {
      '0-1': '0-1 min',
      '2': '2 min',
      '3': '3 min',
      '4': '4 min',
      '5': '5 min',
      '5+': '5+ min',
      'no-appears': 'No aparece',
    };
    return labels[_nextTrainRange] ?? _nextTrainRange!;
  }

  String _getFollowingTrainLabel() {
    if (_followingTrainRange == null) return '';
    final labels = {
      '3-4': '3-4 min',
      '5-6': '5-6 min',
      '7-8': '7-8 min',
      '10+': '10+ min',
      'not-seen': 'No lo vi',
    };
    return labels[_followingTrainRange] ?? _followingTrainRange!;
  }

  bool _canSubmit() {
    return _selectedDirection != null &&
        _nextTrainRange != null &&
        !_isSubmitting;
  }

  Future<void> _submitReport() async {
    if (!_canSubmit()) return;

    setState(() => _isSubmitting = true);

    try {
      // Verificar si puede reportar (no duplicado reciente)
      final canReport = await _reportService.canUserReport(widget.station.id);
      if (!canReport) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya reportaste recientemente. Espera unos minutos.'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isSubmitting = false);
        return;
      }

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

      await _reportService.createTrainTimeReport(
        stationId: widget.station.id,
        line: widget.station.linea,
        direction: _selectedDirection!,
        nextTrainRange: _nextTrainRange!,
        followingTrainRange: _followingTrainRange,
        userPosition: position,
      );

      if (!mounted) return;

      final totalPoints = 10 + (_followingTrainRange != null ? 5 : 0);
      
      // Mostrar animación de puntos
      PointsRewardHelper.showCreateReportPoints(context, points: totalPoints);

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Tiempos confirmados. Ganaste +$totalPoints puntos'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

/// Indicador de página
class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? MetroColors.blue : MetroColors.grayMedium,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

