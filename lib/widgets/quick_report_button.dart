import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/location_provider.dart';
import '../providers/metro_data_provider.dart';
import '../models/station_model.dart';
import '../screens/reports/station_report_flow.dart';
import '../screens/reports/train_report_flow.dart';

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
    final metroProvider = Provider.of<MetroDataProvider>(context, listen: false);

    // Buscar estación más cercana (ubicación opcional)
    Position? userPosition;
    try {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      userPosition = locationProvider.currentPosition;
    } catch (e) {
      // Si no hay ubicación, continuar de todas formas
    }

    StationModel? nearestStation;
    
    if (userPosition != null) {
      // Si hay ubicación, buscar la más cercana
      nearestStation = _findNearestStation(
        metroProvider.stations,
        userPosition!.latitude,
        userPosition!.longitude,
      );
    }

    // Si no hay estación cercana o no hay ubicación, usar la primera estación de L1
    if (nearestStation == null) {
      final stations = metroProvider.stations;
      if (stations.isNotEmpty) {
        nearestStation = stations.firstWhere(
          (s) => s.linea == 'L1',
          orElse: () => stations.first,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay estaciones disponibles'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
    }

    // Abrir nuevo flujo simplificado de reporte de estación
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StationReportFlowScreen(
            station: nearestStation!,
          ),
        ),
      );
    }
  }

  /// Maneja el reporte de tren (2 toques)
  Future<void> _handleTrainReport() async {
    final metroProvider = Provider.of<MetroDataProvider>(context, listen: false);

    // Buscar estación más cercana para el reporte de tren
    Position? userPosition;
    try {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      userPosition = locationProvider.currentPosition;
    } catch (e) {
      // Si no hay ubicación, continuar de todas formas
    }

    StationModel? nearestStation;
    
    if (userPosition != null) {
      // Si hay ubicación, buscar la estación más cercana
      nearestStation = _findNearestStation(
        metroProvider.stations,
        userPosition!.latitude,
        userPosition!.longitude,
      );
    }

    // Si no hay estación cercana o no hay ubicación, usar la primera estación de L1
    if (nearestStation == null) {
      final stations = metroProvider.stations;
      if (stations.isNotEmpty) {
        nearestStation = stations.firstWhere(
          (s) => s.linea == 'L1',
          orElse: () => stations.first,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay estaciones disponibles'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
    }

    // Abrir nuevo flujo simplificado de reporte de tren
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TrainReportFlowScreen(
            station: nearestStation!,
          ),
        ),
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
