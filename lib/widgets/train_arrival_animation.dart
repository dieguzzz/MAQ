import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

/// Animación llamativa de tren llegando - función destacada de la app
class TrainArrivalAnimation extends StatefulWidget {
  final int points;
  final String? directionLabel;
  final Color? lineColor;
  final VoidCallback? onComplete;

  const TrainArrivalAnimation({
    super.key,
    required this.points,
    this.directionLabel,
    this.lineColor,
    this.onComplete,
  });

  /// Muestra la animación de tren llegando de forma global
  static void show(
    BuildContext context, {
    required int points,
    String? directionLabel,
    Color? lineColor,
    VoidCallback? onComplete,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      barrierDismissible: false,
      builder: (dialogContext) => TrainArrivalAnimation(
        points: points,
        directionLabel: directionLabel,
        lineColor: lineColor,
        onComplete: () {
          Navigator.of(dialogContext).pop();
          onComplete?.call();
        },
      ),
    );
  }

  @override
  State<TrainArrivalAnimation> createState() => _TrainArrivalAnimationState();
}

class _TrainArrivalAnimationState extends State<TrainArrivalAnimation>
    with TickerProviderStateMixin {
  late AnimationController _trainController;
  late AnimationController _pointsController;
  late Animation<double> _trainPosition;
  late Animation<double> _trainScale;
  late Animation<double> _trainRotation;
  late Animation<double> _pointsScale;
  late Animation<double> _pointsFade;
  late Animation<double> _particlesAnimation;

  bool _showPoints = false;

  @override
  void initState() {
    super.initState();

    // Vibración fuerte al inicio
    HapticFeedback.mediumImpact();

    // Controlador para el tren (1.5 segundos)
    _trainController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Controlador para los puntos (2 segundos después del tren)
    _pointsController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Animación del tren moviéndose de izquierda a derecha
    _trainPosition = Tween<double>(
      begin: -0.3, // Empieza fuera de la pantalla a la izquierda
      end: 1.3, // Termina fuera de la pantalla a la derecha
    ).animate(
      CurvedAnimation(
        parent: _trainController,
        curve: Curves.easeInOut,
      ),
    );

    // Animación de escala del tren (crece al entrar, se reduce al salir)
    _trainScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 1.2).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 0.3,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 0.4,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.8).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 0.3,
      ),
    ]).animate(_trainController);

    // Animación de rotación sutil del tren
    _trainRotation = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(
      CurvedAnimation(
        parent: _trainController,
        curve: Curves.easeInOut,
      ),
    );

    // Animación de partículas
    _particlesAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _trainController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    // Animación de puntos (aparece después del tren)
    _pointsScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2).chain(
          CurveTween(curve: Curves.elasticOut),
        ),
        weight: 0.4,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 0.2,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 0.4,
      ),
    ]).animate(_pointsController);

    _pointsFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _pointsController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    // Iniciar animación del tren
    _trainController.forward().then((_) {
      // Mostrar puntos después de que termine la animación del tren
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() => _showPoints = true);
          HapticFeedback.lightImpact();
          _pointsController.forward();
        }
      });
    });

    // Cerrar automáticamente después de exactamente 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _trainController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Partículas de fondo
          AnimatedBuilder(
            animation: _particlesAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlesPainter(
                  _particlesAnimation.value,
                  baseColor: widget.lineColor ?? Colors.white,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Tren animado
          AnimatedBuilder(
            animation: _trainController,
            builder: (context, child) {
              return Positioned(
                left: MediaQuery.of(context).size.width * _trainPosition.value,
                top: MediaQuery.of(context).size.height * 0.4,
                child: Transform.scale(
                  scale: _trainScale.value,
                  child: Transform.rotate(
                    angle: _trainRotation.value,
                    child: _buildTrain(),
                  ),
                ),
              );
            },
          ),

          // Puntos ganados (aparece después)
          if (_showPoints)
            Center(
              child: AnimatedBuilder(
                animation: _pointsController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _pointsFade.value,
                    child: Transform.scale(
                      scale: _pointsScale.value,
                      child: _buildPointsDisplay(),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrain() {
    final Color primary = widget.lineColor ?? Colors.blue[700]!;
    final Color lighter = HSLColor.fromColor(primary).withLightness((HSLColor.fromColor(primary).lightness + 0.1).clamp(0.0, 1.0)).toColor();
    final Color darker = HSLColor.fromColor(primary).withLightness((HSLColor.fromColor(primary).lightness - 0.1).clamp(0.0, 1.0)).toColor();

    return Container(
      width: 120,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            darker,
            primary,
            lighter,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Ventanas del tren
          Positioned(
            left: 15,
            top: 10,
            child: Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Positioned(
            left: 50,
            top: 10,
            child: Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Positioned(
            left: 85,
            top: 10,
            child: Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Icono de tren
          const Center(
            child: Icon(
              Icons.train,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsDisplay() {
    String tierTitle;
    String tierEmoji;
    
    if (widget.points >= 10) {
      tierTitle = '¡PRIMER REPORTE!';
      tierEmoji = '🥇';
    } else if (widget.points >= 7) {
      tierTitle = '¡REPORTE RÁPIDO!';
      tierEmoji = '🥈';
    } else if (widget.points >= 5) {
      tierTitle = '¡CONFIRMADO!';
      tierEmoji = '✅';
    } else {
      tierTitle = '¡GRACIAS!';
      tierEmoji = '👍';
    }

    final Color primary = widget.lineColor ?? Colors.green[600]!;
    final Color lighter = HSLColor.fromColor(primary).withLightness((HSLColor.fromColor(primary).lightness + 0.15).clamp(0.0, 1.0)).toColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primary,
            lighter,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.5),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tierEmoji,
            style: const TextStyle(fontSize: 56),
          ),
          const SizedBox(height: 8),
          Text(
            tierTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.5,
              shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '+${widget.points}',
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.0,
              shadows: [Shadow(color: Colors.black26, blurRadius: 12)],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'PTOS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
              letterSpacing: 2,
            ),
          ),
          if (widget.directionLabel != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_train, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Dirección: ${widget.directionLabel}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pintor para partículas de fondo
class ParticlesPainter extends CustomPainter {
  final double progress;
  final Color baseColor;

  ParticlesPainter(this.progress, {required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = baseColor.withValues(alpha: 0.5 * (1 - progress));

    final random = math.Random(42);
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 2 + random.nextDouble() * 3;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
