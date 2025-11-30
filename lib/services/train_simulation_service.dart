import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/train_model.dart';
import '../models/station_model.dart';
import '../utils/metro_data.dart';
import 'simulated_time_service.dart';

/// Servicio que simula el movimiento de los trenes a lo largo de las líneas
class TrainSimulationService {
  final Map<String, double> _trainProgress = {}; // Progreso de cada tren (0.0 a 1.0)
  final Map<String, bool> _trainDirection = {}; // true = avanzando, false = retrocediendo
  final Map<String, List<StationModel>> _lineStations = {};
  bool _isTestMode = false; // En modo test, los trenes se mueven con tiempo acelerado
  final SimulatedTimeService _simulatedTime = SimulatedTimeService();
  
  // Intervalo de actualización (1 segundo para movimiento más fluido)
  static const Duration updateInterval = Duration(seconds: 1);
  
  // Velocidad de movimiento más rápida (factor de aumento)
  static const double speedFactor = 0.8; // 80% de la velocidad normal (más suave y visible)

  /// Establece si estamos en modo test
  void setTestMode(bool isTestMode) {
    _isTestMode = isTestMode;
    if (isTestMode) {
      // En modo test, iniciar tiempo simulado
      _simulatedTime.start();
    } else {
      // Salir de modo test, detener tiempo simulado
      _simulatedTime.stop();
    }
  }

  /// Inicializa la simulación con las estaciones
  void initialize(List<StationModel> stations) {
    // Organizar estaciones por línea
    _lineStations.clear();
    for (var station in stations) {
      _lineStations.putIfAbsent(station.linea, () => []).add(station);
    }
    
    // Ordenar estaciones según el orden de los datos estáticos (no por ID)
    // Esto asegura que los trenes sigan la ruta correcta sin saltarse estaciones
    _lineStations.forEach((linea, lineStations) {
      _sortStationsByStaticOrder(lineStations, linea);
    });

    // Inicializar progreso de trenes
    final sampleTrains = MetroData.getSampleTrains();
    for (var train in sampleTrains) {
      final lineStations = _lineStations[train.linea] ?? [];
      if (lineStations.isNotEmpty) {
        // Inicializar progreso basado en la posición actual del tren
        _trainProgress[train.id] = _calculateInitialProgress(train, lineStations);
        // Dirección: norte = de primera a última estación (0.0 a 1.0)
        // sur = de última a primera estación (1.0 a 0.0)
        _trainDirection[train.id] = train.direccion == DireccionTren.norte;
      }
    }
  }

  /// Calcula el progreso inicial basado en la posición actual del tren
  double _calculateInitialProgress(TrainModel train, List<StationModel> stations) {
    if (stations.isEmpty) return 0.0;

    // Encontrar la estación más cercana
    double minDistance = double.infinity;
    int closestIndex = 0;

    for (int i = 0; i < stations.length; i++) {
      final station = stations[i];
      final distance = _distanceBetween(
        train.ubicacionActual.latitude,
        train.ubicacionActual.longitude,
        station.ubicacion.latitude,
        station.ubicacion.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    // Calcular progreso basado en el índice de la estación más cercana
    return (closestIndex / (stations.length - 1)).clamp(0.0, 1.0);
  }

  /// Ordena las estaciones según el orden de los datos estáticos
  void _sortStationsByStaticOrder(List<StationModel> stations, String linea) {
    // Obtener el orden correcto desde los datos estáticos
    final staticStations = linea == 'linea1' 
        ? MetroData.getLinea1Stations()
        : MetroData.getLinea2Stations();
    
    // Crear un mapa de ID a índice para ordenar
    final orderMap = <String, int>{};
    for (int i = 0; i < staticStations.length; i++) {
      orderMap[staticStations[i].id] = i;
    }
    
    // Ordenar las estaciones según el orden estático
    stations.sort((a, b) {
      final orderA = orderMap[a.id] ?? 999;
      final orderB = orderMap[b.id] ?? 999;
      return orderA.compareTo(orderB);
    });
  }

  /// Calcula la distancia entre dos puntos geográficos (aproximada)
  double _distanceBetween(double lat1, double lng1, double lat2, double lng2) {
    final dLat = lat2 - lat1;
    final dLng = lng2 - lng1;
    return math.sqrt(dLat * dLat + dLng * dLng);
  }

  /// Inicia la simulación (el Timer se maneja externamente)
  void start() {
    // El servicio ya no maneja su propio Timer
    // Las actualizaciones se hacen cuando se llama getUpdatedTrains()
  }

  /// Detiene la simulación (no hace nada ahora, pero se mantiene para compatibilidad)
  void stop() {
    // El Timer se maneja externamente en el widget
  }
  
  /// Actualiza las posiciones internamente (llamado antes de obtener trenes actualizados)
  void updatePositions() {
    _updateTrainPositions();
  }

  /// Actualiza las posiciones de todos los trenes
  void _updateTrainPositions() {
    final sampleTrains = MetroData.getSampleTrains();
    
    for (var train in sampleTrains) {
      final lineStations = _lineStations[train.linea];
      if (lineStations == null || lineStations.length < 2) continue;

      final trainId = train.id;
      var progress = _trainProgress[trainId] ?? 0.0;
      final isForward = _trainDirection[trainId] ?? true;

      // Calcular incremento de progreso
      double baseSpeed;
      double timeFactor;
      
      if (_isTestMode) {
        // En modo test: 3 segundos reales = 1 minuto simulado
        // Entonces 1 segundo real = 20 segundos simulados
        // Para el movimiento, necesitamos acelerar 20x
        baseSpeed = (train.velocidad / 100.0) * speedFactor;
        timeFactor = 20.0; // Aceleración 20x (1 segundo real = 20 segundos simulados)
      } else {
        // Modo normal
        baseSpeed = (train.velocidad / 100.0) * speedFactor;
        timeFactor = 1.0;
      }
      
      final progressIncrement = baseSpeed * (updateInterval.inSeconds / 60.0) * timeFactor;

      // Actualizar progreso
      if (isForward) {
        progress += progressIncrement;
        if (progress >= 1.0) {
          progress = 1.0;
          _trainDirection[trainId] = false; // Cambiar dirección
        }
      } else {
        progress -= progressIncrement;
        if (progress <= 0.0) {
          progress = 0.0;
          _trainDirection[trainId] = true; // Cambiar dirección
        }
      }

      _trainProgress[trainId] = progress;
    }
  }

  /// Obtiene el progreso actual de un tren (0.0 a 1.0)
  double getTrainProgress(TrainModel train) {
    return _trainProgress[train.id] ?? 0.0;
  }

  /// Obtiene la posición actual de un tren basada en su progreso
  /// El tren se mueve secuencialmente entre estaciones adyacentes
  GeoPoint getTrainPosition(TrainModel train) {
    final lineStations = _lineStations[train.linea];
    if (lineStations == null || lineStations.length < 2) {
      return train.ubicacionActual; // Retornar posición original si no hay estaciones
    }

    final progress = _trainProgress[train.id] ?? 0.0;
    final clampedProgress = progress.clamp(0.0, 1.0);

    // Calcular índice de segmento (entre estaciones adyacentes)
    // Esto asegura que el tren pase por todas las estaciones en orden
    final segmentCount = lineStations.length - 1;
    final segmentIndex = (clampedProgress * segmentCount).floor();
    final finalSegmentIndex = segmentIndex.clamp(0, segmentCount - 1);

    // Obtener estaciones adyacentes del segmento actual
    // El tren solo puede estar entre dos estaciones consecutivas
    final startStation = lineStations[finalSegmentIndex];
    final endStation = lineStations[finalSegmentIndex + 1];

    // Calcular posición interpolada entre las dos estaciones adyacentes
    final segmentProgress = (clampedProgress * segmentCount) - finalSegmentIndex;
    final finalSegmentProgress = segmentProgress.clamp(0.0, 1.0);

    // Interpolación lineal entre estaciones adyacentes
    // Esto garantiza que el tren pase por todas las estaciones en orden
    final lat = startStation.ubicacion.latitude +
        (endStation.ubicacion.latitude - startStation.ubicacion.latitude) * finalSegmentProgress;
    final lng = startStation.ubicacion.longitude +
        (endStation.ubicacion.longitude - startStation.ubicacion.longitude) * finalSegmentProgress;

    return GeoPoint(lat, lng);
  }

  /// Obtiene una lista de trenes con posiciones actualizadas
  List<TrainModel> getUpdatedTrains(List<TrainModel> originalTrains) {
    // Actualizar posiciones antes de obtener los trenes
    _updateTrainPositions();
    
    return originalTrains.map((train) {
      final updatedPosition = getTrainPosition(train);
      return TrainModel(
        id: train.id,
        linea: train.linea,
        direccion: train.direccion,
        ubicacionActual: updatedPosition,
        velocidad: train.velocidad * speedFactor, // Velocidad reducida
        estado: train.estado,
        aglomeracion: train.aglomeracion,
        ultimaActualizacion: DateTime.now(),
      );
    }).toList();
  }

  void dispose() {
    stop();
    _trainProgress.clear();
    _trainDirection.clear();
    _lineStations.clear();
  }
}

