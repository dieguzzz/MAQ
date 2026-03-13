import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../models/station_model.dart';
import '../models/train_model.dart';
import '../theme/metro_theme.dart';
import '../services/simplified_report_service.dart';
import '../services/eta_group_service.dart';
import '../services/eta_arrival_service.dart';
import '../models/eta_group_model.dart';
import '../models/simplified_report_model.dart';
import 'station_report_flow_widget.dart';
import '../providers/auth_provider.dart';
import '../services/location_service.dart';
import 'guest_upgrade_dialog.dart';
import 'train_arrival_animation.dart';

/// Widget que combina la información de la estación y el modal de reporte
/// Permite deslizar entre las dos vistas
class StationReportSheet extends StatefulWidget {
  final StationModel station;
  final List<TrainModel>? trains; // Trenes cercanos para reporte de tren
  final int initialPage; // Página inicial (0 = info estación, 1 = reporte)
  final double?
      initialChildSize; // Tamaño inicial del sheet (null = usar default)
  final String?
      initialReportType; // 'station' | 'train' | null - para abrir directamente el formulario

  const StationReportSheet({
    super.key,
    required this.station,
    this.trains,
    this.initialPage = 0, // Por defecto empieza en la primera página
    this.initialChildSize, // Por defecto usa 0.45
    this.initialReportType, // Para abrir directamente el formulario desde el botón rápido
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
    // Force guests to page 0 (info only)
    final isGuest = Provider.of<AuthProvider>(context, listen: false).isGuest;
    final startPage = isGuest ? 0 : widget.initialPage;
    _currentPage = startPage;
    _pageController = PageController(initialPage: startPage);
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
                    // Block guests from accessing report page
                    if (index == 1) {
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      if (auth.isGuest) {
                        _pageController.animateToPage(0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                        GuestUpgradeDialog.show(context, feature: 'los reportes');
                        return;
                      }
                    }
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
                    ),
                    // Página 2: Widget de reporte de estación
                    StationReportFlowWidget(
                      station: widget.station,
                      scrollController: scrollController,
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

/// Vista de información de la estación (primera página)
class StationInfoView extends StatelessWidget {
  final StationModel station;
  final List<TrainModel>? trains;
  final ScrollController? scrollController;
  final VoidCallback? onReportPressed;
  const StationInfoView({
    super.key,
    required this.station,
    this.trains,
    this.scrollController,
    this.onReportPressed,
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
          // Fila con Próximos trenes (izquierda) y Llegó el metro (derecha)
          _TrainsAndArrivalRow(
            station: station,
            trains: trains,
          ),
          const SizedBox(height: 24),
          // Acciones rápidas
          _QuickActions(
            station: station,
            trains: trains,
            onReportStation: onReportPressed,
            scrollController: scrollController,
          ),
          const SizedBox(height: 24),
          _StatusSection(station: station),
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
    final lineColor = station.linea == 'linea1'
        ? MetroColors.blue
        : MetroColors.green;
    final estadoColor = switch (station.estadoActual) {
      EstadoEstacion.normal => MetroColors.stateNormal,
      EstadoEstacion.moderado => MetroColors.stateModerate,
      EstadoEstacion.lleno => MetroColors.stateCritical,
      EstadoEstacion.cerrado => MetroColors.stateInactive,
    };
    final estadoText = switch (station.estadoActual) {
      EstadoEstacion.normal => 'Normal',
      EstadoEstacion.moderado => 'Moderado',
      EstadoEstacion.lleno => 'Lleno',
      EstadoEstacion.cerrado => 'Cerrado',
    };
    final estadoIcon = switch (station.estadoActual) {
      EstadoEstacion.normal => '🟢',
      EstadoEstacion.moderado => '🟡',
      EstadoEstacion.lleno => '🔴',
      EstadoEstacion.cerrado => '⚫',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Color dot for line
            Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: lineColor,
                shape: BoxShape.circle,
              ),
            ),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: estadoColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$estadoIcon $estadoText',
                style: theme.textTheme.labelMedium?.copyWith(
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
              color: lineColor,
            ),
            const SizedBox(width: 8),
            StreamBuilder<List<SimplifiedReportModel>>(
              stream: SimplifiedReportService().getActiveReportsStream(),
              builder: (context, snapshot) {
                int reportCount = 0;
                bool hasReports = false;

                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final now = DateTime.now();
                  final cutoffTime = now.subtract(const Duration(minutes: 10));

                  final stationReports = snapshot.data!
                      .where((r) =>
                          r.stationId == station.id &&
                          r.status == 'active' &&
                          r.createdAt.isAfter(cutoffTime))
                      .toList();

                  reportCount = stationReports.length;
                  hasReports = reportCount > 0;
                }

                return _InfoChip(
                  label: hasReports
                      ? '📊 $reportCount activos'
                      : 'Sin reportes',
                  color: hasReports ? MetroColors.blue : MetroColors.grayMedium,
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// Fila que combina Próximos trenes (izquierda) y Llegó el metro (derecha)
class _TrainsAndArrivalRow extends StatelessWidget {
  const _TrainsAndArrivalRow({
    required this.station,
    this.trains,
  });

  final StationModel station;
  final List<TrainModel>? trains;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Próximos trenes (izquierda)
        Expanded(
          child: _EtaSection(station: station, trains: trains),
        ),
        const SizedBox(width: 12),
        // Llegó el metro (derecha)
        Expanded(
          child: _TrainArrivalBox(station: station),
        ),
      ],
    );
  }
}

enum DirectionKey {
  toAlbrook(label: 'Hacia Albrook', icon: Icons.arrow_downward_rounded),
  toVillaZaita(label: 'Hacia Villa Zaita', icon: Icons.arrow_upward_rounded),
  toNuevoTocumen(
      label: 'Hacia Nuevo Tocumen', icon: Icons.arrow_forward_rounded),
  toSanMiguelito(label: 'Hacia San Miguelito', icon: Icons.arrow_back_rounded);

  final String label;
  final IconData icon;
  const DirectionKey({required this.label, required this.icon});
}

class DirectionEtaGroup {
  final DirectionKey key;
  final List<_EtaData> etas;

  DirectionEtaGroup({required this.key, required this.etas});

  bool get isEmpty => etas.isEmpty;
}
class _EtaSection extends StatelessWidget {
  const _EtaSection({required this.station, this.trains});
  final StationModel station;
  final List<TrainModel>? trains;

  @override
  Widget build(BuildContext context) {
    final etaGroupService = EtaGroupService();

    return StreamBuilder<Map<String, EtaGroupModel?>>(
      stream:
          etaGroupService.watchActiveGroupsByDirectionForStation(station.id),
      builder: (context, snapshot) {
        final groups = snapshot.data;
        final groupA = groups?['A'];
        final groupB = groups?['B'];

        // Si no hay datos de ninguna dirección, mostrar estado vacío
        if (groupA == null && groupB == null) {
          return _buildNoEtaData(context);
        }

        return _EtaDualDirectionBox(
          groupA: groupA,
          groupB: groupB,
          stationId: station.id,
          stationLine: station.linea,
        );
      },
    );
  }

  Widget _buildNoEtaData(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MetroColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        children: [
          Text(
            'Próximos trenes',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: MetroColors.grayDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sin datos recientes',
            style: theme.textTheme.bodySmall?.copyWith(
              color: MetroColors.grayMedium,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Reporta los tiempos del panel',
            style: theme.textTheme.bodySmall?.copyWith(
              color: MetroColors.blue,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}




/// Widget interactivo "Ya llegó el metro" con drag-to-direction.
/// Tap = reporte genérico (+3 pts).
/// Drag ↖/↗ diagonal = reporta dirección específica (+7-10 pts).
class _TrainArrivalBox extends StatefulWidget {
  const _TrainArrivalBox({required this.station});

  final StationModel station;

  @override
  State<_TrainArrivalBox> createState() => _TrainArrivalBoxState();
}

class _TrainArrivalBoxState extends State<_TrainArrivalBox>
    with TickerProviderStateMixin {
  // --- Animations ---
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _snapBackController;
  late Animation<Offset> _snapBackAnimation;

  // --- State ---
  int _previousCount = 0;
  bool _isLoading = false;
  String? _successMessage;
  Timer? _broadcastTimer;
  bool _isBroadcasting = false;

  // --- Drag ---
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  String? _hoveredDirection; // 'A' or 'B' while dragging

  // --- Data ---
  StreamSubscription? _directionSub;
  Map<String, EtaGroupModel?>? _activeGroups;

  static const double _dragThreshold = 40.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _snapBackController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _snapBackAnimation =
        Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(
      CurvedAnimation(parent: _snapBackController, curve: Curves.elasticOut),
    );
    _snapBackController.addListener(() {
      setState(() => _dragOffset = _snapBackAnimation.value);
    });

    // Listen to active directions
    final etaGroupService = EtaGroupService();
    _directionSub = etaGroupService
        .watchActiveGroupsByDirectionForStation(widget.station.id)
        .listen((groups) {
      if (mounted) setState(() => _activeGroups = groups);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _snapBackController.dispose();
    _broadcastTimer?.cancel();
    _directionSub?.cancel();
    super.dispose();
  }

  // --- Broadcast glow (10s repeating pulse) ---
  void _startBroadcastGlow() {
    _isBroadcasting = true;
    _broadcastTimer?.cancel();
    _pulseController.repeat(reverse: true);
    HapticFeedback.mediumImpact();
    _broadcastTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        _pulseController.stop();
        _pulseController.value = 0;
        setState(() => _isBroadcasting = false);
      }
    });
  }

  // --- Drag handling ---
  void _onPanStart(DragStartDetails details) {
    if (_isLoading || _successMessage != null) return;
    _snapBackController.stop();
    setState(() {
      _isDragging = true;
      _dragOffset = Offset.zero;
      _hoveredDirection = null;
    });
    HapticFeedback.selectionClick();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    setState(() {
      _dragOffset += details.delta;
      // Detect diagonal direction: up-left = A, up-right = B
      if (_dragOffset.distance > _dragThreshold) {
        final angle =
            math.atan2(-_dragOffset.dy, _dragOffset.dx); // negative dy = up
        if (angle > 0.3 && angle < 2.8) {
          // Upper-right quadrant → direction B
          final newDir = 'B';
          if (_hoveredDirection != newDir) {
            HapticFeedback.selectionClick();
          }
          _hoveredDirection = newDir;
        } else if (angle < -0.3 || angle > 2.8) {
          // Upper-left / left quadrant → direction A
          final newDir = 'A';
          if (_hoveredDirection != newDir) {
            HapticFeedback.selectionClick();
          }
          _hoveredDirection = newDir;
        } else {
          _hoveredDirection = null;
        }
      } else {
        _hoveredDirection = null;
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;

    final released = _dragOffset.distance > _dragThreshold;
    final direction = _hoveredDirection;

    // Snap back with rubber band
    _snapBackAnimation =
        Tween<Offset>(begin: _dragOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _snapBackController, curve: Curves.elasticOut),
    );
    _snapBackController.forward(from: 0.0);

    setState(() {
      _isDragging = false;
      _hoveredDirection = null;
    });

    if (released && direction != null) {
      HapticFeedback.heavyImpact();
      _handleSubmit(directionCode: direction);
    }
  }

  // --- Tap = generic arrival ---
  void _onTap() {
    if (_isLoading || _successMessage != null) return;
    HapticFeedback.lightImpact();
    _handleSubmit();
  }

  // --- Submit arrival ---
  Future<void> _handleSubmit({String? directionCode}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inicia sesión para reportar'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      Position? position;
      try {
        final locationService = LocationService();
        final status = await locationService.checkLocationStatus();
        if (status.hasPermission) {
          position = await locationService.getCurrentPosition();
        }
      } catch (_) {}

      final arrivalService = EtaArrivalService();
      final result = await arrivalService.submitArrivalTap(
        stationId: widget.station.id,
        userPosition: position,
        directionCode: directionCode,
      );

      if (!mounted) return;

      if (!result.success) {
        final msg = switch (result.reason) {
          'no_active_group' => 'Primero reporta tiempos del panel.',
          'ambiguous_direction' => 'Arrastra para indicar dirección.',
          'out_of_geofence' => 'Debes estar en la estación (≤150m).',
          'no_gps' => 'No pudimos validar tu GPS.',
          'cooldown' => 'Espera antes de confirmar otra vez.',
          'already_counted' => 'Ya confirmaste recientemente.',
          _ => 'No se pudo confirmar.',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      } else {
        // Success!
        final dirLabel = directionCode != null
            ? _dirLabel(directionCode)
            : null;

        final lineColor = widget.station.linea == 'linea1'
            ? MetroColors.blue
            : MetroColors.green;

        if (result.pointsAwarded > 0) {
          TrainArrivalAnimation.show(
            context,
            points: result.pointsAwarded,
            lineColor: lineColor,
            directionLabel: dirLabel,
            onComplete: () {},
          );
        }

        _startBroadcastGlow();
        setState(() {
          _successMessage = dirLabel != null
              ? '✓ → $dirLabel · +${result.pointsAwarded} pts'
              : '✓ +${result.pointsAwarded} pts';
        });
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _successMessage = null;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _dirLabel(String code) {
    if (widget.station.linea == 'linea1') {
      return code == 'A' ? 'Villa Zaita' : 'Albrook';
    } else if (widget.station.linea == 'linea2') {
      return code == 'A' ? 'Nuevo Tocumen' : 'San Miguelito';
    }
    return 'Dir. $code';
  }

  @override
  Widget build(BuildContext context) {
    final etaGroupService = EtaGroupService();
    final lineColor = widget.station.linea == 'linea1'
        ? MetroColors.blue
        : MetroColors.green;

    return StreamBuilder<EtaGroupModel?>(
      stream: etaGroupService.watchBestActiveGroupForStation(widget.station.id),
      builder: (context, snapshot) {
        final group = snapshot.data;
        final arrivedCount = group?.arrivedCount ?? 0;
        final ageMin = group?.ageMinutes ?? 999;
        final hasRecentArrivals =
            group != null && arrivedCount > 0 && ageMin <= 5;
        final directionLabel = group?.directionLabel;

        // Broadcast glow when arrivedCount increases from other users
        if (arrivedCount > _previousCount && !_isBroadcasting) {
          Future.microtask(() {
            if (mounted) _startBroadcastGlow();
          });
        }
        _previousCount = arrivedCount;

        // Direction labels for drag
        final dirA = _dirLabel('A');
        final dirB = _dirLabel('B');
        final leftOpacity =
            _isDragging && _hoveredDirection == 'A' ? 1.0 : (_isDragging ? 0.4 : 0.0);
        final rightOpacity =
            _isDragging && _hoveredDirection == 'B' ? 1.0 : (_isDragging ? 0.4 : 0.0);

        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final pulseVal = _isBroadcasting ? _pulseAnimation.value : 0.0;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // --- Direction labels (visible during drag) ---
                Positioned(
                  left: -8,
                  top: -32,
                  child: AnimatedOpacity(
                    opacity: leftOpacity,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: lineColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '← $dirA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -8,
                  top: -32,
                  child: AnimatedOpacity(
                    opacity: rightOpacity,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: lineColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$dirB →',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),

                // --- Main button ---
                Transform.translate(
                  offset: _dragOffset,
                  child: GestureDetector(
                    onTap: _onTap,
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isDragging
                            ? lineColor.withValues(alpha: 0.15)
                            : hasRecentArrivals
                                ? lineColor.withValues(
                                    alpha: 0.05 + (pulseVal * 0.12))
                                : MetroColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isDragging
                              ? lineColor
                              : hasRecentArrivals
                                  ? lineColor
                                  : MetroColors.grayMedium,
                          width: _isDragging
                              ? 2
                              : hasRecentArrivals
                                  ? (1.5 + (pulseVal * 0.5))
                                  : 1,
                        ),
                        boxShadow: (_isBroadcasting || _isDragging)
                            ? [
                                BoxShadow(
                                  color: lineColor.withValues(
                                      alpha: _isDragging
                                          ? 0.4
                                          : 0.3 * pulseVal),
                                  blurRadius:
                                      _isDragging ? 16 : 8 + (pulseVal * 10),
                                  spreadRadius:
                                      _isDragging ? 3 : pulseVal * 3,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // --- Broadcast badge ---
                          if (_isBroadcasting &&
                              hasRecentArrivals &&
                              _successMessage == null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: lineColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                directionLabel != null
                                    ? '🚇 ¡Llegó! → $directionLabel'
                                    : '🚇 ¡Llegó!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),

                          // --- Icon ---
                          if (_isLoading)
                            const SizedBox(
                              height: 28,
                              width: 28,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          else if (_successMessage != null)
                            Icon(Icons.check_circle_rounded,
                                size: 28, color: lineColor)
                          else
                            Icon(
                              _isDragging
                                  ? Icons.swipe_rounded
                                  : Icons.train_rounded,
                              size: 28,
                              color: hasRecentArrivals || _isDragging
                                  ? lineColor
                                  : MetroColors.grayMedium,
                            ),

                          const SizedBox(height: 4),

                          // --- Text ---
                          if (_successMessage != null)
                            Text(
                              _successMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: lineColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            )
                          else if (_isDragging)
                            Text(
                              _hoveredDirection != null
                                  ? '→ ${_dirLabel(_hoveredDirection!)}'
                                  : 'Arrastra ↗',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: lineColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            )
                          else if (_isBroadcasting && hasRecentArrivals)
                            Text(
                              '¡Confirma! +5 pts',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: lineColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            )
                          else if (hasRecentArrivals)
                            Text(
                              '$arrivedCount ✓',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: lineColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            )
                          else
                            Text(
                              '¿Llegó? 🚇\nArrastra →',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: MetroColors.grayMedium,
                                fontSize: 10,
                                height: 1.3,
                              ),
                            ),
                        ],
                      ),
                    ),
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


/// Helper class para datos de ETA de trenes
class _TrainEta {
  final TrainModel train;
  final int minutes;
  final String confidence;

  _TrainEta({
    required this.train,
    required this.minutes,
    required this.confidence,
  });
}

/// Sección de estado actual - con barra de nivel de gente e íconos de issues
class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.station});

  final StationModel station;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reportService = SimplifiedReportService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StreamBuilder<List<SimplifiedReportModel>>(
                stream: reportService.getActiveReportsStream(),
                builder: (context, snapshot) {
                  bool hasActiveReports = false;
                  int? reportedCrowd;

                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    final stationReports = snapshot.data!
                        .where((r) =>
                            r.stationId == station.id &&
                            r.scope == 'station' &&
                            r.status == 'active')
                        .toList();

                    stationReports
                        .sort((a, b) => b.createdAt.compareTo(a.createdAt));

                    hasActiveReports = stationReports.isNotEmpty;

                    if (hasActiveReports && stationReports.isNotEmpty) {
                      final latestReport = stationReports.first;
                      if (latestReport.stationCrowd != null) {
                        reportedCrowd = latestReport.stationCrowd;
                      }
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🚶 Gente',
                        style: TextStyle(
                          color: MetroColors.grayDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (hasActiveReports && reportedCrowd != null)
                        _CrowdLevelBar(level: reportedCrowd)
                      else if (snapshot.connectionState ==
                          ConnectionState.waiting)
                        const Text('...',
                            style: TextStyle(
                                color: MetroColors.grayMedium, fontSize: 12))
                      else
                        Text(
                          'Sin datos',
                          style: TextStyle(
                            color: MetroColors.grayMedium,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StreamBuilder<List<SimplifiedReportModel>>(
                stream: reportService.getActiveReportsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '⚠️ Alertas',
                          style: TextStyle(
                            color: MetroColors.grayDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('...', style: TextStyle(fontSize: 12, color: MetroColors.grayMedium)),
                      ],
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '⚠️ Alertas',
                          style: TextStyle(
                            color: MetroColors.grayDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Todo bien ✓',
                          style: TextStyle(
                            color: MetroColors.stateNormal,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  }

                  final stationReports = snapshot.data!
                      .where((r) =>
                          r.stationId == station.id &&
                          r.scope == 'station' &&
                          r.status == 'active')
                      .toList();

                  final allIssues = <String>{};
                  for (final report in stationReports) {
                    if (report.stationIssues != null) {
                      allIssues.addAll(report.stationIssues!);
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⚠️ Alertas',
                        style: TextStyle(
                          color: MetroColors.grayDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (allIssues.isEmpty)
                        Text(
                          'Todo bien ✓',
                          style: TextStyle(
                            color: MetroColors.stateNormal,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: allIssues
                              .map((issue) => _IssueTag(issue: issue))
                              .toList(),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Barra de nivel de gente con gradiente verde→amarillo→rojo
class _CrowdLevelBar extends StatelessWidget {
  const _CrowdLevelBar({required this.level});
  final int level;

  @override
  Widget build(BuildContext context) {
    final crowdText = switch (level) {
      1 => 'Vacía',
      2 => 'Poca',
      3 => 'Normal',
      4 => 'Llena',
      5 => 'Muy llena',
      _ => '',
    };
    final fillFraction = level / 5.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Stack(
              children: [
                // Track
                Container(color: MetroColors.grayMedium.withValues(alpha: 0.3)),
                // Fill
                FractionallySizedBox(
                  widthFactor: fillFraction,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          MetroColors.stateNormal,
                          level >= 3 ? MetroColors.stateModerate : MetroColors.stateNormal,
                          level >= 4 ? MetroColors.stateCritical : MetroColors.stateModerate,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          crowdText,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: MetroColors.grayDark,
          ),
        ),
      ],
    );
  }
}

/// Tag compacto de issue con ícono
class _IssueTag extends StatelessWidget {
  const _IssueTag({required this.issue});
  final String issue;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (issue) {
      'ac' => ('❄️', 'A/C'),
      'escalator' => ('🔧', 'Escaleras'),
      'elevator' => ('🔧', 'Ascensor'),
      'atm' => ('💳', 'ATM'),
      'recharge' => ('💳', 'Recarga'),
      'door' => ('🚪', 'Puerta'),
      'screen' => ('📺', 'Pantalla'),
      _ => ('⚠️', issue),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: MetroColors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$icon $label',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: MetroColors.grayDark,
        ),
      ),
    );
  }
}

/// Acciones rápidas - solo el botón de reportar estación
class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.station,
    this.trains,
    this.onReportStation,
    this.scrollController,
  });

  final StationModel station;
  final List<TrainModel>? trains;
  final VoidCallback? onReportStation;
  final ScrollController? scrollController;

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
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => onReportStation?.call(),
            icon: const Icon(Icons.edit_note_rounded, size: 22),
            label: const Text(
              'Reportar estación',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: MetroColors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
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
    this.isUserReport = false,
    this.rawText,
    this.baseTime,
    this.expiresAt,
    this.expectedAt,
    this.midpointMinutes,
  });

  final String label;
  final int minutes;
  final String confidence;
  final bool isUserReport;
  final String? rawText;

  /// Base estable del countdown (NO usar updatedAt).
  final DateTime? baseTime;

  /// Para dejar de mostrar y caer a fallback tras expirar el grupo.
  final DateTime? expiresAt;

  /// Opción B (ideal): backend entrega expectedAt y el cliente solo resta.
  final DateTime? expectedAt;

  /// Midpoint real (2/4/7/10). Si no existe, no hacemos countdown.
  final int? midpointMinutes;
}

class _EtaCountdownText extends StatefulWidget {
  const _EtaCountdownText({
    required this.midpointMinutes,
    required this.baseTime,
    required this.expiresAt,
    required this.expectedAt,
    required this.fallbackText,
    required this.textStyle,
  });

  final int? midpointMinutes;
  final DateTime? baseTime;
  final DateTime? expiresAt;
  final DateTime? expectedAt;
  final String fallbackText;
  final TextStyle? textStyle;

  @override
  State<_EtaCountdownText> createState() => _EtaCountdownTextState();
}

class _EtaCountdownTextState extends State<_EtaCountdownText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    String displayText;

    // Si no hay metadata de countdown, usar el texto original.
    if (widget.expectedAt == null &&
        (widget.midpointMinutes == null ||
            widget.baseTime == null ||
            widget.expiresAt == null)) {
      displayText = widget.fallbackText;
    } else if (widget.expectedAt == null &&
        (widget.midpointMinutes == null || widget.midpointMinutes! <= 0)) {
      // Guard: midpoint inválido => sin datos (evita “Llegando” raro).
      displayText = 'Sin datos';
    } else if (widget.expiresAt != null && now.isAfter(widget.expiresAt!)) {
      displayText = 'Sin datos';
    } else {
      int remainingSeconds;
      if (widget.expectedAt != null) {
        remainingSeconds = widget.expectedAt!.difference(now).inSeconds;
      } else {
        final totalSeconds = widget.midpointMinutes! * 60;
        final elapsedSeconds = now.difference(widget.baseTime!).inSeconds;
        remainingSeconds = totalSeconds - elapsedSeconds;
      }

      // Validar que remainingSeconds no sea negativo
      if (remainingSeconds < 0) remainingSeconds = 0;

      if (remainingSeconds <= 60) {
        displayText = 'Llegando';
      } else {
        final minutes = (remainingSeconds / 60).ceil();
        displayText = '$minutes min';
      }
    }

    // Animar solo cuando cambia la fuente (expectedAt/baseTime/midpoint),
    // no en cada tick del timer.
    final key = widget.expectedAt != null
        ? 'exp-${widget.expectedAt!.millisecondsSinceEpoch}'
        : 'base-${widget.baseTime?.millisecondsSinceEpoch}-${widget.midpointMinutes}';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: Text(
        displayText,
        key: ValueKey(key),
        style: widget.textStyle,
      ),
    );
  }
}

class _EtaLiveGroupBox extends StatefulWidget {
  const _EtaLiveGroupBox({
    required this.group,
    required this.stationId,
  });

  final EtaGroupModel group;
  final String stationId;

  @override
  State<_EtaLiveGroupBox> createState() => _EtaLiveGroupBoxState();
}

class _EtaLiveGroupBoxState extends State<_EtaLiveGroupBox> {
  Timer? _timer;
  static const int NO_FOLLOW_GRACE_SECONDS = 30;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int? _midpointFromBucket(String? bucket) {
    switch (bucket) {
      case '1-2':
        return 2;
      case '3-5':
        return 4;
      case '6-8':
        return 7;
      case '9+':
        return 10;
      default:
        return null;
    }
  }

  int? _effectiveMinutes({required int? minutesP50, required String? bucket}) {
    if (minutesP50 != null && minutesP50 > 0) return minutesP50;
    return _midpointFromBucket(bucket);
  }

  String _confidenceEmoji(double confidence) {
    if (confidence >= 0.75) return '🟢';
    if (confidence >= 0.5) return '🟡';
    return '🔴';
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final theme = Theme.of(context);
    final now = DateTime.now();

    // Calcular tiempos restantes
    final nextRem =
        group.nextEtaExpectedAt?.difference(now).inSeconds ?? 999999;
    final followRem =
        group.followingEtaExpectedAt?.difference(now).inSeconds ?? -1;

    // Rollover: si nextRem <= 0 y hay following válido (followRem > 0)
    final rolled = (nextRem <= 0 && followRem > 0);

    // No follow expired: cuando nextRem <= -30s y no hay following válido
    final noFollowExpired =
        (nextRem <= -NO_FOLLOW_GRACE_SECONDS && followRem <= 0);

    // Si no hay following y ya expiró la gracia, mostrar "Sin datos" con CTA
    if (noFollowExpired) {
      return _buildNoDataWithCTA(theme, context);
    }

    final nextExpectedAt =
        rolled ? group.followingEtaExpectedAt : group.nextEtaExpectedAt;
    final nextBucket = rolled ? group.followingEtaBucket : group.nextEtaBucket;
    final showFollowing = !rolled && group.followingEtaExpectedAt != null;

    final baseTime = group.firstReportedAt ?? group.bucketStart;
    final expiresAt = group.expiresAt;

    final etas = <_EtaData>[];
    final nextMidpointMin = _effectiveMinutes(
      minutesP50:
          rolled ? group.followingEtaMinutesP50 : group.nextEtaMinutesP50,
      bucket: nextBucket,
    );

    if (nextMidpointMin != null && nextMidpointMin > 0) {
      etas.add(
        _EtaData(
          label: 'Próximo',
          minutes: nextMidpointMin,
          confidence:
              '${_confidenceEmoji(group.confidence)} ${group.reportCount}',
          baseTime: baseTime,
          expiresAt: expiresAt,
          expectedAt: nextExpectedAt,
          midpointMinutes: nextMidpointMin,
        ),
      );

      // Solo mostrar "Siguiente" si hay datos reales (no inventar estimados)
      if (showFollowing) {
        final followingMidpointMin = _effectiveMinutes(
          minutesP50: group.followingEtaMinutesP50,
          bucket: group.followingEtaBucket,
        );

        if (followingMidpointMin != null && followingMidpointMin > 0) {
          etas.add(
            _EtaData(
              label: 'Siguiente',
              minutes: followingMidpointMin,
              confidence: _confidenceEmoji(group.confidence),
              baseTime: baseTime,
              expiresAt: expiresAt,
              expectedAt: group.followingEtaExpectedAt,
              midpointMinutes: followingMidpointMin,
            ),
          );
        }
        // NO agregar "Siguiente estimado" - solo mostrar si hay datos reales
      }
    }

    if (etas.isEmpty) {
      // Caer a "Sin datos" si el bucket es unknown.
      return _buildNoDataWithCTA(theme, context);
    }

    // Reutiliza el mismo layout del box de ETAs.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MetroColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: MetroColors.grayMedium,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Próximos trenes',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: MetroColors.grayDark,
            ),
          ),
          const SizedBox(height: 12),
          ...etas.take(2).map(
                (eta) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              eta.label,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: MetroColors.grayDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              eta.confidence,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: MetroColors.grayDark.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _EtaCountdownText(
                        midpointMinutes: eta.midpointMinutes,
                        baseTime: eta.baseTime,
                        expiresAt: eta.expiresAt,
                        expectedAt: eta.expectedAt,
                        fallbackText:
                            eta.minutes == 0 && eta.confidence == 'Sin datos'
                                ? 'Sin datos'
                                : '${eta.minutes} min',
                        textStyle: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              eta.minutes == 0 && eta.confidence == 'Sin datos'
                                  ? MetroColors.grayMedium
                                  : MetroColors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildNoDataWithCTA(ThemeData theme, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MetroColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MetroColors.grayMedium, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Próximos trenes',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: MetroColors.grayDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sin datos',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: MetroColors.grayMedium,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reporta el panel para ayudar a otros',
            style: theme.textTheme.bodySmall?.copyWith(
              color: MetroColors.blue,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget que muestra ETAs para ambas direcciones con barras estilo Waze
class _EtaDualDirectionBox extends StatefulWidget {
  const _EtaDualDirectionBox({
    required this.groupA,
    required this.groupB,
    required this.stationId,
    required this.stationLine,
  });

  final EtaGroupModel? groupA;
  final EtaGroupModel? groupB;
  final String stationId;
  final String stationLine;

  @override
  State<_EtaDualDirectionBox> createState() => _EtaDualDirectionBoxState();
}

class _EtaDualDirectionBoxState extends State<_EtaDualDirectionBox> {
  Timer? _timer;
  static const int NO_FOLLOW_GRACE_SECONDS = 30;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color get _lineColor =>
      (widget.stationLine == 'linea1' || widget.stationLine == 'L1')
          ? MetroColors.blue
          : MetroColors.green;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MetroColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Próximos trenes',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: MetroColors.grayDark,
            ),
          ),
          const SizedBox(height: 14),
          // Direction A
          _buildDirectionBar(
            theme: theme,
            group: widget.groupA,
            directionCode: 'A',
          ),
          const SizedBox(height: 10),
          // Direction B
          _buildDirectionBar(
            theme: theme,
            group: widget.groupB,
            directionCode: 'B',
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionBar({
    required ThemeData theme,
    required EtaGroupModel? group,
    required String directionCode,
  }) {
    final title = _getDirectionTitle(directionCode, widget.stationLine,
        group?.directionLabel);
    final isA = directionCode == 'A';
    final hasData = group != null && !_isExpired(group);

    // Gradient opacity based on data freshness
    final ageMin = group?.ageMinutes ?? 999;
    final freshness = hasData ? (1.0 - (ageMin / 10.0)).clamp(0.3, 1.0) : 0.15;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gradient direction bar
        Container(
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: LinearGradient(
              begin: isA ? Alignment.centerRight : Alignment.centerLeft,
              end: isA ? Alignment.centerLeft : Alignment.centerRight,
              colors: [
                _lineColor.withValues(alpha: freshness),
                _lineColor.withValues(alpha: freshness * 0.3),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Direction label with arrow
        Row(
          children: [
            Icon(
              isA ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
              size: 14,
              color: hasData ? _lineColor : MetroColors.grayMedium,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: hasData ? _lineColor : MetroColors.grayMedium,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // ETA data
        if (!hasData)
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Text(
              'Sin datos',
              style: TextStyle(fontSize: 11, color: MetroColors.grayMedium),
            ),
          )
        else
          _buildEtaInfo(theme: theme, group: group!),
      ],
    );
  }

  Widget _buildEtaInfo({
    required ThemeData theme,
    required EtaGroupModel group,
  }) {
    final now = DateTime.now();
    final nextRem =
        group.nextEtaExpectedAt?.difference(now).inSeconds ?? 999999;
    final followRem =
        group.followingEtaExpectedAt?.difference(now).inSeconds ?? -1;
    final rolled = (nextRem <= 0 && followRem > 0);

    final nextExpectedAt =
        rolled ? group.followingEtaExpectedAt : group.nextEtaExpectedAt;
    final nextBucket = rolled ? group.followingEtaBucket : group.nextEtaBucket;
    final nextMidpointMin = _effectiveMinutes(
      minutesP50:
          rolled ? group.followingEtaMinutesP50 : group.nextEtaMinutesP50,
      bucket: nextBucket,
    );

    final showFollowing = !rolled && group.followingEtaExpectedAt != null;
    final followingMidpointMin = showFollowing
        ? _effectiveMinutes(
            minutesP50: group.followingEtaMinutesP50,
            bucket: group.followingEtaBucket,
          )
        : null;

    if (nextMidpointMin == null || nextMidpointMin <= 0) {
      return Padding(
        padding: const EdgeInsets.only(left: 18),
        child: Text('Sin datos',
            style: TextStyle(fontSize: 11, color: MetroColors.grayMedium)),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 18),
      child: Row(
        children: [
          // Próximo
          Expanded(
            child: _buildCompactEta(
              theme: theme,
              label: 'Próximo',
              expectedAt: nextExpectedAt,
              midpointMinutes: nextMidpointMin,
              baseTime: group.firstReportedAt ?? group.bucketStart,
              expiresAt: group.expiresAt,
            ),
          ),
          // Siguiente
          if (showFollowing &&
              followingMidpointMin != null &&
              followingMidpointMin > 0) ...[
            Container(
              width: 1,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: MetroColors.grayMedium.withValues(alpha: 0.5),
            ),
            Expanded(
              child: _buildCompactEta(
                theme: theme,
                label: 'Siguiente',
                expectedAt: group.followingEtaExpectedAt,
                midpointMinutes: followingMidpointMin,
                baseTime: group.firstReportedAt ?? group.bucketStart,
                expiresAt: group.expiresAt,
              ),
            ),
          ],
          // Confidence indicator
          const SizedBox(width: 8),
          Text(
            _confidenceEmoji(group.confidence),
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactEta({
    required ThemeData theme,
    required String label,
    required DateTime? expectedAt,
    required int midpointMinutes,
    required DateTime baseTime,
    required DateTime expiresAt,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: MetroColors.grayDark.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        _EtaCountdownText(
          midpointMinutes: midpointMinutes,
          baseTime: baseTime,
          expiresAt: expiresAt,
          expectedAt: expectedAt,
          fallbackText: '$midpointMinutes min',
          textStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: _lineColor,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  bool _isExpired(EtaGroupModel group) {
    final now = DateTime.now();
    final nextRem =
        group.nextEtaExpectedAt?.difference(now).inSeconds ?? 999999;
    final followRem =
        group.followingEtaExpectedAt?.difference(now).inSeconds ?? -1;
    return (nextRem <= -NO_FOLLOW_GRACE_SECONDS && followRem <= 0);
  }

  String _getDirectionTitle(String directionCode, String stationLine,
      [String? directionLabel]) {
    if (directionLabel != null && directionLabel.isNotEmpty) {
      return directionLabel;
    }

    if (stationLine == 'linea1') {
      return directionCode == 'A' ? 'Villa Zaita' : 'Albrook';
    } else if (stationLine == 'linea2') {
      return directionCode == 'A' ? 'Nuevo Tocumen' : 'San Miguelito';
    }

    return 'Dir. $directionCode';
  }

  int? _midpointFromBucket(String? bucket) {
    switch (bucket) {
      case '1-2':
        return 2;
      case '3-5':
        return 4;
      case '6-8':
        return 7;
      case '9+':
        return 10;
      default:
        return null;
    }
  }

  int? _effectiveMinutes({required int? minutesP50, required String? bucket}) {
    if (minutesP50 != null && minutesP50 > 0) return minutesP50;
    return _midpointFromBucket(bucket);
  }

  String _confidenceEmoji(double confidence) {
    if (confidence >= 0.75) return '🟢';
    if (confidence >= 0.5) return '🟡';
    return '🔴';
  }
}

  static const int staleWindowMin = 10; // Ventana de fallback
