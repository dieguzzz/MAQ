import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/station_model.dart';
import '../models/train_model.dart';

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
  final Map<String, TrainStatus> _trainStatus = {};
  final Map<String, int> _nextTrainMinutes = {}; // Minutos para próximo tren

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _initializeStatuses();
  }

  void _initializeStatuses() {
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

    // Inicializar estados de trenes
    for (var train in widget.trains) {
      if (train.estado == EstadoTren.detenido) {
        _trainStatus[train.id] = TrainStatus.detenido;
      } else if (train.velocidad < 20) {
        _trainStatus[train.id] = TrainStatus.lento;
      } else {
        _trainStatus[train.id] = TrainStatus.normal;
      }
    }
  }

  @override
  void dispose() {
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

  String _getTrainEmoji(TrainStatus status) {
    switch (status) {
      case TrainStatus.normal:
        return '🚇';
      case TrainStatus.lento:
        return '🚇';
      case TrainStatus.detenido:
        return '🚇';
      case TrainStatus.express:
        return '💨';
    }
  }

  @override
  Widget build(BuildContext context) {
    final linea1Stations = widget.stations
        .where((s) => s.linea == 'linea1')
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    final linea2Stations = widget.stations
        .where((s) => s.linea == 'linea2')
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    return Container(
      color: Colors.grey[100],
      child: CustomPaint(
        painter: MetroMapPainter(
          linea1Stations: linea1Stations,
          linea2Stations: linea2Stations,
          trains: widget.trains,
          stationStatus: _stationStatus,
          trainStatus: _trainStatus,
          nextTrainMinutes: _nextTrainMinutes,
          getStationColor: _getStationColor,
          getStationEmoji: _getStationEmoji,
          getTrainEmoji: _getTrainEmoji,
          animationValue: _animationController.value,
        ),
        child: GestureDetector(
          onTapUp: (details) {
            // Detectar taps en estaciones (simplificado)
          },
        ),
      ),
    );
  }
}

class MetroMapPainter extends CustomPainter {
  final List<StationModel> linea1Stations;
  final List<StationModel> linea2Stations;
  final List<TrainModel> trains;
  final Map<String, StationStatus> stationStatus;
  final Map<String, TrainStatus> trainStatus;
  final Map<String, int> nextTrainMinutes;
  final Color Function(StationStatus) getStationColor;
  final String Function(StationStatus) getStationEmoji;
  final String Function(TrainStatus) getTrainEmoji;
  final double animationValue;

  MetroMapPainter({
    required this.linea1Stations,
    required this.linea2Stations,
    required this.trains,
    required this.stationStatus,
    required this.trainStatus,
    required this.nextTrainMinutes,
    required this.getStationColor,
    required this.getStationEmoji,
    required this.getTrainEmoji,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Dibujar Línea 1 (Azul)
    if (linea1Stations.isNotEmpty) {
      paint.color = Colors.blue;
      _drawLine(canvas, paint, linea1Stations, size);
      _drawStations(canvas, paint, linea1Stations, size, 'LÍNEA 1 AZUL');
    }

    // Dibujar Línea 2 (Verde)
    if (linea2Stations.isNotEmpty) {
      paint.color = Colors.green;
      _drawLine(canvas, paint, linea2Stations, size);
      _drawStations(canvas, paint, linea2Stations, size, 'LÍNEA 2 VERDE');
    }

    // Dibujar trenes
    _drawTrains(canvas, paint, size);
  }

  void _drawLine(Canvas canvas, Paint paint, List<StationModel> stations,
      Size size) {
    if (stations.length < 2) return;

    final path = Path();
    final startX = size.width * 0.1;
    final endX = size.width * 0.9;
    final y = stations.first.linea == 'linea1'
        ? size.height * 0.3
        : size.height * 0.7;

    path.moveTo(startX, y);
    path.lineTo(endX, y);

    canvas.drawPath(path, paint);
  }

  void _drawStations(Canvas canvas, Paint paint, List<StationModel> stations,
      Size size, String lineLabel) {
    if (stations.isEmpty) return;

    final y = stations.first.linea == 'linea1'
        ? size.height * 0.3
        : size.height * 0.7;
    final spacing = (size.width * 0.8) / (stations.length - 1);
    final startX = size.width * 0.1;

    // Dibujar label de línea
    final textPainter = TextPainter(
      text: TextSpan(
        text: lineLabel,
        style: TextStyle(
          color: paint.color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(startX, y - 40));

    // Dibujar estaciones
    for (int i = 0; i < stations.length; i++) {
      final station = stations[i];
      final x = startX + (spacing * i);
      final status = stationStatus[station.id] ?? StationStatus.normal;
      final color = getStationColor(status);
      final emoji = getStationEmoji(status);
      final minutes = nextTrainMinutes[station.id] ?? 0;

      // Círculo de estación
      paint.style = PaintingStyle.fill;
      paint.color = color;
      canvas.drawCircle(Offset(x, y), 12, paint);

      // Borde
      paint.style = PaintingStyle.stroke;
      paint.color = Colors.black;
      paint.strokeWidth = 2;
      canvas.drawCircle(Offset(x, y), 12, paint);

      // Nombre de estación
      final namePainter = TextPainter(
        text: TextSpan(
          text: '• ${station.nombre}',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      namePainter.layout();
      namePainter.paint(canvas, Offset(x - 30, y + 20));

      // Estado y tiempo
      final statusPainter = TextPainter(
        text: TextSpan(
          text: '$emoji (${minutes}min)',
          style: TextStyle(
            color: color,
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      statusPainter.layout();
      statusPainter.paint(canvas, Offset(x - 25, y + 35));
    }
  }

  void _drawTrains(Canvas canvas, Paint paint, Size size) {
    // Dibujar trenes en movimiento (simplificado)
    for (var train in trains) {
      final stations = train.linea == 'linea1'
          ? linea1Stations
          : linea2Stations;
      if (stations.isEmpty) continue;

      final y = train.linea == 'linea1' ? size.height * 0.3 : size.height * 0.7;
      final status = trainStatus[train.id] ?? TrainStatus.normal;
      final emoji = getTrainEmoji(status);

      // Posición animada del tren (simplificado)
      final progress = (animationValue * 0.5) % 1.0;
      final startX = size.width * 0.1;
      final endX = size.width * 0.9;
      final x = startX + (endX - startX) * progress;

      // Dibujar tren
      final trainPainter = TextPainter(
        text: TextSpan(
          text: emoji,
          style: const TextStyle(fontSize: 20),
        ),
        textDirection: TextDirection.ltr,
      );
      trainPainter.layout();
      trainPainter.paint(canvas, Offset(x - 10, y - 10));
    }
  }

  @override
  bool shouldRepaint(MetroMapPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.stationStatus != stationStatus ||
        oldDelegate.trainStatus != trainStatus;
  }
}

