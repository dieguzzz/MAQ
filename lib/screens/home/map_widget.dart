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
  const MapWidget({super.key});

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
    final markers = await _mapService.createStationMarkers(
      stations,
      onStationTap: (station) => _showStationBottomSheet(station),
    );
    if (mounted) {
      setState(() {
        _stationMarkers = markers;
      });
    }
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

        return GoogleMap(
          initialCameraPosition: initialPosition,
          markers: markers,
          circles: stationCircles,
          polylines: polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          mapType: MapType.normal,
          style: MapService.metroMapStyle,
          onMapCreated: (GoogleMapController controller) async {
            _mapController = controller;
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

  @override
  void dispose() {
    _updateTimer?.cancel();
    _trainSimulation.stop();
    _trainSimulation.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}

