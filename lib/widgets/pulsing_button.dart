import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/station_model.dart';

/// Widget que envuelve un botón y le agrega animación de pulso
/// cuando se detecta que alguien reportó "ya llegó el metro"
class PulsingButton extends StatefulWidget {
  final Widget child;
  final StationModel? station; // Si es null, escucha todas las estaciones
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final String heroTag;

  const PulsingButton({
    super.key,
    required this.child,
    this.station,
    this.onPressed,
    required this.backgroundColor,
    required this.heroTag,
  });

  @override
  State<PulsingButton> createState() => _PulsingButtonState();
}

class _PulsingButtonState extends State<PulsingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  StreamSubscription<QuerySnapshot>? _subscription;
  DateTime? _lastArrivalTime;
  Timer? _pulseTimer;

  @override
  void initState() {
    super.initState();

    // Controlador de animación para el pulso
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Animación de pulso (escala de 1.0 a 1.15)
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Escuchar reportes de llegada en tiempo real
    _listenToArrivals();
  }

  void _listenToArrivals() {
    final firestore = FirebaseFirestore.instance;

    Query query =
        firestore.collection('reports').where('scope', isEqualTo: 'train');

    // Si hay una estación específica, filtrar por ella
    if (widget.station != null) {
      query = query.where('stationId', isEqualTo: widget.station!.id);
    }

    _subscription = query.snapshots().listen((snapshot) {
      if (snapshot.docs.isEmpty) return;

      // Buscar el reporte más reciente con arrivalTime
      DateTime? mostRecentArrival;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['arrivalTime'] != null) {
          final arrivalTime = (data['arrivalTime'] as Timestamp).toDate();
          if (mostRecentArrival == null ||
              arrivalTime.isAfter(mostRecentArrival)) {
            mostRecentArrival = arrivalTime;
          }
        }
      }

      if (mostRecentArrival != null) {
        final now = DateTime.now();
        final difference = now.difference(mostRecentArrival);

        // Si el reporte es de los últimos 10 segundos y es diferente al anterior
        if (difference.inSeconds <= 10 &&
            (_lastArrivalTime == null ||
                mostRecentArrival.isAfter(_lastArrivalTime!))) {
          _lastArrivalTime = mostRecentArrival;
          _startPulsing();
        }
      }
    });
  }

  void _startPulsing() {
    if (!mounted) return;

    // Iniciar animación de pulso
    _pulseController.repeat(reverse: true);

    // Detener después de 10 segundos
    _pulseTimer?.cancel();
    _pulseTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        _pulseController.stop();
        _pulseController.reset();
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _pulseTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = _pulseAnimation.value;
        final opacity =
            (scale - 1.0) / 0.15; // 0.0 a 1.0 cuando scale va de 1.0 a 1.15

        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:
                      widget.backgroundColor.withValues(alpha: 0.5 * opacity),
                  blurRadius: 20 * opacity,
                  spreadRadius: 5 * opacity,
                ),
              ],
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}
