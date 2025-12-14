import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../models/station_model.dart';
import '../models/train_model.dart';
import '../theme/metro_theme.dart';
import '../utils/helpers.dart';
import '../providers/location_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';
import '../services/learning_report_service.dart';
import '../services/time_estimation_service.dart';
import '../services/schedule_service.dart';
import '../services/firebase_service.dart';
import '../models/learning_report_model.dart';
import '../models/report_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/reports/station_report_flow.dart';
import '../screens/reports/train_report_flow.dart';
import 'arrival_confirmation_dialog.dart';
import '../services/simplified_report_service.dart';
import '../services/location_service.dart';

/// Widget que combina la información de la estación y el modal de reporte
/// Permite deslizar entre las dos vistas
class StationReportSheet extends StatefulWidget {
  final StationModel station;
  final List<TrainModel>? trains; // Trenes cercanos para reporte de tren
  final int initialPage; // Página inicial (0 = info estación, 1 = reporte)
  final double? initialChildSize; // Tamaño inicial del sheet (null = usar default)

  const StationReportSheet({
    super.key,
    required this.station,
    this.trains,
    this.initialPage = 0, // Por defecto empieza en la primera página
    this.initialChildSize, // Por defecto usa 0.45
  });

  @override
  State<StationReportSheet> createState() => _StationReportSheetState();
}

class _StationReportSheetState extends State<StationReportSheet> {
  late PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: widget.initialChildSize ?? 0.75, // Ampliado por defecto
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: MetroColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Handle con indicador de página
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    const _SheetHandle(color: MetroColors.grayMedium),
                    const SizedBox(height: 8),
                    // Indicadores de página
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _PageIndicator(isActive: _currentPage == 0),
                        const SizedBox(width: 8),
                        _PageIndicator(isActive: _currentPage == 1),
                      ],
                    ),
                  ],
                ),
              ),
              // PageView para deslizar entre vistas
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    // Página 1: Información de la estación (solo ver, sin botones)
                    StationInfoView(
                      station: widget.station,
                      trains: widget.trains,
                      scrollController: scrollController,
                    ),
                    // Página 2: Botones de reporte
                    StationReportView(
                      station: widget.station,
                      scrollController: scrollController,
                      // Si se abre desde el botón rápido, ir directo al selector de tipo
                      // (el usuario puede elegir estación o tren)
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Vista de información de la estación (primera página - solo ver)
class StationInfoView extends StatelessWidget {
  final StationModel station;
  final List<TrainModel>? trains;
  final ScrollController? scrollController;

  const StationInfoView({
    super.key,
    required this.station,
    this.trains,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderSection(station: station),
          const SizedBox(height: 24),
          _EtaSection(station: station),
          const SizedBox(height: 24),
          _StatusSection(station: station),
          const SizedBox(height: 24),
          _ArrivalConfirmationSection(station: station),
        ],
      ),
    );
  }
}

/// Handle del bottom sheet
class _SheetHandle extends StatelessWidget {
  const _SheetHandle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(100),
        ),
      ),
    );
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

/// Sección de header con nombre y estado
class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.station});

  final StationModel station;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final estado = Helpers.getEstadoEstacionText(
      station.estadoActual.name,
    );
    final estadoColor = switch (station.estadoActual) {
      EstadoEstacion.normal => MetroColors.stateNormal,
      EstadoEstacion.moderado => MetroColors.stateModerate,
      EstadoEstacion.lleno => MetroColors.stateCritical,
      EstadoEstacion.cerrado => MetroColors.stateInactive,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                station.nombre,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: MetroColors.grayDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: estadoColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                estado,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: estadoColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _InfoChip(
              label: station.linea == 'linea1' ? 'Línea 1' : 'Línea 2',
              color:
                  station.linea == 'linea1' ? MetroColors.blue : MetroColors.green,
            ),
            const SizedBox(width: 8),
            _InfoChip(
              label: 'Actualizado ${Helpers.formatDateTime(station.ultimaActualizacion)}',
              color: MetroColors.grayMedium,
            ),
          ],
        ),
      ],
    );
  }
}

/// Sección de próximos trenes
class _EtaSection extends StatelessWidget {
  const _EtaSection({required this.station});

  final StationModel station;

  List<_EtaData> get _etas => const [
        _EtaData(label: 'Próximo', minutes: 2, confidence: '✅ 8 usuarios'),
        _EtaData(label: 'Siguiente', minutes: 7, confidence: '⚠️ 3 usuarios'),
        _EtaData(label: 'Más tarde', minutes: 12, confidence: '❓ 1 usuario'),
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Próximos trenes',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ..._etas.map(
          (eta) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: MetroColors.grayLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eta.label,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: MetroColors.grayDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          eta.confidence,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: MetroColors.grayDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${eta.minutes} min',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Sección de estado actual
class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.station});

  final StationModel station;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseService = FirebaseService();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado actual',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        // Mostrar reportes activos de la estación
        StreamBuilder<List<ReportModel>>(
          stream: firebaseService.getActiveReportsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            
            // Filtrar reportes de esta estación
            final stationReports = snapshot.data?.where((report) => 
              report.tipo == TipoReporte.estacion && 
              report.objetivoId == station.id
            ).toList() ?? [];
            
            // Obtener el estado más reciente y problemas
            String estadoPrincipal = 'Normal';
            List<String> problemas = [];
            
            if (stationReports.isNotEmpty) {
              // Ordenar por fecha (más reciente primero)
              stationReports.sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
              final latestReport = stationReports.first;
              
              if (latestReport.estadoPrincipal != null && latestReport.estadoPrincipal!.isNotEmpty) {
                estadoPrincipal = latestReport.estadoPrincipal!;
              }
              
              if (latestReport.problemasEspecificos.isNotEmpty) {
                problemas = latestReport.problemasEspecificos;
              }
            }
            
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Aglomeración',
                            style: TextStyle(
                              color: MetroColors.grayDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildStars(station.aglomeracion),
                          const SizedBox(height: 4),
                          Text(
                            station.getAglomeracionTexto(),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estado reportado',
                            style: TextStyle(
                              color: MetroColors.grayDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            estadoPrincipal,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _getEstadoColor(estadoPrincipal),
                            ),
                          ),
                          if (stationReports.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${stationReports.length} reporte${stationReports.length > 1 ? 's' : ''}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: MetroColors.grayMedium,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (problemas.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Problemas activos',
                        style: TextStyle(
                          color: MetroColors.grayDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: problemas.map((problema) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: MetroColors.energyOrange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              problema,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ] else if (stationReports.isEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Sin problemas reportados',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: MetroColors.grayMedium,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'normal':
        return MetroColors.stateNormal;
      case 'moderado':
        return MetroColors.stateModerate;
      case 'lleno':
        return MetroColors.stateCritical;
      case 'retraso':
        return MetroColors.energyOrange;
      case 'cerrado':
        return MetroColors.stateInactive;
      default:
        return MetroColors.grayDark;
    }
  }

  Widget _buildStars(int value) {
    return Row(
      children: List.generate(
        5,
        (index) => Icon(
          index < value ? Icons.star_rounded : Icons.star_border_rounded,
          size: 20,
          color: MetroColors.energyOrange,
        ),
      ),
    );
  }
}

/// Acciones rápidas con dos botones: tiempo de pantalla y reporte de estación
class _QuickActions extends StatefulWidget {
  const _QuickActions({
    required this.station,
    this.trains,
    this.onReportStation,
    this.onReportTrain,
    this.scrollController,
  });

  final StationModel station;
  final List<TrainModel>? trains;
  final VoidCallback? onReportStation;
  final Function(TrainModel)? onReportTrain;
  final ScrollController? scrollController;

  @override
  State<_QuickActions> createState() => _QuickActionsState();
}

class _QuickActionsState extends State<_QuickActions> {
  Future<void> _showTimeReportDialog() async {
    final timeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final learningService = LearningReportService();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para reportar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.schedule, color: MetroColors.blue),
            SizedBox(width: 8),
            Text('Reportar Tiempo de Pantalla'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '¿Cuántos minutos muestra la pantalla de la estación?',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: timeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Minutos',
                  hintText: 'Ej: 5',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el tiempo';
                  }
                  final time = int.tryParse(value);
                  if (time == null) {
                    return 'Debe ser un número';
                  }
                  if (time < 1 || time > 30) {
                    return 'Debe estar entre 1 y 30 minutos';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MetroColors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reportar'),
          ),
        ],
      ),
    );

    if (result != true) {
      timeController.dispose();
      return;
    }

    final timeValue = int.tryParse(timeController.text);
    if (timeValue == null || timeValue < 1 || timeValue > 30) {
      timeController.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tiempo inválido'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Mostrar indicador de carga
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (loadingContext) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      final now = DateTime.now();
      final report = LearningReportModel(
        id: '', // Se generará al guardar
        usuarioId: authProvider.currentUser!.uid,
        estacionId: widget.station.id,
        linea: widget.station.linea,
        horaLlegadaReal: now,
        tiempoEstimadoMostrado: timeValue,
        retrasoMinutos: 0, // Se actualizará cuando el usuario confirme llegada real
        llegadaATiempo: true, // Inicial
        creadoEn: now,
        calidadReporte: 1.0, // Reportes de pantalla tienen calidad máxima
      );

      await learningService.createLearningReport(report);

      if (mounted) {
        Navigator.of(context).pop(); // Cerrar diálogo de carga
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('¡Tiempo reportado exitosamente!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Cerrar diálogo de carga
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reportar: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      timeController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones rápidas',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        // Dos botones: tiempo de pantalla y reporte de estación
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Botón 1: Reportar tiempo de pantalla (PRIMERO)
            _buildActionButton(
              icon: Icons.schedule,
              label: 'Reportar tiempo',
              subtitle: 'Tiempo de pantalla',
              color: MetroColors.blue,
              onTap: _showTimeReportDialog,
            ),
            // Botón 2: Reportar estación
            _buildActionButton(
              icon: Icons.campaign_outlined,
              label: 'Reportar estación',
              subtitle: 'Estado y problemas',
              color: MetroColors.blue,
              onTap: () => widget.onReportStation?.call(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: MetroColors.grayDark,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: MetroColors.grayDark,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}

/// Sección para confirmar llegada cuando el usuario está cerca
class _ArrivalConfirmationSection extends StatelessWidget {
  const _ArrivalConfirmationSection({required this.station});

  final StationModel station;

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        if (!locationProvider.hasPermission ||
            locationProvider.currentPosition == null) {
          return const SizedBox.shrink();
        }

        // Validación de distancia deshabilitada - se puede reportar desde cualquier ubicación
        // Calcular distancia a la estación
        // final distance = Geolocator.distanceBetween(
        //   locationProvider.currentPosition!.latitude,
        //   locationProvider.currentPosition!.longitude,
        //   station.ubicacion.latitude,
        //   station.ubicacion.longitude,
        // );

        // Mostrar botón siempre (validación de distancia deshabilitada)
        // if (distance > 500) {
        //   return const SizedBox.shrink();
        // }

        // Calcular tiempo estimado para mostrar (con aprendizaje)
        return FutureBuilder<int>(
          future: ScheduleService.getEstimatedArrivalTime(
            station.id,
            station.linea,
            DateTime.now(),
          ),
          builder: (context, snapshot) {
            // Mientras carga, usar tiempo base síncrono
            final tiempoEstimado = snapshot.hasData
                ? snapshot.data!
                : ScheduleService.getEstimatedArrivalTimeSync(
                    station.id,
                    station.linea,
                    DateTime.now(),
                  );

            final theme = Theme.of(context);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confirmar Llegada',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: MetroColors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: MetroColors.blue.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: MetroColors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Estás cerca de esta estación',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: MetroColors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '¿Ya llegaste? Confirma tu llegada para ayudar a mejorar las predicciones del sistema.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: MetroColors.grayDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (dialogContext) =>
                                  ArrivalConfirmationDialog(
                                station: station,
                                tiempoEstimadoMostrado: tiempoEstimado,
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Confirmar Llegada'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MetroColors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Chip de información
class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Vista de reporte (segunda página) - Ahora con formulario integrado
class StationReportView extends StatefulWidget {
  final StationModel station;
  final ScrollController? scrollController;
  final String? initialReportType; // 'station' | 'train' | null - para abrir directamente

  const StationReportView({
    super.key,
    required this.station,
    this.scrollController,
    this.initialReportType,
  });

  @override
  State<StationReportView> createState() => _StationReportViewState();
}

class _StationReportViewState extends State<StationReportView>
    with TickerProviderStateMixin {
  // Estado del formulario
  String? _reportType; // 'station' | 'train' | null
  String? _operational; // 'yes' | 'partial' | 'no'
  int? _crowdLevel; // 1-5 (para estación y tren)
  final Set<String> _selectedIssues = {};
  bool _showOptionalDetails = false;
  // Estado específico de tren
  String? _trainStatus; // 'normal' | 'slow' | 'stopped' | null
  String? _etaBucket; // '1-2' | '3-5' | '6-8' | '9+' | 'unknown' | null
  bool _isSubmitting = false;
  bool _showSuccess = false;
  String? _reportId;
  int _pointsEarned = 0;

  final SimplifiedReportService _reportService = SimplifiedReportService();
  
  // Animaciones
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _successController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _successScaleAnimation;
  late Animation<double> _successRotationAnimation;

  @override
  void initState() {
    super.initState();
    // Si hay un tipo inicial, establecerlo directamente
    if (widget.initialReportType != null) {
      _reportType = widget.initialReportType;
    }
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _successScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _successController,
        curve: Curves.elasticOut,
      ),
    );
    _successRotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _successController,
        curve: Curves.easeInOut,
      ),
    );
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si se completó el reporte, mostrar confirmación
    if (_showSuccess) {
      return _buildSuccessView();
    }

    // Transición animada entre vistas
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.3, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: _buildCurrentView(),
    );
  }

  Widget _buildCurrentView() {
    // Si no se ha seleccionado tipo de reporte, mostrar opciones
    if (_reportType == null) {
      return _buildReportTypeSelector();
    }

    // Si se seleccionó reporte de estación, mostrar formulario
    if (_reportType == 'station') {
      return _buildStationReportForm();
    }

    // Si se seleccionó reporte de tren, mostrar formulario de tren
    if (_reportType == 'train') {
      return _buildTrainReportForm();
    }

    return const SizedBox.shrink();
  }

  Widget _buildReportTypeSelector() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título con animación
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reportar',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ayuda a mejorar la información para todos',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            
            // Botón A: Reportar ESTACIÓN con animación
            _AnimatedReportButton(
              onPressed: () {
                _scaleController.forward().then((_) {
                  _scaleController.reverse();
                  setState(() => _reportType = 'station');
                });
              },
              icon: Icons.add_alert,
              label: 'REPORTAR ESTACIÓN',
              gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              delay: const Duration(milliseconds: 100),
            ),
            const SizedBox(height: 16),
            
            // Botón B: Reportar TREN con animación
            _AnimatedReportButton(
              onPressed: () {
                _scaleController.forward().then((_) {
                  _scaleController.reverse();
                  setState(() => _reportType = 'train');
                });
              },
              icon: Icons.train,
              label: 'REPORTAR TREN',
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              delay: const Duration(milliseconds: 200),
            ),
            
            const SizedBox(height: 40),
            
            // Información de puntos con animación
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue[50]!,
                            Colors.blue[100]!.withOpacity(0.5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.stars,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Gana puntos por reportar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildPointsRow('🎯', 'Reporte de estación: +15 puntos'),
                          const SizedBox(height: 8),
                          _buildPointsRow('🚇', 'Reporte de tren: +20 puntos'),
                          const SizedBox(height: 8),
                          _buildPointsRow('⏱️', 'Estimación de tiempo: +10 puntos extra'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsRow(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStationReportForm() {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con botón de volver
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _reportType = null;
                  _operational = null;
                  _crowdLevel = null;
                  _selectedIssues.clear();
                  _showOptionalDetails = false;
                  _trainStatus = null;
                  _etaBucket = null;
                }),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REPORTAR ESTACIÓN: ${widget.station.nombre}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      '1 de 2',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Pregunta 1: ¿La estación está operativa?
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
            onTap: () => setState(() => _operational = 'yes'),
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            value: 'partial',
            icon: Icons.warning,
            iconColor: Colors.orange,
            title: '⚠️ PARCIAL - Algo falla',
            isSelected: _operational == 'partial',
            onTap: () => setState(() => _operational = 'partial'),
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            value: 'no',
            icon: Icons.cancel,
            iconColor: Colors.red,
            title: '🚫 NO - Cerrada / grave',
            isSelected: _operational == 'no',
            onTap: () => setState(() => _operational = 'no'),
          ),
          
          const SizedBox(height: 32),
          
          // Pregunta 2: ¿Qué tan llena está?
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
          
          const SizedBox(height: 24),
          
          // Botón para agregar detalles opcionales
          if (_canSubmit())
            OutlinedButton.icon(
              onPressed: () => setState(() => _showOptionalDetails = true),
              icon: const Icon(Icons.add),
              label: const Text('Agregar detalles (opcional)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          
          // Mostrar detalles opcionales si el usuario los quiere
          if (_showOptionalDetails) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _buildOptionalDetails(),
          ],
          
          const SizedBox(height: 24),
          
          // Botón de confirmar con animación
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: _canSubmit() ? 1.0 : 0.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.95 + (0.05 * value),
                child: Opacity(
                  opacity: 0.7 + (0.3 * value),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canSubmit() && !_isSubmitting
                          ? () {
                              HapticFeedback.mediumImpact();
                              _submitStationReport();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: _canSubmit() ? 8 : 0,
                        shadowColor: Colors.blue.withOpacity(0.5),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'CONFIRMAR',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Info de puntos
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars, color: Colors.green),
                const SizedBox(width: 8),
                Text('Ganas: +${15 + (_selectedIssues.length * 5)} puntos'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainReportForm() {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con botón de volver
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _reportType = null;
                  _crowdLevel = null;
                  _trainStatus = null;
                  _etaBucket = null;
                }),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REPORTAR TREN: ${widget.station.nombre}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Estación: ${widget.station.nombre}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Pregunta 1: ¿Cómo venía el tren? (obligatorio)
          const Text(
            '1. ¿Cómo venía el tren?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildCrowdOption(1, '🟢 VACÍO', 'Asientos libres', Colors.green),
          const SizedBox(height: 12),
          _buildCrowdOption(2, '🟡 MODERADO', 'De pie cómodo', Colors.orange),
          const SizedBox(height: 12),
          _buildCrowdOption(3, '🔴 LLENO', 'Apretado', Colors.red),
          const SizedBox(height: 12),
          _buildCrowdOption(4, '💀 SARDINA', 'Extremo', Colors.purple),
          
          const SizedBox(height: 32),
          
          // Pregunta 2: Estado del tren (opcional)
          const Text(
            '2. Estado del tren (opcional)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Si notaste algo especial',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _buildTrainStatusOption('normal', '🚇 NORMAL', 'Velocidad usual', Colors.blue),
          const SizedBox(height: 12),
          _buildTrainStatusOption('slow', '🐌 LENTO', 'Menos de 20 km/h', Colors.orange),
          const SizedBox(height: 12),
          _buildTrainStatusOption('stopped', '🛑 DETENIDO', 'Parado en vía', Colors.red),
          
          const SizedBox(height: 32),
          
          // Pregunta 3: ETA (opcional pero recomendado)
          const Text(
            '3. ¿Cuánto falta para el próximo tren? (recomendado)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Esto ayuda a calibrar el sistema',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _buildEtaOption('1-2', '🕐 1-2 MINUTOS', Colors.blue),
          const SizedBox(height: 12),
          _buildEtaOption('3-5', '🕑 3-5 MINUTOS', Colors.blue),
          const SizedBox(height: 12),
          _buildEtaOption('6-8', '🕒 6-8 MINUTOS', Colors.blue),
          const SizedBox(height: 12),
          _buildEtaOption('9+', '🕓 9+ MINUTOS', Colors.blue),
          const SizedBox(height: 12),
          _buildEtaOption('unknown', '🤷 NO SÉ', Colors.grey),
          
          if (_etaBucket != null && _etaBucket != 'unknown') ...[
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
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Te preguntaremos si el tren realmente llegó',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[800],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Botón de confirmar con animación
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: _canSubmitTrain() ? 1.0 : 0.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.95 + (0.05 * value),
                child: Opacity(
                  opacity: 0.7 + (0.3 * value),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canSubmitTrain() && !_isSubmitting
                          ? () {
                              HapticFeedback.mediumImpact();
                              _submitTrainReport();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: _canSubmitTrain() ? 8 : 0,
                        shadowColor: Colors.green.withOpacity(0.5),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'ENVIAR REPORTE',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Info de puntos
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green[50]!,
                  Colors.green[100]!.withOpacity(0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Ganas: +${20 + ((_etaBucket != null && _etaBucket != 'unknown') ? 10 : 0)} puntos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                if (_etaBucket != null && _etaBucket != 'unknown') ...[
                  const SizedBox(height: 4),
                  Text(
                    '+10 puntos por estimar tiempo',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[800],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        iconColor.withOpacity(0.15),
                        iconColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: !isSelected ? Colors.grey[50] : null,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? iconColor.withOpacity(0.5)
                    : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: iconColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: iconColor, size: 28),
                      ),
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
                          decoration: BoxDecoration(
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
            ),
          ),
        );
      },
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
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        color.withOpacity(0.2),
                        color.withOpacity(0.05),
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
                        color: color.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                        spreadRadius: 1,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _crowdLevel = level);
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? color : Colors.grey[800],
                            letterSpacing: 0.3,
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
                                color: color.withOpacity(0.5),
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
            ),
          ),
        );
      },
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
        ...issues.map((issue) => _buildIssueCheckbox(
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
      },
      title: Text('$icon $title'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildSuccessView() {
    // Iniciar animación de éxito
    if (!_successController.isAnimating) {
      _successController.forward();
    }

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // Icono animado de éxito
          AnimatedBuilder(
            animation: _successController,
            builder: (context, child) {
              return Transform.scale(
                scale: _successScaleAnimation.value,
                child: Transform.rotate(
                  angle: (_successRotationAnimation.value - 0.5) * 0.2,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.green[400]!,
                          Colors.green[600]!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          // Título con animación
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: const Text(
                    '🎉 ¡REPORTE ENVIADO!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
              Text(
                _reportType == 'train'
                    ? 'Has mejorado la información del tren\nen ${widget.station.nombre} para:'
                    : 'Has mejorado la información de\n${widget.station.nombre} para:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
          const SizedBox(height: 32),
          // Info rows con animación escalonada
          _buildAnimatedInfoRow('👥', '47 usuarios cercanos', 0),
          const SizedBox(height: 12),
          _buildAnimatedInfoRow('📊', 'Subió confianza de MEDIA a ALTA', 1),
          const SizedBox(height: 12),
          _buildAnimatedInfoRow('⏰', 'Próxima actualización: 2 min', 2),
          const SizedBox(height: 40),
          // Container de puntos con gradiente
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.9 + (0.1 * value),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green[50]!,
                          Colors.green[100]!.withOpacity(0.5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.green[300]!,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.stars,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Puntos ganados:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_reportType == 'station') ...[
                          _buildPointsDetail('✅', 'Reporte básico: +15'),
                          if (_selectedIssues.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildPointsDetail(
                              '✅',
                              '${_selectedIssues.length} problemas: +${_selectedIssues.length * 5}',
                            ),
                          ],
                        ] else if (_reportType == 'train') ...[
                          _buildPointsDetail('✅', 'Reporte básico: +20'),
                          if (_etaBucket != null && _etaBucket != 'unknown') ...[
                            const SizedBox(height: 8),
                            _buildPointsDetail('✅', 'Estimación de tiempo: +10'),
                          ],
                        ],
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            '🏆 Total: +$_pointsEarned puntos',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          // Botón con animación
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: Colors.orange.withOpacity(0.5),
                    ),
                    child: const Text(
                      'VER EN MAPA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedInfoRow(String icon, String text, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: _buildInfoRow(icon, text),
          ),
        );
      },
    );
  }

  Widget _buildPointsDetail(String icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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

  bool _canSubmit() {
    return _operational != null && _crowdLevel != null;
  }

  bool _canSubmitTrain() {
    return _crowdLevel != null && !_isSubmitting;
  }

  Widget _buildTrainStatusOption(String status, String emoji, String subtitle, Color color) {
    final isSelected = _trainStatus == status;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1.0 - (value * 0.02),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        color.withOpacity(0.2),
                        color.withOpacity(0.05),
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
                        color: color.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                        spreadRadius: 1,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _trainStatus = status);
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            emoji.split(' ')[0],
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              emoji,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected ? color : Colors.grey[800],
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
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
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.5),
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
            ),
          ),
        );
      },
    );
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
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        color.withOpacity(0.2),
                        color.withOpacity(0.05),
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
                        color: color.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                        spreadRadius: 1,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _etaBucket = bucket);
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            label.split(' ')[0],
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? color : Colors.grey[800],
                            letterSpacing: 0.3,
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
                                color: color.withOpacity(0.5),
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
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitTrainReport() async {
    if (!_canSubmitTrain()) return;

    setState(() => _isSubmitting = true);

    try {
      // Intentar obtener ubicación (opcional)
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

      final reportId = await _reportService.createTrainReport(
        stationId: widget.station.id,
        crowdLevel: _crowdLevel!,
        trainStatus: _trainStatus,
        etaBucket: _etaBucket,
        trainLine: widget.station.linea,
        userPosition: position,
      );

      if (!mounted) return;

      // Calcular puntos
      int basePoints = 20;
      int bonusPoints = 0;
      if (_etaBucket != null && _etaBucket != 'unknown') {
        bonusPoints = 10;
      }
      _pointsEarned = basePoints + bonusPoints;

      setState(() {
        _isSubmitting = false;
        _reportId = reportId;
        _showSuccess = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _submitStationReport() async {
    if (!_canSubmit()) return;

    setState(() => _isSubmitting = true);

    try {
      // Intentar obtener ubicación (opcional)
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

      final reportId = await _reportService.createStationReport(
        stationId: widget.station.id,
        operational: _operational!,
        crowdLevel: _crowdLevel!,
        issues: _selectedIssues.isNotEmpty ? _selectedIssues.toList() : null,
        userPosition: position,
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _reportId = reportId;
        _pointsEarned = 15 + (_selectedIssues.length * 5);
        _showSuccess = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

/// Botón animado para seleccionar tipo de reporte
class _AnimatedReportButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Gradient gradient;
  final Duration delay;

  const _AnimatedReportButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.gradient,
    this.delay = Duration.zero,
  });

  @override
  State<_AnimatedReportButton> createState() => _AnimatedReportButtonState();
}

class _AnimatedReportButtonState extends State<_AnimatedReportButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
    
    // Iniciar animación de entrada con delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Transform.scale(
              scale: 0.9 + (0.1 * value),
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: widget.gradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _controller.forward().then((_) {
                              _controller.reverse();
                              widget.onPressed();
                            });
                          },
                          onTapDown: (_) => setState(() => _isPressed = true),
                          onTapUp: (_) => setState(() => _isPressed = false),
                          onTapCancel: () => setState(() => _isPressed = false),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 22,
                              horizontal: 24,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    widget.icon,
                                    size: 28,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  widget.label,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Datos de ETA
class _EtaData {
  const _EtaData({
    required this.label,
    required this.minutes,
    required this.confidence,
  });

  final String label;
  final int minutes;
  final String confidence;
}

