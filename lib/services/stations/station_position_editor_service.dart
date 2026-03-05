import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'station_edit_mode_service.dart';

/// Servicio para gestionar la edición de posiciones de estaciones en modo test
class StationPositionEditorService extends ChangeNotifier {
  static final StationPositionEditorService _instance =
      StationPositionEditorService._internal();
  factory StationPositionEditorService() => _instance;
  StationPositionEditorService._internal();

  final StationEditModeService _editModeService = StationEditModeService();

  /// Mapa de posiciones editadas: stationId -> GeoPoint
  final Map<String, GeoPoint> _editedPositions = {};

  /// Obtiene la posición de una estación (editada si existe, null si no hay edición)
  GeoPoint? getPosition(String stationId) {
    if (!_editModeService.isEditModeActive) return null;
    return _editedPositions[stationId];
  }

  /// Actualiza la posición de una estación
  void updatePosition(String stationId, GeoPoint newPosition) {
    if (!_editModeService.isEditModeActive) return;

    _editedPositions[stationId] = newPosition;
    _logPositionUpdate(stationId, newPosition);
    notifyListeners();
  }

  /// Obtiene todas las posiciones editadas
  Map<String, GeoPoint> getAllPositions() {
    return Map.from(_editedPositions);
  }

  /// Indica si el editor está habilitado
  bool get isEnabled => _editModeService.isEditModeActive;

  /// Resetea todas las posiciones editadas
  void reset() {
    _editedPositions.clear();
    _logs.clear();
    notifyListeners();
  }

  /// Resetea la posición de una estación específica
  void resetPosition(String stationId) {
    _editedPositions.remove(stationId);
    notifyListeners();
  }

  /// Lista de logs de coordenadas
  final List<String> _logs = [];
  final int _maxLogs = 100;

  List<String> get logs => List.unmodifiable(_logs);

  void _logPositionUpdate(String stationId, GeoPoint position) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final logEntry =
        '[$timestamp] $stationId: [${position.latitude}, ${position.longitude}]';
    _logs.add(logEntry);

    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }
  }

  /// Obtiene las coordenadas en formato JSON-friendly para copiar
  String getCoordinatesAsText() {
    if (_editedPositions.isEmpty) {
      return 'No hay coordenadas editadas';
    }

    final buffer = StringBuffer();
    buffer.writeln('// Coordenadas Editadas:');
    buffer.writeln('Map<String, GeoPoint> editedPositions = {');

    _editedPositions.forEach((stationId, position) {
      buffer.writeln(
          "  '$stationId': GeoPoint(${position.latitude}, ${position.longitude}),");
    });

    buffer.writeln('};');

    return buffer.toString();
  }

  /// Limpia los logs
  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }
}
