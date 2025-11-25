import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/metro_data_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/map_service.dart';
import '../../services/train_simulation_service.dart';
import '../../models/station_model.dart';
import '../../models/train_model.dart';
import '../../theme/metro_theme.dart';
import '../../widgets/station_bottom_sheet.dart';

class MapWidget extends StatefulWidget {
  final List<StationModel>? highlightedRoute;

  const MapWidget({
    super.key,
    this.highlightedRoute,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  GoogleMapController? _mapController;
  final MapService _mapService = MapService();
  final TrainSimulationService _trainSimulation = TrainSimulationService();
  bool _hasAnimatedInitialCamera = false;
  Position? _lastKnownPosition;
  List<TrainModel> _simulatedTrains = [];
  Timer? _updateTimer;
  Set<Marker> _trainMarkers = {};
  Set<Marker> _stationMarkers = {};

  @override
  void initState() {
    super.initState();
    // Inicializar simulación cuando el widget se monta
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final metroProvider = context.read<MetroDataProvider>();
      if (metroProvider.stations.isNotEmpty) {
        _trainSimulation.initialize(metroProvider.stations);
        _trainSimulation.start();
        _startTrainUpdates(metroProvider.trains);
      }
    });
  }

  void _startTrainUpdates(List<TrainModel> originalTrains) {
    // Actualizar trenes cada 500ms para movimiento más fluido
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(TrainSimulationService.updateInterval, (_) async {
      if (mounted) {
        setState(() {
          _simulatedTrains = _trainSimulation.getUpdatedTrains(originalTrains);
        });
        // Actualizar marcadores
        _updateTrainMarkers(_simulatedTrains);
      }
    });
    // Actualización inicial
    if (mounted) {
      setState(() {
        _simulatedTrains = _trainSimulation.getUpdatedTrains(originalTrains);
      });
      _updateTrainMarkers(_simulatedTrains);
    }
  }

  Future<void> _updateTrainMarkers(List<TrainModel> trains) async {
    final markers = await _mapService.createTrainMarkers(trains);
    if (mounted) {
      setState(() {
        _trainMarkers = markers;
      });
    }
  }

  Future<void> _updateStationMarkers(List<StationModel> stations) async {
    // Calcular tiempos estimados basados en la simulación de trenes
    final estimatedTimes = _calculateEstimatedTimes(stations);
    
    final markers = await _mapService.createStationMarkers(
      stations,
      onStationTap: (station) => _showStationBottomSheet(station),
      estimatedTimes: estimatedTimes,
    );
    if (mounted) {
      setState(() {
        _stationMarkers = markers;
      });
    }
  }

  Map<String, int> _calculateEstimatedTimes(List<StationModel> stations) {
    final estimatedTimes = <String, int>{};
    
    // Agrupar estaciones por línea
    final stationsByLine = <String, List<StationModel>>{};
    for (var station in stations) {
      stationsByLine.putIfAbsent(station.linea, () => []).add(station);
    }
    
    // Para cada línea, calcular tiempo estimado basado en trenes cercanos
    for (var entry in stationsByLine.entries) {
      final lineStations = entry.value;
      final lineTrains = _simulatedTrains.where((t) => t.linea == entry.key).toList();
      
      for (var station in lineStations) {
        int? minTime;
        
        for (var train in lineTrains) {
          // Calcular distancia entre tren y estación
          final distance = _distanceBetweenPoints(
            train.ubicacionActual.latitude,
            train.ubicacionActual.longitude,
            station.ubicacion.latitude,
            station.ubicacion.longitude,
          );
          
          // Asumir velocidad promedio de 30 km/h y calcular tiempo
          // 1 grado ≈ 111 km, entonces distance en grados * 111 = km
          final distanceKm = distance * 111;
          final timeMinutes = (distanceKm / 30 * 60).round();
          
          if (minTime == null || timeMinutes < minTime) {
            minTime = timeMinutes;
          }
        }
        
        if (minTime != null && minTime < 30) { // Solo mostrar si es menos de 30 minutos
          estimatedTimes[station.id] = minTime;
        }
      }
    }
    
    return estimatedTimes;
  }

  double _distanceBetweenPoints(double lat1, double lon1, double lat2, double lon2) {
    final dLat = (lat1 - lat2).abs();
    final dLon = (lon1 - lon2).abs();
    return dLat + dLon; // Aproximación simple
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MetroDataProvider, LocationProvider>(
      builder: (context, metroProvider, locationProvider, child) {
        final stations = metroProvider.stations;
        final trains = metroProvider.trains;
        final currentPosition = locationProvider.currentPosition;
        if (currentPosition != null) {
          _lastKnownPosition = currentPosition;
        }

        // Inicializar simulación si aún no está inicializada o si las estaciones cambiaron
        if (stations.isNotEmpty) {
          if (_simulatedTrains.isEmpty) {
            _trainSimulation.initialize(stations);
            _trainSimulation.start();
            _startTrainUpdates(trains);
          }
        }

        // Usar trenes simulados si están disponibles, sino usar los originales
        final trainsToDisplay = _simulatedTrains.isNotEmpty ? _simulatedTrains : trains;

        // Actualizar marcadores si cambian los trenes
        if (_trainMarkers.isEmpty && trainsToDisplay.isNotEmpty) {
          _updateTrainMarkers(trainsToDisplay);
        }

        // Actualizar marcadores de estaciones si cambian
        if (_stationMarkers.isEmpty && stations.isNotEmpty) {
          _updateStationMarkers(stations);
        }

        // Crear marcadores y capas
        final markers = <Marker>{};
        markers.addAll(_trainMarkers);
        markers.addAll(_stationMarkers);
        // Ya no se agrega marcador azul; el propio map muestra el icono de persona

        final stationCircles = _createStationCircles(stations);
        final polylines = _createLinePolylines(stations);
        final highlightedPolylines = widget.highlightedRoute != null
            ? _createHighlightedRoutePolylines(widget.highlightedRoute!)
            : <Polyline>{};

        _maybeAnimateInitialCamera(stations, _lastKnownPosition);

        // Calcular posición inicial de la cámara
        CameraPosition initialPosition = MapService.initialCameraPosition;
        if (currentPosition != null) {
          initialPosition = CameraPosition(
            target: LatLng(
              currentPosition.latitude,
              currentPosition.longitude,
            ),
            zoom: 14.0,
          );
        } else if (stations.isNotEmpty) {
          // Centrar en la primera estación
          final firstStation = stations.first;
          initialPosition = CameraPosition(
            target: LatLng(
              firstStation.ubicacion.latitude,
              firstStation.ubicacion.longitude,
            ),
            zoom: 12.0,
          );
        }

        // Combinar polylines normales con la ruta resaltada
        final allPolylines = <Polyline>{
          ...polylines,
          ...highlightedPolylines,
        };

        // Ajustar cámara para mostrar la ruta resaltada si existe
        if (widget.highlightedRoute != null && widget.highlightedRoute!.isNotEmpty) {
          _maybeAnimateToRoute(widget.highlightedRoute!);
        }

        return GoogleMap(
          initialCameraPosition: initialPosition,
          markers: markers,
          circles: stationCircles,
          polylines: allPolylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          mapType: MapType.normal,
          style: MapService.metroMapStyle,
          onMapCreated: (GoogleMapController controller) async {
            _mapController = controller;
            // Animar a la ruta después de que el mapa se cree
            if (widget.highlightedRoute != null && widget.highlightedRoute!.isNotEmpty) {
              _animateToRoute(widget.highlightedRoute!);
            }
          },
          onTap: (_) {
            Navigator.of(context).maybePop();
          },
        );
      },
    );
  }

  Set<Circle> _createStationCircles(List<StationModel> stations) {
    final circles = <Circle>{};

    for (final station in stations) {
      final color = _mapService.getStationStateColor(station.estadoActual);
      final center = LatLng(
        station.ubicacion.latitude,
        station.ubicacion.longitude,
      );

      // Círculo principal que indica el estado
      circles.add(
        Circle(
          circleId: CircleId('station_${station.id}'),
          center: center,
          radius: _mapService.getStationRadius(station.estadoActual),
          strokeColor: color,
          strokeWidth: 3,
          fillColor: color.withValues(alpha: 0.25),
          consumeTapEvents: true,
          onTap: () => _showStationBottomSheet(station),
        ),
      );

      // Ya no se dibuja el círculo pequeño, se usa el icono de estación en su lugar
    }

    return circles;
  }

  Set<Polyline> _createLinePolylines(List<StationModel> stations) {
    final grouped = <String, List<StationModel>>{};
    for (final station in stations) {
      grouped.putIfAbsent(station.linea, () => []).add(station);
    }

    final connections = <Polyline>{};
    const double maxDistanceDegrees = 0.03; // ~3km aprox. en Panamá
    final processedPairs = <String>{};

    grouped.forEach((linea, lineStations) {
      for (final station in lineStations) {
        StationModel? nearest;
        double nearestDistance = double.infinity;

        for (final candidate in lineStations) {
          if (candidate.id == station.id) continue;
          final distance = _distanceBetween(station, candidate);
          if (distance < nearestDistance && distance <= maxDistanceDegrees) {
            nearestDistance = distance;
            nearest = candidate;
          }
        }

        if (nearest == null) continue;

        final pairKey = [station.id, nearest.id]..sort();
        final pairId = pairKey.join('_');
        if (processedPairs.contains(pairId)) continue;
        processedPairs.add(pairId);

        connections.add(
          Polyline(
            polylineId: PolylineId('segment_${station.id}_${nearest.id}'),
            color: MetroColors.grayMedium,
            width: 4,
            points: [
              LatLng(
                station.ubicacion.latitude,
                station.ubicacion.longitude,
              ),
              LatLng(
                nearest.ubicacion.latitude,
                nearest.ubicacion.longitude,
              ),
            ],
          ),
        );
      }
    });

    return connections;
  }

  double _distanceBetween(StationModel a, StationModel b) {
    final dLat = (a.ubicacion.latitude - b.ubicacion.latitude).abs();
    final dLng = (a.ubicacion.longitude - b.ubicacion.longitude).abs();
    return dLat + dLng;
  }

  Future<void> _showStationBottomSheet(StationModel station) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StationBottomSheet(station: station),
    );
  }

  void _maybeAnimateInitialCamera(
    List<StationModel> stations,
    Position? userPosition,
  ) {
    if (_hasAnimatedInitialCamera) return;
    if (_mapController == null) return;
    if (userPosition == null) return;
    if (stations.length < 2) return;

    _hasAnimatedInitialCamera = true;
    _animateInitialSequence(stations, userPosition);
  }

  Future<void> _animateInitialSequence(
    List<StationModel> stations,
    Position userPosition,
  ) async {
    final nearestStations = _getNearestStations(stations, userPosition);
    if (nearestStations.length < 2) return;

    final closest = nearestStations.first;
    final second = nearestStations.last;
    if (!mounted || _mapController == null) return;

    Future<void> flyToStation(StationModel station, double zoom) async {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              station.ubicacion.latitude,
              station.ubicacion.longitude,
            ),
            zoom: zoom,
          ),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 600));
    }

    try {
      await flyToStation(closest, 16);
      await flyToStation(second, 16);
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              userPosition.latitude,
              userPosition.longitude,
            ),
            zoom: 15,
          ),
        ),
      );
    } catch (_) {
      // Ignorar errores de animación
    }
  }

  List<StationModel> _getNearestStations(
    List<StationModel> stations,
    Position userPosition,
  ) {
    final sorted = [...stations]
      ..sort(
        (a, b) => _distanceToUser(a, userPosition)
            .compareTo(_distanceToUser(b, userPosition)),
      );
    return sorted.take(2).toList();
  }

  double _distanceToUser(StationModel station, Position position) {
    return Geolocator.distanceBetween(
      station.ubicacion.latitude,
      station.ubicacion.longitude,
      position.latitude,
      position.longitude,
    );
  }

  Set<Polyline> _createHighlightedRoutePolylines(List<StationModel> route) {
    final polylines = <Polyline>{};
    
    if (route.length < 2) return polylines;

    // Crear polylines para cada segmento de la ruta
    for (int i = 0; i < route.length - 1; i++) {
      final start = route[i];
      final end = route[i + 1];
      
      polylines.add(
        Polyline(
          polylineId: PolylineId('highlighted_${start.id}_${end.id}'),
          color: Colors.blue,
          width: 6,
          points: [
            LatLng(
              start.ubicacion.latitude,
              start.ubicacion.longitude,
            ),
            LatLng(
              end.ubicacion.latitude,
              end.ubicacion.longitude,
            ),
          ],
        ),
      );
    }

    return polylines;
  }

  void _maybeAnimateToRoute(List<StationModel> route) {
    if (_mapController == null || route.isEmpty) return;
    _animateToRoute(route);
  }

  Future<void> _animateToRoute(List<StationModel> route) async {
    if (_mapController == null || route.isEmpty) return;

    // Calcular bounds para incluir todas las estaciones de la ruta
    double minLat = route.first.ubicacion.latitude;
    double maxLat = route.first.ubicacion.latitude;
    double minLng = route.first.ubicacion.longitude;
    double maxLng = route.first.ubicacion.longitude;

    for (final station in route) {
      minLat = minLat < station.ubicacion.latitude ? minLat : station.ubicacion.latitude;
      maxLat = maxLat > station.ubicacion.latitude ? maxLat : station.ubicacion.latitude;
      minLng = minLng < station.ubicacion.longitude ? minLng : station.ubicacion.longitude;
      maxLng = maxLng > station.ubicacion.longitude ? maxLng : station.ubicacion.longitude;
    }

    // Agregar padding
    final latPadding = (maxLat - minLat) * 0.2;
    final lngPadding = (maxLng - minLng) * 0.2;

    final bounds = LatLngBounds(
      southwest: LatLng(minLat - latPadding, minLng - lngPadding),
      northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
    );

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _trainSimulation.stop();
    _trainSimulation.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}

