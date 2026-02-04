import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:ui' as ui show lerpDouble;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/station_model.dart';
import '../models/train_model.dart';
import '../services/train_simulation_service.dart';
import '../services/app_mode_service.dart';
import '../services/station_position_editor_service.dart';
import '../services/station_edit_mode_service.dart';
import '../providers/auth_provider.dart';
import '../providers/metro_data_provider.dart';
import '../widgets/station_position_editor_modal.dart';
import '../widgets/train_arrival_animation.dart';
import '../widgets/pulsing_button.dart';
import '../services/eta_arrival_service.dart';
import '../services/location_service.dart';
import '../providers/location_provider.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/metro_data.dart';
import '../services/eta_group_service.dart';
import '../models/eta_group_model.dart';

enum StationStatus {
  normal, // 🟢 Verde
  moderado, // 🟡 Amarillo
  lleno, // 🔴 Rojo
  cerrado, // ⚫ Gris
}

enum TrainStatus {
  normal, // 🚇 →
  lento, // 🚇 ···>
  detenido, // 🚇 ■
  express, // 💨
}

class CustomMetroMap extends StatefulWidget {
  final List<StationModel> stations;
  final List<TrainModel> trains;
  final Function(StationModel)? onStationTap;
  final Function(TrainModel)? onTrainTap;
  final List<StationModel>? highlightedRoute;

  const CustomMetroMap({
    super.key,
    required this.stations,
    required this.trains,
    this.onStationTap,
    this.onTrainTap,
    this.highlightedRoute,
  });

  @override
  State<CustomMetroMap> createState() => _CustomMetroMapState();
}

class _CustomMetroMapState extends State<CustomMetroMap>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final Map<String, StationStatus> _stationStatus = {};
  final Map<String, int?> _nextTrainMinutes = {}; // Minutos reales de ETA groups
  final TrainSimulationService _trainSimulation = TrainSimulationService();
  final EtaGroupService _etaGroupService = EtaGroupService();
  final Map<String, StreamSubscription> _etaSubscriptions = {};
  // Mapa trainId → (stationId donde fue último avistamiento, timestamp)
  final Map<String, _TrainSighting> _lastTrainSightings = {};
  StreamSubscription? _trainSightingsSub;
  final StationPositionEditorService _positionEditor =
      StationPositionEditorService();
  List<TrainModel> _simulatedTrains = [];
  Timer? _updateTimer;
  bool _isTestMode = false;
  String? _draggingStationId;
  Offset? _dragOffset;
  _GeoBounds? _currentBounds;
  bool _hasDragged =
      false; // Para detectar si hubo movimiento durante el arrastre
  Timer?
      _tapTimer; // Timer para retrasar el tap y permitir que el pan se active primero
  DateTime? _lastTrainButtonTap;
  Timer? _trainButtonTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      })
      ..repeat();

    _initializeStatuses();
    _initializeTrainSimulation();
    _subscribeToTrainSightings();
  }

  void _initializeTrainSimulation() async {
    if (widget.stations.isNotEmpty) {
      _trainSimulation.initialize(widget.stations);

      // Verificar si estamos en modo test
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      bool isTestMode = false;

      if (user != null) {
        try {
          final appModeService = AppModeService();
          isTestMode = await appModeService.isTestMode(user.uid);
          _trainSimulation.setTestMode(isTestMode);

          if (mounted) {
            setState(() {
              _isTestMode = isTestMode;
            });
          }

          // El editor de posiciones ahora se controla mediante el botón EDIT
          print('🧪 Modo Test activado: Los trenes no se moverán.');
          print('🧪 Activa el modo EDIT para mover estaciones.');
        } catch (e) {
          print('Error verificando modo test: $e');
        }
      }

      // Animación de trenes deshabilitada - los trenes no se moverán
      // _trainSimulation.start();
      // if (isTestMode) {
      //   // En modo test, actualizar cada 3 segundos reales (equivalente a 1 minuto simulado)
      //   _startTrainUpdates(widget.trains, isTestMode: true);
      // } else {
      //   _startTrainUpdates(widget.trains, isTestMode: false);
      // }

      // Usar los trenes originales sin simulación
      if (mounted) {
        setState(() {
          _simulatedTrains = widget.trains;
        });
      }
    }
  }

  @override
  void didUpdateWidget(CustomMetroMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Detectar cambios en estaciones o trenes
    final stationsChanged =
        oldWidget.stations.length != widget.stations.length ||
            !_listsEqualStations(oldWidget.stations, widget.stations);
    final trainsChanged = oldWidget.trains.length != widget.trains.length ||
        !_listsEqualTrains(oldWidget.trains, widget.trains);

    if (stationsChanged || trainsChanged) {
      _initializeStatuses();
      _initializeTrainSimulation();
    } else {
      _initializeStatuses();
      // Re-verificar modo test en caso de que haya cambiado
      _checkTestMode();
    }
  }

  Future<void> _checkTestMode() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      try {
        final appModeService = AppModeService();
        final isTestMode = await appModeService.isTestMode(user.uid);

        if (mounted && _isTestMode != isTestMode) {
          setState(() {
            _isTestMode = isTestMode;
          });

          // El editor de posiciones ahora se controla mediante el botón EDIT
          if (isTestMode) {
            print(
                '🧪 Modo Test detectado. Activa el modo EDIT para mover estaciones.');
          }
        }
      } catch (e) {
        print('Error verificando modo test: $e');
      }
    }
  }

  /// Compara dos listas de estaciones para ver si son iguales (por ID y estado)
  bool _listsEqualStations(List<StationModel> list1, List<StationModel> list2) {
    if (list1.length != list2.length) return false;

    // Crear mapas por ID para comparación rápida
    final map1 = {for (var s in list1) s.id: s};
    final map2 = {for (var s in list2) s.id: s};

    // Verificar que todos los IDs coincidan y que los estados sean iguales
    for (var id in map1.keys) {
      if (!map2.containsKey(id)) return false;

      final s1 = map1[id]!;
      final s2 = map2[id]!;

      // Comparar estado y aglomeración (campos que afectan la visualización)
      if (s1.estadoActual != s2.estadoActual ||
          s1.aglomeracion != s2.aglomeracion ||
          s1.confidence != s2.confidence) {
        return false; // Hay cambios en el estado
      }
    }

    return true;
  }

  /// Compara dos listas de trenes para ver si son iguales (por ID)
  bool _listsEqualTrains(List<TrainModel> list1, List<TrainModel> list2) {
    if (list1.length != list2.length) return false;
    final ids1 = list1.map((t) => t.id).toSet();
    final ids2 = list2.map((t) => t.id).toSet();
    return ids1.length == ids2.length && ids1.every((id) => ids2.contains(id));
  }

  List<StationModel> _getOrderedStations(String linea) {
    // Obtener el orden correcto desde los datos estáticos
    final staticStations = linea == 'linea1'
        ? MetroData.getLinea1Stations()
        : MetroData.getLinea2Stations();

    // Crear un mapa de ID a índice para ordenar
    final orderMap = <String, int>{};
    for (int i = 0; i < staticStations.length; i++) {
      orderMap[staticStations[i].id] = i;
    }

    // Obtener estaciones de la línea y ordenarlas según el orden estático
    final stations = widget.stations.where((s) => s.linea == linea).toList();
    stations.sort((a, b) {
      final orderA = orderMap[a.id] ?? 999;
      final orderB = orderMap[b.id] ?? 999;
      return orderA.compareTo(orderB);
    });

    return stations;
  }

  void _initializeStatuses() {
    _stationStatus.clear();

    // Inicializar estados basados en estadoActual y aglomeración
    for (var station in widget.stations) {
      // Priorizar estadoActual si está disponible
      if (station.estadoActual == EstadoEstacion.cerrado) {
        _stationStatus[station.id] = StationStatus.cerrado;
      } else if (station.estadoActual == EstadoEstacion.lleno) {
        _stationStatus[station.id] = StationStatus.lleno;
      } else if (station.estadoActual == EstadoEstacion.moderado) {
        _stationStatus[station.id] = StationStatus.moderado;
      } else {
        // Si no hay estado específico, usar aglomeración
        if (station.aglomeracion <= 2) {
          _stationStatus[station.id] = StationStatus.normal;
        } else if (station.aglomeracion == 3) {
          _stationStatus[station.id] = StationStatus.moderado;
        } else {
          _stationStatus[station.id] = StationStatus.lleno;
        }
      }

      // Inicializar sin datos de ETA (null = sin datos)
      _nextTrainMinutes[station.id] = null;
    }

    // Suscribirse a ETA groups reales para cada estación
    _subscribeToEtaGroups();
  }

  void _subscribeToEtaGroups() {
    // Cancelar suscripciones previas de estaciones que ya no existen
    final currentIds = widget.stations.map((s) => s.id).toSet();
    final toRemove = _etaSubscriptions.keys
        .where((id) => !currentIds.contains(id))
        .toList();
    for (final id in toRemove) {
      _etaSubscriptions[id]?.cancel();
      _etaSubscriptions.remove(id);
    }

    // Crear suscripciones para nuevas estaciones
    for (final station in widget.stations) {
      if (_etaSubscriptions.containsKey(station.id)) continue;

      _etaSubscriptions[station.id] = _etaGroupService
          .watchBestActiveGroupForStation(station.id)
          .listen((group) {
        if (!mounted) return;

        final minutes = _calculateRemainingMinutes(group);
        if (_nextTrainMinutes[station.id] != minutes) {
          setState(() {
            _nextTrainMinutes[station.id] = minutes;
          });
        }
      });
    }
  }

  /// Calcula los minutos restantes desde un EtaGroup activo.
  /// Retorna null si no hay datos válidos.
  int? _calculateRemainingMinutes(EtaGroupModel? group) {
    if (group == null || !group.isActive) return null;

    // Prioridad 1: calcular desde nextEtaExpectedAt (tiempo absoluto)
    if (group.nextEtaExpectedAt != null) {
      final remaining =
          group.nextEtaExpectedAt!.difference(DateTime.now()).inMinutes;
      // Si ya pasó, no mostrar
      if (remaining < 0) return null;
      return remaining;
    }

    // Prioridad 2: usar nextEtaMinutesP50 (mediana del bucket)
    if (group.nextEtaMinutesP50 != null) {
      return group.nextEtaMinutesP50;
    }

    // Prioridad 3: convertir bucket a minutos aproximados
    return EtaGroupService.etaBucketToMinutes(group.nextEtaBucket);
  }

  /// Escucha eta_groups activos con arrivedCount > 0 para posicionar trenes
  /// en la última estación donde se reportó una llegada.
  void _subscribeToTrainSightings() {
    _trainSightingsSub?.cancel();
    _trainSightingsSub = FirebaseFirestore.instance
        .collection('eta_groups')
        .where('status', isEqualTo: 'active')
        .orderBy('updatedAt', descending: true)
        .limit(20)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      final now = DateTime.now();
      final sightings = <String, _TrainSighting>{};

      for (final doc in snapshot.docs) {
        final group = EtaGroupModel.fromFirestore(doc);
        if (now.isAfter(group.expiresAt)) continue;

        // Crear un trainId sintético basado en línea+dirección
        final trainKey = '${group.line}_${group.directionCode}';

        final existing = sightings[trainKey];
        // Mantener el más reciente
        if (existing == null ||
            group.updatedAt.isAfter(existing.updatedAt)) {
          sightings[trainKey] = _TrainSighting(
            stationId: group.stationId,
            line: group.line,
            directionCode: group.directionCode,
            updatedAt: group.updatedAt,
            hasArrived: group.arrivedCount > 0,
          );
        }
      }

      if (mounted) {
        setState(() {
          _lastTrainSightings
            ..clear()
            ..addAll(sightings);
        });
      }
    });
  }

  /// Calcula el progreso (0.0-1.0) de un tren en su línea según la última estación.
  double _getTrainProgressFromSighting(
      TrainModel train, List<StationModel> lineStations) {
    final dirCode =
        train.direccion == DireccionTren.norte ? 'A' : 'B';
    final key = '${train.linea}_$dirCode';
    final sighting = _lastTrainSightings[key];
    if (sighting == null) {
      return 0.0;
    }

    // Buscar índice de la estación en la línea
    final stationIndex =
        lineStations.indexWhere((s) => s.id == sighting.stationId);
    if (stationIndex < 0 || lineStations.length < 2) {
      return 0.0;
    }

    return stationIndex / (lineStations.length - 1);
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _trainButtonTimer?.cancel();
    _trainSightingsSub?.cancel();
    for (final sub in _etaSubscriptions.values) {
      sub.cancel();
    }
    _etaSubscriptions.clear();
    _trainSimulation.stop();
    _trainSimulation.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Color _getStationColor(StationStatus status) {
    switch (status) {
      case StationStatus.normal:
        return Colors.green;
      case StationStatus.moderado:
        return Colors.orange;
      case StationStatus.lleno:
        return Colors.red;
      case StationStatus.cerrado:
        return Colors.grey;
    }
  }

  String _getStationEmoji(StationStatus status) {
    switch (status) {
      case StationStatus.normal:
        return '🟢';
      case StationStatus.moderado:
        return '🟡';
      case StationStatus.lleno:
        return '🔴';
      case StationStatus.cerrado:
        return '⚫';
    }
  }

  /// Maneja el botón "Ya llegó el metro"
  void _handleTrainArrival() {
    final now = DateTime.now();

    // Si hay un toque previo dentro de 500ms, es doble toque
    if (_lastTrainButtonTap != null &&
        now.difference(_lastTrainButtonTap!) <
            const Duration(milliseconds: 50)) {
      // Cancelar el timer del primer toque
      _trainButtonTimer?.cancel();
      _trainButtonTimer = null;
      _lastTrainButtonTap = null;

      // Doble toque: esperar medio segundo antes de enviar reporte
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          _sendTrainArrivalReport(showAnimationFirst: true);
        }
      });
      return;
    }

    // Registrar este toque
    _lastTrainButtonTap = now;

    // Cancelar timer anterior si existe
    _trainButtonTimer?.cancel();

    // Esperar 500ms para ver si hay un segundo toque
    _trainButtonTimer = Timer(const Duration(milliseconds: 500), () {
      // Si pasó el tiempo sin segundo toque, mostrar diálogo
      _trainButtonTimer = null;
      _lastTrainButtonTap = null;

      if (!mounted) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Debes iniciar sesión para reportar'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      _showTrainArrivalSheet();
    });
  }

  /// Obtiene la estación más cercana al usuario
  StationModel? _getNearestStation() {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    final currentPosition = locationProvider.currentPosition;
    if (currentPosition == null || widget.stations.isEmpty) return null;

    StationModel? nearest;
    double minDistance = double.infinity;
    for (final station in widget.stations) {
      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        station.ubicacion.latitude,
        station.ubicacion.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearest = station;
      }
    }
    return nearest;
  }

  /// Muestra bottom sheet para confirmar llegada con selección de dirección
  void _showTrainArrivalSheet() {
    final nearestStation = _getNearestStation();
    if (nearestStation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo determinar la estación'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _TrainArrivalSheetContent(
          station: nearestStation,
          etaGroupService: _etaGroupService,
          onConfirm: (String? directionCode) {
            Navigator.of(sheetContext).pop();
            _sendTrainArrivalReport(
              showAnimationFirst: true,
              directionCode: directionCode,
            );
          },
        );
      },
    );
  }

  /// Envía el reporte de llegada del tren
  Future<void> _sendTrainArrivalReport({
    bool showAnimationFirst = false,
    String? directionCode,
  }) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      if (user == null) return;

      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);
      final currentPosition = locationProvider.currentPosition;

      // Obtener estación más cercana
      StationModel? nearestStation;
      if (currentPosition != null && widget.stations.isNotEmpty) {
        double minDistance = double.infinity;
        for (final station in widget.stations) {
          final distance = Geolocator.distanceBetween(
            currentPosition.latitude,
            currentPosition.longitude,
            station.ubicacion.latitude,
            station.ubicacion.longitude,
          );
          if (distance < minDistance) {
            minDistance = distance;
            nearestStation = station;
          }
        }
      }

      // Si no hay estación cercana, usar la primera disponible
      if (nearestStation == null && widget.stations.isNotEmpty) {
        nearestStation = widget.stations.first;
      }

      if (nearestStation == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo determinar la estación'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final station = nearestStation;

      // Obtener ubicación (opcional); backend exige GPS confiable para contar/puntos.
      Position? position;
      try {
        final locationService = LocationService();
        final status = await locationService.checkLocationStatus();
        if (status.hasPermission) {
          position = await locationService.getCurrentPosition();
        }
      } catch (e) {
        print('No se pudo obtener ubicación: $e');
      }

      final arrivalService = EtaArrivalService();
      final result = await arrivalService.submitArrivalTap(
        stationId: station.id,
        userPosition: position,
        directionCode: directionCode,
      );

      if (!mounted) return;

      if (!result.success) {
        final msg = switch (result.reason) {
          'no_active_group' =>
            'Primero reporta el tiempo del panel para poder confirmar.',
          'ambiguous_direction' =>
            'Hay varias direcciones activas. Reporta el tiempo del panel para indicar tu dirección.',
          'out_of_geofence' =>
            'Debes estar en la estación (≤150m) para que cuente.',
          'no_gps' =>
            'No pudimos validar tu GPS aquí. No cuenta ni otorga puntos, pero puedes reportar el panel.',
          'cooldown' => 'Espera un poco antes de confirmar otra vez.',
          'already_counted' => 'Ya registramos tu confirmación recientemente.',
          _ => 'No se pudo confirmar. Intenta de nuevo.',
        };

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
        return;
      }

      // Mostrar animación con puntos reales (siempre sin pasos extra).
      TrainArrivalAnimation.show(
        context,
        points: result.pointsAwarded,
        onComplete: () {},
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        // Ordenar estaciones según el orden de los datos estáticos
        final linea1Stations = _getOrderedStations('linea1');
        final linea2Stations = _getOrderedStations('linea2');

        // Aplicar coordenadas editadas a las estaciones antes de proyectarlas
        final stationsWithEditedPositions = widget.stations.map((station) {
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

        final bounds = _GeoBounds.fromStations(stationsWithEditedPositions);
        _currentBounds = bounds;

        // Separar estaciones de la línea principal y la rama del aeropuerto
        // Corredor Sur está en la línea principal y se conecta con Las Mañanitas e ITSE
        // La rama del aeropuerto: ITSE y Aeropuerto (Corredor Sur está en la línea principal)
        final linea2MainStations = linea2Stations
            .where((s) => s.id != 'l2_aeropuerto' && s.id != 'l2_itse')
            .toList();
        // La rama del aeropuerto: ITSE y Aeropuerto (se conectan desde Corredor Sur)
        final linea2AirportBranchStations = [
          ...linea2Stations.where((s) => s.id == 'l2_itse'),
          ...linea2Stations.where((s) => s.id == 'l2_aeropuerto'),
        ];

        // Calcular puntos para las líneas
        var line1Points = _projectStations(linea1Stations, size, bounds);
        var line2Points = _projectStations(linea2MainStations, size, bounds);
        var line2AirportPoints =
            _projectStations(linea2AirportBranchStations, size, bounds);

        // Si hay una estación siendo arrastrada, ajustar su punto en las listas
        if (_draggingStationId != null && _dragOffset != null) {
          // Actualizar punto en línea 1
          for (int i = 0; i < linea1Stations.length; i++) {
            if (linea1Stations[i].id == _draggingStationId &&
                i < line1Points.length) {
              line1Points[i] = line1Points[i] + _dragOffset!;
              break;
            }
          }
          // Actualizar punto en línea 2
          for (int i = 0; i < linea2Stations.length; i++) {
            if (linea2Stations[i].id == _draggingStationId &&
                i < line2Points.length) {
              line2Points[i] = line2Points[i] + _dragOffset!;
              break;
            }
          }
        }

        return SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey[100]),
                child: CustomPaint(
                  size: size,
                  painter: MetroMapPainter(
                    linea1Stations: linea1Stations,
                    linea2Stations: linea2MainStations,
                    linea2AirportStations: linea2AirportBranchStations,
                    line1Points: line1Points,
                    line2Points: line2Points,
                    line2AirportPoints: line2AirportPoints,
                    stationStatus: _stationStatus,
                    nextTrainMinutes: _nextTrainMinutes,
                    getStationColor: _getStationColor,
                    getStationEmoji: _getStationEmoji,
                    highlightedRoute: widget.highlightedRoute,
                    allStations: widget.stations,
                    positionEditor: _positionEditor,
                    bounds: _currentBounds,
                    size: size,
                    draggingStationId: _draggingStationId,
                    dragOffset: _dragOffset,
                  ),
                ),
              ),
              ..._buildTrainWidgets(
                line1Points: line1Points,
                line2Points: line2Points,
                line2AirportPoints: line2AirportPoints,
              ),
              // Overlay invisible para detectar taps en estaciones
              ..._buildStationTapOverlays(
                linea1Stations: linea1Stations,
                linea2Stations: linea2Stations,
                line1Points: line1Points,
                line2Points: line2Points,
                line2AirportPoints: line2AirportPoints,
                size: size,
              ),
              // Botón "Ya llegó el metro" (abajo del medidor de km) con animación de pulso
              Positioned(
                bottom: 80,
                right: 8,
                child: Consumer<LocationProvider>(
                  builder: (context, locationProvider, child) {
                    // Obtener estación más cercana para el pulso
                    StationModel? nearestStation;
                    final currentPosition = locationProvider.currentPosition;
                    if (currentPosition != null && widget.stations.isNotEmpty) {
                      double minDistance = double.infinity;
                      for (final station in widget.stations) {
                        final distance = Geolocator.distanceBetween(
                          currentPosition.latitude,
                          currentPosition.longitude,
                          station.ubicacion.latitude,
                          station.ubicacion.longitude,
                        );
                        if (distance < minDistance) {
                          minDistance = distance;
                          nearestStation = station;
                        }
                      }
                    }

                    return PulsingButton(
                      station: nearestStation,
                      backgroundColor: Colors.green,
                      heroTag: 'train_arrival_fab_custom',
                      onPressed: _handleTrainArrival,
                      child: FloatingActionButton(
                        heroTag: 'train_arrival_fab_custom_inner',
                        onPressed: _handleTrainArrival,
                        backgroundColor: Colors.green,
                        child: Image.asset(
                          'assets/icons/metro-station_2340498.png',
                          width: 24,
                          height: 24,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildTrainWidgets({
    required List<Offset> line1Points,
    required List<Offset> line2Points,
    required List<Offset> line2AirportPoints,
  }) {
    final widgets = <Widget>[];
    final pointsByLine = {
      'linea1': line1Points,
      'linea2': line2Points,
      'linea2_airport': line2AirportPoints,
    };

    // Estaciones ordenadas por línea para calcular progreso
    final linea1Stations = _getOrderedStations('linea1');
    final linea2Stations = _getOrderedStations('linea2');
    final stationsByLine = {
      'linea1': linea1Stations,
      'linea2': linea2Stations,
    };

    // Usar trenes simulados si están disponibles, sino usar los originales
    final trainsToDisplay =
        _simulatedTrains.isNotEmpty ? _simulatedTrains : widget.trains;

    for (final train in trainsToDisplay) {
      final points = pointsByLine[train.linea];
      if (points == null || points.length < 2) continue;

      final lineStations = stationsByLine[train.linea] ?? [];
      final dirCode =
          train.direccion == DireccionTren.norte ? 'A' : 'B';
      final sightingKey = '${train.linea}_$dirCode';
      final hasSighting = _lastTrainSightings.containsKey(sightingKey);

      // Si no hay datos de avistamiento, no mostrar el tren
      if (!hasSighting) continue;

      final progress =
          _getTrainProgressFromSighting(train, lineStations);

      final position = _positionAlongLine(points, progress);
      final color = train.linea == 'linea1' ? Colors.blue : Colors.green;
      final forward = train.direccion == DireccionTren.norte;
      const trainWidth = 36.0;
      const trainHeight = 16.0;

      // Pulso animado para indicar "último avistamiento"
      final pulseValue =
          (math.sin(_animationController.value * 2 * math.pi) + 1) / 2;

      widgets.add(
        AnimatedPositioned(
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
          left: position.dx - trainWidth / 2,
          top: position.dy - trainHeight / 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Halo de pulso
              Container(
                width: trainWidth + 12,
                height: trainHeight + 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: color.withValues(alpha: 0.15 + pulseValue * 0.1),
                ),
                alignment: Alignment.center,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(
                    forward ? 1.0 : -1.0,
                    1.0,
                    1.0,
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/train.svg',
                    width: trainWidth,
                    height: trainHeight,
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  List<Widget> _buildStationTapOverlays({
    required List<StationModel> linea1Stations,
    required List<StationModel> linea2Stations,
    required List<Offset> line1Points,
    required List<Offset> line2Points,
    required List<Offset> line2AirportPoints,
    required Size size,
  }) {
    final widgets = <Widget>[];
    const tapRadius = 30.0;

    // Agregar overlays para estaciones de línea 1
    for (int i = 0; i < linea1Stations.length && i < line1Points.length; i++) {
      final station = linea1Stations[i];
      final basePoint = line1Points[i];
      final editedPosition = _positionEditor.getPosition(station.id);

      // Usar posición editada si existe, sino usar la proyectada
      final point = editedPosition != null && _currentBounds != null
          ? _geoPointToCanvas(editedPosition, size, _currentBounds!)
          : basePoint;

      // Si está siendo arrastrada, usar el offset del drag
      final finalPoint = _draggingStationId == station.id && _dragOffset != null
          ? point + _dragOffset!
          : point;

      widgets.add(
        Positioned(
          left: finalPoint.dx - tapRadius,
          top: finalPoint.dy - tapRadius,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: (_draggingStationId == station.id || _hasDragged)
                ? null
                : () {
                    // Cancelar cualquier timer de tap pendiente
                    _tapTimer?.cancel();
                    // En modo test, mostrar modal de edición de coordenadas
                    if (_isTestMode && !_hasDragged) {
                      _showPositionEditorModal(context, station);
                    } else if (!_isTestMode && !_hasDragged) {
                      widget.onStationTap?.call(station);
                    }
                  },
            onPanStart: _isTestMode
                ? (details) {
                    // Cancelar el timer de tap para que no se abra el modal
                    _tapTimer?.cancel();
                    print('🧪 Drag start: ${station.nombre}');
                    setState(() {
                      _draggingStationId = station.id;
                      _dragOffset = Offset.zero;
                      _hasDragged = false; // Resetear el flag
                    });
                  }
                : null,
            onPanUpdate: _isTestMode
                ? (details) {
                    if (_draggingStationId == station.id) {
                      // Si hay movimiento significativo, marcar como arrastrado
                      if (details.delta.distance > 5.0) {
                        _hasDragged = true;
                      }
                      setState(() {
                        _dragOffset = _dragOffset! + details.delta;
                      });
                    }
                  }
                : null,
            onPanEnd: _isTestMode
                ? (details) {
                    if (_draggingStationId == station.id &&
                        _currentBounds != null &&
                        _dragOffset != null) {
                      // Actualizar posición siempre que haya movimiento (aunque sea mínimo)
                      // Esto permite dejar la estación exactamente donde el usuario quiere
                      final newCanvasPoint = point + _dragOffset!;

                      // Validar que el punto esté dentro de los límites del canvas (con padding)
                      const padding = 48.0;
                      final clampedX = newCanvasPoint.dx
                          .clamp(padding, size.width - padding);
                      final clampedY = newCanvasPoint.dy
                          .clamp(padding, size.height - padding);
                      final clampedPoint = Offset(clampedX, clampedY);

                      final newGeoPoint = _canvasToGeoPoint(
                          clampedPoint, size, _currentBounds!);
                      print(
                          '🧪 Drag end: ${station.nombre} -> [${newGeoPoint.latitude}, ${newGeoPoint.longitude}]');
                      _positionEditor.updatePosition(station.id, newGeoPoint);

                      // Notificar al provider para refrescar
                      Provider.of<MetroDataProvider>(context, listen: false)
                          .notifyListeners();
                    }
                    setState(() {
                      _draggingStationId = null;
                      _dragOffset = null;
                      _hasDragged = false;
                    });
                  }
                : null,
            onPanCancel: () {
              final editModeService =
                  Provider.of<StationEditModeService>(context, listen: false);
              if (!editModeService.isEditModeActive) return null;

              return () {
                print('🧪 Drag cancel: ${station.nombre}');
                setState(() {
                  _draggingStationId = null;
                  _dragOffset = null;
                  _hasDragged = false;
                });
              };
            }(),
            child: Consumer<StationEditModeService>(
              builder: (context, editModeService, child) {
                final isEditModeActive = editModeService.isEditModeActive;
                return Container(
                  width: tapRadius * 2,
                  height: tapRadius * 2,
                  decoration: BoxDecoration(
                    color: isEditModeActive && _draggingStationId == station.id
                        ? Colors.blue.withOpacity(0.3)
                        : (isEditModeActive
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.transparent),
                    shape: BoxShape.circle,
                    border: isEditModeActive
                        ? Border.all(
                            color: Colors.blue.withOpacity(0.5), width: 2)
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    // Agregar overlays para estaciones de línea 2
    for (int i = 0; i < linea2Stations.length && i < line2Points.length; i++) {
      final station = linea2Stations[i];
      final basePoint = line2Points[i];
      final editedPosition = _positionEditor.getPosition(station.id);

      // Usar posición editada si existe, sino usar la proyectada
      final point = editedPosition != null && _currentBounds != null
          ? _geoPointToCanvas(editedPosition, size, _currentBounds!)
          : basePoint;

      // Si está siendo arrastrada, usar el offset del drag
      final finalPoint = _draggingStationId == station.id && _dragOffset != null
          ? point + _dragOffset!
          : point;

      widgets.add(
        Positioned(
          left: finalPoint.dx - tapRadius,
          top: finalPoint.dy - tapRadius,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: (_draggingStationId == station.id || _hasDragged)
                ? null
                : () {
                    // Cancelar cualquier timer de tap pendiente
                    _tapTimer?.cancel();
                    // En modo test, mostrar modal de edición de coordenadas
                    if (_isTestMode && !_hasDragged) {
                      _showPositionEditorModal(context, station);
                    } else if (!_isTestMode && !_hasDragged) {
                      widget.onStationTap?.call(station);
                    }
                  },
            onPanStart: _isTestMode
                ? (details) {
                    // Cancelar el timer de tap para que no se abra el modal
                    _tapTimer?.cancel();
                    print('🧪 Drag start: ${station.nombre}');
                    setState(() {
                      _draggingStationId = station.id;
                      _dragOffset = Offset.zero;
                      _hasDragged = false; // Resetear el flag
                    });
                  }
                : null,
            onPanUpdate: _isTestMode
                ? (details) {
                    if (_draggingStationId == station.id) {
                      // Si hay movimiento significativo, marcar como arrastrado
                      if (details.delta.distance > 5.0) {
                        _hasDragged = true;
                      }
                      setState(() {
                        _dragOffset = _dragOffset! + details.delta;
                      });
                    }
                  }
                : null,
            onPanEnd: _isTestMode
                ? (details) {
                    if (_draggingStationId == station.id &&
                        _currentBounds != null &&
                        _dragOffset != null) {
                      // Actualizar posición siempre que haya movimiento (aunque sea mínimo)
                      // Esto permite dejar la estación exactamente donde el usuario quiere
                      final newCanvasPoint = point + _dragOffset!;

                      // Validar que el punto esté dentro de los límites del canvas (con padding)
                      const padding = 48.0;
                      final clampedX = newCanvasPoint.dx
                          .clamp(padding, size.width - padding);
                      final clampedY = newCanvasPoint.dy
                          .clamp(padding, size.height - padding);
                      final clampedPoint = Offset(clampedX, clampedY);

                      final newGeoPoint = _canvasToGeoPoint(
                          clampedPoint, size, _currentBounds!);
                      print(
                          '🧪 Drag end: ${station.nombre} -> [${newGeoPoint.latitude}, ${newGeoPoint.longitude}]');
                      _positionEditor.updatePosition(station.id, newGeoPoint);

                      // Notificar al provider para refrescar
                      Provider.of<MetroDataProvider>(context, listen: false)
                          .notifyListeners();
                    }
                    setState(() {
                      _draggingStationId = null;
                      _dragOffset = null;
                      _hasDragged = false;
                    });
                  }
                : null,
            onPanCancel: () {
              final editModeService =
                  Provider.of<StationEditModeService>(context, listen: false);
              if (!editModeService.isEditModeActive) return null;

              return () {
                print('🧪 Drag cancel: ${station.nombre}');
                setState(() {
                  _draggingStationId = null;
                  _dragOffset = null;
                  _hasDragged = false;
                });
              };
            }(),
            child: Consumer<StationEditModeService>(
              builder: (context, editModeService, child) {
                final isEditModeActive = editModeService.isEditModeActive;
                return Container(
                  width: tapRadius * 2,
                  height: tapRadius * 2,
                  decoration: BoxDecoration(
                    color: isEditModeActive && _draggingStationId == station.id
                        ? Colors.blue.withOpacity(0.3)
                        : (isEditModeActive
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.transparent),
                    shape: BoxShape.circle,
                    border: isEditModeActive
                        ? Border.all(
                            color: Colors.blue.withOpacity(0.5), width: 2)
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    // Agregar overlays para estaciones de la rama del aeropuerto (ITSE y Aeropuerto)
    final linea2AirportStations = linea2Stations
        .where((s) => s.id == 'l2_aeropuerto' || s.id == 'l2_itse')
        .toList();

    // Ordenar la rama del aeropuerto: ITSE → Aeropuerto
    linea2AirportStations.sort((a, b) {
      final order = {'l2_itse': 0, 'l2_aeropuerto': 1};
      return (order[a.id] ?? 999).compareTo(order[b.id] ?? 999);
    });

    for (int i = 0;
        i < linea2AirportStations.length && i < line2AirportPoints.length;
        i++) {
      final station = linea2AirportStations[i];
      final basePoint = line2AirportPoints[i];
      final editedPosition = _positionEditor.getPosition(station.id);

      final point = editedPosition != null && _currentBounds != null
          ? _geoPointToCanvas(editedPosition, size, _currentBounds!)
          : basePoint;

      final finalPoint = _draggingStationId == station.id && _dragOffset != null
          ? point + _dragOffset!
          : point;

      widgets.add(
        Positioned(
          left: finalPoint.dx - tapRadius,
          top: finalPoint.dy - tapRadius,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: (_draggingStationId == station.id || _hasDragged)
                ? null
                : () {
                    _tapTimer?.cancel();
                    if (_isTestMode && !_hasDragged) {
                      _showPositionEditorModal(context, station);
                    } else if (!_isTestMode && !_hasDragged) {
                      widget.onStationTap?.call(station);
                    }
                  },
            onPanStart: _isTestMode
                ? (details) {
                    _tapTimer?.cancel();
                    setState(() {
                      _draggingStationId = station.id;
                      _dragOffset = Offset.zero;
                      _hasDragged = false;
                    });
                  }
                : null,
            onPanUpdate: _isTestMode
                ? (details) {
                    if (_draggingStationId == station.id) {
                      if (details.delta.distance > 5.0) {
                        _hasDragged = true;
                      }
                      setState(() {
                        _dragOffset = _dragOffset! + details.delta;
                      });
                    }
                  }
                : null,
            onPanEnd: _isTestMode
                ? (details) {
                    if (_draggingStationId == station.id &&
                        _currentBounds != null &&
                        _dragOffset != null) {
                      final newCanvasPoint = point + _dragOffset!;
                      const padding = 48.0;
                      final clampedX = newCanvasPoint.dx
                          .clamp(padding, size.width - padding);
                      final clampedY = newCanvasPoint.dy
                          .clamp(padding, size.height - padding);
                      final clampedPoint = Offset(clampedX, clampedY);
                      final newGeoPoint = _canvasToGeoPoint(
                          clampedPoint, size, _currentBounds!);
                      _positionEditor.updatePosition(station.id, newGeoPoint);
                      Provider.of<MetroDataProvider>(context, listen: false)
                          .notifyListeners();
                    }
                    setState(() {
                      _draggingStationId = null;
                      _dragOffset = null;
                      _hasDragged = false;
                    });
                  }
                : null,
            child: Consumer<StationEditModeService>(
              builder: (context, editModeService, child) {
                final isEditModeActive = editModeService.isEditModeActive;
                return Container(
                  width: tapRadius * 2,
                  height: tapRadius * 2,
                  decoration: BoxDecoration(
                    color: isEditModeActive && _draggingStationId == station.id
                        ? Colors.blue.withOpacity(0.3)
                        : (isEditModeActive
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.transparent),
                    shape: BoxShape.circle,
                    border: isEditModeActive
                        ? Border.all(
                            color: Colors.blue.withOpacity(0.5), width: 2)
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    // Agregar overlays para trenes (solo los que tienen avistamiento)
    final trainPointsByLine = {
      'linea1': line1Points,
      'linea2': line2Points,
      'linea2_airport': line2AirportPoints,
    };
    final trainStationsByLine = {
      'linea1': linea1Stations,
      'linea2': linea2Stations,
    };
    final trainsToDisplay =
        _simulatedTrains.isNotEmpty ? _simulatedTrains : widget.trains;

    for (final train in trainsToDisplay) {
      final points = trainPointsByLine[train.linea];
      if (points == null || points.length < 2) continue;

      final dirCode =
          train.direccion == DireccionTren.norte ? 'A' : 'B';
      final sightingKey = '${train.linea}_$dirCode';
      if (!_lastTrainSightings.containsKey(sightingKey)) continue;

      final lineStations = trainStationsByLine[train.linea] ?? [];
      final progress =
          _getTrainProgressFromSighting(train, lineStations);
      final position = _positionAlongLine(points, progress);

      widgets.add(
        Positioned(
          left: position.dx - tapRadius,
          top: position.dy - tapRadius,
          child: GestureDetector(
            onTap: () => widget.onTrainTap?.call(train),
            child: Container(
              width: tapRadius * 2,
              height: tapRadius * 2,
              color: Colors.transparent,
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Offset _positionAlongLine(List<Offset> points, double progress) {
    if (points.length < 2) {
      return points.isNotEmpty ? points.first : Offset.zero;
    }
    final totalSegments = points.length - 1;
    final scaled = progress * totalSegments;
    final index = scaled.floor().clamp(0, totalSegments - 1);
    final t = scaled - index;
    final start = points[index];
    final end = points[index + 1];
    final dx = ui.lerpDouble(start.dx, end.dx, t)!;
    final dy = ui.lerpDouble(start.dy, end.dy, t)!;
    return Offset(dx, dy);
  }

  /// Muestra el modal para editar la posición de una estación
  void _showPositionEditorModal(BuildContext context, StationModel station) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true, // Permitir cerrar tocando fuera
      enableDrag: true, // Permitir arrastrar para cerrar
      builder: (context) => StationPositionEditorModal(station: station),
    );
  }

  /// Muestra un diálogo con las coordenadas de la estación
  void _showCoordinatesDialog(BuildContext context, StationModel station) {
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
            const Text('Coordenadas:',
                style: TextStyle(fontWeight: FontWeight.bold)),
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
                style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.blue),
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
                  const SnackBar(
                      content: Text('Coordenadas copiadas al portapapeles')),
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

  /// Convierte coordenadas de canvas (píxeles) a GeoPoint
  GeoPoint _canvasToGeoPoint(Offset canvasPoint, Size size, _GeoBounds bounds) {
    const padding = 48.0;
    final width = size.width - padding * 2;
    final height = size.height - padding * 2;

    final normalizedX = ((canvasPoint.dx - padding) / width).clamp(0.0, 1.0);
    final normalizedY =
        1.0 - ((canvasPoint.dy - padding) / height).clamp(0.0, 1.0);

    final lng = bounds.minLng + normalizedX * bounds.lngSpan;
    final lat = bounds.minLat + normalizedY * bounds.latSpan;

    return GeoPoint(lat, lng);
  }

  /// Convierte GeoPoint a coordenadas de canvas (píxeles)
  Offset _geoPointToCanvas(GeoPoint geoPoint, Size size, _GeoBounds bounds) {
    const padding = 48.0;
    final width = size.width - padding * 2;
    final height = size.height - padding * 2;

    final normalizedLng = (geoPoint.longitude - bounds.minLng) / bounds.lngSpan;
    final normalizedLat = (geoPoint.latitude - bounds.minLat) / bounds.latSpan;

    final x = padding + normalizedLng * width;
    final y = padding + (1 - normalizedLat) * height;

    return Offset(x, y);
  }
}

class MetroMapPainter extends CustomPainter {
  final List<StationModel> linea1Stations;
  final List<StationModel> linea2Stations;
  final List<StationModel> linea2AirportStations;
  final List<Offset> line1Points;
  final List<Offset> line2Points;
  final List<Offset> line2AirportPoints;
  final Map<String, StationStatus> stationStatus;
  final Map<String, int?> nextTrainMinutes;
  final Color Function(StationStatus) getStationColor;
  final String Function(StationStatus) getStationEmoji;
  final List<StationModel>? highlightedRoute;
  final List<StationModel> allStations;
  final StationPositionEditorService? positionEditor;
  final _GeoBounds? bounds;
  final Size? size;
  final String? draggingStationId;
  final Offset? dragOffset;

  MetroMapPainter({
    required this.linea1Stations,
    required this.linea2Stations,
    required this.linea2AirportStations,
    required this.line1Points,
    required this.line2Points,
    required this.line2AirportPoints,
    required this.stationStatus,
    required this.nextTrainMinutes,
    required this.getStationColor,
    required this.getStationEmoji,
    this.highlightedRoute,
    required this.allStations,
    this.positionEditor,
    this.bounds,
    this.size,
    this.draggingStationId,
    this.dragOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Determinar si las líneas están en la ruta resaltada
    final line1InRoute = _isLineInRoute('linea1');
    final line2InRoute = _isLineInRoute('linea2');

    // Dibujar Línea 1 - cambiar color si está en la ruta
    if (linea1Stations.isNotEmpty) {
      paint.color = line1InRoute ? Colors.blue : Colors.red;
      paint.strokeWidth = line1InRoute ? 6 : 4;
      _drawLine(canvas, paint, line1Points);
      _drawStations(
        canvas,
        paint,
        linea1Stations,
        line1Points,
        'LÍNEA 1',
      );
    }

    // Dibujar Línea 2 principal - cambiar color si está en la ruta
    if (linea2Stations.isNotEmpty) {
      paint.color = line2InRoute ? Colors.orange : Colors.green;
      paint.strokeWidth = line2InRoute ? 6 : 4;
      _drawLine(canvas, paint, line2Points);
      _drawStations(
        canvas,
        paint,
        linea2Stations,
        line2Points,
        'LÍNEA 2',
      );
    }

    // Dibujar rama del aeropuerto (ITSE → Aeropuerto, desde Corredor Sur)
    if (linea2AirportStations.isNotEmpty && line2AirportPoints.length >= 2) {
      final airportInRoute = _isAirportBranchInRoute();
      paint.color = airportInRoute ? Colors.orange : Colors.green;
      paint.strokeWidth = airportInRoute ? 6 : 4;
      _drawLine(canvas, paint, line2AirportPoints);
      _drawStations(
        canvas,
        paint,
        linea2AirportStations,
        line2AirportPoints,
        '',
      );

      // Dibujar conexión desde Corredor Sur (en línea principal) a ITSE
      Offset? corredorSurPoint;
      Offset? itsePoint;

      // Buscar Corredor Sur en la línea principal (linea2Stations incluye todas las estaciones)
      for (int i = 0; i < linea2Stations.length; i++) {
        if (linea2Stations[i].id == 'l2_corredor_sur') {
          // Buscar el punto correspondiente en line2Points
          for (int j = 0;
              j < linea2Stations.length && j < line2Points.length;
              j++) {
            if (linea2Stations[j].id == 'l2_corredor_sur') {
              corredorSurPoint = line2Points[j];
              break;
            }
          }
          break;
        }
      }

      // Buscar ITSE en la rama del aeropuerto
      if (linea2AirportStations.isNotEmpty && line2AirportPoints.isNotEmpty) {
        for (int i = 0;
            i < linea2AirportStations.length && i < line2AirportPoints.length;
            i++) {
          if (linea2AirportStations[i].id == 'l2_itse') {
            itsePoint = line2AirportPoints[i];
            break;
          }
        }
      }

      // Dibujar conexión Corredor Sur → ITSE
      if (corredorSurPoint != null && itsePoint != null) {
        final airportInRoute = _isAirportBranchInRoute();
        paint.color = airportInRoute ? Colors.orange : Colors.green;
        paint.strokeWidth = airportInRoute ? 6 : 5;
        final path = Path()
          ..moveTo(corredorSurPoint.dx, corredorSurPoint.dy)
          ..lineTo(itsePoint.dx, itsePoint.dy);
        canvas.drawPath(path, paint);
      }
    }

    // Dibujar interconexión entre L1 y L2 en San Miguelito
    _drawInterconnection(canvas, paint);

    // Dibujar ruta resaltada si existe
    if (highlightedRoute != null && highlightedRoute!.isNotEmpty) {
      _drawHighlightedRoute(canvas, paint);
    }
  }

  void _drawInterconnection(Canvas canvas, Paint paint) {
    // Buscar estación San Miguelito en L1
    Offset? l1SanMiguelitoPoint;
    for (int i = 0; i < linea1Stations.length && i < line1Points.length; i++) {
      if (linea1Stations[i].id == 'l1_san_miguelito') {
        l1SanMiguelitoPoint = line1Points[i];
        break;
      }
    }

    // Buscar estación San Miguelito en L2 (ya no existe, se eliminó)
    Offset? l2SanMiguelitoPoint;
    // l2_san_miguelito fue eliminado - no hay interconexión en San Miguelito

    // No dibujar interconexión ya que l2_san_miguelito fue eliminado
    if (false && l1SanMiguelitoPoint != null && l2SanMiguelitoPoint != null) {
      paint
        ..color = Colors.orange
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      final path = Path()
        ..moveTo(l1SanMiguelitoPoint.dx, l1SanMiguelitoPoint.dy)
        ..lineTo(l2SanMiguelitoPoint.dx, l2SanMiguelitoPoint.dy);

      canvas.drawPath(path, paint);

      // Dibujar círculo de interconexión en cada estación
      paint
        ..style = PaintingStyle.fill
        ..color = Colors.orange.withOpacity(0.3);
      canvas.drawCircle(l1SanMiguelitoPoint, 12, paint);
      canvas.drawCircle(l2SanMiguelitoPoint, 12, paint);

      paint
        ..style = PaintingStyle.stroke
        ..color = Colors.orange
        ..strokeWidth = 2;
      canvas.drawCircle(l1SanMiguelitoPoint, 12, paint);
      canvas.drawCircle(l2SanMiguelitoPoint, 12, paint);
    }
  }

  void _drawHighlightedRoute(Canvas canvas, Paint paint) {
    if (highlightedRoute == null || highlightedRoute!.length < 2) return;

    // Crear un mapa de estaciones a sus puntos en el canvas
    final stationToPoint = <String, Offset>{};

    // Mapear estaciones de línea 1
    for (int i = 0; i < linea1Stations.length && i < line1Points.length; i++) {
      stationToPoint[linea1Stations[i].id] = line1Points[i];
    }

    // Mapear estaciones de línea 2
    for (int i = 0; i < linea2Stations.length && i < line2Points.length; i++) {
      stationToPoint[linea2Stations[i].id] = line2Points[i];
    }

    // Mapear estaciones de la rama del aeropuerto
    for (int i = 0;
        i < linea2AirportStations.length && i < line2AirportPoints.length;
        i++) {
      stationToPoint[linea2AirportStations[i].id] = line2AirportPoints[i];
    }

    // Dibujar la ruta resaltada
    paint
      ..color = Colors.blue
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    final path = Path();
    bool isFirst = true;

    for (final station in highlightedRoute!) {
      final point = stationToPoint[station.id];
      if (point != null) {
        if (isFirst) {
          path.moveTo(point.dx, point.dy);
          isFirst = false;
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
    }

    canvas.drawPath(path, paint);

    // Dibujar círculos más grandes en las estaciones de la ruta
    paint
      ..style = PaintingStyle.fill
      ..color = Colors.blue.withValues(alpha: 0.3);

    for (final station in highlightedRoute!) {
      final point = stationToPoint[station.id];
      if (point != null) {
        canvas.drawCircle(point, 12, paint);
      }
    }

    // Dibujar borde azul más grueso
    paint
      ..style = PaintingStyle.stroke
      ..color = Colors.blue
      ..strokeWidth = 2;

    for (final station in highlightedRoute!) {
      final point = stationToPoint[station.id];
      if (point != null) {
        canvas.drawCircle(point, 12, paint);
      }
    }
  }

  void _drawLine(Canvas canvas, Paint paint, List<Offset> points) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  bool _isLineInRoute(String linea) {
    if (highlightedRoute == null || highlightedRoute!.isEmpty) return false;
    return highlightedRoute!.any((station) => station.linea == linea);
  }

  bool _isAirportBranchInRoute() {
    if (highlightedRoute == null || highlightedRoute!.isEmpty) return false;
    final airportStationIds = ['l2_itse', 'l2_aeropuerto'];
    return highlightedRoute!
        .any((station) => airportStationIds.contains(station.id));
  }

  void _drawStations(
    Canvas canvas,
    Paint paint,
    List<StationModel> stations,
    List<Offset> points,
    String label,
  ) {
    if (stations.isEmpty || points.isEmpty) return;

    final labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: paint.color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout();
    final labelPoint = points.first + const Offset(-20, -30);
    labelPainter.paint(canvas, labelPoint);

    for (int i = 0; i < stations.length; i++) {
      final station = stations[i];
      var point = points[i];

      // Si está siendo arrastrada, aplicar el offset del drag
      if (draggingStationId == station.id && dragOffset != null) {
        point = point + dragOffset!;
      }
      // Usar coordenada editada si existe
      else if (positionEditor != null && bounds != null && size != null) {
        final editedPosition = positionEditor!.getPosition(station.id);
        if (editedPosition != null) {
          // Convertir GeoPoint editado a coordenadas de canvas
          const padding = 48.0;
          final width = size!.width - padding * 2;
          final height = size!.height - padding * 2;

          final normalizedLng =
              (editedPosition.longitude - bounds!.minLng) / bounds!.lngSpan;
          final normalizedLat =
              (editedPosition.latitude - bounds!.minLat) / bounds!.latSpan;

          final x = padding + normalizedLng * width;
          final y = padding + (1 - normalizedLat) * height;

          point = Offset(x, y);
        }
      }

      final status = stationStatus[station.id] ?? StationStatus.normal;
      final color = getStationColor(status);
      final emoji = getStationEmoji(status);
      final minutes = nextTrainMinutes[station.id];

      paint
        ..style = PaintingStyle.fill
        ..color = color;
      canvas.drawCircle(point, 10, paint);

      paint
        ..style = PaintingStyle.stroke
        ..color = Colors.black
        ..strokeWidth = 2;
      canvas.drawCircle(point, 10, paint);

      // Dibujar fondo blanco semi-transparente para el nombre
      final namePainter = TextPainter(
        text: TextSpan(
          text: station.nombre,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.white,
                blurRadius: 3,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      namePainter.layout();

      // Dibujar fondo blanco redondeado para el nombre
      final nameRect = Rect.fromLTWH(
        point.dx - namePainter.width / 2 - 4,
        point.dy + 14 - 2,
        namePainter.width + 8,
        namePainter.height + 4,
      );
      final nameBackgroundPaint = Paint()
        ..color = Colors.white.withOpacity(0.9)
        ..style = PaintingStyle.fill;
      final nameBorderPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      final namePath = Path()
        ..addRRect(RRect.fromRectAndRadius(nameRect, const Radius.circular(4)));
      canvas.drawPath(namePath, nameBackgroundPaint);
      canvas.drawPath(namePath, nameBorderPaint);

      namePainter.paint(canvas, point + Offset(-namePainter.width / 2, 14));

      // Dibujar fondo para el estado (con ETA real o "—" si no hay datos)
      final etaText = minutes != null ? '${minutes}min' : '—';
      final statusText = '$emoji ($etaText)';
      final statusPainter = TextPainter(
        text: TextSpan(
          text: statusText,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            shadows: const [
              Shadow(
                color: Colors.white,
                blurRadius: 2,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      statusPainter.layout();

      // Dibujar fondo blanco para el estado
      final statusRect = Rect.fromLTWH(
        point.dx - statusPainter.width / 2 - 3,
        point.dy + 28 - 2,
        statusPainter.width + 6,
        statusPainter.height + 3,
      );
      final statusBackgroundPaint = Paint()
        ..color = Colors.white.withOpacity(0.85)
        ..style = PaintingStyle.fill;

      final statusPath = Path()
        ..addRRect(
            RRect.fromRectAndRadius(statusRect, const Radius.circular(3)));
      canvas.drawPath(statusPath, statusBackgroundPaint);

      statusPainter.paint(canvas, point + Offset(-statusPainter.width / 2, 28));
    }
  }

  @override
  bool shouldRepaint(MetroMapPainter oldDelegate) {
    return oldDelegate.stationStatus != stationStatus ||
        oldDelegate.nextTrainMinutes != nextTrainMinutes ||
        oldDelegate.line1Points != line1Points ||
        oldDelegate.line2Points != line2Points ||
        oldDelegate.line2AirportPoints != line2AirportPoints ||
        oldDelegate.draggingStationId != draggingStationId ||
        oldDelegate.dragOffset != dragOffset;
  }
}

List<Offset> _projectStations(
  List<StationModel> stations,
  Size size,
  _GeoBounds bounds,
) {
  if (stations.isEmpty) return [];
  const padding = 48.0;
  final width = size.width - padding * 2;
  final height = size.height - padding * 2;
  return stations.map((station) {
    final normalizedLng =
        (station.ubicacion.longitude - bounds.minLng) / bounds.lngSpan;
    final normalizedLat =
        (station.ubicacion.latitude - bounds.minLat) / bounds.latSpan;

    final x = padding + normalizedLng * width;
    final y = padding + (1 - normalizedLat) * height;
    return Offset(x, y);
  }).toList();
}

Offset _positionAlongLine(List<Offset> points, double progress) {
  if (points.length < 2) {
    return points.isNotEmpty ? points.first : Offset.zero;
  }
  final totalSegments = points.length - 1;
  final scaled = progress * totalSegments;
  final index = scaled.floor().clamp(0, totalSegments - 1);
  final t = scaled - index;
  final start = points[index];
  final end = points[index + 1];
  final dx = ui.lerpDouble(start.dx, end.dx, t)!;
  final dy = ui.lerpDouble(start.dy, end.dy, t)!;
  return Offset(dx, dy);
}

class _TrainSighting {
  final String stationId;
  final String line;
  final String directionCode;
  final DateTime updatedAt;
  final bool hasArrived;

  _TrainSighting({
    required this.stationId,
    required this.line,
    required this.directionCode,
    required this.updatedAt,
    required this.hasArrived,
  });
}

class _GeoBounds {
  _GeoBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  double get latSpan => (maxLat - minLat).abs().clamp(0.0001, double.infinity);
  double get lngSpan => (maxLng - minLng).abs().clamp(0.0001, double.infinity);

  factory _GeoBounds.fromStations(List<StationModel> stations) {
    if (stations.isEmpty) {
      return _GeoBounds(
        minLat: 0,
        maxLat: 1,
        minLng: 0,
        maxLng: 1,
      );
    }
    double minLat = stations.first.ubicacion.latitude;
    double maxLat = minLat;
    double minLng = stations.first.ubicacion.longitude;
    double maxLng = minLng;

    for (final station in stations) {
      minLat = math.min(minLat, station.ubicacion.latitude);
      maxLat = math.max(maxLat, station.ubicacion.latitude);
      minLng = math.min(minLng, station.ubicacion.longitude);
      maxLng = math.max(maxLng, station.ubicacion.longitude);
    }

    return _GeoBounds(
      minLat: minLat,
      maxLat: maxLat,
      minLng: minLng,
      maxLng: maxLng,
    );
  }
}

/// Bottom sheet para confirmar llegada del tren con selección de dirección.
class _TrainArrivalSheetContent extends StatefulWidget {
  final StationModel station;
  final EtaGroupService etaGroupService;
  final void Function(String? directionCode) onConfirm;

  const _TrainArrivalSheetContent({
    required this.station,
    required this.etaGroupService,
    required this.onConfirm,
  });

  @override
  State<_TrainArrivalSheetContent> createState() =>
      _TrainArrivalSheetContentState();
}

class _TrainArrivalSheetContentState extends State<_TrainArrivalSheetContent> {
  String? _selectedDirection;
  Map<String, EtaGroupModel?>? _activeGroups;
  bool _loading = true;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.etaGroupService
        .watchActiveGroupsByDirectionForStation(widget.station.id)
        .listen((groups) {
      if (!mounted) return;
      final activeDirections =
          groups.entries.where((e) => e.value != null).toList();

      setState(() {
        _activeGroups = groups;
        _loading = false;
        // Auto-seleccionar si solo hay una dirección activa
        if (activeDirections.length == 1) {
          _selectedDirection = activeDirections.first.key;
        }
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  String _getDirectionLabel(String directionCode) {
    if (widget.station.linea == 'linea1') {
      return directionCode == 'A' ? 'Hacia Albrook' : 'Hacia Villa Zaita';
    } else if (widget.station.linea == 'linea2') {
      return directionCode == 'A'
          ? 'Hacia San Miguelito'
          : 'Hacia Nuevo Tocumen';
    }
    return 'Dirección $directionCode';
  }

  @override
  Widget build(BuildContext context) {
    final activeDirections = _activeGroups?.entries
            .where((e) => e.value != null)
            .map((e) => e.key)
            .toList() ??
        [];
    final hasMultipleDirections = activeDirections.length > 1;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Row(
              children: [
                const Text('🚇', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '¿Llegó el metro?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF333333),
                        ),
                      ),
                      Text(
                        widget.station.nombre,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Selección de dirección (si hay múltiples activas)
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (hasMultipleDirections) ...[
              Text(
                '¿En qué dirección?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              for (final dir in activeDirections)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildDirectionOption(dir),
                ),
              const SizedBox(height: 8),
            ],

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'NO',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: (!hasMultipleDirections ||
                            _selectedDirection != null)
                        ? () => widget.onConfirm(
                              _selectedDirection ?? activeDirections.firstOrNull,
                            )
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'SÍ, LLEGÓ',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionOption(String directionCode) {
    final isSelected = _selectedDirection == directionCode;
    final group = _activeGroups?[directionCode];
    final label = group?.directionLabel != null
        ? 'Hacia ${group!.directionLabel}'
        : _getDirectionLabel(directionCode);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedDirection = directionCode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withValues(alpha: 0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.green.withValues(alpha: 0.5)
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              directionCode == 'A'
                  ? Icons.arrow_back_rounded
                  : Icons.arrow_forward_rounded,
              color: isSelected ? Colors.green : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.green[800] : Colors.grey[800],
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.green, size: 22),
          ],
        ),
      ),
    );
  }
}
