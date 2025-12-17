import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/station_model.dart';
import '../../services/simplified_report_service.dart';
import '../../services/location_service.dart';
import '../../services/report_progress_service.dart';
import '../../widgets/points_reward_animation.dart';

/// Flujo de reporte de estación (2 pasos)
class StationReportFlowScreen extends StatefulWidget {
  final StationModel station;

  const StationReportFlowScreen({
    super.key,
    required this.station,
  });

  @override
  State<StationReportFlowScreen> createState() => _StationReportFlowScreenState();
}

class _StationReportFlowScreenState extends State<StationReportFlowScreen> {
  int _currentStep = 0;
  
  // Paso 1: Información básica
  String? _operational; // 'yes' | 'partial' | 'no'
  int? _crowdLevel; // 1-5
  
  // Paso 2: Problemas específicos (opcional)
  final Set<String> _selectedIssues = {};
  bool _showOptionalDetails = false;
  
  final SimplifiedReportService _reportService = SimplifiedReportService();
  final ReportProgressService _progressService = ReportProgressService();
  bool _isSubmitting = false;
  bool _isLoadingProgress = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void dispose() {
    // Guardar progreso cuando se destruye el widget
    _saveProgress();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    try {
      print('🔄 Cargando progreso para estación ${widget.station.id}...');
      final progress = await _progressService.getStationReportProgress(widget.station.id);
      if (progress != null && mounted) {
        print('✅ Progreso encontrado: $progress');
        setState(() {
          _operational = progress['operational'] as String?;
          _crowdLevel = progress['crowdLevel'] as int?;
          _showOptionalDetails = progress['showOptionalDetails'] ?? false;
          final issues = progress['selectedIssues'] as List<dynamic>?;
          if (issues != null) {
            _selectedIssues.clear();
            _selectedIssues.addAll(issues.map((e) => e.toString()));
          }
          _isLoadingProgress = false;
        });
      } else {
        print('ℹ️ No hay progreso guardado para esta estación');
        if (mounted) {
          setState(() {
            _isLoadingProgress = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error al cargar progreso: $e');
      if (mounted) {
        setState(() {
          _isLoadingProgress = false;
        });
      }
    }
  }

  Future<void> _saveProgress() async {
    try {
      // Solo guardar si hay algún progreso (al menos una opción seleccionada)
      if (_operational != null || _crowdLevel != null || _selectedIssues.isNotEmpty) {
        await _progressService.saveStationReportProgress(
          stationId: widget.station.id,
          operational: _operational,
          crowdLevel: _crowdLevel,
          selectedIssues: _selectedIssues.isNotEmpty ? _selectedIssues.toList() : null,
          showOptionalDetails: _showOptionalDetails,
        );
        print('✅ Progreso guardado para estación ${widget.station.id}: operational=$_operational, crowdLevel=$_crowdLevel, issues=${_selectedIssues.length}');
      }
    } catch (e) {
      print('❌ Error al guardar progreso: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProgress) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return PopScope(
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        // Guardar progreso cuando el usuario sale de la pantalla
        if (didPop) {
          await _saveProgress();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('REPORTAR ESTACIÓN: ${widget.station.nombre}'),
              Text(
                _currentStep == 0 ? '1 de 2' : '2 de 2 (Opcional)',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        body: _currentStep == 0 ? _buildStep1() : _buildStep2(),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '1. ¿La estación está operativa?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            value: 'yes',
            icon: Icons.check_circle,
            iconColor: Colors.green,
            title: '✅ SÍ - Todo funciona',
            isSelected: _operational == 'yes',
            onTap: () {
              setState(() => _operational = 'yes');
              _saveProgress();
            },
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            value: 'partial',
            icon: Icons.warning,
            iconColor: Colors.orange,
            title: '⚠️ PARCIAL - Algo falla',
            isSelected: _operational == 'partial',
            onTap: () {
              setState(() => _operational = 'partial');
              _saveProgress();
            },
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            value: 'no',
            icon: Icons.cancel,
            iconColor: Colors.red,
            title: '🚫 NO - Cerrada / grave',
            isSelected: _operational == 'no',
            onTap: () {
              setState(() => _operational = 'no');
              _saveProgress();
            },
          ),
          
          const SizedBox(height: 32),
          
          const Text(
            '2. ¿Qué tan llena está?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildCrowdOption(1, '🟢 BAJA', 'Cómodo moverse', Colors.green),
          const SizedBox(height: 12),
          _buildCrowdOption(2, '🟡 MODERADA', 'Algo llena', Colors.orange),
          const SizedBox(height: 12),
          _buildCrowdOption(3, '🟠 LLENA', 'Difícil moverse', Colors.deepOrange),
          const SizedBox(height: 12),
          _buildCrowdOption(4, '🔴 MUY LLENA', 'Muy apretado', Colors.red),
          const SizedBox(height: 12),
          _buildCrowdOption(5, '💀 SARDINA', 'Extremo', Colors.purple),
          
          const SizedBox(height: 32),
          
          // Botón para agregar detalles opcionales
          if (_canContinueStep1())
            OutlinedButton.icon(
              onPressed: () {
                setState(() => _showOptionalDetails = true);
                _saveProgress();
              },
              icon: const Icon(Icons.add),
              label: const Text('Agregar detalles (opcional)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canContinueStep1() ? _submitReport : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
              ),
              child: const Text(
                'CONFIRMAR',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.stars, color: Colors.green),
                SizedBox(width: 8),
                Text('Ganas: +15 puntos'),
              ],
            ),
          ),
          
          // Mostrar detalles opcionales si el usuario los quiere
          if (_showOptionalDetails) ...[
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            _buildOptionalDetails(),
          ],
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
        const Text(
          'Problemas rápidos (opcional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...issues.take(5).map((issue) => _buildIssueCheckbox(
          issue['id']!,
          issue['icon']!,
          issue['title']!,
        )),
        if (_selectedIssues.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${_selectedIssues.length * 5} puntos por problemas',
              style: const TextStyle(color: Colors.blue, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildStep2() {
    // Este paso ya no se usa - todo está en Step 1 ahora
    return const SizedBox.shrink();
  }

  Widget _buildOptionCard({
    required String value,
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? iconColor.withOpacity(0.1) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 32),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
              if (isSelected)
                const Icon(Icons.check_circle, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCrowdOption(int level, String emoji, String subtitle, Color color) {
    final isSelected = _crowdLevel == level;
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? color.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () {
          setState(() => _crowdLevel = level);
          _saveProgress();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$emoji $subtitle',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIssueCheckbox(String id, String icon, String title) {
    final isSelected = _selectedIssues.contains(id);
    return CheckboxListTile(
      value: isSelected,
      onChanged: (value) {
        setState(() {
          if (value == true) {
            _selectedIssues.add(id);
          } else {
            _selectedIssues.remove(id);
          }
        });
        _saveProgress();
      },
      title: Text('$icon $title'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  bool _canContinueStep1() {
    return _operational != null && _crowdLevel != null;
  }


  Future<void> _submitReport() async {
    if (!_canContinueStep1()) return;

    setState(() => _isSubmitting = true);

    try {
      // Intentar obtener ubicación (opcional - no bloquea el reporte)
      Position? position;
      try {
        final locationService = LocationService();
        final status = await locationService.checkLocationStatus();
        if (status.hasPermission) {
          position = await locationService.getCurrentPosition();
        }
      } catch (e) {
        // Si no hay permisos o falla, continuar sin ubicación
        print('No se pudo obtener ubicación: $e');
      }

      final reportId = await _reportService.createStationReport(
        stationId: widget.station.id,
        operational: _operational!,
        crowdLevel: _crowdLevel!,
        issues: _selectedIssues.isNotEmpty ? _selectedIssues.toList() : null,
        userPosition: position, // Opcional
      );

      // Limpiar el progreso guardado después de enviar
      await _progressService.clearStationReportProgress(widget.station.id);

      if (!mounted) return;

      // Mostrar animación de puntos ganados antes de navegar
      final totalPoints = 15 + (_selectedIssues.length * 5);
      PointsRewardHelper.showCreateReportPoints(context, points: totalPoints);

      // Esperar un momento para que se vea la animación
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Mostrar pantalla de éxito y luego volver
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReportSuccessScreen(
            reportId: reportId,
            station: widget.station,
            points: totalPoints,
            issuesCount: _selectedIssues.length,
          ),
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

/// Pantalla de éxito después de enviar reporte
class ReportSuccessScreen extends StatelessWidget {
  final String reportId;
  final StationModel station;
  final int points;
  final int issuesCount;

  const ReportSuccessScreen({
    super.key,
    required this.reportId,
    required this.station,
    required this.points,
    required this.issuesCount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                '🎉 ¡REPORTE ENVIADO!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Text(
                'Has mejorado la información de\n${station.nombre} para:',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              _buildInfoRow('👥', '47 usuarios cercanos'),
              _buildInfoRow('📊', 'Subió confianza de MEDIA a ALTA'),
              _buildInfoRow('⏰', 'Próxima actualización: 2 min'),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Puntos ganados:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('✅ Reporte básico: +15'),
                    if (issuesCount > 0)
                      Text('✅ $issuesCount problemas: +${issuesCount * 5}'),
                    const SizedBox(height: 8),
                    Text(
                      '🏆 Total: +$points puntos',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text('VER EN MAPA'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
