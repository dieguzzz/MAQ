import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/simulator_state_model.dart';
import '../models/station_model.dart';
import 'simulated_time_service.dart';

/// Servicio para gestionar el estado del simulador de metro
class MetroSimulatorService extends ChangeNotifier {
  static final MetroSimulatorService _instance = MetroSimulatorService._internal();
  factory MetroSimulatorService() => _instance;
  MetroSimulatorService._internal();

  SimulatorState _state = SimulatorState.defaultState();
  Timer? _autoModeTimer;
  final SimulatedTimeService _simulatedTime = SimulatedTimeService();

  /// Estado actual del simulador
  SimulatorState get state => _state;

  /// Indica si el simulador está activo
  bool get isActive => _state.stationId != null;

  /// Obtiene la estación actual simulada (si está configurada)
  StationModel? getSimulatedStation(List<StationModel> availableStations) {
    if (_state.stationId == null) return null;
    try {
      return availableStations.firstWhere((s) => s.id == _state.stationId);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene el estado de estación simulado para una estación específica
  EstadoEstacion? getSimulatedStationStatus(String stationId) {
    if (_state.stationId != stationId) return null;
    return _state.toEstadoEstacion();
  }

  /// Obtiene la aglomeración simulada para una estación específica
  int? getSimulatedAglomeracion(String stationId) {
    if (_state.stationId != stationId) return null;
    return _state.getAglomeracionFromPassengerLoad();
  }

  /// Obtiene el estado del tren simulado
  SimulatorTrainStatus? getSimulatedTrainStatus() {
    if (!isActive) return null;
    return _state.trainStatus;
  }

  /// Obtiene el tiempo hasta el próximo tren (en segundos)
  int? getNextTrainInSeconds() {
    if (!isActive) return _state.nextTrainInSeconds;
    return _state.nextTrainInSeconds;
  }

  /// Obtiene el tipo de incidente simulado
  SimulatorIncidentType? getSimulatedIncident() {
    if (!isActive) return null;
    return _state.incidentType;
  }

  /// Obtiene la ubicación simulada
  SimulatorLocationType? getSimulatedLocation() {
    if (!isActive) return null;
    return _state.simulatedLocation;
  }

  /// Actualiza el estado del simulador
  void updateState(SimulatorState newState) {
    _state = newState;
    _logChange('Estado actualizado: ${newState.getStatusDescription()}');
    notifyListeners();
  }

  /// Actualiza la estación seleccionada
  void setStation(String? stationId) {
    _state = _state.copyWith(stationId: stationId);
    _logChange('Estación seleccionada: $stationId');
    notifyListeners();
  }

  /// Actualiza el estado de la estación
  void setStationStatus(SimulatorStationStatus status) {
    _state = _state.copyWith(stationStatus: status);
    _logChange('Estado de estación: ${_state.getStationStatusText()}');
    notifyListeners();
  }

  /// Actualiza el estado del tren
  void setTrainStatus(SimulatorTrainStatus status) {
    _state = _state.copyWith(trainStatus: status);
    _logChange('Estado del tren: ${_state.getTrainStatusText()}');
    notifyListeners();
  }

  /// Actualiza el tiempo hasta el próximo tren
  void setNextTrainInSeconds(int? seconds) {
    _state = _state.copyWith(nextTrainInSeconds: seconds);
    if (seconds != null) {
      _logChange('Próximo tren en: ${seconds}s');
    }
    notifyListeners();
  }

  /// Actualiza la carga de pasajeros
  void setPassengerLoad(SimulatorPassengerLoad load) {
    final aglomeracion = _state.getAglomeracionFromPassengerLoad();
    _state = _state.copyWith(
      passengerLoad: load,
      aglomeracion: aglomeracion,
    );
    _logChange('Carga de pasajeros: ${_state.getPassengerLoadText()}');
    notifyListeners();
  }

  /// Actualiza el incidente
  void setIncident(SimulatorIncidentType incident) {
    _state = _state.copyWith(incidentType: incident);
    _logChange('Incidente: ${_state.getIncidentText()}');
    notifyListeners();
  }

  /// Actualiza la ubicación simulada
  void setSimulatedLocation(SimulatorLocationType? location) {
    _state = _state.copyWith(simulatedLocation: location);
    if (location != null) {
      _logChange('Ubicación: ${_state.getLocationText()}');
    }
    notifyListeners();
  }

  /// Activa o desactiva el modo automático
  void setAutoMode(bool enabled) {
    _state = _state.copyWith(isAutoMode: enabled);
    if (enabled) {
      _startAutoMode();
      _logChange('Modo automático activado');
    } else {
      _stopAutoMode();
      _logChange('Modo automático desactivado');
    }
    notifyListeners();
  }

  /// Reinicia el simulador a valores por defecto
  void reset() {
    _stopAutoMode();
    _state = SimulatorState.defaultState().copyWith(
      stationId: _state.stationId, // Mantener estación seleccionada
      selectedLinea: _state.selectedLinea,
    );
    _logChange('Simulador reiniciado');
    notifyListeners();
  }

  /// Inicia el modo automático (ciclo de tren)
  void _startAutoMode() {
    _stopAutoMode(); // Asegurarse de que no hay otro timer activo

    // Ciclo: llegando -> en estación -> saliendo -> sin tren -> llegando...
    _autoModeTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      // En modo test, 3 segundos reales = 1 minuto simulado
      // El ciclo completo dura aproximadamente 2 minutos simulados:
      // - Llegando: 30 seg sim = 1.5 seg real
      // - En estación: 60 seg sim = 3 seg real
      // - Saliendo: 30 seg sim = 1.5 seg real

      switch (_state.trainStatus) {
        case SimulatorTrainStatus.sinTren:
          setTrainStatus(SimulatorTrainStatus.llegando);
          setNextTrainInSeconds(30); // 30 segundos simulados
          break;
        case SimulatorTrainStatus.llegando:
          setTrainStatus(SimulatorTrainStatus.enEstacion);
          setNextTrainInSeconds(null);
          break;
        case SimulatorTrainStatus.enEstacion:
          setTrainStatus(SimulatorTrainStatus.saliendo);
          setNextTrainInSeconds(null);
          break;
        case SimulatorTrainStatus.saliendo:
          setTrainStatus(SimulatorTrainStatus.sinTren);
          setNextTrainInSeconds(60); // 1 minuto simulado hasta el siguiente
          break;
      }
    });
  }

  /// Detiene el modo automático
  void _stopAutoMode() {
    _autoModeTimer?.cancel();
    _autoModeTimer = null;
  }

  /// Lista de logs recientes
  final List<String> _logs = [];
  final int _maxLogs = 50;

  List<String> get logs => List.unmodifiable(_logs);

  void _logChange(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19); // HH:MM:SS
    _logs.insert(0, '[$timestamp] $message');
    if (_logs.length > _maxLogs) {
      _logs.removeLast();
    }
    notifyListeners();
  }

  /// Limpia los logs
  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _stopAutoMode();
    super.dispose();
  }
}

