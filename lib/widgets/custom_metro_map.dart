import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui show lerpDouble;
import 'package:flutter_svg/flutter_svg.dart';
import '../models/station_model.dart';
import '../models/train_model.dart';
import '../data/train_simulation_table.dart';
import '../services/train_simulation_service.dart';
import '../utils/metro_data.dart';

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

  const CustomMetroMap({
    super.key,
    required this.stations,
    required this.trains,
    this.onStationTap,
    this.onTrainTap,
  });

  @override
  State<CustomMetroMap> createState() => _CustomMetroMapState();
}

class _CustomMetroMapState extends State<CustomMetroMap>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final Map<String, StationStatus> _stationStatus = {};
  final Map<String, int> _nextTrainMinutes = {}; // Minutos para próximo tren
  final TrainSimulationService _trainSimulation = TrainSimulationService();
  List<TrainModel> _simulatedTrains = [];
  Timer? _updateTimer;
  final Map<String, List<StationModel>> _orderedStations = {};

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
  }

  void _initializeTrainSimulation() {
    if (widget.stations.isNotEmpty) {
      _trainSimulation.initialize(widget.stations);
      _trainSimulation.start();
      _startTrainUpdates(widget.trains);
    }
  }

  void _startTrainUpdates(List<TrainModel> originalTrains) {
    _updateTimer?.cancel();
    // Actualizar más frecuentemente para movimiento más fluido (cada 1 segundo)
    _updateTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      if (mounted) {
        setState(() {
          _simulatedTrains = _trainSimulation.getUpdatedTrains(originalTrains);
        });
      }
    });
    // Actualización inicial
    if (mounted) {
      setState(() {
        _simulatedTrains = _trainSimulation.getUpdatedTrains(originalTrains);
      });
    }
  }

  @override
  void didUpdateWidget(CustomMetroMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stations != widget.stations || oldWidget.trains != widget.trains) {
      _initializeStatuses();
      _initializeTrainSimulation();
    } else {
      _initializeStatuses();
    }
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
    _nextTrainMinutes.clear();

    // Inicializar estados basados en aglomeración
    for (var station in widget.stations) {
      if (station.aglomeracion <= 2) {
        _stationStatus[station.id] = StationStatus.normal;
      } else if (station.aglomeracion == 3) {
        _stationStatus[station.id] = StationStatus.moderado;
      } else {
        _stationStatus[station.id] = StationStatus.lleno;
      }

      // Tiempo estimado para próximo tren (simulado)
      _nextTrainMinutes[station.id] = math.Random().nextInt(10) + 1;
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        // Ordenar estaciones según el orden de los datos estáticos
        final linea1Stations = _getOrderedStations('linea1');
        final linea2Stations = _getOrderedStations('linea2');

        final bounds = _GeoBounds.fromStations(widget.stations);
        final line1Points = _projectStations(linea1Stations, size, bounds);
        final line2Points = _projectStations(linea2Stations, size, bounds);

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
                    linea2Stations: linea2Stations,
                    line1Points: line1Points,
                    line2Points: line2Points,
                    stationStatus: _stationStatus,
                    nextTrainMinutes: _nextTrainMinutes,
                    getStationColor: _getStationColor,
                    getStationEmoji: _getStationEmoji,
                  ),
                ),
              ),
              ..._buildTrainWidgets(
                line1Points: line1Points,
                line2Points: line2Points,
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
  }) {
    final widgets = <Widget>[];
    final pointsByLine = {
      'linea1': line1Points,
      'linea2': line2Points,
    };

    // Usar trenes simulados si están disponibles, sino usar los originales
    final trainsToDisplay = _simulatedTrains.isNotEmpty ? _simulatedTrains : widget.trains;

    for (final train in trainsToDisplay) {
      final points = pointsByLine[train.linea];
      if (points == null || points.length < 2) continue;

      // Obtener el progreso del tren (0.0 a 1.0)
      final progress = _getTrainProgress(train);
      
      final position = _positionAlongLine(points, progress);
      final color = train.linea == 'linea1' ? Colors.blue : Colors.green;
      final forward = train.direccion == DireccionTren.norte;
      const trainWidth = 36.0;
      const trainHeight = 16.0;

      widgets.add(
        AnimatedPositioned(
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
          left: position.dx - trainWidth / 2,
          top: position.dy - trainHeight / 2,
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
      );
    }

    return widgets;
  }

  double _getTrainProgress(TrainModel train) {
    // Obtener el progreso directamente desde el servicio de simulación
    return _trainSimulation.getTrainProgress(train);
  }
}

class MetroMapPainter extends CustomPainter {
  final List<StationModel> linea1Stations;
  final List<StationModel> linea2Stations;
  final List<Offset> line1Points;
  final List<Offset> line2Points;
  final Map<String, StationStatus> stationStatus;
  final Map<String, int> nextTrainMinutes;
  final Color Function(StationStatus) getStationColor;
  final String Function(StationStatus) getStationEmoji;

  MetroMapPainter({
    required this.linea1Stations,
    required this.linea2Stations,
    required this.line1Points,
    required this.line2Points,
    required this.stationStatus,
    required this.nextTrainMinutes,
    required this.getStationColor,
    required this.getStationEmoji,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    if (linea1Stations.isNotEmpty) {
      paint.color = Colors.blue;
      _drawLine(canvas, paint, line1Points);
      _drawStations(
        canvas,
        paint,
        linea1Stations,
        line1Points,
        'LÍNEA 1 AZUL',
      );
    }

    if (linea2Stations.isNotEmpty) {
      paint.color = Colors.green;
      _drawLine(canvas, paint, line2Points);
      _drawStations(
        canvas,
        paint,
        linea2Stations,
        line2Points,
        'LÍNEA 2 VERDE',
      );
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
      final point = points[i];
      final status = stationStatus[station.id] ?? StationStatus.normal;
      final color = getStationColor(status);
      final emoji = getStationEmoji(status);
      final minutes = nextTrainMinutes[station.id] ?? 0;

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

      // Dibujar fondo para el estado
      final statusText = '$emoji (${minutes}min)';
      final statusPainter = TextPainter(
        text: TextSpan(
          text: statusText,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            shadows: [
              const Shadow(
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
        ..addRRect(RRect.fromRectAndRadius(statusRect, const Radius.circular(3)));
      canvas.drawPath(statusPath, statusBackgroundPaint);
      
      statusPainter.paint(canvas, point + Offset(-statusPainter.width / 2, 28));
    }
  }

  @override
  bool shouldRepaint(MetroMapPainter oldDelegate) {
    return oldDelegate.stationStatus != stationStatus ||
        oldDelegate.nextTrainMinutes != nextTrainMinutes ||
        oldDelegate.line1Points != line1Points ||
        oldDelegate.line2Points != line2Points;
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

