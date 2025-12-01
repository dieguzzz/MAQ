import 'package:flutter/foundation.dart';
import '../services/firebase_service.dart';
import '../services/app_mode_service.dart';
import '../services/metro_simulator_service.dart';
import '../services/station_position_editor_service.dart';
import '../models/station_model.dart';
import '../models/train_model.dart';
import '../utils/metro_data.dart';
import '../providers/auth_provider.dart';

class MetroDataProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final AppModeService _appModeService = AppModeService();
  final MetroSimulatorService _simulator = MetroSimulatorService();
  final StationPositionEditorService _positionEditor = StationPositionEditorService();
  
  List<StationModel> _stations = [];
  List<TrainModel> _trains = [];
  bool _isLoading = false;
  String _selectedLinea = 'all'; // 'all' = todas las líneas, 'linea1' o 'linea2'
  bool _streamInitialized = false;
  bool _isTestMode = false;

  List<StationModel> get stations {
    _ensureStreamInitialized();
    
    // Si el simulador está activo, aplicar estados simulados a las estaciones
    List<StationModel> stationsToReturn;
    if (_selectedLinea == 'all') {
      stationsToReturn = List<StationModel>.from(_stations);
    } else {
      stationsToReturn = _stations.where((s) => s.linea == _selectedLinea).toList();
    }
    
    // Aplicar estados simulados si el simulador está activo
    if (_simulator.isActive) {
      stationsToReturn = stationsToReturn.map((station) {
        // Obtener estado simulado para esta estación
        final simulatedStatus = _simulator.getSimulatedStationStatus(station.id);
        final simulatedAglomeracion = _simulator.getSimulatedAglomeracion(station.id);
        
        if (simulatedStatus != null || simulatedAglomeracion != null) {
          // Crear una copia de la estación con el estado simulado
          return StationModel(
            id: station.id,
            nombre: station.nombre,
            linea: station.linea,
            ubicacion: station.ubicacion,
            estadoActual: simulatedStatus ?? station.estadoActual,
            aglomeracion: simulatedAglomeracion ?? station.aglomeracion,
            ultimaActualizacion: DateTime.now(),
          );
        }
        return station;
      }).toList();
    }
    
    // Aplicar coordenadas editadas si existen
    stationsToReturn = stationsToReturn.map((station) {
      final editedPosition = _positionEditor.getPosition(station.id);
      if (editedPosition != null) {
        return StationModel(
          id: station.id,
          nombre: station.nombre,
          linea: station.linea,
          ubicacion: editedPosition,
          estadoActual: station.estadoActual,
          aglomeracion: station.aglomeracion,
          ultimaActualizacion: DateTime.now(),
        );
      }
      return station;
    }).toList();
    
    return stationsToReturn;
  }
  
  List<TrainModel> get trains {
    _ensureStreamInitialized();
    // Siempre retornar una nueva lista para que la comparación funcione correctamente
    if (_selectedLinea == 'all') {
      // "Todas las líneas" - retornar todos los trenes (Línea 1 + Línea 2)
      final allTrains = List<TrainModel>.from(_trains);
      print('🔍 MetroDataProvider: trains getter - selectedLinea=all, retornando ${allTrains.length} trenes (todos)');
      return allTrains;
    } else {
      // Filtrar por línea específica
      final filtered = _trains.where((t) => t.linea == _selectedLinea).toList();
      print('🔍 MetroDataProvider: trains getter - selectedLinea=$_selectedLinea, retornando ${filtered.length} trenes');
      return filtered;
    }
  }

  bool get isLoading => _isLoading;
  String get selectedLinea => _selectedLinea;

  MetroDataProvider() {
    // No inicializar streams aquí - se hará de forma lazy cuando se necesiten
    // Cargar datos estáticos iniciales
    _stations = MetroData.getAllStations();
    _trains = MetroData.getSampleTrains();
  }

  /// Inicializa los streams solo cuando se necesitan (lazy initialization)
  void _ensureStreamInitialized() {
    if (_streamInitialized) return;
    _streamInitialized = true;
    _init();
  }

  void _init() async {
    // En modo test, no escuchar streams de Firestore para trenes
    if (!_isTestMode) {
      // Listen to stations stream
      _firebaseService.getStationsStream().listen(
        (stations) {
          // Filtrar estaciones duplicadas o incorrectas de San Miguelito
          final filteredStations = stations.where((s) => 
            s.id != 'l2_san_miguelito' && 
            s.id != 'l2_san_miguelito_l1'
          ).toList();
          _stations = filteredStations.isNotEmpty ? filteredStations : MetroData.getAllStations();
          notifyListeners();
        },
        onError: (error) {
          print('Error en stream de estaciones: $error');
          // Usar datos estáticos como fallback
          _stations = MetroData.getAllStations();
          notifyListeners();
        },
      );

      // Listen to trains stream
      _firebaseService.getTrainsStream().listen(
        (trains) {
          _trains =
              trains.isNotEmpty ? trains : MetroData.getSampleTrains();
          notifyListeners();
        },
        onError: (error) {
          print('Error en stream de trenes: $error');
          _trains = MetroData.getSampleTrains();
          notifyListeners();
        },
      );
    } else {
      // En modo test, usar solo datos estáticos
      print('🧪 Modo Test: Usando datos estáticos sin streams de Firestore');
      _stations = MetroData.getAllStations();
      _trains = MetroData.getSampleTrains();
      notifyListeners();
    }

    // Load initial data
    loadData();
  }

  /// Establece el modo test
  void setTestMode(bool isTestMode) {
    if (_isTestMode == isTestMode) return; // Ya está en ese modo
    
    _isTestMode = isTestMode;
    print('🧪 MetroDataProvider: Modo Test ${isTestMode ? "activado" : "desactivado"}');
    
    if (isTestMode) {
      // En modo test, usar solo datos estáticos sin streams
      _stations = MetroData.getAllStations();
      _trains = MetroData.getSampleTrains();
      notifyListeners();
    } else {
      // Al salir de modo test, reinicializar streams
      _streamInitialized = false;
      _ensureStreamInitialized();
    }
  }

  /// Verifica y actualiza el modo test basado en el userId
  Future<void> checkTestMode(String? userId) async {
    if (userId == null) {
      _isTestMode = false;
      return;
    }
    
    try {
      final isTest = await _appModeService.isTestMode(userId);
      if (_isTestMode != isTest) {
        setTestMode(isTest);
      }
    } catch (e) {
      print('Error verificando modo test: $e');
      _isTestMode = false;
    }
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // En modo test, usar solo datos estáticos
      if (_isTestMode) {
        print('🧪 Modo Test: Cargando datos estáticos de prueba');
        _stations = MetroData.getAllStations();
        _trains = MetroData.getSampleTrains();
      } else {
        _stations = await _firebaseService.getStations();
        _trains = await _firebaseService.getTrains();
        if (_trains.isEmpty) {
          _trains = MetroData.getSampleTrains();
        }
        
        // Filtrar estaciones duplicadas o incorrectas de San Miguelito
        _stations = _stations.where((s) => 
          s.id != 'l2_san_miguelito' && 
          s.id != 'l2_san_miguelito_l1'
        ).toList();
        
        // Si no hay estaciones en Firestore, usar datos estáticos como fallback
        if (_stations.isEmpty) {
          print('No hay estaciones en Firestore, usando datos estáticos...');
          _stations = MetroData.getAllStations();
        }
      }
    } catch (e) {
      print('Error loading metro data: $e');
      // Si hay error, usar datos estáticos como fallback
      print('Usando datos estáticos como fallback...');
      _stations = MetroData.getAllStations();
      _trains = MetroData.getSampleTrains();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedLinea(String linea) {
    // Siempre actualizar y notificar, incluso si el valor es el mismo
    // Esto asegura que "Todas las líneas" funcione correctamente
    _selectedLinea = linea;
    print('🔍 MetroDataProvider: setSelectedLinea($linea) - notificando listeners');
    notifyListeners();
  }

  StationModel? getStationById(String id) {
    try {
      return _stations.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  TrainModel? getTrainById(String id) {
    try {
      return _trains.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  List<StationModel> getStationsByLinea(String linea) {
    return _stations.where((s) => s.linea == linea).toList();
  }
}

