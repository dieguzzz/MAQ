import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../models/station_model.dart';
import '../models/train_model.dart';
import '../theme/metro_theme.dart';
import '../utils/helpers.dart';
import '../providers/location_provider.dart';
import '../providers/metro_data_provider.dart';
import '../services/schedule_service.dart';
import '../services/time_estimation_service.dart';
import '../services/simplified_report_service.dart';
import '../models/simplified_report_model.dart';
import 'station_report_flow_widget.dart';
import 'arrival_confirmation_dialog.dart';

/// Widget que combina la información de la estación y el modal de reporte
/// Permite deslizar entre las dos vistas
class StationReportSheet extends StatefulWidget {
  final StationModel station;
  final List<TrainModel>? trains; // Trenes cercanos para reporte de tren
  final int initialPage; // Página inicial (0 = info estación, 1 = reporte)
  final double? initialChildSize; // Tamaño inicial del sheet (null = usar default)
  final String? initialReportType; // 'station' | 'train' | null - para abrir directamente el formulario

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
              color:
                  station.linea == 'linea1' ? MetroColors.blue : MetroColors.green,
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
                  color: hasReports 
                      ? MetroColors.blue 
                      : MetroColors.grayMedium,
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
          child: _EtaSectionBox(station: station, trains: trains),
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

/// Box de Próximos trenes
class _EtaSectionBox extends StatelessWidget {
  const _EtaSectionBox({
    required this.station,
    this.trains,
  });

  final StationModel station;
  final List<TrainModel>? trains;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reportService = SimplifiedReportService();
    
    // Si no hay trenes pasados, obtener del provider
    if (trains == null || trains!.isEmpty) {
      return Consumer<MetroDataProvider>(
        builder: (context, metroProvider, child) {
          return StreamBuilder<List<SimplifiedReportModel>>(
            stream: reportService.getActiveReportsStream(),
            builder: (context, snapshot) {
              final availableTrains = metroProvider.trains;
              
              // Obtener datos agregados de reportes
              _AggregatedArrivalData? aggregated;
              if (snapshot.hasData) {
                aggregated = _TrainArrivalAggregator.processReports(
                  snapshot.data!,
                  station.id,
                );
              }
              
              // Calcular ETAs pasando aggregatedData
              final etas = _calculateRealEtas(availableTrains, aggregatedData: aggregated);
              
              return _buildBox(theme, etas);
            },
          );
        },
      );
    }

    return StreamBuilder<List<SimplifiedReportModel>>(
      stream: reportService.getActiveReportsStream(),
      builder: (context, snapshot) {
        // Obtener datos agregados de reportes
        _AggregatedArrivalData? aggregated;
        if (snapshot.hasData) {
          aggregated = _TrainArrivalAggregator.processReports(
            snapshot.data!,
            station.id,
          );
        }
        
        // Calcular ETAs pasando aggregatedData
        final etas = _calculateRealEtas(trains, aggregatedData: aggregated);
        
        return _buildBox(theme, etas);
      },
    );
  }

  List<_EtaData> _calculateRealEtas(
    List<TrainModel>? availableTrains, {
    _AggregatedArrivalData? aggregatedData,
  }) {
    // Si hay reportes activos con reportedMinutes, priorizar esos
    if (aggregatedData != null &&
        aggregatedData.isActive &&
        aggregatedData.reportedMinutes != null) {
      final etas = <_EtaData>[];
      
      // Usar el tiempo reportado como próximo tren
      etas.add(
        _EtaData(
          label: 'Próximo',
          minutes: aggregatedData.reportedMinutes!,
          confidence: _getConfidenceEmoji(aggregatedData.confidence) +
              ' ${aggregatedData.count} reportes',
        ),
      );
      
      // Calcular siguiente tren basado en intervalo típico (5-7 min después)
      final nextTrainMinutes = aggregatedData.reportedMinutes! + 6;
      etas.add(
        _EtaData(
          label: 'Siguiente',
          minutes: nextTrainMinutes,
          confidence: 'Estimado',
        ),
      );
      
      return etas;
    }

    // Si no hay reportes con tiempo, verificar si hay trenes disponibles
    if (availableTrains == null || availableTrains.isEmpty) {
      // Si no hay reportes activos, usar datos históricos para tiempos
      if (aggregatedData == null || !aggregatedData.isActive) {
        // Usar datos históricos para tiempos cuando no hay reportes
        final baseMinutes = ScheduleService.getEstimatedArrivalTimeSync(
          station.id,
          station.linea,
          DateTime.now(),
        );
        
        return [
          _EtaData(
            label: 'Próximo',
            minutes: baseMinutes,
            confidence: 'Horario base',
          ),
        ];
      }
      
      // Si hay reportes activos pero sin tiempo específico, usar horario base
      final baseMinutes = ScheduleService.getEstimatedArrivalTimeSync(
        station.id,
        station.linea,
        DateTime.now(),
      );
      
      return [
        _EtaData(
          label: 'Próximo',
          minutes: baseMinutes,
          confidence: _getConfidenceEmoji(aggregatedData.confidence) +
              ' ${aggregatedData.count} usuarios',
        ),
      ];
    }

    final timeEstimationService = TimeEstimationService();
    final etas = <_EtaData>[];

    final relevantTrains = availableTrains
        .where((train) => train.linea == station.linea)
        .toList();

    if (relevantTrains.isEmpty) {
      // Si no hay reportes activos, usar datos históricos para tiempos
      if (aggregatedData == null || !aggregatedData.isActive) {
        // Usar datos históricos para tiempos cuando no hay reportes
        final baseMinutes = ScheduleService.getEstimatedArrivalTimeSync(
          station.id,
          station.linea,
          DateTime.now(),
        );
        
        return [
          _EtaData(
            label: 'Próximo',
            minutes: baseMinutes,
            confidence: 'Horario base',
          ),
        ];
      }
      
      // Si hay reportes activos, usar horario base
      final baseMinutes = ScheduleService.getEstimatedArrivalTimeSync(
        station.id,
        station.linea,
        DateTime.now(),
      );
      
      return [
        _EtaData(
          label: 'Próximo',
          minutes: baseMinutes,
          confidence: _getConfidenceEmoji(aggregatedData.confidence) +
              ' ${aggregatedData.count} usuarios',
        ),
      ];
    }

    final trainEtas = relevantTrains.map((train) {
      final minutes = timeEstimationService.calculateEstimatedArrivalTime(
        train,
        station,
      );
      return _TrainEta(
        train: train,
        minutes: minutes,
        confidence: train.confidence ?? 'medium',
      );
    }).toList();

    trainEtas.sort((a, b) => a.minutes.compareTo(b.minutes));

    if (trainEtas.isNotEmpty) {
      final next = trainEtas[0];
      String confidenceText = _getConfidenceText(next.confidence, next.train);
      
      // Mejorar confianza si hay reportes agregados
      if (aggregatedData != null && aggregatedData.isActive) {
        confidenceText = _getConfidenceEmoji(aggregatedData.confidence) +
            ' ${aggregatedData.count} usuarios';
      }
      
      etas.add(
        _EtaData(
          label: 'Próximo',
          minutes: next.minutes,
          confidence: confidenceText,
        ),
      );

      if (trainEtas.length > 1) {
        final following = trainEtas[1];
        String confidenceText2 = _getConfidenceText(following.confidence, following.train);
        
        // Mejorar confianza si hay reportes agregados
        if (aggregatedData != null && aggregatedData.isActive) {
          confidenceText2 = _getConfidenceEmoji(aggregatedData.confidence) +
              ' ${aggregatedData.count} usuarios';
        }
        
        etas.add(
          _EtaData(
            label: 'Siguiente',
            minutes: following.minutes,
            confidence: confidenceText2,
          ),
        );
      }
    }

    return etas;
  }

  String _getConfidenceText(String confidence, TrainModel train) {
    if (train.isEstimated == true) {
      return 'Estimado';
    }

    switch (confidence) {
      case 'high':
        return '✅ Alta';
      case 'medium':
        return '⚠️ Media';
      case 'low':
      default:
        return '❓ Baja';
    }
  }

  String _getConfidenceEmoji(String confidence) {
    switch (confidence) {
      case 'Alta':
        return '✅';
      case 'Media':
        return '⚠️';
      case 'Baja':
      default:
        return '❓';
    }
  }

  Widget _buildBox(ThemeData theme, List<_EtaData> etas) {
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
                  Text(
                    eta.minutes == 0 && eta.confidence == 'Sin datos'
                        ? 'Sin datos'
                        : '${eta.minutes} min',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: eta.minutes == 0 && eta.confidence == 'Sin datos'
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
    final reportService = SimplifiedReportService();

    return StreamBuilder<List<SimplifiedReportModel>>(
      stream: reportService.getActiveReportsStream(),
      builder: (context, snapshot) {
        _AggregatedArrivalData? aggregatedData;
        int recentArrivals = 0;
        
        if (snapshot.hasData) {
          aggregatedData = _TrainArrivalAggregator.processReports(
            snapshot.data!,
            widget.station.id,
          );
          
          if (aggregatedData != null) {
            recentArrivals = aggregatedData.count;
          }
        }

        final hasRecentArrivals = aggregatedData != null && aggregatedData.isActive;
        final isStale = aggregatedData != null && !aggregatedData.isActive;

        // Detectar cuando hay un nuevo reporte (incluyendo el primer reporte)
        if (recentArrivals > _previousCount) {
          // Usar un pequeño delay para asegurar que el widget está montado
          Future.microtask(() {
            if (mounted) {
              _triggerPulse();
              _triggerStarGlow();
            }
          });
        }
        _previousCount = recentArrivals;

        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasRecentArrivals
                    ? MetroColors.blue.withOpacity(0.05 + (_pulseAnimation.value * 0.1))
                    : MetroColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasRecentArrivals
                      ? MetroColors.blue
                      : isStale
                          ? MetroColors.grayMedium
                          : MetroColors.grayMedium,
                  width: hasRecentArrivals ? (1.5 + (_pulseAnimation.value * 0.5)) : 1,
                ),
                boxShadow: hasRecentArrivals
                    ? [
                        BoxShadow(
                          color: MetroColors.blue.withOpacity(0.3 * _pulseAnimation.value),
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
                    animation: Listenable.merge([_pulseAnimation, _starGlowAnimation]),
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
                                      color: MetroColors.blue.withOpacity(0.6 * _starGlowAnimation.value),
                                      blurRadius: 12 + (_starGlowAnimation.value * 12),
                                      spreadRadius: _starGlowAnimation.value * 4,
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
                  if (aggregatedData != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      aggregatedData.isActive
                          ? '${aggregatedData.count} reporte${aggregatedData.count > 1 ? 's' : ''}'
                          : 'Hace ${aggregatedData.ageMin} min',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: hasRecentArrivals
                            ? MetroColors.blue
                            : MetroColors.grayDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (aggregatedData.isActive) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Último minuto',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: MetroColors.grayDark.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
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

/// Sección de próximos trenes - ahora con datos reales (mantener para compatibilidad)
class _EtaSection extends StatelessWidget {
  const _EtaSection({
    required this.station,
    this.trains,
  });

  final StationModel station;
  final List<TrainModel>? trains;

  /// Calcula los tiempos de llegada de los trenes que vienen hacia la estación
  List<_EtaData> _calculateRealEtas(List<TrainModel>? availableTrains) {
    if (availableTrains == null || availableTrains.isEmpty) {
      // Si no hay trenes, usar horario base
      return [
        _EtaData(
          label: 'Próximo',
          minutes: ScheduleService.getEstimatedArrivalTimeSync(
            station.id,
            station.linea,
            DateTime.now(),
          ),
          confidence: 'Horario base',
        ),
      ];
    }

    final timeEstimationService = TimeEstimationService();
    final etas = <_EtaData>[];

    // Filtrar trenes de la misma línea y calcular tiempos
    final relevantTrains = availableTrains
        .where((train) => train.linea == station.linea)
        .toList();

    if (relevantTrains.isEmpty) {
      // Si no hay trenes de la misma línea, usar horario base
      return [
        _EtaData(
          label: 'Próximo',
          minutes: ScheduleService.getEstimatedArrivalTimeSync(
            station.id,
            station.linea,
            DateTime.now(),
          ),
          confidence: 'Horario base',
        ),
      ];
    }

    // Calcular ETA para cada tren
    final trainEtas = relevantTrains.map((train) {
      final minutes = timeEstimationService.calculateEstimatedArrivalTime(
        train,
        station,
      );
      return _TrainEta(
        train: train,
        minutes: minutes,
        confidence: train.confidence ?? 'medium',
      );
    }).toList();

    // Ordenar por tiempo de llegada (más cercano primero)
    trainEtas.sort((a, b) => a.minutes.compareTo(b.minutes));

    // Tomar solo los 2 primeros (próximo y siguiente)
    if (trainEtas.isNotEmpty) {
      final next = trainEtas[0];
      final confidenceText = _getConfidenceText(next.confidence, next.train);
      etas.add(
        _EtaData(
          label: 'Próximo',
          minutes: next.minutes,
          confidence: confidenceText,
        ),
      );

      if (trainEtas.length > 1) {
        final following = trainEtas[1];
        final confidenceText2 = _getConfidenceText(following.confidence, following.train);
        etas.add(
          _EtaData(
            label: 'Siguiente',
            minutes: following.minutes,
            confidence: confidenceText2,
          ),
        );
      }
    }

    return etas;
  }

  String _getConfidenceText(String confidence, TrainModel train) {
    // Contar reportes recientes para este tren
    // Por ahora, usar la confianza del tren y su estado
    if (train.isEstimated == true) {
      return 'Estimado';
    }

    switch (confidence) {
      case 'high':
        return '✅ Alta confianza';
      case 'medium':
        return '⚠️ Confianza media';
      case 'low':
      default:
        return '❓ Baja confianza';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Si no hay trenes pasados, obtener del provider
    if (trains == null || trains!.isEmpty) {
      return Consumer<MetroDataProvider>(
        builder: (context, metroProvider, child) {
          final availableTrains = metroProvider.trains;
          final etas = _calculateRealEtas(availableTrains);
          
          if (etas.isEmpty) {
            return const SizedBox.shrink();
          }

          return _buildEtaList(theme, etas);
        },
      );
    }

    final etas = _calculateRealEtas(trains);
    
    if (etas.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildEtaList(theme, etas);
  }

  Widget _buildEtaList(ThemeData theme, List<_EtaData> etas) {
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
        ...etas.map(
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
                    stationReports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    
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
                      else if (snapshot.connectionState == ConnectionState.waiting)
                        const Text('Cargando...', style: TextStyle(color: MetroColors.grayMedium))
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
                            : snapshot.connectionState == ConnectionState.waiting
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
                    allIssues.addAll(report.stationIssues);
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

    final formatted = issues
        .map((issue) => issueNames[issue] ?? issue)
        .join(' • ');

    return formatted;
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
        .where((r) =>
            r.stationId == stationId &&
            r.scope == 'train')
        .toList();

    if (trainReports.isEmpty) return null;

    // 2) Separar en dos grupos:
    //    - Reportes con arrivalTime (llegadas confirmadas)
    //    - Reportes con etaBucket sin arrivalTime (ETAs futuros)
    final arrivalReports = trainReports
        .where((r) => r.arrivalTime != null)
        .toList();
    
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
            
            if (mostRecent.etaBucket != null && mostRecent.etaBucket!.isNotEmpty) {
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
      final futureEtaBuckets = futureEtaReports
          .map((r) => r.etaBucket!)
          .toList();
      
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
      if (arrivalData.reportedMinutes == null && futureReportedMinutes != null) {
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
      final confidence = calculateConfidence(futureReportCount, 0); // ageMin = 0 porque son futuros
      
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

