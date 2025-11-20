import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/station_model.dart';
import '../models/train_model.dart';

class MapService {
  // Centro de Panamá (aproximado)
  static const LatLng panamaCenter = LatLng(9.0, -79.5);

  // Configuración inicial del mapa
  static const CameraPosition initialCameraPosition = CameraPosition(
    target: panamaCenter,
    zoom: 12.0,
  );

  // Crear marcador para estación
  Marker createStationMarker(StationModel station) {
    Color markerColor;
    switch (station.estadoActual) {
      case EstadoEstacion.normal:
        markerColor = Colors.green;
        break;
      case EstadoEstacion.congestionado:
        markerColor = Colors.orange;
        break;
      case EstadoEstacion.cerrado:
        markerColor = Colors.red;
        break;
    }

    return Marker(
      markerId: MarkerId(station.id),
      position: LatLng(
        station.ubicacion.latitude,
        station.ubicacion.longitude,
      ),
      infoWindow: InfoWindow(
        title: station.nombre,
        snippet: 'Estado: ${station.getAglomeracionTexto()}',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        _getMarkerHue(markerColor),
      ),
    );
  }

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

  // Crear conjunto de marcadores para estaciones
  Set<Marker> createStationMarkers(List<StationModel> stations) {
    return stations.map((station) => createStationMarker(station)).toSet();
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
}

