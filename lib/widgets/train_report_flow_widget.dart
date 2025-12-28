import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../models/station_model.dart';
import '../services/simplified_report_service.dart';
import '../services/location_service.dart';
import '../widgets/points_reward_animation.dart';
import '../theme/metro_theme.dart';

/// Widget de flujo de reporte de tren para usar en bottom sheet
class TrainReportFlowWidget extends StatefulWidget {
  final StationModel station;
  final ScrollController? scrollController;

  const TrainReportFlowWidget({
    super.key,
    required this.station,
    this.scrollController,
  });

  @override
  State<TrainReportFlowWidget> createState() => _TrainReportFlowWidgetState();
}

class _TrainReportFlowWidgetState extends State<TrainReportFlowWidget> {
  late PageController _pageController;
  int _currentPage = 0;
  
  // Pregunta 1: Tiempo del panel digital
  String? _etaBucket; // '1-2' | '3-5' | '6-8' | '9+' | 'unknown'
  bool _isFromPanel = false; // Si viene del panel digital oficial
  
  // Pregunta 2: Aglomeración
  int? _crowdLevel; // 1-5
  
  // Pregunta 3: Problemas específicos (opcional)
  final Set<String> _selectedIssues = {};
  
  final SimplifiedReportService _reportService = SimplifiedReportService();
  final LocationService _locationService = LocationService();
  bool _isSubmitting = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _checkLocationAndDistance();
  }

  /// Verifica la ubicación y distancia a la estación para validar panel
  Future<void> _checkLocationAndDistance() async {
    try {
      final status = await _locationService.checkLocationStatus();
      if (status.hasPermission) {
        _currentPosition = await _locationService.getCurrentPosition();
      }
    } catch (e) {
      print('No se pudo obtener ubicación: $e');
    }
  }

  /// Valida si el usuario está dentro del geofence de la estación (200m)
  bool _isWithinStationGeofence() {
    if (_currentPosition == null) return false;
    
    try {
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        widget.station.ubicacion.latitude,
        widget.station.ubicacion.longitude,
      );
      return distance <= 200; // 200 metros
    } catch (e) {
      print('Error calculando distancia: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Reportar: ${widget.station.nombre}',
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
              _buildPage1(),
              _buildPage2(),
              _buildPage3(),
            ],
          ),
        ),
      ],
    );
  }

  // Página 1: ¿Qué dice el panel digital?
  Widget _buildPage1() {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '1. ¿Qué dice el panel digital?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: MetroColors.grayDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mira el panel oficial de la estación y copia el tiempo que muestra',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: MetroColors.grayDark,
            ),
          ),
          const SizedBox(height: 24),
          // Simulación visual del panel
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[700]!, width: 2),
            ),
            child: Column(
              children: [
                Text(
                  'PRÓXIMO TREN',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _etaBucket != null && _etaBucket != 'unknown'
                      ? _getPanelDisplayTime(_etaBucket!)
                      : '--',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'minutos',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildEtaOption('1-2', '🕐 1-2 MINUTOS', Colors.green),
          _buildEtaOption('3-5', '🕑 3-5 MINUTOS', Colors.orange),
          _buildEtaOption('6-8', '🕒 6-8 MINUTOS', Colors.deepOrange),
          _buildEtaOption('9+', '🕓 9+ MINUTOS', Colors.red),
          _buildEtaOption('unknown', '🚫 APAGADO / NO FUNCIONA', Colors.grey),
          const SizedBox(height: 24),
          // Checkbox para "Fuente: Pantalla del andén"
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isFromPanel ? Colors.blue[50] : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isFromPanel ? Colors.blue : Colors.grey[300]!,
                width: _isFromPanel ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _isFromPanel,
                  onChanged: (value) {
                    if (value == true) {
                      // Validar geofence antes de permitir
                      if (!_isWithinStationGeofence()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Debes estar dentro de la estación (200m) para marcar como panel digital'),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 3),
                          ),
                        );
                        return;
                      }
                    }
                    setState(() {
                      _isFromPanel = value ?? false;
                    });
                  },
                  activeColor: Colors.blue,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fuente: Pantalla del andén',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: MetroColors.grayDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Marca esto si copiaste el tiempo directamente del panel digital oficial de la estación',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: MetroColors.grayDark.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _etaBucket != null
                ? () {
                    HapticFeedback.lightImpact();
                    _nextPage();
                  }
                : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
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

  String _getPanelDisplayTime(String bucket) {
    switch (bucket) {
      case '1-2':
        return '2';
      case '3-5':
        return '4';
      case '6-8':
        return '7';
      case '9+':
        return '10';
      default:
        return '--';
    }
  }

  Widget _buildEtaOption(String bucket, String label, Color color) {
    final isSelected = _etaBucket == bucket;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1.0 - (value * 0.02),
          child: GestureDetector(
            onTap: () {
              setState(() => _etaBucket = bucket);
            },
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
                  Text(label.split(' ')[0], style: const TextStyle(fontSize: 28)),
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
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.green,
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

  // Página 2: ¿Qué tan lleno está?
  Widget _buildPage2() {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '2. ¿Qué tan lleno está?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: MetroColors.grayDark,
            ),
          ),
          const SizedBox(height: 24),
          _buildCrowdOption(1, '🟢 BAJA', 'Cómodo moverse', Colors.green),
          _buildCrowdOption(2, '🟡 MODERADA', 'Algo llena', Colors.orange),
          _buildCrowdOption(3, '🟠 LLENA', 'Difícil moverse', Colors.deepOrange),
          _buildCrowdOption(4, '🔴 MUY LLENA', 'Muy apretado', Colors.red),
          _buildCrowdOption(5, '💀 SARDINA', 'Extremo', Colors.purple),
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
                    onPressed: _crowdLevel != null
                        ? () {
                            HapticFeedback.lightImpact();
                            _nextPage();
                          }
                        : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
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

  // Página 3: Problemas específicos (opcional)
  Widget _buildPage3() {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Problemas rápidos (opcional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          _buildOptionalDetails(),
          const SizedBox(height: 32),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ganas: +${10 + (_selectedIssues.length * 5)} puntos',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      if (_etaBucket != null && _etaBucket != 'unknown')
                        Text(
                          '+20 puntos al validar llegada',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                          ),
                        ),
                    ],
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
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOptionalDetails() {
    final issues = [
      {'id': 'recharge', 'icon': '🎫', 'title': 'MÁQUINA RECARGA'},
      {'id': 'atm', 'icon': '💵', 'title': 'CAJERO / EFECTIVO'},
      {'id': 'ac', 'icon': '❄️', 'title': 'AIRE ACONDICIONADO'},
      {'id': 'escalator', 'icon': '⬆️', 'title': 'ESCALERAS ELÉCTRICAS'},
      {'id': 'elevator', 'icon': '♿', 'title': 'ELEVADOR / ACCESIBILIDAD'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...issues.map((issue) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildIssueCheckbox(
            issue['id']!,
            issue['icon']!,
            issue['title']!,
          ),
        )),
        if (_selectedIssues.isNotEmpty) ...[
          const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '+${_selectedIssues.length * 5} puntos por problemas',
                    style: TextStyle(
                      color: Colors.green[800],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }


  Widget _buildCrowdOption(int level, String emoji, String subtitle, Color color) {
    final isSelected = _crowdLevel == level;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1.0 - (value * 0.02),
          child: GestureDetector(
            onTap: () {
              setState(() => _crowdLevel = level);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.2),
                          color.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: !isSelected ? Colors.grey[50] : null,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? color : Colors.grey[300]!,
                  width: isSelected ? 2.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                          spreadRadius: 1,
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
                  Text(emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      '$emoji $subtitle',
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

  Widget _buildIssueCheckbox(String id, String icon, String title) {
    final isSelected = _selectedIssues.contains(id);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.green : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedIssues.remove(id);
              } else {
                _selectedIssues.add(id);
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green.withValues(alpha: 0.1) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? Colors.green[800] : Colors.grey[800],
                    ),
                  ),
                ),
                AnimatedScale(
                  scale: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.elasticOut,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
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
      ),
    );
  }

  bool _canSubmit() {
    return _etaBucket != null && _crowdLevel != null && !_isSubmitting;
  }

  Future<void> _submitReport() async {
    if (!_canSubmit()) return;

    setState(() => _isSubmitting = true);

    try {
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

      await _reportService.createTrainReport(
        stationId: widget.station.id,
        etaBucket: _etaBucket!,
        crowdLevel: _crowdLevel!,
        issues: _selectedIssues.isNotEmpty ? _selectedIssues.toList() : null,
        trainLine: widget.station.linea,
        userPosition: position,
        isPanelTime: _isFromPanel, // Pasar el flag de panel
      );

      if (!mounted) return;

      final totalPoints = 10 + (_selectedIssues.length * 5);
      PointsRewardHelper.showCreateReportPoints(context, points: totalPoints);

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.of(context).pop();
      
      // Mostrar mensaje informando sobre la validación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅ Reporte enviado. Ganaste +$totalPoints puntos'),
              const SizedBox(height: 4),
              Text(
                'Te avisaremos para confirmar cuando llegue el tren',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
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
        color: isActive ? Colors.green : MetroColors.grayMedium,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
