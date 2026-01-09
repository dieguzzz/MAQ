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
  State<TrainTimeReportFlowWidget> createState() =>
      _TrainTimeReportFlowWidgetState();
}

class _TrainTimeReportFlowWidgetState extends State<TrainTimeReportFlowWidget> {
  late PageController _pageController;
  int _currentPage = 0;

  // Estado del formulario
  String?
      _selectedDirection; // Nombre de destino: 'Villa Zaita', 'Albrook', etc.
  int? _nextTrainMinutes; // 1..12
  bool _nextTrainUnknown = false;
  int? _followingTrainMinutes; // 1..12 (opcional)

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
    try {
      final locationService = LocationService();
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

          if (distance > 150) {
            print(
                'Advertencia: Usuario fuera de la estación (${distance.toStringAsFixed(0)}m)');
          }
        }
      }
    } catch (e) {
      print('Error verificando ubicación: $e');
    }
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle superior
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header con progreso animado
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reportar Tiempos',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: MetroColors.grayDark,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                              ),
                        ),
                        Text(
                          widget.station.nombre,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: MetroColors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: MetroColors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Paso ${_currentPage + 1}/3',
                        style: TextStyle(
                          color: MetroColors.blue,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Barra de progreso elegante
                Stack(
                  children: [
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      height: 8,
                      width: MediaQuery.of(context).size.width *
                          ((_currentPage + 1) / 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [MetroColors.blue, Color(0xFF66B2FF)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: MetroColors.blue.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
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
                _buildPage3(), // Siguiente tren
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Página 1: ¿Hacia dónde vas?
  Widget _buildPage1() {
    final directions =
        TrainDirectionHelper.getAvailableDirections(widget.station.linea);

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📍', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Text(
                '¿Hacia dónde vas?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: MetroColors.grayDark,
                      letterSpacing: -0.5,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Para darte el tiempo exacto, necesitamos saber tu dirección.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MetroColors.grayMedium,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 24),
          ...directions.map((direction) => _buildDirectionCard(
                direction: direction,
                isSelected: _selectedDirection == direction,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedDirection = direction);
                },
              )),
          const SizedBox(height: 32),
          _buildActionButton(
            label: 'CONTINUAR',
            onPressed: _selectedDirection != null ? _nextPage : null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDirectionCard({
    required String direction,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color =
        widget.station.linea == 'linea1' ? MetroColors.blue : MetroColors.green;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [Colors.white, color.withValues(alpha: 0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: !isSelected ? Colors.white : null,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? color : Colors.grey[200]!,
                width: isSelected ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? color.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? color : Colors.grey[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    direction.contains('Albrook') ||
                            direction.contains('Miguelito')
                        ? Icons.south_rounded
                        : Icons.north_rounded,
                    color: isSelected ? Colors.white : Colors.grey[400],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hacia',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? color : MetroColors.grayMedium,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        direction,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: MetroColors.grayDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded,
                      color: MetroColors.blue, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Página 2: Próximo Tren
  Widget _buildPage2() {
    final minutesOptions = List<int>.generate(12, (i) => i + 1);

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🚇', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Text(
                'Próximo Tren',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: MetroColors.grayDark,
                      letterSpacing: -0.5,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '¿En cuántos minutos llega el primer tren que ves en la pantalla?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MetroColors.grayMedium,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 24),
          _buildMinutesGrid(
            minutesOptions: minutesOptions,
            selected: _nextTrainMinutes,
            onSelected: (v) {
              HapticFeedback.selectionClick();
              setState(() {
                _nextTrainMinutes = v;
                _nextTrainUnknown = false;
              });
            },
          ),
          const SizedBox(height: 16),
          _buildTimeOptionCard(
            label: 'No aparece en el panel',
            isSelected: _nextTrainUnknown,
            color: Colors.orange,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _nextTrainUnknown = true;
                _nextTrainMinutes = null;
              });
            },
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildSecondaryButton(onPressed: _previousPage, label: 'ATRÁS'),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  label: 'CONTINUAR',
                  onPressed: (_nextTrainMinutes != null || _nextTrainUnknown)
                      ? _nextPage
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Página 3: Siguiente Tren + Confirmación
  Widget _buildPage3() {
    final minutesOptions = List<int>.generate(12, (i) => i + 1);
    const basePoints = 10;
    final followingBonus = _followingTrainMinutes != null ? 5 : 0;
    final totalPoints = basePoints + followingBonus;

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🕒', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Text(
                'Siguiente Tren',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: MetroColors.grayDark,
                      letterSpacing: -0.5,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Si el panel muestra un segundo tren abajo, selecciónalo también.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MetroColors.grayMedium,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 24),
          _buildMinutesGrid(
            minutesOptions: minutesOptions,
            selected: _followingTrainMinutes,
            onSelected: (v) {
              HapticFeedback.selectionClick();
              setState(() => _followingTrainMinutes = v);
            },
            color: MetroColors.blue,
          ),
          const SizedBox(height: 16),
          _buildTimeOptionCard(
            label: 'Omitir este paso',
            isSelected: _followingTrainMinutes == null,
            color: Colors.grey,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _followingTrainMinutes = null);
            },
          ),
          const SizedBox(height: 32),
          // Resumen de puntos con diseño Duolingo
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.green.withValues(alpha: 0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3), width: 2),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('✨', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GANARÁS APROX.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.green[700],
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        '+$totalPoints PUNTOS',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.green[800],
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildSecondaryButton(onPressed: _previousPage, label: 'VOLVER'),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  label: 'ENVIAR REPORTE',
                  onPressed:
                      _canSubmit() && !_isSubmitting ? _submitReport : null,
                  isSubmitting: _isSubmitting,
                  color: Colors.green[600]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    VoidCallback? onPressed,
    bool isSubmitting = false,
    Color color = MetroColors.blue,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: color.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 3, color: Colors.white),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildSecondaryButton(
      {required VoidCallback onPressed, required String label}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        side: BorderSide(color: Colors.grey[300]!, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: MetroColors.grayMedium,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildMinutesGrid({
    required List<int> minutesOptions,
    required int? selected,
    required Function(int) onSelected,
    Color color = MetroColors.blue,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: minutesOptions.length,
      itemBuilder: (context, index) {
        final minutes = minutesOptions[index];
        final isSelected = selected == minutes;
        return _buildTimeOptionCard(
          label: '$minutes min',
          isSelected: isSelected,
          color: color,
          onTap: () => onSelected(minutes),
        );
      },
    );
  }

  Widget _buildTimeOptionCard({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.grey[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : Colors.grey[200]!,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: label.contains('min') ? 22 : 14,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : MetroColors.grayDark,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  bool _canSubmit() {
    return _selectedDirection != null &&
        (_nextTrainMinutes != null || _nextTrainUnknown);
  }

  void _submitReport() async {
    if (!_canSubmit()) return;

    setState(() => _isSubmitting = true);

    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentPosition();

      await _reportService.createTrainTimeReport(
        stationId: widget.station.id,
        line: widget.station.linea,
        direction: _selectedDirection!,
        nextTrainMinutes: _nextTrainMinutes,
        nextTrainUnknown: _nextTrainUnknown,
        followingTrainMinutes: _followingTrainMinutes,
        userPosition: position,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);

        // Mostrar animación de puntos
        final basePoints = 10;
        final followingBonus = _followingTrainMinutes != null ? 5 : 0;
        final totalPoints = basePoints + followingBonus;

        PointsRewardAnimation.show(
          context,
          points: totalPoints,
          message: '¡Gracias por reportar!',
        );

        // Regresar después de un breve delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar reporte: $e')),
        );
      }
    }
  }
}
