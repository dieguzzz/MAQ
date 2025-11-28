import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/station_model.dart';
import '../models/train_model.dart';
import '../theme/metro_theme.dart';

class MapService {
  // Centro de Panamá (aproximado)
  static const LatLng panamaCenter = LatLng(9.0, -79.5);

  // Mapa de abreviaciones para estaciones (más cortas y limpias)
  static const Map<String, String> _stationAbbreviations = {
    // Línea 1
    'Albrook': 'Alb',
    '5 de Mayo': '5 Mayo',
    'Lotería': 'Lot',
    'Santo Tomás': 'S. Tomás',
    'Iglesia del Carmen': 'I. Carmen',
    'Vía Argentina': 'V. Arg',
    'Fernández de Córdoba': 'F. Córdoba',
    'El Ingenio': 'Ingenio',
    '12 de Octubre': '12 Oct',
    'Pueblo Nuevo': 'P. Nuevo',
    'San Miguelito': 'S. Miguel',
    'Pan de Azúcar': 'P. Azúcar',
    'Los Andes': 'Andes',
    'San Isidro': 'S. Isidro',
    'Villa Zaita': 'V. Zaita',
    // Línea 2
    'San Miguelito L1': 'S. Mig L1',
    'Paraíso': 'Paraíso',
    'Cincuentenario': '50 Años',
    'Villa Lucre': 'V. Lucre',
    'El Crisol': 'Crisol',
    'Brisas del Golf': 'B. Golf',
    'Cerro Viento': 'C. Viento',
    'San Antonio': 'S. Antonio',
    'Pedregal': 'Pedregal',
    'Don Bosco': 'D. Bosco',
    'Corredor Sur': 'C. Sur',
    'Las Mañanitas': 'Mañanitas',
    'Hospital del Este': 'H. Este',
    'Altos de Tocumen': 'A. Tocumen',
    '24 de Diciembre': '24 Dic',
    'Nuevo Tocumen': 'N. Tocumen',
    'ITSE': 'ITSE',
    'Aeropuerto': 'Aerop',
  };

  /// Obtiene la abreviación de una estación
  static String getStationAbbreviation(String fullName) {
    return _stationAbbreviations[fullName] ?? fullName;
  }

  // Configuración inicial del mapa
  static const CameraPosition initialCameraPosition = CameraPosition(
    target: panamaCenter,
    zoom: 12.0,
  );

  // Cache para los iconos de tren
  static BitmapDescriptor? _trainIconNorte;
  static BitmapDescriptor? _trainIconSur;
  
  // Cache para el icono de estación
  static BitmapDescriptor? _stationIcon;

  // Crear icono personalizado de tren
  Future<BitmapDescriptor> _createTrainIcon(DireccionTren direccion) async {
    // Usar emoji de tren 🚇
    const String emoji = '🚇';
    const double size = 60.0;
    
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    // Color de fondo según la dirección
    final Color backgroundColor = direccion == DireccionTren.norte 
        ? Colors.blue.shade700 
        : Colors.orange.shade700;
    
    // Dibujar círculo de fondo
    final Paint backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 2,
      backgroundPaint,
    );
    
    // Dibujar borde
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 2,
      borderPaint,
    );
    
    // Dibujar emoji de tren
    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(
          fontSize: size * 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );
    
    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();
    
    return BitmapDescriptor.fromBytes(uint8List);
  }

  // Crear marcador para tren
  Future<Marker> createTrainMarker(
    TrainModel train, {
    VoidCallback? onTap,
  }) async {
    // Usar cache si está disponible
    BitmapDescriptor icon;
    if (train.direccion == DireccionTren.norte) {
      _trainIconNorte ??= await _createTrainIcon(DireccionTren.norte);
      icon = _trainIconNorte!;
    } else {
      _trainIconSur ??= await _createTrainIcon(DireccionTren.sur);
      icon = _trainIconSur!;
    }
    
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
      icon: icon,
      onTap: onTap,
    );
  }

  // Crear conjunto de marcadores para trenes
  Future<Set<Marker>> createTrainMarkers(
    List<TrainModel> trains, {
    Function(TrainModel)? onTrainTap,
  }) async {
    final markers = <Marker>[];
    for (var train in trains) {
      markers.add(
        await createTrainMarker(
          train,
          onTap: onTrainTap != null ? () => onTrainTap(train) : null,
        ),
      );
    }
    return markers.toSet();
  }

  // Crear icono personalizado de estación de metro
  Future<BitmapDescriptor> _createStationIcon() async {
    // Usar emoji de estación de metro 🚉
    const String emoji = '🚉';
    const double size = 50.0;
    
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    // Color de fondo gris oscuro para estaciones
    final Color backgroundColor = Colors.grey.shade800;
    
    // Dibujar círculo de fondo
    final Paint backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 2,
      backgroundPaint,
    );
    
    // Dibujar borde blanco
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 2,
      borderPaint,
    );
    
    // Dibujar emoji de estación
    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(
          fontSize: size * 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );
    
    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();
    
    return BitmapDescriptor.fromBytes(uint8List);
  }

  // Crear marcador para estación
  Future<Marker> createStationMarker(
    StationModel station, {
    VoidCallback? onTap,
    int? estimatedMinutes,
  }) async {
    // Usar cache si está disponible
    _stationIcon ??= await _createStationIcon();
    
    String snippet = 'Línea ${station.linea}';
    if (estimatedMinutes != null) {
      snippet += '\nPróximo tren: ~$estimatedMinutes min';
    }
    
    return Marker(
      markerId: MarkerId('station_marker_${station.id}'),
      position: LatLng(
        station.ubicacion.latitude,
        station.ubicacion.longitude,
      ),
      icon: _stationIcon!,
      infoWindow: InfoWindow(
        title: getStationAbbreviation(station.nombre),
        snippet: snippet,
      ),
      onTap: onTap,
    );
  }

  // Crear conjunto de marcadores para estaciones
  Future<Set<Marker>> createStationMarkers(
    List<StationModel> stations, {
    Function(StationModel)? onStationTap,
    Map<String, int>? estimatedTimes, // Map<stationId, minutes>
  }) async {
    final markers = <Marker>[];
    for (var station in stations) {
      final estimatedMinutes = estimatedTimes?[station.id];
      markers.add(
        await createStationMarker(
          station,
          onTap: onStationTap != null ? () => onStationTap(station) : null,
          estimatedMinutes: estimatedMinutes,
        ),
      );
    }
    return markers.toSet();
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

  static const String metroMapStyle = '''
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

