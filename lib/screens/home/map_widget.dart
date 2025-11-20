import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../providers/metro_data_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/map_service.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  GoogleMapController? _mapController;
  final MapService _mapService = MapService();

  @override
  Widget build(BuildContext context) {
    return Consumer2<MetroDataProvider, LocationProvider>(
      builder: (context, metroProvider, locationProvider, child) {
        final stations = metroProvider.stations;
        final trains = metroProvider.trains;
        final currentPosition = locationProvider.currentPosition;

        // Crear marcadores
        Set<Marker> markers = {};
        markers.addAll(_mapService.createStationMarkers(stations));
        markers.addAll(_mapService.createTrainMarkers(trains));

        // Agregar marcador de ubicación actual
        if (currentPosition != null) {
          markers.add(
            Marker(
              markerId: const MarkerId('current_location'),
              position: LatLng(
                currentPosition.latitude,
                currentPosition.longitude,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
              infoWindow: const InfoWindow(title: 'Tu ubicación'),
            ),
          );
        }

        // Calcular posición inicial de la cámara
        CameraPosition initialPosition = MapService.initialCameraPosition;
        if (currentPosition != null) {
          initialPosition = CameraPosition(
            target: LatLng(
              currentPosition.latitude,
              currentPosition.longitude,
            ),
            zoom: 14.0,
          );
        } else if (stations.isNotEmpty) {
          // Centrar en la primera estación
          final firstStation = stations.first;
          initialPosition = CameraPosition(
            target: LatLng(
              firstStation.ubicacion.latitude,
              firstStation.ubicacion.longitude,
            ),
            zoom: 12.0,
          );
        }

        return GoogleMap(
          initialCameraPosition: initialPosition,
          markers: markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          mapType: MapType.normal,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          onTap: (LatLng position) {
            // Mostrar información o crear reporte rápido
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

