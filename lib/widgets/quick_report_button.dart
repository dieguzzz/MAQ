import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/metro_theme.dart';
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

    // Retornar siempre la más cercana encontrada (sin límite de distancia)
    return nearest;
  }

  /// Maneja el reporte de estación (1 toque) - Abre directamente el formulario
  Future<void> _handleStationReport() async {
    final metroProvider =
        Provider.of<MetroDataProvider>(context, listen: false);
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);

    // Intentar obtener ubicación rápidamente (con timeout corto)
    Position? userPosition = locationProvider.currentPosition;
    if (userPosition == null && locationProvider.hasPermission) {
      try {
        await locationProvider.getCurrentLocation().timeout(
              const Duration(milliseconds: 800),
            );
        userPosition = locationProvider.currentPosition;
      } catch (e) {
        // Si falla, continuar sin ubicación
        userPosition = locationProvider.currentPosition;
      }
    }

    // Determinar estación a usar
    StationModel? selectedStation;
    final stations = metroProvider.stations;

    if (stations.isEmpty) {
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

    // Si hay ubicación, buscar la más cercana
    if (userPosition != null) {
      selectedStation = _findNearestStation(
        stations,
        userPosition.latitude,
        userPosition.longitude,
      );
    }

    // Si no hay estación seleccionada, usar la primera de L1 como fallback
    selectedStation ??= stations.firstWhere(
      (s) => s.linea == 'L1' || s.linea == 'linea1',
      orElse: () => stations.first,
    );

    // Abrir bottom sheet con la estación seleccionada
    if (mounted) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => StationReportSheet(
          station: selectedStation!,
          initialPage: 1, // Abrir directamente en la vista de reporte
          initialReportType:
              'station', // Abrir directamente en formulario de estación
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _handleStationReport,
      backgroundColor: Colors.white,
      foregroundColor: MetroColors.blue,
      heroTag: "report_station",
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 2),
      ),
      child: Image.asset(
        'assets/icons/train-station_11991245.png',
        width: 28,
        height: 28,
        color: MetroColors.blue,
      ),
    );
  }
}
