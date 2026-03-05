import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/station_model.dart';
import '../services/station_position_editor_service.dart';
import '../theme/metro_theme.dart';
import 'package:provider/provider.dart';
import '../providers/metro_data_provider.dart';

/// Modal para editar la posición de una estación en modo test
class StationPositionEditorModal extends StatefulWidget {
  final StationModel station;

  const StationPositionEditorModal({
    super.key,
    required this.station,
  });

  @override
  State<StationPositionEditorModal> createState() =>
      _StationPositionEditorModalState();
}

class _StationPositionEditorModalState
    extends State<StationPositionEditorModal> {
  final StationPositionEditorService _positionEditor =
      StationPositionEditorService();
  late double _latitude;
  late double _longitude;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    // Obtener coordenadas actuales (editadas si existen, sino las originales)
    final editedPosition = _positionEditor.getPosition(widget.station.id);
    if (editedPosition != null) {
      _latitude = editedPosition.latitude;
      _longitude = editedPosition.longitude;
    } else {
      _latitude = widget.station.ubicacion.latitude;
      _longitude = widget.station.ubicacion.longitude;
    }
    _latController = TextEditingController(text: _latitude.toStringAsFixed(6));
    _lngController = TextEditingController(text: _longitude.toStringAsFixed(6));
    _hasChanges = false;
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editedPosition = _positionEditor.getPosition(widget.station.id);
    final isEdited = editedPosition != null;

    return PopScope(
      canPop:
          !_hasChanges, // Solo permitir salir sin confirmación si no hay cambios
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasChanges) {
          // Si no se cerró y hay cambios, mostrar confirmación
          final shouldClose = await _showExitConfirmation(context);
          if (shouldClose && mounted) {
            // Si el usuario confirma, salir sin guardar
            Navigator.of(context).pop();
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: MetroColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: MetroColors.grayMedium,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Título
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.station.nombre,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isEdited)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: MetroColors.energyOrange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Editada',
                      style: TextStyle(
                        color: MetroColors.energyOrange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Editar Coordenadas',
              style: theme.textTheme.titleMedium?.copyWith(
                color: MetroColors.grayDark,
              ),
            ),
            const SizedBox(height: 24),

            // Coordenadas actuales (originales)
            Card(
              color: MetroColors.grayLight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coordenadas Originales',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: MetroColors.grayDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      '[${widget.station.ubicacion.latitude.toStringAsFixed(6)}, ${widget.station.ubicacion.longitude.toStringAsFixed(6)}]',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Editor de latitud
            Text(
              'Latitud',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Botón flecha izquierda (disminuir)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  onPressed: () {
                    setState(() {
                      _latitude -= 0.0001;
                      _hasChanges = true;
                      _latController.text = _latitude.toStringAsFixed(6);
                      _updatePosition();
                    });
                  },
                  tooltip: 'Disminuir 0.0001',
                ),
                Expanded(
                  child: Slider(
                    value: _latitude,
                    min: _latitude - 0.02, // Rango pequeño para ajuste fino
                    max: _latitude + 0.02,
                    divisions: 400, // Precisión alta
                    label: _latitude.toStringAsFixed(6),
                    onChanged: (value) {
                      setState(() {
                        _latitude = value;
                        _hasChanges = true;
                        _latController.text = _latitude.toStringAsFixed(6);
                        _updatePosition();
                      });
                    },
                  ),
                ),
                // Botón flecha derecha (aumentar)
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 20),
                  onPressed: () {
                    setState(() {
                      _latitude += 0.0001;
                      _hasChanges = true;
                      _latController.text = _latitude.toStringAsFixed(6);
                      _updatePosition();
                    });
                  },
                  tooltip: 'Aumentar 0.0001',
                ),
                SizedBox(
                  width: 140,
                  child: TextField(
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      labelText: 'Lat',
                    ),
                    controller: _latController,
                    onChanged: (value) {
                      final lat = double.tryParse(value);
                      if (lat != null) {
                        setState(() {
                          _latitude = lat;
                          _hasChanges = true;
                          _updatePosition();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Editor de longitud
            Text(
              'Longitud',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Botón flecha izquierda (disminuir)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  onPressed: () {
                    setState(() {
                      _longitude -= 0.0001;
                      _hasChanges = true;
                      _lngController.text = _longitude.toStringAsFixed(6);
                      _updatePosition();
                    });
                  },
                  tooltip: 'Disminuir 0.0001',
                ),
                Expanded(
                  child: Slider(
                    value: _longitude,
                    min: _longitude - 0.02,
                    max: _longitude + 0.02,
                    divisions: 400,
                    label: _longitude.toStringAsFixed(6),
                    onChanged: (value) {
                      setState(() {
                        _longitude = value;
                        _hasChanges = true;
                        _lngController.text = _longitude.toStringAsFixed(6);
                        _updatePosition();
                      });
                    },
                  ),
                ),
                // Botón flecha derecha (aumentar)
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 20),
                  onPressed: () {
                    setState(() {
                      _longitude += 0.0001;
                      _hasChanges = true;
                      _lngController.text = _longitude.toStringAsFixed(6);
                      _updatePosition();
                    });
                  },
                  tooltip: 'Aumentar 0.0001',
                ),
                SizedBox(
                  width: 140,
                  child: TextField(
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      labelText: 'Lng',
                    ),
                    controller: _lngController,
                    onChanged: (value) {
                      final lng = double.tryParse(value);
                      if (lng != null) {
                        // Permitir cualquier valor válido
                        setState(() {
                          _longitude = lng;
                          _hasChanges = true;
                          _updatePosition();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Coordenadas nuevas
            Card(
              color: MetroColors.blue.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_location,
                            size: 16, color: MetroColors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Coordenadas Nuevas',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: MetroColors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Formato para copiar fácilmente
                    SelectableText(
                      "'${widget.station.id}': [${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)}]",
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: MetroColors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Formato alternativo
                    SelectableText(
                      'GeoPoint(${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)})',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: MetroColors.grayDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final text =
                                  "'${widget.station.id}': [${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)}]";
                              Clipboard.setData(ClipboardData(text: text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Coordenadas copiadas'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Copiar'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isEdited)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _positionEditor
                                    .resetPosition(widget.station.id);
                                Provider.of<MetroDataProvider>(context,
                                        listen: false)
                                    .notifyListeners();
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Posición restaurada'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Reset'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: MetroColors.energyOrange,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _hasChanges ? _applyChanges : null,
                    icon: const Icon(Icons.check),
                    label: const Text('Aplicar Cambios'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MetroColors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  Future<bool> _showExitConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('¿Descartar cambios?'),
            content: const Text(
                'Has realizado cambios en las coordenadas. ¿Deseas descartarlos y cerrar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Descartar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _updatePosition() {
    // Actualizar posición en tiempo real mientras se ajusta
    final newGeoPoint = GeoPoint(_latitude, _longitude);
    _positionEditor.updatePosition(widget.station.id, newGeoPoint);

    // Notificar al provider para refrescar el mapa
    Provider.of<MetroDataProvider>(context, listen: false).notifyListeners();
  }

  void _applyChanges() {
    final newGeoPoint = GeoPoint(_latitude, _longitude);
    _positionEditor.updatePosition(widget.station.id, newGeoPoint);

    // Notificar al provider
    Provider.of<MetroDataProvider>(context, listen: false).notifyListeners();

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Posición de ${widget.station.nombre} actualizada'),
        backgroundColor: MetroColors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
