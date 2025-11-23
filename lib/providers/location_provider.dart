import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/firebase_service.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  final FirebaseService _firebaseService = FirebaseService();
  
  Position? _currentPosition;
  bool _isTracking = false;
  bool _hasPermission = false;

  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;
  bool get hasPermission => _hasPermission;

  LocationProvider() {
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    _hasPermission = await _locationService.checkLocationPermission();
    notifyListeners();
    if (_hasPermission) {
      await getCurrentLocation();
    }
  }

  Future<void> getCurrentLocation() async {
    _hasPermission = await _locationService.checkLocationPermission();
    if (!_hasPermission) {
      notifyListeners();
      return;
    }

    try {
      _currentPosition = await _locationService.getCurrentPosition();
      if (_currentPosition != null && _firebaseService.getCurrentUser() != null) {
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

