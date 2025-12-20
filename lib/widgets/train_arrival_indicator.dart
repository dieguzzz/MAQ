import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/station_model.dart';

/// Widget que muestra un indicador de metro con animación intermitente
/// cuando se detecta que alguien reportó "ya llegó el metro"
class TrainArrivalIndicator extends StatefulWidget {
  final StationModel station;
  final double size;

  const TrainArrivalIndicator({
    super.key,
    required this.station,
    this.size = 60.0,
  });

  @override
  State<TrainArrivalIndicator> createState() => _TrainArrivalIndicatorState();
}

class _TrainArrivalIndicatorState extends State<TrainArrivalIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  StreamSubscription<QuerySnapshot>? _subscription;
  DateTime? _lastArrivalTime;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    
    // Controlador de animación para el parpadeo
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Animación de parpadeo (opacidad de 0.3 a 1.0)
    _blinkAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _blinkController,
        curve: Curves.easeInOut,
      ),
    );

    // Escuchar reportes de llegada en tiempo real
    _listenToArrivals();
  }

  void _listenToArrivals() {
    final firestore = FirebaseFirestore.instance;
    
    _subscription = firestore
        .collection('reports')
        .where('stationId', isEqualTo: widget.station.id)
        .where('scope', isEqualTo: 'train')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) return;

      // Buscar el reporte más reciente con arrivalTime
      DateTime? mostRecentArrival;
      for (var doc in snapshot.docs) {
        final data = doc.data();
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
          _startBlinking();
        }
      }
    });
  }

  void _startBlinking() {
    if (!mounted) return;

    // Iniciar animación de parpadeo
    _blinkController.repeat(reverse: true);

    // Detener después de 10 segundos
    _blinkTimer?.cancel();
    _blinkTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        _blinkController.stop();
        _blinkController.reset();
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _blinkTimer?.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBlinking = _blinkController.isAnimating;
    
    return AnimatedBuilder(
      animation: _blinkAnimation,
      builder: (context, child) {
        // Cuando está parpadeando, usar la animación. Cuando no, mostrar normal
        final opacity = isBlinking ? _blinkAnimation.value : 1.0;
        final borderOpacity = isBlinking ? _blinkAnimation.value : 0.5;
        final shadowOpacity = isBlinking ? _blinkAnimation.value : 0.3;
        
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2 * opacity),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.green.withOpacity(borderOpacity),
              width: isBlinking ? 3 : 2,
            ),
            boxShadow: isBlinking ? [
              BoxShadow(
                color: Colors.green.withOpacity(0.5 * shadowOpacity),
                blurRadius: 15 * shadowOpacity,
                spreadRadius: 3 * shadowOpacity,
              ),
            ] : [],
          ),
          child: Center(
            child: Image.asset(
              'assets/icons/metro-station_2340498.png',
              width: widget.size * 0.7,
              height: widget.size * 0.7,
              color: Colors.green,
            ),
          ),
        );
      },
    );
  }
}

