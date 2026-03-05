import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location/location_service.dart';
import '../services/core/firebase_service.dart';
import '../services/simulation/metro_simulator_service.dart';
import '../models/simulator_state_model.dart';
import '../utils/metro_data.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  final FirebaseService _firebaseService = FirebaseService();
  final MetroSimulatorService _simulator = MetroSimulatorService();

  Position? _currentPosition;
  bool _isTracking = false;
  bool _hasPermission = false;
  bool _isGpsEnabled = false;

  Position? get currentPosition {
    // Si hay ubicación simulada, retornar posición simulada
    final simulatedLocation = _simulator.getSimulatedLocation();
    if (simulatedLocation != null) {
      return _getSimulatedPosition(simulatedLocation);
    }
    return _currentPosition;
  }

  /// Obtiene una posición simulada basada en el tipo de ubicación
  Position? _getSimulatedPosition(SimulatorLocationType locationType) {
    final stationId = _simulator.state.stationId;
    if (stationId == null) return _currentPosition;

    // Obtener la estación seleccionada
    final allStations = MetroData.getAllStations();
    try {
      final station = allStations.firstWhere((s) => s.id == stationId);

      // Calcular posición basada en la distancia simulada
      switch (locationType) {
        case SimulatorLocationType.enEstacion:
          // Misma posición que la estación (dentro de 500m)
          return Position(
            latitude: station.ubicacion.latitude,
            longitude: station.ubicacion.longitude,
            timestamp: DateTime.now(),
            accuracy: 50.0,
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            altitudeAccuracy: 0.0,
            headingAccuracy: 0.0,
          );
        case SimulatorLocationType.acercandose:
          // Posición a 750m de la estación (entre 500m y 1km)
          // Calcular punto a 750m al norte de la estación
          const offset = 750.0 / 111000.0; // Aproximadamente 1 grado = 111km
          return Position(
            latitude: station.ubicacion.latitude + offset,
            longitude: station.ubicacion.longitude,
            timestamp: DateTime.now(),
            accuracy: 100.0,
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            altitudeAccuracy: 0.0,
            headingAccuracy: 0.0,
          );
        case SimulatorLocationType.fuera:
          // Posición a 1.5km de la estación (más de 1km)
          const offset = 1500.0 / 111000.0;
          return Position(
            latitude: station.ubicacion.latitude + offset,
            longitude: station.ubicacion.longitude,
            timestamp: DateTime.now(),
            accuracy: 200.0,
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            altitudeAccuracy: 0.0,
            headingAccuracy: 0.0,
          );
      }
    } catch (e) {
      return _currentPosition;
    }
  }

  bool get isTracking => _isTracking;
  bool get hasPermission => _hasPermission;
  bool get isGpsEnabled => _isGpsEnabled;

  LocationProvider() {
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await _locationService.checkLocationStatus();
    _isGpsEnabled = status.isGpsEnabled;
    _hasPermission = status.hasPermission;
    notifyListeners();
    if (_hasPermission) {
      await getCurrentLocation();
    }
  }

  Future<LocationPermissionStatus> checkLocationStatus() async {
    final status = await _locationService.checkLocationStatus();
    _isGpsEnabled = status.isGpsEnabled;
    _hasPermission = status.hasPermission;
    notifyListeners();
    return status;
  }

  Future<void> getCurrentLocation() async {
    final status = await _locationService.checkLocationStatus();
    _isGpsEnabled = status.isGpsEnabled;
    _hasPermission = status.hasPermission;

    if (!_hasPermission) {
      notifyListeners();
      return;
    }

    // Si no tiene permisos pero el GPS está activado, solicitar permisos
    if (!_hasPermission && _isGpsEnabled) {
      _hasPermission = await _locationService.checkLocationPermission();
      if (!_hasPermission) {
        notifyListeners();
        return;
      }
    }

    try {
      _currentPosition = await _locationService.getCurrentPosition();
      if (_currentPosition != null &&
          _firebaseService.getCurrentUser() != null) {
        // Actualizar ubicación del usuario en Firestore
        final geoPoint = _locationService.positionToGeoPoint(_currentPosition!);
        await _firebaseService.updateUser(
          _firebaseService.getCurrentUser()!.uid,
          {'ultima_ubicacion': geoPoint},
        );
      }
      notifyListeners();
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void startTracking() {
    if (!_hasPermission) return;

    _isTracking = true;
    notifyListeners();

    _locationService.getPositionStream().listen((Position position) {
      _currentPosition = position;

      // Actualizar ubicación del usuario en Firestore
      if (_firebaseService.getCurrentUser() != null) {
        final geoPoint = _locationService.positionToGeoPoint(position);
        _firebaseService.updateUser(
          _firebaseService.getCurrentUser()!.uid,
          {'ultima_ubicacion': geoPoint},
        );
      }

      notifyListeners();
    });
  }

  void stopTracking() {
    _isTracking = false;
    notifyListeners();
  }
}
