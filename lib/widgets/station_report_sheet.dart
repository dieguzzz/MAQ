import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../models/station_model.dart';
import '../models/train_model.dart';
import '../theme/metro_theme.dart';
import '../utils/helpers.dart';
import '../providers/location_provider.dart';
import '../providers/auth_provider.dart';
import '../services/learning_report_service.dart';
import '../services/time_estimation_service.dart';
import '../services/schedule_service.dart';
import '../models/learning_report_model.dart';
import 'enhanced_report_modal.dart';
import 'arrival_confirmation_dialog.dart';

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
                    // Página 1: Información de la estación
                    StationInfoView(
                      station: widget.station,
                      trains: widget.trains,
                      scrollController: scrollController,
                      onReportPressed: () {
                        // Deslizar a la página de reporte de estación
                        _pageController.animateToPage(
                          1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      onReportTrain: (train) {
                        // Cerrar el bottom sheet actual y abrir modal de reporte de tren
                        Navigator.of(context).pop();
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (context.mounted) {
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (modalContext) => EnhancedReportModal(train: train),
                            );
                          }
                        });
                      },
                    ),
                    // Página 2: Modal de reporte
                    EnhancedReportModal(station: widget.station),
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

/// Vista de información de la estación (primera página)
class StationInfoView extends StatelessWidget {
  final StationModel station;
  final List<TrainModel>? trains;
  final ScrollController? scrollController;
  final VoidCallback? onReportPressed;
  final Function(TrainModel)? onReportTrain;

  const StationInfoView({
    super.key,
    required this.station,
    this.trains,
    this.scrollController,
    this.onReportPressed,
    this.onReportTrain,
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
          // Acciones rápidas primero
          _QuickActions(
            station: station,
            trains: trains,
            onReportStation: onReportPressed,
            onReportTrain: onReportTrain,
            scrollController: scrollController,
          ),
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
                    'Problemas activos',
                    style: TextStyle(
                      color: MetroColors.grayDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'A/C estable • Sonido OK',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
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

        // Calcular distancia a la estación
        final distance = Geolocator.distanceBetween(
          locationProvider.currentPosition!.latitude,
          locationProvider.currentPosition!.longitude,
          station.ubicacion.latitude,
          station.ubicacion.longitude,
        );

        // Mostrar botón solo si está dentro de 500m
        if (distance > 500) {
          return const SizedBox.shrink();
        }

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

