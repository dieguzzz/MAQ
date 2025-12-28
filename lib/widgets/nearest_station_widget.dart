import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/location_provider.dart';
import '../providers/metro_data_provider.dart';
import '../models/station_model.dart';
import '../theme/metro_theme.dart';
import '../widgets/station_report_sheet.dart';
import '../services/simplified_report_service.dart';
import '../models/simplified_report_model.dart';

class NearestStationWidget extends StatefulWidget {
  const NearestStationWidget({super.key});

  @override
  State<NearestStationWidget> createState() => _NearestStationWidgetState();
}

class _NearestStationWidgetState extends State<NearestStationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _starGlowController;
  late Animation<double> _starGlowAnimation;
  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
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
    _starGlowController.dispose();
    super.dispose();
  }

  void _triggerStarGlow() {
    _starGlowController.forward(from: 0.0).then((_) {
      if (mounted) {
        _starGlowController.reverse();
      }
    });
  }

  StationModel? _findNearestStation(
    List<StationModel> stations,
    double userLat,
    double userLon,
  ) {
    if (stations.isEmpty) return null;

    StationModel? nearest;
    double minDistance = double.infinity;

    for (var station in stations) {
      final distance = Geolocator.distanceBetween(
        userLat,
        userLon,
        station.ubicacion.latitude,
        station.ubicacion.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearest = station;
      }
    }

    return nearest;
  }

  String _getLineaText(String linea) {
    if (linea == 'linea1' || linea == 'L1') {
      return 'Línea 1';
    } else if (linea == 'linea2' || linea == 'L2') {
      return 'Línea 2';
    }
    return linea;
  }

  void _openStationDetails(BuildContext context, StationModel station) {
    final metroProvider = Provider.of<MetroDataProvider>(context, listen: false);
    final trains = metroProvider.trains.where((t) => t.linea == station.linea).toList();
    
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StationReportSheet(
        station: station,
        trains: trains.isNotEmpty ? trains : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportService = SimplifiedReportService();
    
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        return Consumer<MetroDataProvider>(
          builder: (context, metroProvider, child) {
            // Obtener ubicación del usuario
            final userPosition = locationProvider.currentPosition;
            final stations = metroProvider.stations;

            // Si no hay ubicación o no hay estaciones, no mostrar nada
            if (userPosition == null || stations.isEmpty) {
              return const SizedBox.shrink();
            }

            // Encontrar estación más cercana
            final nearestStation = _findNearestStation(
              stations,
              userPosition.latitude,
              userPosition.longitude,
            );

            // Si no se encontró estación, no mostrar nada
            if (nearestStation == null) {
              return const SizedBox.shrink();
            }

            return StreamBuilder<List<SimplifiedReportModel>>(
              stream: reportService.getActiveReportsStream(),
              builder: (context, snapshot) {
                // Usar el agregador en lugar del filtro simple
                bool hasRecentArrivals = false;
                int recentCount = 0;
                
                if (snapshot.hasData) {
                  final aggregated = _TrainArrivalAggregator.processReports(
                    snapshot.data!,
                    nearestStation.id,
                  );
                  
                  if (aggregated != null) {
                    hasRecentArrivals = aggregated.isActive;
                    recentCount = aggregated.count;
                  }
                }

                // Detectar cuando hay un nuevo reporte
                if (recentCount > _previousCount) {
                  Future.microtask(() {
                    if (mounted) {
                      _triggerStarGlow();
                    }
                  });
                }
                _previousCount = recentCount;

                return GestureDetector(
                  onTap: () => _openStationDetails(context, nearestStation),
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: const BoxConstraints(maxWidth: 300),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: hasRecentArrivals
                              ? MetroColors.blue.withOpacity(0.2)
                              : Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: hasRecentArrivals
                          ? Border.all(
                              color: MetroColors.blue,
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estación ${nearestStation.nombre}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: MetroColors.grayDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getLineaText(nearestStation.linea),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: nearestStation.linea == 'linea1' || nearestStation.linea == 'L1'
                                    ? MetroColors.blue
                                    : MetroColors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (hasRecentArrivals) ...[
                          const SizedBox(width: 8),
                          AnimatedBuilder(
                            animation: _starGlowAnimation,
                            builder: (context, child) {
                              return Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: MetroColors.blue.withOpacity(0.1 + (_starGlowAnimation.value * 0.2)),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: MetroColors.blue.withOpacity(0.5 * _starGlowAnimation.value),
                                      blurRadius: 8 + (_starGlowAnimation.value * 8),
                                      spreadRadius: _starGlowAnimation.value * 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.star,
                                  color: MetroColors.blue,
                                  size: 18,
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
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
          
          arrivalData = _AggregatedArrivalData(
            count: count,
            ageMin: ageMin,
            confidence: confidence,
            isActive: true,
            latestArrivalTime: latestBucket,
          );
        } else {
          // Fallback: reporte más reciente si está dentro de 10 min
          final mostRecent = arrivalReports.reduce(
            (a, b) => a.arrivalTime!.isAfter(b.arrivalTime!) ? a : b,
          );

          final fallbackAge = now.difference(mostRecent.arrivalTime!).inMinutes;

          if (fallbackAge <= staleWindowMin) {
            arrivalData = _AggregatedArrivalData(
              count: 1,
              ageMin: fallbackAge,
              confidence: 'Baja',
              isActive: false,
              latestArrivalTime: mostRecent.arrivalTime!,
            );
          }
        }
      }
    }

    // 4) Procesar reportes de ETAs futuros (etaBucket sin arrivalTime)
    if (futureEtaReports.isNotEmpty && (arrivalData == null || !arrivalData.isActive)) {
      // Si no hay llegadas recientes pero hay ETAs futuros, considerar activos
      final confidence = calculateConfidence(futureEtaReports.length, 0);
      
      return _AggregatedArrivalData(
        count: futureEtaReports.length,
        ageMin: 0,
        confidence: confidence,
        isActive: true, // Activos porque son predicciones futuras
        latestArrivalTime: now,
      );
    }

    // 5) Retornar datos de llegadas si existen
    if (arrivalData != null) {
      return arrivalData;
    }

    // 6) Sin datos recientes
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

