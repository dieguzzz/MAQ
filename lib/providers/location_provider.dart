import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/firebase_service.dart';
import '../services/metro_simulator_service.dart';
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
    
    // Si el GPS está activado pero no hay permisos, intentar solicitarlos
    if (!_hasPermission && _isGpsEnabled) {
      _hasPermission = await _locationService.checkLocationPermission();
      notifyListeners();
    }
    
    if (_hasPermission) {
      await getCurrentLocation();
      // Iniciar tracking para actualización continua
      startTracking();
    }
  }

  Future<LocationPermissionStatus> checkLocationStatus() async {
    final status = await _locationService.checkLocationStatus();
    _isGpsEnabled = status.isGpsEnabled;
    _hasPermission = status.hasPermission;
    
    // Si el GPS está activado pero no hay permisos, intentar solicitarlos
    if (!_hasPermission && _isGpsEnabled) {
      _hasPermission = await _locationService.checkLocationPermission();
    }
    
    notifyListeners();
    return LocationPermissionStatus(
      isGpsEnabled: _isGpsEnabled,
      permission: status.permission,
      hasPermission: _hasPermission,
    );
  }

  Future<void> getCurrentLocation() async {
    final status = await _locationService.checkLocationStatus();
    _isGpsEnabled = status.isGpsEnabled;
    _hasPermission = status.hasPermission;
    
    // Si no tiene permisos pero el GPS está activado, intentar solicitarlos
    if (!_hasPermission && _isGpsEnabled) {
      _hasPermission = await _locationService.checkLocationPermission();
      notifyListeners();
    }
    
    // Si aún no tiene permisos después de intentar, salir
    if (!_hasPermission) {
      notifyListeners();
      return;
    }

    try {
      _currentPosition = await _locationService.getCurrentPosition();
      if (_currentPosition != null && _firebaseService.getCurrentUser() != null) {
        // Actualizar ubicación del usuario en Firestore (con manejo de errores)
        try {
          final geoPoint = _locationService.positionToGeoPoint(_currentPosition!);
          await _firebaseService.updateUser(
            _firebaseService.getCurrentUser()!.uid,
            {'ultima_ubicacion': geoPoint},
          );
        } catch (e) {
          // Si falla actualizar en Firestore, solo loguear el error pero continuar
          print('Error actualizando ubicación en Firestore: $e');
        }
      }
      notifyListeners();
      
      // Iniciar tracking si no está activo
      if (!_isTracking && _hasPermission) {
        startTracking();
      }
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
      
      // Actualizar ubicación del usuario en Firestore (con manejo de errores)
      if (_firebaseService.getCurrentUser() != null) {
        try {
          final geoPoint = _locationService.positionToGeoPoint(position);
          _firebaseService.updateUser(
            _firebaseService.getCurrentUser()!.uid,
            {'ultima_ubicacion': geoPoint},
          ).catchError((e) {
            // Si falla, solo loguear el error pero continuar
            print('Error actualizando ubicación en Firestore (stream): $e');
          });
        } catch (e) {
          print('Error procesando ubicación: $e');
        }
      }
      
      notifyListeners();
    });
  }

  void stopTracking() {
    _isTracking = false;
    notifyListeners();
  }
}

