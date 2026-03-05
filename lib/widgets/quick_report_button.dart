import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/location_provider.dart';
import '../providers/metro_data_provider.dart';
import '../models/station_model.dart';
import 'station_report_sheet.dart';

class QuickReportButton extends StatefulWidget {
  const QuickReportButton({super.key});

  @override
  State<QuickReportButton> createState() => _QuickReportButtonState();
}

class _QuickReportButtonState extends State<QuickReportButton> {
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

  /// Maneja el reporte de estación (1 toque) - Abre directamente el formulario
  Future<void> _handleStationReport() async {
    final metroProvider =
        Provider.of<MetroDataProvider>(context, listen: false);

    // Buscar estación más cercana (ubicación opcional)
    Position? userPosition;
    try {
      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);
      userPosition = locationProvider.currentPosition;
    } catch (e) {
      // Si no hay ubicación, continuar de todas formas
    }

    StationModel? nearestStation;

    if (userPosition != null) {
      // Si hay ubicación, buscar la más cercana
      nearestStation = _findNearestStation(
        metroProvider.stations,
        userPosition.latitude,
        userPosition.longitude,
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

    // Abrir bottom sheet directamente en el formulario de reporte de estación
    if (mounted) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => StationReportSheet(
          station: nearestStation!,
          initialPage: 1, // Abrir directamente en la vista de reporte
          initialReportType:
              'station', // Abrir directamente en formulario de estación
        ),
      );
    }
  }

  /// Maneja el reporte de tren (2 toques) - Abre directamente el formulario
  Future<void> _handleTrainReport() async {
    final metroProvider =
        Provider.of<MetroDataProvider>(context, listen: false);

    // Buscar estación más cercana para el reporte de tren
    Position? userPosition;
    try {
      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);
      userPosition = locationProvider.currentPosition;
    } catch (e) {
      // Si no hay ubicación, continuar de todas formas
    }

    StationModel? nearestStation;

    if (userPosition != null) {
      // Si hay ubicación, buscar la estación más cercana
      nearestStation = _findNearestStation(
        metroProvider.stations,
        userPosition.latitude,
        userPosition.longitude,
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

    // Abrir bottom sheet directamente en el formulario de reporte de tren
    if (mounted) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => StationReportSheet(
          station: nearestStation!,
          initialPage: 1, // Abrir directamente en la vista de reporte
          initialReportType:
              'train', // Abrir directamente en formulario de tren
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón para reportar estación
        FloatingActionButton(
          onPressed: _handleStationReport,
          backgroundColor: Colors.blue,
          heroTag: "report_station",
          child: Image.asset(
            'assets/icons/train-station_11991245.png',
            width: 24,
            height: 24,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        // Botón para reportar tren
        FloatingActionButton(
          onPressed: _handleTrainReport,
          backgroundColor: Colors.green,
          heroTag: "report_train",
          child: const Icon(Icons.train, color: Colors.white),
        ),
      ],
    );
  }
}
