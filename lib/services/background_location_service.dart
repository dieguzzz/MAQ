import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BackgroundLocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Note: FirebaseService removed as unused

  StreamSubscription<Position>? _positionSubscription;
  Timer? _updateTimer;
  bool _isTracking = false;

  bool get isTracking => _isTracking;

  Future<void> startTracking() async {
    if (_isTracking) return;

    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) {
      throw Exception('Permisos de ubicación no concedidos');
    }

    _isTracking = true;

    // Actualizar ubicación cada 30 segundos cuando la app está en foreground
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // metros
      ),
    ).listen(
      (position) {
        _updateUserLocation(position);
      },
      onError: (error) {
        print('Error en ubicación: $error');
      },
    );

    // También actualizar periódicamente
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        await _updateUserLocation(position);
      } catch (e) {
        print('Error obteniendo ubicación: $e');
      }
    });
  }

  Future<void> stopTracking() async {
    _isTracking = false;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<void> _updateUserLocation(Position position) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final geoPoint = GeoPoint(position.latitude, position.longitude);

    // Actualizar ubicación del usuario
    await _firestore.collection('users').doc(user.uid).update({
      'ultima_ubicacion': geoPoint,
      'ultima_ubicacion_timestamp': FieldValue.serverTimestamp(),
    });

    // Agregar entrada al historial de ubicaciones (para análisis)
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('location_history')
        .add({
      'ubicacion': geoPoint,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Limpiar historial antiguo (mantener solo últimas 100 entradas)
    final historySnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('location_history')
        .orderBy('timestamp', descending: true)
        .get();

    if (historySnapshot.docs.length > 100) {
      final toDelete = historySnapshot.docs.sublist(100);
      final batch = _firestore.batch();
      for (var doc in toDelete) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  void dispose() {
    stopTracking();
  }
}
