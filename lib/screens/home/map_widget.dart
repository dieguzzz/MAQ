import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/metro_data_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/map_service.dart';
import '../../models/station_model.dart';
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
  bool _hasAnimatedInitialCamera = false;
  Position? _lastKnownPosition;

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

        // Crear marcadores y capas
        final markers = <Marker>{};
        markers.addAll(_mapService.createTrainMarkers(trains));
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
          zoomControlsEnabled: true,
          mapToolbarEnabled: false,
          mapType: MapType.normal,
          onMapCreated: (GoogleMapController controller) async {
            _mapController = controller;
            await _mapService.applyMapStyle(controller);
          },
          onTap: (_) {
            Navigator.of(context).maybePop();
          },
        );
      },
    );
  }

  Marker _createCurrentLocationMarker(Position position) {
    return Marker(
      markerId: const MarkerId('current_location'),
      position: LatLng(position.latitude, position.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueAzure,
      ),
      infoWindow: const InfoWindow(title: 'Tu ubicación'),
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

      // Punto exacto de la estación
      circles.add(
        Circle(
          circleId: CircleId('station_dot_${station.id}'),
          center: center,
          radius: 12, // ~12 metros para mostrar un punto exacto
          strokeColor: Colors.white,
          strokeWidth: 2,
          fillColor: MetroColors.grayDark,
          consumeTapEvents: true,
          onTap: () => _showStationBottomSheet(station),
        ),
      );
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

    Future<void> _flyToStation(StationModel station, double zoom) async {
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
      await _flyToStation(closest, 16);
      await _flyToStation(second, 16);
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

  LatLngBounds _boundsFromPoints(List<LatLng> points) {
    double? minLat, maxLat, minLng, maxLng;
    for (final point in points) {
      minLat = (minLat == null) ? point.latitude : (point.latitude < minLat ? point.latitude : minLat);
      maxLat = (maxLat == null) ? point.latitude : (point.latitude > maxLat ? point.latitude : maxLat);
      minLng = (minLng == null) ? point.longitude : (point.longitude < minLng ? point.longitude : minLng);
      maxLng = (maxLng == null) ? point.longitude : (point.longitude > maxLng ? point.longitude : maxLng);
    }

    if (minLat != null && maxLat != null && minLat == maxLat) {
      minLat -= 0.001;
      maxLat += 0.001;
    }
    if (minLng != null && maxLng != null && minLng == maxLng) {
      minLng -= 0.001;
      maxLng += 0.001;
    }

    return LatLngBounds(
      southwest: LatLng(minLat ?? 0, minLng ?? 0),
      northeast: LatLng(maxLat ?? 0, maxLng ?? 0),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

