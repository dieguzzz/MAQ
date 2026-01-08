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
  State<StationReportFlowWidget> createState() => _StationReportFlowWidgetState();
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
      final progress = await _progressService.getStationReportProgress(widget.station.id);
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
      if (_operational != null || _crowdLevel != null || _specificIssues.isNotEmpty) {
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
      return const Center(child: CircularProgressIndicator());
    }

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

  // Página 1: ¿La estación está funcionando?
  Widget _buildPage1() {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '1. ¿La estación está funcionando?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: MetroColors.grayDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Piensa en lo básico: entrar, pasar torniquetes, movilidad y servicio.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: MetroColors.grayMedium,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          _buildOptionCard(
            value: 'yes',
            icon: Icons.check_circle,
            iconColor: Colors.green,
            title: '✅ Sí, todo normal',
            isSelected: _operational == 'yes',
            onTap: () {
              setState(() => _operational = 'yes');
              _saveProgress();
            },
          ),
          _buildOptionCard(
            value: 'partial',
            icon: Icons.warning,
            iconColor: Colors.orange,
            title: '⚠️ Sí, pero con fallas',
            isSelected: _operational == 'partial',
            onTap: () {
              setState(() => _operational = 'partial');
              _saveProgress();
            },
          ),
          _buildOptionCard(
            value: 'no',
            icon: Icons.cancel,
            iconColor: Colors.red,
            title: '🚫 No / cerrada',
            isSelected: _operational == 'no',
            onTap: () {
              setState(() => _operational = 'no');
              _saveProgress();
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _operational != null
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

  // Página 2: ¿Qué tan llena está la estación ahora?
  Widget _buildPage2() {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '2. ¿Qué tan llena está la estación ahora?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: MetroColors.grayDark,
            ),
          ),
          const SizedBox(height: 24),
          _buildCrowdOption(1, '🟢 Baja', 'Caminas fácil', Colors.green),
          _buildCrowdOption(2, '🟡 Moderada', 'Hay fila / se siente', Colors.orange),
          _buildCrowdOption(3, '🟠 Llena', 'Cuesta moverse', Colors.deepOrange),
          _buildCrowdOption(4, '🔴 Muy llena', 'Apretado', Colors.red),
          _buildCrowdOption(5, '💀 Sardina', 'No se puede avanzar', Colors.purple),
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

  // Página 3: ¿Qué está fallando? (opcional)
  Widget _buildPage3() {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '3. ¿Qué está fallando? (opcional)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: MetroColors.grayDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Marca solo lo que NO está funcionando.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: MetroColors.grayMedium,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          _buildOptionalDetails(),
          const SizedBox(height: 24),
          // Resumen antes de enviar
          if (_operational != null && _crowdLevel != null) ...[
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
                  'Ganas: +${15 + (_specificIssues.length * 10)} puntos',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lista de problemas específicos agregados
        if (_specificIssues.isNotEmpty) ...[
          ..._specificIssues.asMap().entries.map((entry) {
            final index = entry.key;
            final issue = entry.value;
            return _buildSpecificIssueCard(issue, index);
          }),
          const SizedBox(height: 16),
        ],
        
        // Botón para agregar problema
        OutlinedButton.icon(
          onPressed: _showAddIssueDialog,
          icon: const Icon(Icons.add, color: MetroColors.blue),
          label: const Text(
            'Agregar Problema Específico',
            style: TextStyle(
              color: MetroColors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            side: const BorderSide(color: MetroColors.blue, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        
        if (_specificIssues.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars, color: Colors.blue, size: 18),
                const SizedBox(width: 8),
                Text(
                  '+${_specificIssues.length * 10} puntos por problemas específicos',
                  style: TextStyle(
                    color: Colors.blue[800],
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
  
  Widget _buildSpecificIssueCard(SpecificIssue issue, int index) {
    final icon = _getIssueIcon(issue.type);
    final statusColor = _getStatusColor(issue.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
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
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
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
              borderRadius: BorderRadius.circular(6),
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
  
  Future<void> _showAddIssueDialog() async {
    String? selectedType;
    final locationController = TextEditingController();
    String? selectedStatus;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Agregar Problema Específico'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Selector de tipo
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Problema',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedType,
                  items: const [
                    DropdownMenuItem(value: 'ac', child: Text('❄️ Aire Acondicionado')),
                    DropdownMenuItem(value: 'escalator', child: Text('🎢 Escalera Eléctrica')),
                    DropdownMenuItem(value: 'elevator', child: Text('🛗 Elevador')),
                    DropdownMenuItem(value: 'atm', child: Text('🏧 Cajero/ATM')),
                    DropdownMenuItem(value: 'recharge', child: Text('💳 Máquina de Recarga')),
                    DropdownMenuItem(value: 'bathroom', child: Text('🚻 Baño')),
                    DropdownMenuItem(value: 'lights', child: Text('💡 Iluminación')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedType = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Campo de texto para ubicación
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación / Descripción',
                    hintText: 'Ej: Escalera principal entrada norte',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 100,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                // Selector de estado
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'not_working', child: Text('🔴 No Funciona')),
                    DropdownMenuItem(value: 'working_poorly', child: Text('🟡 Funciona Mal')),
                    DropdownMenuItem(value: 'out_of_service', child: Text('⚫ Fuera de Servicio')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedStatus = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: selectedType != null &&
                      locationController.text.isNotEmpty &&
                      selectedStatus != null
                  ? () {
                      setState(() {
                        _specificIssues.add(SpecificIssue(
                          type: selectedType!,
                          location: locationController.text,
                          status: selectedStatus!,
                        ));
                      });
                      _saveProgress();
                      Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: MetroColors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
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
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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

  Widget _buildCrowdOption(int level, String emoji, String subtitle, Color color) {
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

  String _buildSummaryText() {
    final parts = <String>[];
    
    // Estado operativo
    if (_operational == 'yes') {
      parts.add('Funciona ✅');
    } else if (_operational == 'partial') {
      parts.add('Funciona con fallas ⚠️');
    } else if (_operational == 'no') {
      parts.add('No funciona / cerrada 🚫');
    }
    
    // Nivel de llenura
    if (_crowdLevel != null) {
      final crowdLabels = {
        1: 'Baja 🟢',
        2: 'Moderada 🟡',
        3: 'Llena 🟠',
        4: 'Muy llena 🔴',
        5: 'Sardina 💀',
      };
      parts.add(crowdLabels[_crowdLevel] ?? '');
    }
    
    // Problemas específicos
    if (_specificIssues.isNotEmpty) {
      final issuesList = _specificIssues.map((issue) => _getIssueTypeName(issue.type)).join(', ');
      parts.add('${ _specificIssues.length} problema(s): $issuesList');
    } else {
      parts.add('Sin problemas específicos');
    }
    
    return parts.join(' • ');
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

