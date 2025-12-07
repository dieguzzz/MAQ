import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/metro_data_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/map_service.dart';
import '../../services/train_simulation_service.dart';
import '../../models/station_model.dart';
import '../../models/train_model.dart';
import '../../theme/metro_theme.dart';
import '../../widgets/station_report_sheet.dart';
import '../../widgets/enhanced_report_modal.dart';
import '../../widgets/station_position_editor_modal.dart';
import '../../services/app_mode_service.dart';
import '../../providers/auth_provider.dart';
import '../../services/station_position_editor_service.dart';
import '../../services/station_edit_mode_service.dart';
import '../../utils/metro_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class MapWidget extends StatefulWidget {
  final List<StationModel>? highlightedRoute;

  const MapWidget({
    super.key,
    this.highlightedRoute,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  GoogleMapController? _mapController;
  final MapService _mapService = MapService();
  final TrainSimulationService _trainSimulation = TrainSimulationService();
  final StationPositionEditorService _positionEditor = StationPositionEditorService();
  bool _hasAnimatedInitialCamera = false;
  Position? _lastKnownPosition;
  List<TrainModel> _simulatedTrains = [];
  Timer? _updateTimer;
  Set<Marker> _trainMarkers = {};
  Set<Marker> _stationMarkers = {};
  List<StationModel>? _previousStations;
  List<TrainModel>? _previousTrains;
  String? _previousSelectedLinea; // Puede ser null en la primera carga, luego será 'all', 'linea1' o 'linea2'
  bool _isTestMode = false;

  @override
  void initState() {
    super.initState();
    // Animación de trenes deshabilitada - los trenes no se moverán
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final metroProvider = context.read<MetroDataProvider>();
      if (metroProvider.stations.isNotEmpty) {
        // _trainSimulation.initialize(metroProvider.stations);
        // _trainSimulation.start();
        // _startTrainUpdates(metroProvider.trains);
        
        // Usar los trenes originales sin simulación
        if (mounted) {
          setState(() {
            _simulatedTrains = metroProvider.trains;
          });
          _updateTrainMarkers(metroProvider.trains);
        }
      }
    });
    
    // Escuchar cambios en el modo de edición para actualizar marcadores
    final editModeService = StationEditModeService();
    editModeService.addListener(_onEditModeChanged);
  }

  void _onEditModeChanged() {
    // Cuando cambia el modo de edición, actualizar los marcadores
    if (mounted) {
      final metroProvider = Provider.of<MetroDataProvider>(context, listen: false);
      if (metroProvider.stations.isNotEmpty) {
        print('🔄 Modo edición cambió - actualizando marcadores');
        _updateStationMarkers(metroProvider.stations);
      }
    }
  }

  void _startTrainUpdates(List<TrainModel> originalTrains) {
    // Animación de trenes deshabilitada - los trenes no se moverán
    // _updateTimer?.cancel();
    // _updateTimer = Timer.periodic(TrainSimulationService.updateInterval, (_) async {
    //   if (mounted) {
    //     setState(() {
    //       _simulatedTrains = _trainSimulation.getUpdatedTrains(originalTrains);
    //     });
    //     // Actualizar marcadores
    //     _updateTrainMarkers(_simulatedTrains);
    //   }
    // });
    // Actualización inicial - usar trenes originales sin simulación
    if (mounted) {
      setState(() {
        _simulatedTrains = originalTrains;
      });
      _updateTrainMarkers(originalTrains);
    }
  }

  Future<void> _updateTrainMarkers(List<TrainModel> trains) async {
    final markers = await _mapService.createTrainMarkers(
      trains,
      onTrainTap: _showTrainReportModal,
    );
    if (mounted) {
      setState(() {
        _trainMarkers = markers;
      });
    }
  }

  Future<void> _showTrainReportModal(TrainModel train) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnhancedReportModal(train: train),
    );
  }

  Future<void> _updateStationMarkers(List<StationModel> stations) async {
    // Calcular tiempos estimados basados en la simulación de trenes
    final estimatedTimes = _calculateEstimatedTimes(stations);
    
    // Aplicar coordenadas editadas a las estaciones antes de crear marcadores
    final stationsWithEditedPositions = stations.map((station) {
      final editedPosition = _positionEditor.getPosition(station.id);
      if (editedPosition != null) {
        return StationModel(
          id: station.id,
          nombre: station.nombre,
          linea: station.linea,
          ubicacion: editedPosition,
          estadoActual: station.estadoActual,
          aglomeracion: station.aglomeracion,
          ultimaActualizacion: station.ultimaActualizacion,
        );
      }
      return station;
    }).toList();
    
    final markers = await _mapService.createStationMarkers(
      stationsWithEditedPositions,
      onStationTap: (station) {
        final editModeService = Provider.of<StationEditModeService>(context, listen: false);
        // Si está en modo edición, mostrar coordenadas en lugar del bottom sheet
        if (editModeService.isEditModeActive) {
          _showCoordinatesDialog(station);
        } else {
          // Encontrar la estación original para pasar al bottom sheet
          final originalStation = stations.firstWhere((s) => s.id == station.id);
          _showStationBottomSheet(originalStation);
        }
      },
      estimatedTimes: estimatedTimes,
      draggable: () {
        final editModeService = Provider.of<StationEditModeService>(context, listen: false);
        return editModeService.isEditModeActive;
      }(), // Hacer arrastrables solo cuando el modo de edición está activo
      onStationDragEnd: () {
        final editModeService = Provider.of<StationEditModeService>(context, listen: false);
        if (!editModeService.isEditModeActive) return null;
        return (station, newPosition) {
          // Cuando se arrastra un marcador en Google Maps, actualizar la posición
          final newGeoPoint = GeoPoint(newPosition.latitude, newPosition.longitude);
          print('🧪 Marker drag end: ${station.nombre} -> [${newPosition.latitude}, ${newPosition.longitude}]');
          _positionEditor.updatePosition(station.id, newGeoPoint);
          
          // Notificar al provider para refrescar
          Provider.of<MetroDataProvider>(context, listen: false).notifyListeners();
          
          // Actualizar los marcadores para reflejar la nueva posición
          _updateStationMarkers(stations);
        };
      }(),
    );
    if (mounted) {
      setState(() {
        _stationMarkers = markers;
      });
    }
  }

  Map<String, int> _calculateEstimatedTimes(List<StationModel> stations) {
    final estimatedTimes = <String, int>{};
    
    // Agrupar estaciones por línea
    final stationsByLine = <String, List<StationModel>>{};
    for (var station in stations) {
      stationsByLine.putIfAbsent(station.linea, () => []).add(station);
    }
    
    // Para cada línea, calcular tiempo estimado basado en trenes cercanos
    for (var entry in stationsByLine.entries) {
      final lineStations = entry.value;
      final lineTrains = _simulatedTrains.where((t) => t.linea == entry.key).toList();
      
      for (var station in lineStations) {
        int? minTime;
        
        for (var train in lineTrains) {
          // Calcular distancia entre tren y estación
          final distance = _distanceBetweenPoints(
            train.ubicacionActual.latitude,
            train.ubicacionActual.longitude,
            station.ubicacion.latitude,
            station.ubicacion.longitude,
          );
          
          // Asumir velocidad promedio de 30 km/h y calcular tiempo
          // 1 grado ≈ 111 km, entonces distance en grados * 111 = km
          final distanceKm = distance * 111;
          final timeMinutes = (distanceKm / 30 * 60).round();
          
          if (minTime == null || timeMinutes < minTime) {
            minTime = timeMinutes;
          }
        }
        
        if (minTime != null && minTime < 30) { // Solo mostrar si es menos de 30 minutos
          estimatedTimes[station.id] = minTime;
        }
      }
    }
    
    return estimatedTimes;
  }

  double _distanceBetweenPoints(double lat1, double lon1, double lat2, double lon2) {
    final dLat = (lat1 - lat2).abs();
    final dLon = (lon1 - lon2).abs();
    return dLat + dLon; // Aproximación simple
  }

  /// Compara dos listas de estaciones para ver si son iguales (por ID)
  bool _listsEqualStations(List<StationModel> list1, List<StationModel> list2) {
    if (list1.length != list2.length) return false;
    final ids1 = list1.map((s) => s.id).toSet();
    final ids2 = list2.map((s) => s.id).toSet();
    return ids1.length == ids2.length && ids1.every((id) => ids2.contains(id));
  }

  /// Compara dos listas de trenes para ver si son iguales (por ID)
  bool _listsEqualTrains(List<TrainModel> list1, List<TrainModel> list2) {
    if (list1.length != list2.length) return false;
    final ids1 = list1.map((t) => t.id).toSet();
    final ids2 = list2.map((t) => t.id).toSet();
    return ids1.length == ids2.length && ids1.every((id) => ids2.contains(id));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MetroDataProvider, LocationProvider>(
      builder: (context, metroProvider, locationProvider, child) {
        final stations = metroProvider.stations;
        final trains = metroProvider.trains;
        final selectedLinea = metroProvider.selectedLinea;
        final currentPosition = locationProvider.currentPosition;
        if (currentPosition != null) {
          _lastKnownPosition = currentPosition;
        }

        // Detectar cambios en el filtro de línea (más confiable que comparar listas)
        final filterChanged = _previousSelectedLinea != selectedLinea;
        
        // Debug
        if (filterChanged) {
          print('🔍 MapWidget: Filtro cambió de $_previousSelectedLinea a $selectedLinea');
          print('🔍 MapWidget: Estaciones: ${stations.length}, Trenes: ${trains.length}');
          print('🔍 MapWidget: Estaciones Línea 1: ${stations.where((s) => s.linea == 'linea1').length}');
          print('🔍 MapWidget: Estaciones Línea 2: ${stations.where((s) => s.linea == 'linea2').length}');
        }
        
        // Si el filtro cambió, forzar actualización de marcadores
        // También detectar cambios en las listas filtradas (por si cambian los datos)
        final stationsChanged = filterChanged || _previousStations == null || 
            _previousStations!.length != stations.length ||
            !_listsEqualStations(_previousStations!, stations);
        final trainsChanged = filterChanged || _previousTrains == null || 
            _previousTrains!.length != trains.length ||
            !_listsEqualTrains(_previousTrains!, trains);

        // Animación de trenes deshabilitada - los trenes no se moverán
        if (stations.isNotEmpty) {
          if (_simulatedTrains.isEmpty || stationsChanged) {
            // Usar addPostFrameCallback para evitar setState durante build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                // _trainSimulation.initialize(stations);
                // _trainSimulation.start();
                // _startTrainUpdates(trains);
                
                // Usar los trenes originales sin simulación
                setState(() {
                  _simulatedTrains = trains;
                });
                _updateTrainMarkers(trains);
              }
            });
          }
        }

        // Usar trenes simulados si están disponibles, sino usar los originales
        final trainsToDisplay = _simulatedTrains.isNotEmpty ? _simulatedTrains : trains;

        // Actualizar marcadores cuando cambian las listas filtradas
        if (stationsChanged || trainsChanged || filterChanged) {
          print('🔍 MapWidget: Actualizando marcadores - stationsChanged=$stationsChanged, trainsChanged=$trainsChanged, filterChanged=$filterChanged');
          print('🔍 MapWidget: selectedLinea=$selectedLinea, estaciones totales=${stations.length}');
          
          // Si el filtro cambió a "Todas las líneas" ('all'), reinicializar todo
          if (filterChanged && selectedLinea == 'all') {
            print('🔍 MapWidget: Cambio a "Todas las líneas" - reinicializando todo');
            print('🔍 MapWidget: Debe mostrar ${stations.length} estaciones (L1 + L2)');
            // Limpiar todo
            _stationMarkers.clear();
            _trainMarkers.clear();
            _simulatedTrains.clear();
            _previousStations = null;
            _previousTrains = null;
            
            // Animación de trenes deshabilitada - usar trenes originales sin simulación
            if (stations.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  print('🔍 MapWidget: Usando trenes originales sin simulación');
                  // _trainSimulation.initialize(stations);
                  // _trainSimulation.start();
                  // _startTrainUpdates(trains);
                  
                  // Usar los trenes originales sin simulación
                  setState(() {
                    _simulatedTrains = trains;
                  });
                  _updateTrainMarkers(trains);
                }
              });
            }
          }
          
          // Limpiar marcadores antiguos inmediatamente
          _stationMarkers.clear();
          _trainMarkers.clear();
          
          // Actualizar marcadores con las nuevas listas
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              print('🔍 MapWidget: Actualizando marcadores - ${stations.length} estaciones y ${trainsToDisplay.length} trenes');
              print('🔍 MapWidget: Estaciones L1=${stations.where((s) => s.linea == 'linea1').length}, L2=${stations.where((s) => s.linea == 'linea2').length}');
              
              if (stations.isNotEmpty) {
                _updateStationMarkers(stations).then((_) {
                  print('🔍 MapWidget: Marcadores de estaciones actualizados: ${_stationMarkers.length}');
                });
              }
              if (trainsToDisplay.isNotEmpty) {
                _updateTrainMarkers(trainsToDisplay).then((_) {
                  print('🔍 MapWidget: Marcadores de trenes actualizados: ${_trainMarkers.length}');
                });
              }
              
              // Guardar estado actual para la próxima comparación (siempre crear nuevas listas)
              _previousStations = List.from(stations);
              _previousTrains = List.from(trainsToDisplay);
              _previousSelectedLinea = selectedLinea;
              
              print('🔍 MapWidget: Estado guardado - selectedLinea=$selectedLinea, estaciones=${_previousStations?.length ?? 0}');
            }
          });
        } else {
          // Solo actualizar si están vacíos (primera carga)
          if (_trainMarkers.isEmpty && trainsToDisplay.isNotEmpty) {
            _updateTrainMarkers(trainsToDisplay);
            _previousTrains = trainsToDisplay.map((t) => t).toList();
            if (_previousSelectedLinea == null) {
              _previousSelectedLinea = selectedLinea;
            }
          }
          if (_stationMarkers.isEmpty && stations.isNotEmpty) {
            _updateStationMarkers(stations);
            _previousStations = stations.map((s) => s).toList();
            if (_previousSelectedLinea == null) {
              _previousSelectedLinea = selectedLinea;
            }
          }
        }

        // Crear marcadores y capas
        final markers = <Marker>{};
        markers.addAll(_trainMarkers);
        markers.addAll(_stationMarkers);
        // Ya no se agrega marcador azul; el propio map muestra el icono de persona

        final stationCircles = _createStationCircles(stations);
        final polylines = _createLinePolylines(stations);
        final highlightedPolylines = widget.highlightedRoute != null
            ? _createHighlightedRoutePolylines(widget.highlightedRoute!)
            : <Polyline>{};

        _maybeAnimateInitialCamera(stations, _lastKnownPosition);

        // Calcular posición inicial de la cámara
        CameraPosition initialPosition = MapService.initialCameraPosition;
        LatLng? userLocation;
        bool isUserInPanamaCity = false;

        if (currentPosition != null) {
          userLocation = LatLng(
            currentPosition.latitude,
            currentPosition.longitude,
          );
          isUserInPanamaCity = MapService.isWithinPanamaCityBounds(userLocation);
          
          if (isUserInPanamaCity) {
            // Usuario está en la ciudad, centrar en su ubicación
            initialPosition = CameraPosition(
              target: userLocation,
              zoom: 14.0,
            );
          } else {
            // Usuario fuera de la ciudad, centrar en el sistema de metro
            final metroCenter = stations.isNotEmpty
                ? MapService.calculateCenterFromStations(stations)
                : MapService.metroSystemCenter;
            initialPosition = CameraPosition(
              target: metroCenter,
              zoom: 12.0,
            );
          }
        } else if (stations.isNotEmpty) {
          // Sin ubicación, centrar en el sistema de metro
          final metroCenter = MapService.calculateCenterFromStations(stations);
          initialPosition = CameraPosition(
            target: metroCenter,
            zoom: 12.0,
          );
        }

        // Combinar polylines normales con la ruta resaltada
        final allPolylines = <Polyline>{
          ...polylines,
          ...highlightedPolylines,
        };

        // Ajustar cámara para mostrar la ruta resaltada si existe
        if (widget.highlightedRoute != null && widget.highlightedRoute!.isNotEmpty) {
          _maybeAnimateToRoute(widget.highlightedRoute!);
        }

        return GoogleMap(
          initialCameraPosition: initialPosition,
          markers: markers,
          circles: stationCircles,
          polylines: allPolylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          mapType: MapType.normal,
          style: MapService.metroMapStyle,
          // Limitar el mapa a la Ciudad de Panamá
          cameraTargetBounds: CameraTargetBounds(MapService.panamaCityBounds),
          minMaxZoomPreference: const MinMaxZoomPreference(10.0, 18.0),
          onMapCreated: (GoogleMapController controller) async {
            _mapController = controller;
            
            // Si el usuario no está en la ciudad, forzar centrado en el metro
            if (currentPosition != null && !isUserInPanamaCity) {
              final metroCenter = stations.isNotEmpty
                  ? MapService.calculateCenterFromStations(stations)
                  : MapService.metroSystemCenter;
              await controller.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: metroCenter,
                    zoom: 12.0,
                  ),
                ),
              );
            }
            
            // Animar a la ruta después de que el mapa se cree
            if (widget.highlightedRoute != null && widget.highlightedRoute!.isNotEmpty) {
              _animateToRoute(widget.highlightedRoute!);
            }
          },
          // Removido onTap para evitar que al tocar fuera cierre la app
          // Si hay algún modal abierto, el usuario puede cerrarlo tocando fuera del modal
        );
      },
    );
  }

  Set<Circle> _createStationCircles(List<StationModel> stations) {
    final circles = <Circle>{};

    for (final station in stations) {
      // Usar coordenada editada si existe
      final editedPosition = _positionEditor.getPosition(station.id);
      final location = editedPosition != null
          ? LatLng(editedPosition.latitude, editedPosition.longitude)
          : LatLng(station.ubicacion.latitude, station.ubicacion.longitude);
      
      final color = _mapService.getStationStateColor(station.estadoActual);

      // Círculo principal que indica el estado
      circles.add(
        Circle(
          circleId: CircleId('station_${station.id}'),
          center: location,
          radius: _mapService.getStationRadius(station.estadoActual),
          strokeColor: color,
          strokeWidth: 3,
          fillColor: color.withValues(alpha: 0.25),
          consumeTapEvents: true,
          onTap: () => _showStationBottomSheet(station),
        ),
      );

      // Ya no se dibuja el círculo pequeño, se usa el icono de estación en su lugar
    }

    return circles;
  }

  Set<Polyline> _createLinePolylines(List<StationModel> stations) {
    final connections = <Polyline>{};

    // Obtener estaciones ordenadas según el orden estático
    final linea1StaticStations = MetroData.getLinea1Stations();
    final linea2StaticStations = MetroData.getLinea2Stations();

    // Crear mapas de orden para cada línea
    final linea1OrderMap = <String, int>{};
    for (int i = 0; i < linea1StaticStations.length; i++) {
      linea1OrderMap[linea1StaticStations[i].id] = i;
    }

    final linea2OrderMap = <String, int>{};
    for (int i = 0; i < linea2StaticStations.length; i++) {
      linea2OrderMap[linea2StaticStations[i].id] = i;
    }

    // Separar estaciones por línea y ordenarlas
    final linea1Stations = stations.where((s) => s.linea == 'linea1').toList();
    linea1Stations.sort((a, b) {
      final orderA = linea1OrderMap[a.id] ?? 999;
      final orderB = linea1OrderMap[b.id] ?? 999;
      return orderA.compareTo(orderB);
    });

    final linea2MainStations = stations.where((s) => 
      s.linea == 'linea2' && s.id != 'l2_aeropuerto' && s.id != 'l2_itse'
    ).toList();
    linea2MainStations.sort((a, b) {
      final orderA = linea2OrderMap[a.id] ?? 999;
      final orderB = linea2OrderMap[b.id] ?? 999;
      return orderA.compareTo(orderB);
    });

    // Rama del aeropuerto: ITSE y Aeropuerto (Corredor Sur está en la línea principal)
    // Orden: ITSE → Aeropuerto
    final linea2AirportStations = [
      ...stations.where((s) => s.id == 'l2_itse'),
      ...stations.where((s) => s.id == 'l2_aeropuerto'),
    ];

    // Dibujar Línea 1 en ROJO
    if (linea1Stations.length >= 2) {
      for (int i = 0; i < linea1Stations.length - 1; i++) {
        final start = linea1Stations[i];
        final end = linea1Stations[i + 1];
        
        final startEdited = _positionEditor.getPosition(start.id);
        final endEdited = _positionEditor.getPosition(end.id);
        
        final startPoint = startEdited != null
            ? LatLng(startEdited.latitude, startEdited.longitude)
            : LatLng(start.ubicacion.latitude, start.ubicacion.longitude);
        final endPoint = endEdited != null
            ? LatLng(endEdited.latitude, endEdited.longitude)
            : LatLng(end.ubicacion.latitude, end.ubicacion.longitude);

        connections.add(
          Polyline(
            polylineId: PolylineId('l1_segment_${start.id}_${end.id}'),
            color: Colors.red,
            width: 5,
            points: [startPoint, endPoint],
          ),
        );
      }
    }

    // Dibujar Línea 2 principal en VERDE
    if (linea2MainStations.length >= 2) {
      for (int i = 0; i < linea2MainStations.length - 1; i++) {
        final start = linea2MainStations[i];
        final end = linea2MainStations[i + 1];
        
        final startEdited = _positionEditor.getPosition(start.id);
        final endEdited = _positionEditor.getPosition(end.id);
        
        final startPoint = startEdited != null
            ? LatLng(startEdited.latitude, startEdited.longitude)
            : LatLng(start.ubicacion.latitude, start.ubicacion.longitude);
        final endPoint = endEdited != null
            ? LatLng(endEdited.latitude, endEdited.longitude)
            : LatLng(end.ubicacion.latitude, end.ubicacion.longitude);

        connections.add(
          Polyline(
            polylineId: PolylineId('l2_segment_${start.id}_${end.id}'),
            color: Colors.green,
            width: 5,
            points: [startPoint, endPoint],
          ),
        );
      }
    }

    // Dibujar rama del aeropuerto: ITSE → Aeropuerto
    if (linea2AirportStations.length >= 2) {
      for (int i = 0; i < linea2AirportStations.length - 1; i++) {
        final start = linea2AirportStations[i];
        final end = linea2AirportStations[i + 1];
        
        final startEdited = _positionEditor.getPosition(start.id);
        final endEdited = _positionEditor.getPosition(end.id);
        
        final startPoint = startEdited != null
            ? LatLng(startEdited.latitude, startEdited.longitude)
            : LatLng(start.ubicacion.latitude, start.ubicacion.longitude);
        final endPoint = endEdited != null
            ? LatLng(endEdited.latitude, endEdited.longitude)
            : LatLng(end.ubicacion.latitude, end.ubicacion.longitude);

        connections.add(
          Polyline(
            polylineId: PolylineId('l2_airport_segment_${start.id}_${end.id}'),
            color: Colors.green,
            width: 5,
            points: [startPoint, endPoint],
          ),
        );
      }
    }
    
    // Dibujar conexión desde Corredor Sur a ITSE
    StationModel? corredorSur;
    StationModel? itse;
    
    try {
      corredorSur = linea2MainStations.firstWhere((s) => s.id == 'l2_corredor_sur');
    } catch (e) {
      // No encontrado
    }
    
    try {
      itse = linea2AirportStations.firstWhere((s) => s.id == 'l2_itse');
    } catch (e) {
      // No encontrado
    }
    
    if (corredorSur != null && itse != null) {
      final corredorSurEdited = _positionEditor.getPosition(corredorSur.id);
      final itseEdited = _positionEditor.getPosition(itse.id);
      
      final corredorSurPoint = corredorSurEdited != null
          ? LatLng(corredorSurEdited.latitude, corredorSurEdited.longitude)
          : LatLng(corredorSur.ubicacion.latitude, corredorSur.ubicacion.longitude);
      final itsePoint = itseEdited != null
          ? LatLng(itseEdited.latitude, itseEdited.longitude)
          : LatLng(itse.ubicacion.latitude, itse.ubicacion.longitude);

      connections.add(
        Polyline(
          polylineId: const PolylineId('l2_corredor_sur_itse'),
          color: Colors.green,
          width: 5,
          points: [corredorSurPoint, itsePoint],
        ),
      );
    }

    // Dibujar interconexión entre L1 y L2 en San Miguelito
    StationModel? l1SanMiguelito;
    StationModel? l2SanMiguelito;
    
    try {
      l1SanMiguelito = linea1Stations.firstWhere((s) => s.id == 'l1_san_miguelito');
    } catch (e) {
      // Estación no encontrada
    }
    
    // l2_san_miguelito fue eliminado - no hay interconexión en San Miguelito
    l2SanMiguelito = null;

    // No dibujar interconexión ya que l2_san_miguelito fue eliminado
    if (false && l1SanMiguelito != null && l2SanMiguelito != null) {
      final l1Edited = _positionEditor.getPosition(l1SanMiguelito.id);
      final l2Edited = _positionEditor.getPosition(l2SanMiguelito.id);
      
      final l1Point = l1Edited != null
          ? LatLng(l1Edited.latitude, l1Edited.longitude)
          : LatLng(l1SanMiguelito.ubicacion.latitude, l1SanMiguelito.ubicacion.longitude);
      final l2Point = l2Edited != null
          ? LatLng(l2Edited.latitude, l2Edited.longitude)
          : LatLng(l2SanMiguelito.ubicacion.latitude, l2SanMiguelito.ubicacion.longitude);

      connections.add(
        Polyline(
          polylineId: const PolylineId('interconnection_l1_l2'),
          color: Colors.orange,
          width: 4,
          points: [l1Point, l2Point],
        ),
      );
    }

    return connections;
  }

  double _distanceBetween(StationModel a, StationModel b) {
    final dLat = (a.ubicacion.latitude - b.ubicacion.latitude).abs();
    final dLng = (a.ubicacion.longitude - b.ubicacion.longitude).abs();
    return dLat + dLng;
  }

  void _showCoordinatesDialog(StationModel station) {
    final editedPosition = _positionEditor.getPosition(station.id);
    final position = editedPosition ?? station.ubicacion;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(station.nombre),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Coordenadas:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Latitud: ${position.latitude}'),
            Text('Longitud: ${position.longitude}'),
            const SizedBox(height: 8),
            SelectableText(
              '[${position.latitude}, ${position.longitude}]',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            if (editedPosition != null) ...[
              const SizedBox(height: 8),
              const Text(
                '(Coordenada editada)',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.blue),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text: '[${position.latitude}, ${position.longitude}]',
              ));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coordenadas copiadas al portapapeles')),
                );
              }
              Navigator.of(context).pop();
            },
            child: const Text('Copiar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showStationBottomSheet(StationModel station) async {
    if (!mounted) return;
    final navigatorContext = context;
    
    // Verificar si estamos en modo test
    bool isTestMode = false;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user != null) {
      try {
        final appModeService = AppModeService();
        isTestMode = await appModeService.isTestMode(user.uid);
        
        if (mounted) {
          setState(() {
            _isTestMode = isTestMode;
          });
        }
      } catch (e) {
        print('Error verificando modo test: $e');
      }
    }
    
    // En modo test, mostrar modal de edición de coordenadas
    if (isTestMode) {
      await showModalBottomSheet<void>(
        context: navigatorContext,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: true, // Permitir cerrar tocando fuera
        enableDrag: true, // Permitir arrastrar para cerrar
        builder: (sheetContext) => StationPositionEditorModal(station: station),
      );
    } else {
      // Modo normal: mostrar bottom sheet de reporte
      final metroProvider = Provider.of<MetroDataProvider>(context, listen: false);
      final trains = metroProvider.trains.where((t) => t.linea == station.linea).toList();
      
      await showModalBottomSheet<void>(
        context: navigatorContext,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => StationReportSheet(
          station: station,
          trains: trains.isNotEmpty ? trains : null,
        ),
      );
    }
  }

  void _maybeAnimateInitialCamera(
    List<StationModel> stations,
    Position? userPosition,
  ) {
    if (_hasAnimatedInitialCamera) return;
    if (_mapController == null) return;
    if (userPosition == null) return;
    if (stations.length < 2) return;

    _hasAnimatedInitialCamera = true;
    _animateInitialSequence(stations, userPosition);
  }

  Future<void> _animateInitialSequence(
    List<StationModel> stations,
    Position userPosition,
  ) async {
    final nearestStations = _getNearestStations(stations, userPosition);
    if (nearestStations.length < 2) return;

    final closest = nearestStations.first;
    final second = nearestStations.last;
    if (!mounted || _mapController == null) return;

    Future<void> flyToStation(StationModel station, double zoom) async {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              station.ubicacion.latitude,
              station.ubicacion.longitude,
            ),
            zoom: zoom,
          ),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 600));
    }

    try {
      await flyToStation(closest, 16);
      await flyToStation(second, 16);
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              userPosition.latitude,
              userPosition.longitude,
            ),
            zoom: 15,
          ),
        ),
      );
    } catch (_) {
      // Ignorar errores de animación
    }
  }

  List<StationModel> _getNearestStations(
    List<StationModel> stations,
    Position userPosition,
  ) {
    final sorted = [...stations]
      ..sort(
        (a, b) => _distanceToUser(a, userPosition)
            .compareTo(_distanceToUser(b, userPosition)),
      );
    return sorted.take(2).toList();
  }

  double _distanceToUser(StationModel station, Position position) {
    return Geolocator.distanceBetween(
      station.ubicacion.latitude,
      station.ubicacion.longitude,
      position.latitude,
      position.longitude,
    );
  }

  Set<Polyline> _createHighlightedRoutePolylines(List<StationModel> route) {
    final polylines = <Polyline>{};
    
    if (route.length < 2) return polylines;

    // Crear polylines para cada segmento de la ruta
    for (int i = 0; i < route.length - 1; i++) {
      final start = route[i];
      final end = route[i + 1];
      
      polylines.add(
        Polyline(
          polylineId: PolylineId('highlighted_${start.id}_${end.id}'),
          color: Colors.blue,
          width: 6,
          points: [
            LatLng(
              start.ubicacion.latitude,
              start.ubicacion.longitude,
            ),
            LatLng(
              end.ubicacion.latitude,
              end.ubicacion.longitude,
            ),
          ],
        ),
      );
    }

    return polylines;
  }

  void _maybeAnimateToRoute(List<StationModel> route) {
    if (_mapController == null || route.isEmpty) return;
    _animateToRoute(route);
  }

  Future<void> _animateToRoute(List<StationModel> route) async {
    if (_mapController == null || route.isEmpty) return;

    // Calcular bounds para incluir todas las estaciones de la ruta
    double minLat = route.first.ubicacion.latitude;
    double maxLat = route.first.ubicacion.latitude;
    double minLng = route.first.ubicacion.longitude;
    double maxLng = route.first.ubicacion.longitude;

    for (final station in route) {
      minLat = minLat < station.ubicacion.latitude ? minLat : station.ubicacion.latitude;
      maxLat = maxLat > station.ubicacion.latitude ? maxLat : station.ubicacion.latitude;
      minLng = minLng < station.ubicacion.longitude ? minLng : station.ubicacion.longitude;
      maxLng = maxLng > station.ubicacion.longitude ? maxLng : station.ubicacion.longitude;
    }

    // Agregar padding
    final latPadding = (maxLat - minLat) * 0.2;
    final lngPadding = (maxLng - minLng) * 0.2;

    final bounds = LatLngBounds(
      southwest: LatLng(minLat - latPadding, minLng - lngPadding),
      northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
    );

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  @override
  void dispose() {
    // Remover listener del modo de edición
    final editModeService = StationEditModeService();
    editModeService.removeListener(_onEditModeChanged);
    _updateTimer?.cancel();
    _trainSimulation.stop();
    _trainSimulation.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}

