import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../models/station_model.dart';
import '../models/train_model.dart';
import '../theme/metro_theme.dart';
import '../utils/helpers.dart';
import '../providers/location_provider.dart';
import '../services/schedule_service.dart';
import '../services/time_estimation_service.dart';
import '../services/simplified_report_service.dart';
import '../services/eta_group_service.dart';
import '../services/eta_arrival_service.dart';
import '../models/eta_group_model.dart';
import '../models/simplified_report_model.dart';
import 'station_report_flow_widget.dart';
import '../providers/auth_provider.dart';
import 'guest_upgrade_dialog.dart';

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
              color: station.linea == 'linea1'
                  ? MetroColors.blue
                  : MetroColors.green,
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

                  // Contar todos los reportes activos de esta estación (station + train)
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
                      ? '$reportCount ${reportCount == 1 ? 'reporte' : 'reportes'}'
                      : 'No hay reportes',
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

/// Helper para combinar reportes de usuarios con datos de trenes reales
class _CombinedEtaService {
  final TimeEstimationService _timeEstimationService = TimeEstimationService();

  List<DirectionEtaGroup> calculateDirectionGroups(
    StationModel station,
    List<TrainModel>? trains,
    List<SimplifiedReportModel> activeReports,
  ) {
    // 1. Determine valid directions for this station's line
    final List<DirectionKey> validKeys =
        (station.linea == 'linea1' || station.linea == 'L1')
            ? [DirectionKey.toVillaZaita, DirectionKey.toAlbrook]
            : [DirectionKey.toNuevoTocumen, DirectionKey.toSanMiguelito];

    final groups = <DirectionEtaGroup>[];
    final now = DateTime.now();

    for (final key in validKeys) {
      final etas = <_EtaData>[];

      // 2. Filter User Reports for this direction key
      final relevantReports = activeReports.where((r) {
        if (r.scope != 'train' || r.stationId != station.id) return false;
        final age = now.difference(r.createdAt).inMinutes;
        if (age >= 10) return false;

        // Map report direction string to key
        final reportKey = _mapStringToKey(station.linea, r.direction);
        return reportKey == key;
      }).toList();

      relevantReports.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Get best user report
      _EtaData? userNextTrain;
      for (final report in relevantReports) {
        if (userNextTrain == null) {
          final elapsed = now.difference(report.createdAt).inMinutes;
          if (report.etaBucket != null && report.etaBucket != 'unknown') {
            userNextTrain = _EtaData(
              label: 'Próximo',
              minutes: _parseBucket(report.etaBucket!),
              confidence: 'Reportado hace $elapsed min',
              isUserReport: true,
              rawText: report.etaBucket,
            );
          } else if (report.etaExpectedAt != null) {
            final remainingInSeconds =
                report.etaExpectedAt!.difference(now).inSeconds;
            final remaining = (remainingInSeconds / 60).ceil();

            if (remaining >= -1) {
              userNextTrain = _EtaData(
                label: 'Próximo',
                minutes: remaining > 0 ? remaining : 0,
                confidence: 'Reportado hace $elapsed min',
                isUserReport: true,
              );
            }
          }
        }
      }

      // 3. Filter Real Trains
      final realTrainEtas = <_TrainEta>[];
      if (trains != null) {
        final relevantTrains = trains.where((t) {
          if (t.linea != station.linea) return false;
          final trainKey = _mapTrainToKey(station.linea, t.direccion);
          return trainKey == key;
        }).toList();

        for (final train in relevantTrains) {
          final minutes = _timeEstimationService.calculateEstimatedArrivalTime(
              train, station);
          if (minutes >= -1) {
            realTrainEtas.add(_TrainEta(
              train: train,
              minutes: minutes > 0 ? minutes : 0,
              confidence: train.confidence ?? 'medium',
            ));
          }
        }
        realTrainEtas.sort((a, b) => a.minutes.compareTo(b.minutes));
      }

      // 4. Combine (Max 2 items)
      if (userNextTrain != null) {
        etas.add(userNextTrain);
        if (realTrainEtas.isNotEmpty) {
          final nextReal = realTrainEtas.firstWhere(
              (t) => t.minutes > userNextTrain!.minutes + 2,
              orElse: () => realTrainEtas.last);

          if (nextReal.minutes > userNextTrain.minutes + 2) {
            etas.add(_EtaData(
              label: 'Siguiente',
              minutes: nextReal.minutes,
              confidence: _getConfidenceText(nextReal.confidence),
            ));
          }
        }
      } else if (realTrainEtas.isNotEmpty) {
        final next = realTrainEtas[0];
        etas.add(_EtaData(
          label: 'Próximo',
          minutes: next.minutes,
          confidence: _getConfidenceText(next.confidence),
        ));
        if (realTrainEtas.length > 1) {
          final following = realTrainEtas[1];
          if (following.minutes != next.minutes || realTrainEtas.length > 2) {
            etas.add(_EtaData(
              label: 'Siguiente',
              minutes: following.minutes,
              confidence: _getConfidenceText(following.confidence),
            ));
          }
        }
      }

      groups.add(DirectionEtaGroup(key: key, etas: etas));
    }

    return groups;
  }

  DirectionKey? _mapStringToKey(String line, String? directionStr) {
    if (directionStr == null) return null;
    final d = directionStr.toLowerCase();
    final isL1 = line == 'linea1' || line == 'L1';
    if (isL1) {
      // Direction code A = Villa Zaita (norte), B = Albrook (sur)
      if (d == 'a' ||
          d.contains('villa zaita') ||
          d.contains('villazaita') ||
          d.contains('norte')) {
        return DirectionKey.toVillaZaita;
      }
      if (d == 'b' || d.contains('albrook') || d.contains('sur')) {
        return DirectionKey.toAlbrook;
      }
    } else {
      // Direction code A = Nuevo Tocumen (este), B = San Miguelito (oeste)
      if (d == 'a' || d.contains('tocumen') || d.contains('este')) {
        return DirectionKey.toNuevoTocumen;
      }
      if (d == 'b' ||
          d.contains('san miguelito') ||
          d.contains('oeste')) {
        return DirectionKey.toSanMiguelito;
      }
    }
    return null;
  }

  DirectionKey? _mapTrainToKey(String line, DireccionTren dir) {
    final isL1 = line == 'linea1' || line == 'L1';
    if (isL1) {
      return dir == DireccionTren.sur
          ? DirectionKey.toAlbrook
          : DirectionKey.toVillaZaita;
    } else {
      return dir == DireccionTren.sur
          ? DirectionKey.toSanMiguelito
          : DirectionKey.toNuevoTocumen;
    }
  }

  int _parseBucket(String bucket) {
    if (bucket.contains('-')) {
      final parts = bucket.split('-');
      return int.tryParse(parts[0]) ?? 5;
    }
    return 5;
  }

  String _getConfidenceText(String confidence) {
    switch (confidence) {
      case 'high':
        return '✅ Alta confianza';
      case 'medium':
        return '⚠️ Confianza media';
      default:
        return '❓ Baja confianza';
    }
  }
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

class _DirectionCard extends StatelessWidget {
  final DirectionEtaGroup group;
  const _DirectionCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: MetroColors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(group.key.icon, size: 16, color: MetroColors.blue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.key.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: MetroColors.grayDark,
                  ),
                ),
              ),
              if (group.isEmpty)
                Text('Sin datos',
                    style: TextStyle(fontSize: 10, color: Colors.grey[400])),
            ],
          ),
          const SizedBox(height: 12),
          if (group.isEmpty)
            const Center(
                child: Text('No hay trenes próximos',
                    style: TextStyle(color: Colors.grey, fontSize: 12)))
          else
            ...group.etas.map((eta) => _buildMiniEtaRow(context, eta)),
        ],
      ),
    );
  }

  Widget _buildMiniEtaRow(BuildContext context, _EtaData eta) {
    final theme = Theme.of(context);
    final isArriving = eta.minutes <= 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eta.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                eta.confidence,
                style: TextStyle(fontSize: 10, color: Colors.grey[400]),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              isArriving ? 'Llegando' : (eta.rawText ?? '${eta.minutes} min'),
              key: ValueKey('${eta.label}_${eta.minutes}'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isArriving ? MetroColors.green : MetroColors.grayDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Box de Llegó el metro - Solo visualización con efectos
class _TrainArrivalBox extends StatefulWidget {
  const _TrainArrivalBox({required this.station});

  final StationModel station;

  @override
  State<_TrainArrivalBox> createState() => _TrainArrivalBoxState();
}

class _TrainArrivalBoxState extends State<_TrainArrivalBox>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  late AnimationController _starGlowController;
  late Animation<double> _starGlowAnimation;
  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.elasticOut,
      ),
    );

    // Animación de brillo de la estrella por 5 segundos
    _starGlowController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _starGlowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _starGlowController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _starGlowController.dispose();
    super.dispose();
  }

  void _triggerPulse() {
    _pulseController.forward(from: 0.0).then((_) {
      _pulseController.reverse();
    });
  }

  void _triggerStarGlow() {
    _starGlowController.forward(from: 0.0).then((_) {
      if (mounted) {
        _starGlowController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final etaGroupService = EtaGroupService();

    return StreamBuilder<EtaGroupModel?>(
      stream: etaGroupService.watchBestActiveGroupForStation(widget.station.id),
      builder: (context, snapshot) {
        final group = snapshot.data;
        final arrivedCount = group?.arrivedCount ?? 0;
        final ageMin = group?.ageMinutes ?? 999;

        final hasRecentArrivals =
            group != null && arrivedCount > 0 && ageMin <= 5;
        final isStale = group != null && (ageMin > 5 && ageMin <= 10);

        // Detectar cuando hay un nuevo reporte (incluyendo el primer reporte)
        if (arrivedCount > _previousCount) {
          // Usar un pequeño delay para asegurar que el widget está montado
          Future.microtask(() {
            if (mounted) {
              _triggerPulse();
              _triggerStarGlow();
            }
          });
        }
        _previousCount = arrivedCount;

        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasRecentArrivals
                    ? MetroColors.blue
                        .withValues(alpha: 0.05 + (_pulseAnimation.value * 0.1))
                    : MetroColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasRecentArrivals
                      ? MetroColors.blue
                      : isStale
                          ? MetroColors.grayMedium
                          : MetroColors.grayMedium,
                  width: hasRecentArrivals
                      ? (1.5 + (_pulseAnimation.value * 0.5))
                      : 1,
                ),
                boxShadow: hasRecentArrivals
                    ? [
                        BoxShadow(
                          color: MetroColors.blue
                              .withValues(alpha: 0.3 * _pulseAnimation.value),
                          blurRadius: 8 + (_pulseAnimation.value * 8),
                          spreadRadius: _pulseAnimation.value * 2,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Llegó el metro',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: MetroColors.grayDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation:
                        Listenable.merge([_pulseAnimation, _starGlowAnimation]),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: hasRecentArrivals
                            ? 1.0 + (_scaleAnimation.value * 0.1)
                            : 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: hasRecentArrivals
                                ? [
                                    BoxShadow(
                                      color: MetroColors.blue.withValues(
                                          alpha:
                                              0.6 * _starGlowAnimation.value),
                                      blurRadius:
                                          12 + (_starGlowAnimation.value * 12),
                                      spreadRadius:
                                          _starGlowAnimation.value * 4,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            Icons.star,
                            size: 32,
                            color: hasRecentArrivals
                                ? MetroColors.blue
                                : isStale
                                    ? MetroColors.grayMedium
                                    : MetroColors.grayMedium,
                          ),
                        ),
                      );
                    },
                  ),
                  if (group != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      ageMin <= 5
                          ? '$arrivedCount llegada${arrivedCount == 1 ? '' : 's'}'
                          : 'Hace $ageMin min',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: hasRecentArrivals
                            ? MetroColors.blue
                            : MetroColors.grayDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    Text(
                      'Sin datos',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: MetroColors.grayMedium,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
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

/// Sección de estado actual - ahora con datos reales de reportes
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
          'Estado actual',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StreamBuilder<List<SimplifiedReportModel>>(
                stream: reportService.getActiveReportsStream(),
                builder: (context, snapshot) {
                  // Verificar si hay reportes activos para esta estación
                  bool hasActiveReports = false;
                  int? reportedCrowd;

                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    final stationReports = snapshot.data!
                        .where((r) =>
                            r.stationId == station.id &&
                            r.scope == 'station' &&
                            r.status == 'active')
                        .toList();

                    // Ordenar por fecha (más reciente primero)
                    stationReports
                        .sort((a, b) => b.createdAt.compareTo(a.createdAt));

                    hasActiveReports = stationReports.isNotEmpty;

                    // Obtener aglomeración de reportes si hay
                    if (hasActiveReports && stationReports.isNotEmpty) {
                      // Usar el reporte más reciente
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
                        'Aglomeración',
                        style: TextStyle(
                          color: MetroColors.grayDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (hasActiveReports && reportedCrowd != null)
                        _buildStars(reportedCrowd)
                      else if (snapshot.connectionState ==
                          ConnectionState.waiting)
                        const Text('Cargando...',
                            style: TextStyle(color: MetroColors.grayMedium))
                      else
                        const Text(
                          'No hay reportes',
                          style: TextStyle(
                            color: MetroColors.grayMedium,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        hasActiveReports && reportedCrowd != null
                            ? _getCrowdText(reportedCrowd)
                            : snapshot.connectionState ==
                                    ConnectionState.waiting
                                ? ''
                                : 'Sin datos actuales',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: hasActiveReports && reportedCrowd != null
                              ? MetroColors.grayDark
                              : MetroColors.grayMedium,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<List<SimplifiedReportModel>>(
                stream: reportService.getActiveReportsStream(),
                builder: (context, snapshot) {
                  // Verificar estado de conexión primero
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Column(
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
                          'Cargando...',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    );
                  }

                  // Verificar errores
                  if (snapshot.hasError) {
                    return Column(
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
                          'Error al cargar datos',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ],
                    );
                  }

                  // Si no hay datos (stream vacío pero ya emitió)
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Column(
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
                          'Sin problemas reportados',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    );
                  }

                  // Filtrar reportes de esta estación
                  final stationReports = snapshot.data!
                      .where((r) =>
                          r.stationId == station.id &&
                          r.scope == 'station' &&
                          r.status == 'active')
                      .toList();

                  // Obtener problemas únicos de todos los reportes
                  final allIssues = <String>{};
                  for (final report in stationReports) {
                    if (report.stationIssues != null) {
                      allIssues.addAll(report.stationIssues!);
                    }
                  }

                  final issuesText = _formatIssues(allIssues);

                  return Column(
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
                        issuesText.isEmpty
                            ? 'Sin problemas reportados'
                            : issuesText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: issuesText.isEmpty
                              ? MetroColors.grayMedium
                              : MetroColors.grayDark,
                        ),
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

  String _formatIssues(Set<String> issues) {
    if (issues.isEmpty) return '';

    final issueNames = <String, String>{
      'ac': 'A/C',
      'escalator': 'Escaleras',
      'elevator': 'Ascensor',
      'atm': 'ATM',
      'recharge': 'Recarga',
    };

    final formatted =
        issues.map((issue) => issueNames[issue] ?? issue).join(' • ');

    return formatted;
  }

  Widget _buildStars(int value) {
    return Row(
      children: List.generate(
        5,
        (index) => Icon(
          index < value ? Icons.star_rounded : Icons.star_border_rounded,
          size: 20,
          color: MetroColors.red,
        ),
      ),
    );
  }

  String _getCrowdText(int crowdLevel) {
    switch (crowdLevel) {
      case 1:
        return 'Vacía';
      case 2:
        return 'Baja';
      case 3:
        return 'Media';
      case 4:
        return 'Alta';
      case 5:
        return 'Muy Alta';
      default:
        return 'Desconocida';
    }
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
            icon: const Icon(Icons.add_alert, size: 24),
            label: const Text(
              'REPORTAR ESTACIÓN',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                    color: MetroColors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: MetroColors.blue.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
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
                          onPressed: () async {
                            final service = EtaArrivalService();
                            final result = await service.submitArrivalTap(
                              stationId: station.id,
                              userPosition: locationProvider.currentPosition,
                            );

                            if (!context.mounted) return;

                            if (result.success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '✅ Confirmado. +${result.pointsAwarded} puntos',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              return;
                            }

                            final msg = switch (result.reason) {
                              'no_active_group' =>
                                'Primero reporta el tiempo del panel para poder confirmar.',
                              'ambiguous_direction' =>
                                'Hay varias direcciones activas. Reporta el tiempo del panel para indicar tu dirección.',
                              'out_of_geofence' =>
                                'Debes estar en la estación (≤150m) para que cuente.',
                              'no_gps' =>
                                'No pudimos validar tu GPS aquí. No cuenta ni otorga puntos, pero puedes reportar el panel.',
                              'cooldown' =>
                                'Espera un poco antes de confirmar otra vez.',
                              'already_counted' =>
                                'Ya registramos tu confirmación recientemente.',
                              _ => 'No se pudo confirmar. Intenta de nuevo.',
                            };

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: Colors.red,
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

/// Widget que muestra ETAs para ambas direcciones (A y B)
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MetroColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MetroColors.grayMedium, width: 1),
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
          const SizedBox(height: 16),
          // Dos columnas: dirección A y B
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columna A
              Expanded(
                child: _buildDirectionColumn(
                  theme: theme,
                  group: widget.groupA,
                  directionCode: 'A',
                  stationLine: widget.stationLine,
                ),
              ),
              const SizedBox(width: 16),
              // Divisor vertical
              Container(
                width: 1,
                color: MetroColors.grayMedium,
              ),
              const SizedBox(width: 16),
              // Columna B
              Expanded(
                child: _buildDirectionColumn(
                  theme: theme,
                  group: widget.groupB,
                  directionCode: 'B',
                  stationLine: widget.stationLine,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionColumn({
    required ThemeData theme,
    required EtaGroupModel? group,
    required String directionCode,
    required String stationLine,
  }) {
    if (group == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getDirectionTitle(directionCode, stationLine),
            style: theme.textTheme.labelMedium?.copyWith(
              color: MetroColors.grayMedium,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sin datos',
            style: theme.textTheme.bodySmall?.copyWith(
              color: MetroColors.grayMedium,
              fontSize: 11,
            ),
          ),
        ],
      );
    }

    final now = DateTime.now();
    final nextRem =
        group.nextEtaExpectedAt?.difference(now).inSeconds ?? 999999;
    final followRem =
        group.followingEtaExpectedAt?.difference(now).inSeconds ?? -1;
    final rolled = (nextRem <= 0 && followRem > 0);
    final noFollowExpired =
        (nextRem <= -NO_FOLLOW_GRACE_SECONDS && followRem <= 0);

    if (noFollowExpired) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getDirectionTitle(
                directionCode, stationLine, group.directionLabel),
            style: theme.textTheme.labelMedium?.copyWith(
              color: MetroColors.grayMedium,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sin datos',
            style: theme.textTheme.bodySmall?.copyWith(
              color: MetroColors.grayMedium,
              fontSize: 11,
            ),
          ),
        ],
      );
    }

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de dirección
        Text(
          _getDirectionTitle(directionCode, stationLine, group.directionLabel),
          style: theme.textTheme.labelMedium?.copyWith(
            color: MetroColors.blue,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),

        // Próximo
        if (nextMidpointMin != null && nextMidpointMin > 0)
          _buildEtaRow(
            theme: theme,
            label: 'Próximo',
            expectedAt: nextExpectedAt,
            midpointMinutes: nextMidpointMin,
            baseTime: group.firstReportedAt ?? group.bucketStart,
            expiresAt: group.expiresAt,
            confidence: _confidenceEmoji(group.confidence),
            reportCount: group.reportCount,
          ),

        // Siguiente (solo si hay datos reales)
        if (showFollowing &&
            followingMidpointMin != null &&
            followingMidpointMin > 0) ...[
          const SizedBox(height: 6),
          _buildEtaRow(
            theme: theme,
            label: 'Siguiente',
            expectedAt: group.followingEtaExpectedAt,
            midpointMinutes: followingMidpointMin,
            baseTime: group.firstReportedAt ?? group.bucketStart,
            expiresAt: group.expiresAt,
            confidence: _confidenceEmoji(group.confidence),
          ),
        ],
      ],
    );
  }

  Widget _buildEtaRow({
    required ThemeData theme,
    required String label,
    required DateTime? expectedAt,
    required int midpointMinutes,
    required DateTime baseTime,
    required DateTime expiresAt,
    required String confidence,
    int? reportCount,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: MetroColors.grayDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              if (reportCount != null) ...[
                const SizedBox(height: 2),
                Text(
                  '$confidence $reportCount',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: MetroColors.grayDark.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 2),
                Text(
                  confidence,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: MetroColors.grayDark.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
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
            color: MetroColors.blue,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _getDirectionTitle(String directionCode, String stationLine,
      [String? directionLabel]) {
    if (directionLabel != null && directionLabel.isNotEmpty) {
      return 'Hacia $directionLabel';
    }

    if (stationLine == 'linea1') {
      return directionCode == 'A' ? 'Hacia Villa Zaita' : 'Hacia Albrook';
    } else if (stationLine == 'linea2') {
      return directionCode == 'A'
          ? 'Hacia Nuevo Tocumen'
          : 'Hacia San Miguelito';
    }

    return 'Dirección $directionCode';
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

/// Helper para procesar reportes de llegada del metro con agrupación por minuto
class _TrainArrivalAggregator {
  static const int activeWindowMin = 5; // Ventana activa
  static const int staleWindowMin = 10; // Ventana de fallback

  /// Trunca un DateTime al minuto más cercano
  static DateTime bucketToMinute(DateTime time) {
    return DateTime(
      time.year,
      time.month,
      time.day,
      time.hour,
      time.minute,
    );
  }

  /// Calcula la moda (valor más común) de una lista
  static int? mode(List<int> values) {
    if (values.isEmpty) return null;

    final counts = <int, int>{};
    for (final value in values) {
      counts[value] = (counts[value] ?? 0) + 1;
    }

    int? mostCommon;
    int maxCount = 0;
    for (final entry in counts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostCommon = entry.key;
      }
    }

    return mostCommon;
  }

  /// Calcula la moda de strings (para etaBucket)
  static String? modeString(List<String> values) {
    if (values.isEmpty) return null;

    final counts = <String, int>{};
    for (final value in values) {
      if (value.isNotEmpty && value != 'unknown') {
        counts[value] = (counts[value] ?? 0) + 1;
      }
    }

    if (counts.isEmpty) return null;

    String? mostCommon;
    int maxCount = 0;
    for (final entry in counts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostCommon = entry.key;
      }
    }

    return mostCommon;
  }

  /// Convierte etaBucket a minutos
  static int? bucketToMinutes(String? etaBucket) {
    if (etaBucket == null || etaBucket.isEmpty || etaBucket == 'unknown') {
      return null;
    }

    switch (etaBucket) {
      case '1-2':
        return 2; // 1.5 redondeado a 2
      case '3-5':
        return 4; // punto medio
      case '6-8':
        return 7; // punto medio
      case '9+':
        return 10; // mínimo razonable
      default:
        return null;
    }
  }

  /// Calcula el nivel de confianza basado en conteo y frescura
  static String calculateConfidence(int count, int ageMin) {
    if (count >= 3 && ageMin <= 2) {
      return 'Alta';
    } else if (count >= 2 || (ageMin >= 3 && ageMin <= 5)) {
      return 'Media';
    } else {
      return 'Baja';
    }
  }

  /// Procesa reportes y retorna información agregada
  static _AggregatedArrivalData? processReports(
    List<SimplifiedReportModel> reports,
    String stationId,
  ) {
    final now = DateTime.now();

    // 1) Filtrar reportes de tren de esta estación
    final trainReports = reports
        .where((r) => r.stationId == stationId && r.scope == 'train')
        .toList();

    if (trainReports.isEmpty) return null;

    // 2) Separar en dos grupos:
    //    - Reportes con arrivalTime (llegadas confirmadas)
    //    - Reportes con etaBucket sin arrivalTime (ETAs futuros)
    final arrivalReports =
        trainReports.where((r) => r.arrivalTime != null).toList();

    final futureEtaReports = trainReports
        .where((r) =>
            r.arrivalTime == null &&
            r.etaBucket != null &&
            r.etaBucket!.isNotEmpty &&
            r.etaBucket != 'unknown' &&
            // Validar que el ETA no haya expirado
            (r.etaExpectedAt == null ||
                now.isBefore(r.etaExpectedAt!.add(const Duration(minutes: 5)))))
        .toList();

    // 3) Procesar reportes de llegadas confirmadas (arrivalTime)
    _AggregatedArrivalData? arrivalData;
    if (arrivalReports.isNotEmpty) {
      // Agrupar por minuto (bucket)
      final buckets = <DateTime, List<SimplifiedReportModel>>{};
      for (final report in arrivalReports) {
        final bucket = bucketToMinute(report.arrivalTime!);
        buckets.putIfAbsent(bucket, () => []).add(report);
      }

      if (buckets.isNotEmpty) {
        final latestBucket = buckets.keys.reduce(
          (a, b) => a.isAfter(b) ? a : b,
        );
        final bucketReports = buckets[latestBucket]!;
        final ageMin = now.difference(latestBucket).inMinutes;

        // Si el bucket está dentro de la ventana activa (5 min)
        if (ageMin <= activeWindowMin) {
          final count = bucketReports.length;
          final confidence = calculateConfidence(count, ageMin);

          // Extraer etaBucket de los reportes y calcular moda
          final etaBuckets = bucketReports
              .where((r) => r.etaBucket != null && r.etaBucket!.isNotEmpty)
              .map((r) => r.etaBucket!)
              .toList();

          String? reportedEtaBucket;
          int? reportedMinutes;

          if (etaBuckets.isNotEmpty) {
            reportedEtaBucket = modeString(etaBuckets);
            if (reportedEtaBucket != null) {
              reportedMinutes = bucketToMinutes(reportedEtaBucket);
            }
          }

          arrivalData = _AggregatedArrivalData(
            count: count,
            ageMin: ageMin,
            confidence: confidence,
            isActive: true,
            latestArrivalTime: latestBucket,
            reportedMinutes: reportedMinutes,
            reportedEtaBucket: reportedEtaBucket,
          );
        } else {
          // Fallback: reporte más reciente si está dentro de 10 min
          final mostRecent = arrivalReports.reduce(
            (a, b) => a.arrivalTime!.isAfter(b.arrivalTime!) ? a : b,
          );

          final fallbackAge = now.difference(mostRecent.arrivalTime!).inMinutes;

          if (fallbackAge <= staleWindowMin) {
            String? reportedEtaBucket;
            int? reportedMinutes;

            if (mostRecent.etaBucket != null &&
                mostRecent.etaBucket!.isNotEmpty) {
              reportedEtaBucket = mostRecent.etaBucket;
              reportedMinutes = bucketToMinutes(reportedEtaBucket);
            }

            arrivalData = _AggregatedArrivalData(
              count: 1,
              ageMin: fallbackAge,
              confidence: 'Baja',
              isActive: false,
              latestArrivalTime: mostRecent.arrivalTime!,
              reportedMinutes: reportedMinutes,
              reportedEtaBucket: reportedEtaBucket,
            );
          }
        }
      }
    }

    // 4) Procesar reportes de ETAs futuros (etaBucket sin arrivalTime)
    int? futureReportedMinutes;
    String? futureReportedEtaBucket;
    int futureReportCount = 0;

    if (futureEtaReports.isNotEmpty) {
      // Extraer etaBucket de los reportes futuros y calcular moda
      final futureEtaBuckets =
          futureEtaReports.map((r) => r.etaBucket!).toList();

      if (futureEtaBuckets.isNotEmpty) {
        futureReportedEtaBucket = modeString(futureEtaBuckets);
        if (futureReportedEtaBucket != null) {
          futureReportedMinutes = bucketToMinutes(futureReportedEtaBucket);
        }
        futureReportCount = futureEtaReports.length;
      }
    }

    // 5) Combinar datos: priorizar llegadas confirmadas, pero usar ETAs futuros si no hay llegadas recientes
    if (arrivalData != null && arrivalData.isActive) {
      // Si hay llegadas confirmadas recientes, usar esos datos
      // Pero si no tienen reportedMinutes, intentar usar ETAs futuros
      if (arrivalData.reportedMinutes == null &&
          futureReportedMinutes != null) {
        return _AggregatedArrivalData(
          count: arrivalData.count + futureReportCount,
          ageMin: arrivalData.ageMin,
          confidence: arrivalData.confidence,
          isActive: true,
          latestArrivalTime: arrivalData.latestArrivalTime,
          reportedMinutes: futureReportedMinutes,
          reportedEtaBucket: futureReportedEtaBucket,
        );
      }
      return arrivalData;
    }

    // 6) Si no hay llegadas recientes pero hay ETAs futuros, usar esos
    if (futureReportedMinutes != null && futureReportCount > 0) {
      // Calcular confianza basada en conteo de reportes futuros
      final confidence = calculateConfidence(
          futureReportCount, 0); // ageMin = 0 porque son futuros

      return _AggregatedArrivalData(
        count: futureReportCount,
        ageMin: 0, // Son reportes futuros, no pasados
        confidence: confidence,
        isActive: true, // Activos porque son predicciones futuras
        latestArrivalTime: now, // Usar ahora como referencia
        reportedMinutes: futureReportedMinutes,
        reportedEtaBucket: futureReportedEtaBucket,
      );
    }

    // 7) Si hay arrivalData stale pero no hay ETAs futuros, retornarlo
    if (arrivalData != null) {
      return arrivalData;
    }

    // 8) Sin datos recientes
    return null;
  }
}

/// Datos agregados de llegadas del metro
class _AggregatedArrivalData {
  final int count;
  final int ageMin;
  final String confidence;
  final bool isActive; // true si está en ventana activa, false si es fallback
  final DateTime latestArrivalTime;
  final int? reportedMinutes; // Tiempo en minutos basado en moda de etaBucket
  final String? reportedEtaBucket; // El bucket más común

  _AggregatedArrivalData({
    required this.count,
    required this.ageMin,
    required this.confidence,
    required this.isActive,
    required this.latestArrivalTime,
    this.reportedMinutes,
    this.reportedEtaBucket,
  });
}
