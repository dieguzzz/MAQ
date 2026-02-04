import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationPermissionStatus {
  final bool isGpsEnabled;
  final LocationPermission permission;
  final bool hasPermission;

  LocationPermissionStatus({
    required this.isGpsEnabled,
    required this.permission,
    required this.hasPermission,
  });
}

class LocationService {
  /// Verifica el estado de los permisos sin solicitarlos
  Future<LocationPermissionStatus> checkLocationStatus() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    return LocationPermissionStatus(
      isGpsEnabled: serviceEnabled,
      permission: permission,
      hasPermission: serviceEnabled &&
          (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always),
    );
  }

  Future<bool> checkLocationPermission() async {
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

  Future<Position?> getCurrentPosition() async {
    bool hasPermission = await checkLocationPermission();
    if (!hasPermission) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // metros
      ),
    );
  }

  GeoPoint positionToGeoPoint(Position position) {
    return GeoPoint(position.latitude, position.longitude);
  }

  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // km
  }

  Future<bool> isLocationWithinRadius(
    GeoPoint location,
    GeoPoint center,
    double radiusKm,
  ) async {
    final distance = calculateDistance(
      location.latitude,
      location.longitude,
      center.latitude,
      center.longitude,
    );
    return distance <= radiusKm;
  }
}
