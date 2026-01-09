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
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
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
          Row(
            children: [
              const Text('📺', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¿Qué dice el panel digital?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: MetroColors.grayDark,
                        letterSpacing: -0.5,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Mira el panel oficial de la estación y selecciona el tiempo.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MetroColors.grayDark,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 24),
          // Simulación visual del panel
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B), // Dark slate
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF334155), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PRÓXIMO TREN',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _etaBucket != null && _etaBucket != 'unknown'
                      ? _getPanelDisplayTime(_etaBucket!)
                      : '--',
                  style: const TextStyle(
                    color: Color(0xFFFFCC00), // LED Amber
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Courier', // Monospace feel
                    letterSpacing: 4,
                    shadows: [
                      BoxShadow(
                        color: Color(0x66FFCC00),
                        blurRadius: 20,
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'MINUTOS',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildEtaOption('1-2', '🕐 1-2 min', 'Llegando ya', Colors.green),
          _buildEtaOption('3-5', '🕑 3-5 min', 'Espera corta', Colors.teal),
          _buildEtaOption('6-8', '🕒 6-8 min', 'Espera media', Colors.orange),
          _buildEtaOption('9+', '🕓 9+ min', 'Demora', Colors.red),
          _buildEtaOption('unknown', '🚫 Apagado', 'No funciona', Colors.grey),
          const SizedBox(height: 24),
          // Checkbox para "Fuente: Pantalla del andén"
          GestureDetector(
            onTap: () {
              bool newValue = !_isFromPanel;
              if (newValue == true) {
                // Validar geofence antes de permitir
                if (!_isWithinStationGeofence()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Debes estar en la estación para validar panel oficial'),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
              }
              setState(() {
                _isFromPanel = newValue;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isFromPanel
                    ? MetroColors.blue.withValues(alpha: 0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isFromPanel ? MetroColors.blue : Colors.grey[200]!,
                  width: _isFromPanel ? 2 : 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color:
                          _isFromPanel ? MetroColors.blue : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color:
                            _isFromPanel ? MetroColors.blue : Colors.grey[400]!,
                        width: 2,
                      ),
                    ),
                    child: _isFromPanel
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('👀', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(
                              'Lo vi en la pantalla',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _isFromPanel
                                        ? MetroColors.blue
                                        : MetroColors.grayDark,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ganas +20 puntos extras por confirmar',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: MetroColors.grayMedium, // No opacity
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: MetroColors.blue,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: MetroColors.blue.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'SIGUIENTE',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5),
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

  Widget _buildEtaOption(
      String bucket, String title, String subtitle, Color color) {
    final isSelected = _etaBucket == bucket;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1.0 + (value * 0.02),
          child: GestureDetector(
            onTap: () {
              setState(() => _etaBucket = bucket);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
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
                color: !isSelected ? Colors.white : null,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : Colors.grey[200]!,
                  width: isSelected ? 2 : 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        title.split(' ')[0], // Emoji
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.substring(
                              title.indexOf(' ') + 1), // Remove emoji
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? color : MetroColors.grayDark,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected
                                ? color.withValues(alpha: 0.8)
                                : MetroColors.grayMedium,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
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
          Row(
            children: [
              const Text('👥', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¿Qué tan lleno está?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: MetroColors.grayDark,
                        letterSpacing: -0.5,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Informa sobre la cantidad de personas en el tren.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MetroColors.grayDark,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 24),
          _buildCrowdOption(
              1, '🟢', 'BAJA', 'Muchos asientos vacíos', Colors.green),
          _buildCrowdOption(
              2, '🟡', 'MEDIA', 'Gente de pie, pero cómodo', Colors.teal),
          _buildCrowdOption(
              3, '🟠', 'ALTA', 'Bien lleno, poco espacio', Colors.orange),
          _buildCrowdOption(
              4, '🔴', 'SARDINA', 'No cabe un alma más', Colors.purple),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _previousPage();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  child: Text(
                    'ATRÁS',
                    style: TextStyle(
                      color: MetroColors.grayMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _crowdLevel != 0
                      ? () {
                          HapticFeedback.lightImpact();
                          _nextPage();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: MetroColors.blue,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: MetroColors.blue.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
          Row(
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¿Algo más que reportar?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: MetroColors.grayDark,
                        letterSpacing: -0.5,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Informa sobre problemas específicos para ganar más puntos.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MetroColors.grayDark,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 16),
          _buildOptionalDetails(),
          const SizedBox(height: 32),
          // Resumen de puntos
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withValues(alpha: 0.1),
                  Colors.green.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.3),
                width: 2,
              ),
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
                        'TOTAL PUNTOS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.green[700],
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        '+${10 + (_selectedIssues.length * 5)} PUNTOS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
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
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white),
              label: _isSubmitting
                  ? const SizedBox.shrink()
                  : const Text(
                      'ENVIAR REPORTE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: MetroColors.blue,
                foregroundColor: Colors.white,
                elevation: 6,
                shadowColor: MetroColors.blue.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => _previousPage(),
              child: Text(
                'VOLVER A EDITAR',
                style: TextStyle(
                  color: MetroColors.grayMedium,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
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

  Widget _buildCrowdOption(
      int level, String emoji, String title, String subtitle, Color color) {
    final isSelected = _crowdLevel == level;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1.0 + (value * 0.02),
          child: GestureDetector(
            onTap: () {
              setState(() => _crowdLevel = level);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
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
                color: !isSelected ? Colors.white : null,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : Colors.grey[200]!,
                  width: isSelected ? 2 : 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? color : MetroColors.grayDark,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected
                                ? color.withValues(alpha: 0.8)
                                : MetroColors.grayMedium,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1.0 + (value * 0.02),
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedIssues.remove(id);
                } else {
                  _selectedIssues.add(id);
                }
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [
                          Color(0x26EF4444), // Red 0.15
                          Color(0x0DEF4444), // Red 0.05
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: !isSelected ? Colors.white : null,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.red : Colors.grey[200]!,
                  width: isSelected ? 2 : 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
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
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color:
                            isSelected ? Colors.red[800] : MetroColors.grayDark,
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
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
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
