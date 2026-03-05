import 'package:flutter/foundation.dart';

/// Servicio para gestionar el modo de edición de estaciones
class StationEditModeService extends ChangeNotifier {
  static final StationEditModeService _instance =
      StationEditModeService._internal();
  factory StationEditModeService() => _instance;
  StationEditModeService._internal();

  /// Indica si el modo de edición está activo
  bool _isEditModeActive = false;

  bool get isEditModeActive => _isEditModeActive;

  /// Activa el modo de edición
  void activate() {
    if (_isEditModeActive) return;
    _isEditModeActive = true;
    notifyListeners();
  }

  /// Desactiva el modo de edición
  void deactivate() {
    if (!_isEditModeActive) return;
    _isEditModeActive = false;
    notifyListeners();
  }

  /// Alterna el modo de edición
  void toggle() {
    _isEditModeActive = !_isEditModeActive;
    notifyListeners();
  }
}
