import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/station_model.dart';
import '../models/train_model.dart';
import '../theme/metro_theme.dart';

class MapService {
  // Centro de Panamá (aproximado)
  static const LatLng panamaCenter = LatLng(9.0, -79.5);

  // Configuración inicial del mapa
  static const CameraPosition initialCameraPosition = CameraPosition(
    target: panamaCenter,
    zoom: 12.0,
  );

  // Crear marcador para tren
  Marker createTrainMarker(TrainModel train) {
    return Marker(
      markerId: MarkerId(train.id),
      position: LatLng(
        train.ubicacionActual.latitude,
        train.ubicacionActual.longitude,
      ),
      infoWindow: InfoWindow(
        title: 'Tren ${train.linea}',
        snippet: 'Dirección: ${train.direccion == DireccionTren.norte ? "Norte" : "Sur"}',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueBlue,
      ),
    );
  }

  // Convertir color a hue de BitmapDescriptor
  double _getMarkerHue(Color color) {
    if (color == Colors.green) return BitmapDescriptor.hueGreen;
    if (color == Colors.orange) return BitmapDescriptor.hueOrange;
    if (color == Colors.red) return BitmapDescriptor.hueRed;
    return BitmapDescriptor.hueBlue;
  }
  
  // Crear conjunto de marcadores para trenes
  Set<Marker> createTrainMarkers(List<TrainModel> trains) {
    return trains.map((train) => createTrainMarker(train)).toSet();
  }

  // Calcular zoom para mostrar todas las estaciones
  double calculateZoomForStations(List<StationModel> stations) {
    if (stations.isEmpty) return 12.0;

    double minLat = stations.first.ubicacion.latitude;
    double maxLat = stations.first.ubicacion.latitude;
    double minLng = stations.first.ubicacion.longitude;
    double maxLng = stations.first.ubicacion.longitude;

    for (var station in stations) {
      minLat = minLat < station.ubicacion.latitude
          ? minLat
          : station.ubicacion.latitude;
      maxLat = maxLat > station.ubicacion.latitude
          ? maxLat
          : station.ubicacion.latitude;
      minLng = minLng < station.ubicacion.longitude
          ? minLng
          : station.ubicacion.longitude;
      maxLng = maxLng > station.ubicacion.longitude
          ? maxLng
          : station.ubicacion.longitude;
    }

    // Cálculo simple de zoom basado en la diferencia de coordenadas
    double latDiff = maxLat - minLat;
    double lngDiff = maxLng - minLng;
    double maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

    if (maxDiff < 0.01) return 15.0;
    if (maxDiff < 0.05) return 13.0;
    if (maxDiff < 0.1) return 12.0;
    return 11.0;
  }

  Color getStationStateColor(EstadoEstacion estado) {
    switch (estado) {
      case EstadoEstacion.normal:
        return MetroColors.stateNormal;
      case EstadoEstacion.moderado:
        return MetroColors.stateModerate;
      case EstadoEstacion.lleno:
        return MetroColors.stateCritical;
      case EstadoEstacion.cerrado:
        return MetroColors.stateInactive;
    }
  }

  double getStationRadius(EstadoEstacion estado) {
    switch (estado) {
      case EstadoEstacion.normal:
        return 120;
      case EstadoEstacion.moderado:
        return 160;
      case EstadoEstacion.lleno:
        return 200;
      case EstadoEstacion.cerrado:
        return 110;
    }
  }

  Future<void> applyMapStyle(GoogleMapController controller) async {
    await controller.setMapStyle(_metroMapStyle);
  }

  static const String _metroMapStyle = '''
  [
    {
      "featureType": "poi",
      "stylers": [
        { "visibility": "off" }
      ]
    },
    {
      "featureType": "transit",
      "stylers": [
        { "visibility": "off" }
      ]
    },
    {
      "featureType": "road",
      "elementType": "labels",
      "stylers": [
        { "visibility": "off" }
      ]
    },
    {
      "featureType": "water",
      "stylers": [
        { "color": "#b5e3ff" }
      ]
    },
    {
      "featureType": "landscape",
      "stylers": [
        { "color": "#f2f4f7" }
      ]
    }
  ]
  ''';
}

