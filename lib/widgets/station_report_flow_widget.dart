import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../models/station_model.dart';
import '../models/simplified_report_model.dart';
import '../services/simplified_report_service.dart';
import '../services/location_service.dart';
import '../services/report_progress_service.dart';
import '../widgets/points_reward_animation.dart';
import '../theme/metro_theme.dart';

/// Widget de flujo de reporte de estación para usar en bottom sheet
class StationReportFlowWidget extends StatefulWidget {
  final StationModel station;
  final ScrollController? scrollController;

  const StationReportFlowWidget({
    super.key,
    required this.station,
    this.scrollController,
  });

  @override
  State<StationReportFlowWidget> createState() =>
      _StationReportFlowWidgetState();
}

class _StationReportFlowWidgetState extends State<StationReportFlowWidget> {
  late PageController _pageController;
  int _currentPage = 0;

  // Pregunta 1: Información básica
  String? _operational; // 'yes' | 'partial' | 'no'
  int? _crowdLevel; // 1-5

  // Pregunta 3: Problemas específicos con ubicación detallada (nuevo sistema)
  final List<SpecificIssue> _specificIssues = [];

  final SimplifiedReportService _reportService = SimplifiedReportService();
  final ReportProgressService _progressService = ReportProgressService();
  bool _isSubmitting = false;
  bool _isLoadingProgress = true;

  final List<Map<String, dynamic>> _issueTypes = [
    {'id': 'ac', 'name': 'Aire Acond.', 'icon': '❄️'},
    {'id': 'escalator', 'name': 'Escalera', 'icon': '🪜'},
    {'id': 'elevator', 'name': 'Ascensor', 'icon': '🛗'},
    {'id': 'atm', 'name': 'Cajero', 'icon': '🏧'},
    {'id': 'recharge', 'name': 'Recarga', 'icon': '💳'},
    {'id': 'bathroom', 'name': 'Baño', 'icon': '🚻'},
    {'id': 'lights', 'name': 'Luces', 'icon': '💡'},
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadProgress();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _saveProgress();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    try {
      final progress =
          await _progressService.getStationReportProgress(widget.station.id);
      if (progress != null && mounted) {
        setState(() {
          _operational = progress['operational'] as String?;
          _crowdLevel = progress['crowdLevel'] as int?;
          // Cargar problemas específicos si existen (nuevo formato)
          final issuesData = progress['specificIssues'] as List<dynamic>?;
          if (issuesData != null) {
            _specificIssues.clear();
            for (final issueMap in issuesData) {
              if (issueMap is Map<String, dynamic>) {
                _specificIssues.add(SpecificIssue(
                  type: issueMap['type'] as String,
                  location: issueMap['location'] as String,
                  status: issueMap['status'] as String,
                ));
              }
            }
          }
          _isLoadingProgress = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoadingProgress = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProgress = false;
        });
      }
    }
  }

  Future<void> _saveProgress() async {
    try {
      if (_operational != null ||
          _crowdLevel != null ||
          _specificIssues.isNotEmpty) {
        await _progressService.saveStationReportProgress(
          stationId: widget.station.id,
          operational: _operational,
          crowdLevel: _crowdLevel,
          selectedIssues: null, // Legacy field, ya no se usa
          showOptionalDetails: false,
        );
      }
    } catch (e) {
      print('❌ Error al guardar progreso: $e');
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
    if (_isLoadingProgress) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(MetroColors.blue),
        ),
      );
    }

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
                          'Reportar Estación',
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
                        style: const TextStyle(
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
                _buildPage1(),
                _buildPage2(),
                _buildPage3(),
              ],
            ),
          ),
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
        style: const TextStyle(
          color: MetroColors.grayMedium,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }

  // Página 1: ¿La estación está funcionando?
  Widget _buildPage1() {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏢', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Text(
                '¿Cómo está la estación?',
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
            'Piensa en lo básico: accesos, torniquetes y movilidad general.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MetroColors.grayMedium,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 24),
          _buildOptionCard(
            value: 'yes',
            icon: Icons.check_circle_rounded,
            iconColor: Colors.green,
            title: 'Sí, todo normal',
            isSelected: _operational == 'yes',
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _operational = 'yes');
              _saveProgress();
            },
          ),
          _buildOptionCard(
            value: 'partial',
            icon: Icons.warning_rounded,
            iconColor: Colors.orange,
            title: 'Sí, pero con fallas',
            isSelected: _operational == 'partial',
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _operational = 'partial');
              _saveProgress();
            },
          ),
          _buildOptionCard(
            value: 'no',
            icon: Icons.cancel_rounded,
            iconColor: Colors.red,
            title: 'No / cerrada / bloqueada',
            isSelected: _operational == 'no',
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _operational = 'no');
              _saveProgress();
            },
          ),
          const SizedBox(height: 32),
          _buildActionButton(
            label: 'CONTINUAR',
            onPressed: _operational != null ? _nextPage : null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Página 2: ¿Qué tan llena está la estación ahora?
  Widget _buildPage2() {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('👥', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Text(
                'Nivel de gente',
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
            '¿Qué tan llena se siente la estación en este momento?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MetroColors.grayMedium,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 24),
          _buildCrowdOption(1, 'Baja', 'Caminas fácil', Colors.green),
          _buildCrowdOption(
              2, 'Moderada', 'Hay fila / se siente', Colors.orange),
          _buildCrowdOption(3, 'Llena', 'Cuesta moverse', Colors.deepOrange),
          _buildCrowdOption(4, 'Muy llena', 'Apretado / empujones', Colors.red),
          _buildCrowdOption(5, 'Crítica', 'No se puede avanzar', Colors.purple),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildSecondaryButton(onPressed: _previousPage, label: 'ATRÁS'),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  label: 'CONTINUAR',
                  onPressed: _crowdLevel != null ? _nextPage : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Página 3: ¿Qué está fallando? (opcional)
  Widget _buildPage3() {
    final totalPoints = 15 + (_specificIssues.length * 10);

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Text(
                '¿Hay fallas?',
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
            'Reporta equipo dañado o servicios fuera de servicio.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MetroColors.grayMedium,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 24),
          _buildOptionalDetails(),
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
                        'REPORTE VALIOSO',
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

  Widget _buildOptionalDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿Hay algún problema específico?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: MetroColors.grayDark,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.9,
          children: _issueTypes.map((type) {
            final isAdded = _specificIssues.any((i) => i.type == type['id']);
            return _buildIssueTypeChip(type, isAdded);
          }).toList(),
        ),
        if (_specificIssues.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'Problemas agregados:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: MetroColors.grayDark,
            ),
          ),
          const SizedBox(height: 12),
          ..._specificIssues.asMap().entries.map((entry) {
            return _buildSpecificIssueCard(entry.value, entry.key);
          }),
        ],
      ],
    );
  }

  Widget _buildIssueTypeChip(Map<String, dynamic> type, bool isAdded) {
    return InkWell(
      onTap: () {
        if (isAdded) {
          setState(() {
            _specificIssues.removeWhere((i) => i.type == type['id']);
          });
        } else {
          _showAddIssueDialogWithType(type['id'], type['name'], type['icon']);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color:
              isAdded ? MetroColors.blue.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAdded ? MetroColors.blue : Colors.grey[300]!,
            width: isAdded ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              type['icon'],
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              type['name'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isAdded ? FontWeight.bold : FontWeight.w500,
                color: isAdded ? MetroColors.blue : MetroColors.grayDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddIssueDialogWithType(String typeId, String name, String icon) {
    final locationController = TextEditingController();
    String status = 'not_working';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final bottomInsets = MediaQuery.of(context).viewInsets.bottom;
          return Container(
            padding: EdgeInsets.only(bottom: bottomInsets),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
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
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(icon, style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Reportar $name',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: MetroColors.grayDark,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Indica la ubicación y el estado actual',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: MetroColors.grayMedium,
                                height: 1.4,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Ubicación
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ubicación específica',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: MetroColors.grayDark,
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: locationController,
                          onChanged: (_) => setSheetState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Ej: Entrada norte, Andén 2...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: MetroColors.blue, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Estado
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¿Cómo está?',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: MetroColors.grayDark,
                              ),
                        ),
                        const SizedBox(height: 12),
                        _buildOptionCard(
                          value: 'not_working',
                          icon: Icons.cancel_rounded,
                          iconColor: Colors.red,
                          title: 'No Funciona',
                          isSelected: status == 'not_working',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setSheetState(() => status = 'not_working');
                          },
                        ),
                        _buildOptionCard(
                          value: 'working_poorly',
                          icon: Icons.warning_rounded,
                          iconColor: Colors.orange,
                          title: 'Funciona Mal',
                          isSelected: status == 'working_poorly',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setSheetState(() => status = 'working_poorly');
                          },
                        ),
                        _buildOptionCard(
                          value: 'out_of_service',
                          icon: Icons.block_rounded,
                          iconColor: Colors.grey,
                          title: 'Fuera de Servicio',
                          isSelected: status == 'out_of_service',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setSheetState(() => status = 'out_of_service');
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Botones
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(
                      children: [
                        _buildSecondaryButton(
                          onPressed: () => Navigator.pop(context),
                          label: 'CANCELAR',
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            label: 'AGREGAR',
                            onPressed: locationController.text.isNotEmpty
                                ? () {
                                    setState(() {
                                      _specificIssues.add(SpecificIssue(
                                        type: typeId,
                                        location: locationController.text,
                                        status: status,
                                      ));
                                    });
                                    Navigator.pop(context);
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpecificIssueCard(SpecificIssue issue, int index) {
    final icon = _getIssueIcon(issue.type);
    final statusColor = _getStatusColor(issue.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MetroColors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: MetroColors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getIssueTypeName(issue.type),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: MetroColors.grayDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      issue.location,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _specificIssues.removeAt(index);
                  });
                  _saveProgress();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getStatusName(issue.status),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getIssueIcon(String type) {
    switch (type) {
      case 'ac':
        return '❄️';
      case 'escalator':
        return '🎢';
      case 'elevator':
        return '🛗';
      case 'atm':
        return '🏧';
      case 'recharge':
        return '💳';
      case 'bathroom':
        return '🚻';
      case 'lights':
        return '💡';
      default:
        return '⚠️';
    }
  }

  String _getIssueTypeName(String type) {
    switch (type) {
      case 'ac':
        return 'Aire Acondicionado';
      case 'escalator':
        return 'Escalera Eléctrica';
      case 'elevator':
        return 'Elevador';
      case 'atm':
        return 'Cajero/ATM';
      case 'recharge':
        return 'Máquina de Recarga';
      case 'bathroom':
        return 'Baño';
      case 'lights':
        return 'Iluminación';
      default:
        return type;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'not_working':
        return Colors.red;
      case 'working_poorly':
        return Colors.orange;
      case 'out_of_service':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusName(String status) {
    switch (status) {
      case 'not_working':
        return '🔴 No Funciona';
      case 'working_poorly':
        return '🟡 Funciona Mal';
      case 'out_of_service':
        return '⚫ Fuera de Servicio';
      default:
        return status;
    }
  }

  Widget _buildOptionCard({
    required String value,
    required IconData icon,
    required Color iconColor,
    required String title,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          iconColor.withValues(alpha: 0.15),
                          iconColor.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: !isSelected ? Colors.grey[50] : null,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? iconColor.withValues(alpha: 0.5)
                      : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: iconColor.withValues(alpha: 0.3),
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
                  Icon(icon, color: iconColor, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? iconColor : Colors.grey[800],
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
                        color: Colors.blue,
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

  Widget _buildCrowdOption(
      int level, String emoji, String subtitle, Color color) {
    final isSelected = _crowdLevel == level;

    // Mapear emoji a icono para consistencia con página 1
    IconData icon;
    switch (level) {
      case 1:
        icon = Icons.check_circle;
        break;
      case 2:
        icon = Icons.info;
        break;
      case 3:
        icon = Icons.warning;
        break;
      case 4:
        icon = Icons.error;
        break;
      case 5:
        icon = Icons.cancel;
        break;
      default:
        icon = Icons.circle;
    }

    return _buildOptionCard(
      value: level.toString(),
      icon: icon,
      iconColor: color,
      title: '$emoji $subtitle',
      isSelected: isSelected,
      onTap: () {
        setState(() => _crowdLevel = level);
        _saveProgress();
      },
    );
  }

  bool _canSubmit() {
    return _operational != null && _crowdLevel != null && !_isSubmitting;
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

      // Usar el nuevo método que crea múltiples reportes (general + problemas específicos)
      final reportIds = await _reportService.createStationReportWithIssues(
        stationId: widget.station.id,
        operational: _operational!,
        crowdLevel: _crowdLevel!,
        specificIssues: _specificIssues.isNotEmpty ? _specificIssues : null,
        userPosition: position,
      );

      await _progressService.clearStationReportProgress(widget.station.id);

      if (!mounted) return;

      final totalPoints = 15 + (_specificIssues.length * 10);
      PointsRewardHelper.showCreateReportPoints(context, points: totalPoints);

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.of(context).pop();

      final issueCount = reportIds.length - 1; // Restar el reporte general
      final message = issueCount > 0
          ? '✅ Reporte enviado: Estado general + $issueCount problema(s) específico(s). Ganaste +$totalPoints puntos'
          : '✅ Reporte de estado general enviado. Ganaste +$totalPoints puntos';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
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
