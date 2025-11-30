import 'package:cloud_firestore/cloud_firestore.dart';
import 'station_model.dart';
import 'train_model.dart';

/// Estado de la estación en el simulador
enum SimulatorStationStatus {
  operativa,
  cerrada,
  accesoParcial,
}

/// Estado del tren en el simulador
enum SimulatorTrainStatus {
  llegando,
  enEstacion,
  saliendo,
  sinTren,
}

/// Nivel de carga de pasajeros
enum SimulatorPassengerLoad {
  baja,
  media,
  alta,
  completa,
}

/// Tipos de incidentes que se pueden simular
enum SimulatorIncidentType {
  ninguno,
  averiaTren,
  averiaVias,
  retraso,
  personaEnVias,
  emergencia,
}

/// Ubicación simulada del usuario
enum SimulatorLocationType {
  enEstacion, // Dentro de 500m
  acercandose, // Entre 500m y 1km
  fuera, // Más de 1km
}

/// Modelo completo del estado del simulador
class SimulatorState {
  final String? stationId;
  final String? destinationStationId;
  final String? selectedLinea;
  final SimulatorStationStatus stationStatus;
  final int aglomeracion; // 1-5 (mapea a: 1=Baja, 2=Media, 3=Alta, 4=Completa, 5=Completa)
  final SimulatorTrainStatus trainStatus;
  final int? nextTrainInSeconds; // Próximo tren en X segundos
  final SimulatorPassengerLoad passengerLoad;
  final SimulatorIncidentType incidentType;
  final SimulatorLocationType? simulatedLocation;
  final bool isAutoMode;
  final DateTime lastUpdated;

  SimulatorState({
    this.stationId,
    this.destinationStationId,
    this.selectedLinea,
    this.stationStatus = SimulatorStationStatus.operativa,
    this.aglomeracion = 1,
    this.trainStatus = SimulatorTrainStatus.sinTren,
    this.nextTrainInSeconds,
    this.passengerLoad = SimulatorPassengerLoad.baja,
    this.incidentType = SimulatorIncidentType.ninguno,
    this.simulatedLocation,
    this.isAutoMode = false,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  /// Crea una copia del estado con algunos campos modificados
  SimulatorState copyWith({
    String? stationId,
    String? destinationStationId,
    String? selectedLinea,
    SimulatorStationStatus? stationStatus,
    int? aglomeracion,
    SimulatorTrainStatus? trainStatus,
    int? nextTrainInSeconds,
    SimulatorPassengerLoad? passengerLoad,
    SimulatorIncidentType? incidentType,
    SimulatorLocationType? simulatedLocation,
    bool? isAutoMode,
  }) {
    return SimulatorState(
      stationId: stationId ?? this.stationId,
      destinationStationId: destinationStationId ?? this.destinationStationId,
      selectedLinea: selectedLinea ?? this.selectedLinea,
      stationStatus: stationStatus ?? this.stationStatus,
      aglomeracion: aglomeracion ?? this.aglomeracion,
      trainStatus: trainStatus ?? this.trainStatus,
      nextTrainInSeconds: nextTrainInSeconds ?? this.nextTrainInSeconds,
      passengerLoad: passengerLoad ?? this.passengerLoad,
      incidentType: incidentType ?? this.incidentType,
      simulatedLocation: simulatedLocation ?? this.simulatedLocation,
      isAutoMode: isAutoMode ?? this.isAutoMode,
      lastUpdated: DateTime.now(),
    );
  }

  /// Estado por defecto (reset)
  factory SimulatorState.defaultState() {
    return SimulatorState(
      stationStatus: SimulatorStationStatus.operativa,
      aglomeracion: 1,
      trainStatus: SimulatorTrainStatus.sinTren,
      passengerLoad: SimulatorPassengerLoad.baja,
      incidentType: SimulatorIncidentType.ninguno,
      isAutoMode: false,
    );
  }

  /// Convierte estado de estación a EstadoEstacion
  EstadoEstacion toEstadoEstacion() {
    switch (stationStatus) {
      case SimulatorStationStatus.cerrada:
        return EstadoEstacion.cerrado;
      case SimulatorStationStatus.accesoParcial:
        return EstadoEstacion.moderado;
      case SimulatorStationStatus.operativa:
        // Si hay mucha aglomeración, devolver moderado o lleno
        if (aglomeracion >= 5) {
          return EstadoEstacion.lleno;
        } else if (aglomeracion >= 4) {
          return EstadoEstacion.moderado;
        }
        return EstadoEstacion.normal;
    }
  }

  /// Convierte carga de pasajeros a aglomeración (1-5)
  int getAglomeracionFromPassengerLoad() {
    switch (passengerLoad) {
      case SimulatorPassengerLoad.baja:
        return 1;
      case SimulatorPassengerLoad.media:
        return 2;
      case SimulatorPassengerLoad.alta:
        return 4;
      case SimulatorPassengerLoad.completa:
        return 5;
    }
  }

  /// Obtiene el texto descriptivo del estado
  String getStatusDescription() {
    final parts = <String>[];
    
    parts.add('Estación: ${_getStationStatusText()}');
    parts.add('Tren: ${_getTrainStatusText()}');
    
    if (nextTrainInSeconds != null) {
      parts.add('Próximo tren: ${nextTrainInSeconds}s');
    }
    
    parts.add('Pasajeros: ${_getPassengerLoadText()}');
    
    if (incidentType != SimulatorIncidentType.ninguno) {
      parts.add('Incidente: ${_getIncidentText()}');
    }
    
    if (simulatedLocation != null) {
      parts.add('Ubicación: ${_getLocationText()}');
    }
    
    return parts.join(' | ');
  }

  String _getStationStatusText() {
    switch (stationStatus) {
      case SimulatorStationStatus.operativa:
        return 'Operativa';
      case SimulatorStationStatus.cerrada:
        return 'Cerrada';
      case SimulatorStationStatus.accesoParcial:
        return 'Acceso Parcial';
    }
  }

  String _getTrainStatusText() {
    switch (trainStatus) {
      case SimulatorTrainStatus.llegando:
        return 'Llegando';
      case SimulatorTrainStatus.enEstacion:
        return 'En Estación';
      case SimulatorTrainStatus.saliendo:
        return 'Saliendo';
      case SimulatorTrainStatus.sinTren:
        return 'Sin Tren';
    }
  }

  String _getPassengerLoadText() {
    switch (passengerLoad) {
      case SimulatorPassengerLoad.baja:
        return 'Baja';
      case SimulatorPassengerLoad.media:
        return 'Media';
      case SimulatorPassengerLoad.alta:
        return 'Alta';
      case SimulatorPassengerLoad.completa:
        return 'Completa';
    }
  }

  String _getIncidentText() {
    switch (incidentType) {
      case SimulatorIncidentType.ninguno:
        return 'Ninguno';
      case SimulatorIncidentType.averiaTren:
        return 'Avería en Tren';
      case SimulatorIncidentType.averiaVias:
        return 'Avería en Vías';
      case SimulatorIncidentType.retraso:
        return 'Retraso';
      case SimulatorIncidentType.personaEnVias:
        return 'Persona en Vías';
      case SimulatorIncidentType.emergencia:
        return 'Emergencia';
    }
  }

  String _getLocationText() {
    switch (simulatedLocation!) {
      case SimulatorLocationType.enEstacion:
        return 'En Estación';
      case SimulatorLocationType.acercandose:
        return 'Acercándose';
      case SimulatorLocationType.fuera:
        return 'Fuera';
    }
  }

  // Métodos públicos para acceso desde otros archivos
  String getStationStatusText() => _getStationStatusText();
  String getTrainStatusText() => _getTrainStatusText();
  String getPassengerLoadText() => _getPassengerLoadText();
  String getIncidentText() => _getIncidentText();
  String getLocationText() => _getLocationText();
}

