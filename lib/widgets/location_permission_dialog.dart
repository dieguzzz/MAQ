import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationPermissionDialog extends StatelessWidget {
  final bool isGpsEnabled;
  final bool hasPermission;

  const LocationPermissionDialog({
    super.key,
    required this.isGpsEnabled,
    required this.hasPermission,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.location_on,
            color: Colors.blue,
            size: 28,
          ),
          const SizedBox(width: 8),
          const Text('Permisos de Ubicación'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recuerda que para que funcione el mapa activa el GPS y acepta los permisos.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          if (!isGpsEnabled)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.gps_off, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El GPS está desactivado',
                      style: TextStyle(
                        color: Colors.orange[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (!hasPermission)
            Container(
              padding: const EdgeInsets.all(12),
              margin: EdgeInsets.only(top: !isGpsEnabled ? 8 : 0),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.block, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Los permisos de ubicación están denegados',
                      style: TextStyle(
                        color: Colors.red[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Rechazar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Aceptar'),
        ),
      ],
    );
  }

  static Future<bool?> show(BuildContext context, {
    required bool isGpsEnabled,
    required bool hasPermission,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => LocationPermissionDialog(
        isGpsEnabled: isGpsEnabled,
        hasPermission: hasPermission,
      ),
    );
  }
}














