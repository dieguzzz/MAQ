import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/location_provider.dart';
import '../providers/metro_data_provider.dart';
import '../models/station_model.dart';
import '../models/train_model.dart';
import 'station_report_sheet.dart';
import 'enhanced_report_modal.dart';

class QuickReportButton extends StatefulWidget {
  const QuickReportButton({super.key});

  @override
  State<QuickReportButton> createState() => _QuickReportButtonState();
}

class _QuickReportButtonState extends State<QuickReportButton> {
  DateTime? _lastTap;
  static const Duration _doubleTapDelay = Duration(milliseconds: 400);

  /// Encuentra la estación más cercana al usuario
  StationModel? _findNearestStation(
    List<StationModel> stations,
    double userLat,
    double userLon,
  ) {
    if (stations.isEmpty) return null;

    StationModel? nearest;
    double minDistance = double.infinity;

    for (var station in stations) {
      final distance = Geolocator.distanceBetween(
        userLat,
        userLon,
        station.ubicacion.latitude,
        station.ubicacion.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearest = station;
      }
    }

    // Solo retornar si está a menos de 2 km
    return minDistance <= 2000 ? nearest : null;
  }

  /// Encuentra el tren más cercano al usuario
  TrainModel? _findNearestTrain(
    List<TrainModel> trains,
    double userLat,
    double userLon,
  ) {
    if (trains.isEmpty) return null;

    TrainModel? nearest;
    double minDistance = double.infinity;

    for (var train in trains) {
      final distance = Geolocator.distanceBetween(
        userLat,
        userLon,
        train.ubicacionActual.latitude,
        train.ubicacionActual.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearest = train;
      }
    }

    // Solo retornar si está a menos de 1 km
    return minDistance <= 1000 ? nearest : null;
  }

  /// Maneja el toque del botón con detección de doble toque
  void _handleTap() {
    final now = DateTime.now();

    if (_lastTap == null) {
      // Primer tap - esperar para ver si hay segundo
      _lastTap = now;
      Future.delayed(_doubleTapDelay, () {
        if (mounted && _lastTap != null &&
            DateTime.now().difference(_lastTap!) >= _doubleTapDelay) {
          // Solo un tap - reporte de estación
          _lastTap = null;
          _handleStationReport();
        }
      });
    } else {
      // Segundo tap dentro del delay
      if (now.difference(_lastTap!) < _doubleTapDelay) {
        // Doble tap - reporte de tren
        _lastTap = null;
        _handleTrainReport();
      } else {
        // Taps muy separados, tratar como tap simple
        _lastTap = now;
        Future.delayed(_doubleTapDelay, () {
          if (mounted && _lastTap != null &&
              DateTime.now().difference(_lastTap!) >= _doubleTapDelay) {
            _lastTap = null;
            _handleStationReport();
          }
        });
      }
    }
  }

  /// Obtiene la ubicación del usuario
  Future<Position?> _getUserLocation() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);

    // Obtener ubicación actual del usuario
    var userPosition = locationProvider.currentPosition;
    if (userPosition == null) {
      // Si no hay ubicación, pedir permisos
      await locationProvider.getCurrentLocation();
      userPosition = locationProvider.currentPosition;
      if (userPosition == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Se necesita acceso a la ubicación para reportar'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return null;
      }
    }
    return userPosition;
  }

  /// Maneja el reporte de estación (1 toque)
  Future<void> _handleStationReport() async {
    final userPosition = await _getUserLocation();
    if (userPosition == null) return;

    final metroProvider = Provider.of<MetroDataProvider>(context, listen: false);

    // Buscar estación más cercana
    final nearestStation = _findNearestStation(
      metroProvider.stations,
      userPosition.latitude,
      userPosition.longitude,
    );

    if (nearestStation == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay estaciones cercanas para reportar'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Obtener trenes de la misma línea
    final trains = metroProvider.trains
        .where((t) => t.linea == nearestStation.linea)
        .toList();

    // Abrir StationReportSheet directamente en la página de reporte (página 1) y ampliado al máximo
    if (mounted) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => StationReportSheet(
          station: nearestStation,
          trains: trains.isNotEmpty ? trains : null,
          initialPage: 1, // Empezar directamente en la página de reporte
          initialChildSize: 0.85, // Ampliado al máximo (85% de la pantalla)
        ),
      );
    }
  }

  /// Maneja el reporte de tren (2 toques)
  Future<void> _handleTrainReport() async {
    final userPosition = await _getUserLocation();
    if (userPosition == null) return;

    final metroProvider = Provider.of<MetroDataProvider>(context, listen: false);

    // Buscar tren más cercano
    final nearestTrain = _findNearestTrain(
      metroProvider.trains,
      userPosition.latitude,
      userPosition.longitude,
    );

    if (nearestTrain == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay trenes cercanos para reportar'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Abrir EnhancedReportModal directamente
    if (mounted) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (modalContext) => EnhancedReportModal(train: nearestTrain),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _handleTap,
      backgroundColor: Colors.green,
      child: const Icon(Icons.add_alert),
    );
  }
}
