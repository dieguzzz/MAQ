import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/metro_data.dart';
import '../core/notification_service.dart';
import '../../core/logger.dart';

class BackgroundLocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _updateTimer;
  bool _isTracking = false;

  bool get isTracking => _isTracking;

  // Cache de estaciones para no procesar repetidamente
  final _stations = MetroData.getAllStations();
  static const double _geofenceRadiusMeters = 150.0; // Radio de alerta
  static const int _cooldownHours = 6; // Enfriamiento por estación

  // Throttle: only write location_history if moved >100m from last write
  static const double _minLocationHistoryDistanceMeters = 100.0;
  Position? _lastHistoryPosition;

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
        AppLogger.error('Error en ubicación: $error');
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
        AppLogger.error('Error obteniendo ubicación: $e');
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

    // Actualizar ubicación del usuario con transaction para evitar contención,
    // o simplemente un update directo.
    await _firestore.collection('users').doc(user.uid).update({
      'ultima_ubicacion': geoPoint,
      'ultima_ubicacion_timestamp': FieldValue.serverTimestamp(),
    });

    // Only write to location_history if user moved >100m since last write
    // This reduces Firestore writes significantly
    bool shouldWriteHistory = true;
    if (_lastHistoryPosition != null) {
      final distanceSinceLastWrite = Geolocator.distanceBetween(
        _lastHistoryPosition!.latitude,
        _lastHistoryPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      shouldWriteHistory =
          distanceSinceLastWrite >= _minLocationHistoryDistanceMeters;
    }

    if (shouldWriteHistory) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('location_history')
          .add({
        'ubicacion': geoPoint,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _lastHistoryPosition = position;
    }

    // --- Lógica de Geofencing (Alertas Proactivas) ---
    _checkGeofencesAndAlert(position);
  }

  Future<void> _checkGeofencesAndAlert(Position position) async {
    for (final station in _stations) {
      final double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        station.ubicacion.latitude,
        station.ubicacion.longitude,
      );

      if (distance <= _geofenceRadiusMeters) {
        await _triggerStationAlert(station.id, station.nombre);
        // Si está cerca de una, podemos hacer break o notificar de todas.
        // Mejor break para no sobrecargar si caen dos estaciones cerca (poco probable pero posible).
        break;
      }
    }
  }

  Future<void> _triggerStationAlert(
      String stationId, String stationName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String cooldownKey = 'last_notification_$stationId';
      final int lastNotificationMs = prefs.getInt(cooldownKey) ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final int msPassed = nowMs - lastNotificationMs;
      const int cooldownMs = _cooldownHours * 60 * 60 * 1000;

      if (msPassed > cooldownMs) {
        // Enviar alerta al usuario
        await _notificationService.showLocalNotification(
          title: '📍 Estás cerca del Metro',
          body:
              'Estás en la estación $stationName. ¡Abre la app, reporta su estado y gana puntos!',
          payload: 'station_alert:$stationId',
        );

        // Guardar nuevo timestamp para evitar spam
        await prefs.setInt(cooldownKey, nowMs);
      }
    } catch (e) {
      AppLogger.error('Error en Geofence Alert: $e');
    }
  }

  void dispose() {
    stopTracking();
  }
}
