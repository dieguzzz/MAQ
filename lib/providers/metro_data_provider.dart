import 'package:flutter/foundation.dart';
import '../services/firebase_service.dart';
import '../models/station_model.dart';
import '../models/train_model.dart';
import '../utils/metro_data.dart';

class MetroDataProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  List<StationModel> _stations = [];
  List<TrainModel> _trains = [];
  bool _isLoading = false;
  String? _selectedLinea;

  List<StationModel> get stations => _selectedLinea == null
      ? _stations
      : _stations.where((s) => s.linea == _selectedLinea).toList();
  
  List<TrainModel> get trains => _selectedLinea == null
      ? _trains
      : _trains.where((t) => t.linea == _selectedLinea).toList();
  
  bool get isLoading => _isLoading;
  String? get selectedLinea => _selectedLinea;

  MetroDataProvider() {
    _init();
  }

  void _init() {
    // Listen to stations stream
    _firebaseService.getStationsStream().listen(
      (stations) {
        _stations = stations.isNotEmpty ? stations : MetroData.getAllStations();
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

    // Load initial data
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _stations = await _firebaseService.getStations();
      _trains = await _firebaseService.getTrains();
      if (_trains.isEmpty) {
        _trains = MetroData.getSampleTrains();
      }
      
      // Si no hay estaciones en Firestore, usar datos estáticos como fallback
      if (_stations.isEmpty) {
        print('No hay estaciones en Firestore, usando datos estáticos...');
        _stations = MetroData.getAllStations();
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

  void setSelectedLinea(String? linea) {
    _selectedLinea = linea;
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

