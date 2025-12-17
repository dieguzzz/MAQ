import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget animado que muestra puntos ganados de forma elegante y no intrusiva
class PointsRewardAnimation extends StatefulWidget {
  final int points;
  final String? message;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onComplete;

  const PointsRewardAnimation({
    super.key,
    required this.points,
    this.message,
    this.icon,
    this.color,
    this.onComplete,
  });

  /// Muestra una animación de puntos ganados de forma global
  static OverlayEntry? show(
    BuildContext context, {
    required int points,
    String? message,
    IconData? icon,
    Color? color,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: PointsRewardAnimation(
            points: points,
            message: message,
            icon: icon,
            color: color,
            onComplete: () {
              overlayEntry.remove();
            },
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Remover automáticamente después de la duración
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });

    return overlayEntry;
  }

  @override
  State<PointsRewardAnimation> createState() => _PointsRewardAnimationState();
}

class _PointsRewardAnimationState extends State<PointsRewardAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    
    // Vibración sutil
    HapticFeedback.lightImpact();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Animación de fade in/out
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    // Animación de escala (aparece desde pequeño)
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    // Animación de deslizamiento desde abajo
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Animación de rebote para el número de puntos
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.6, curve: Curves.elasticOut),
      ),
    );

    _controller.forward().then((_) {
      // Después de aparecer, esperar un poco y desaparecer
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _controller.reverse().then((_) {
            widget.onComplete?.call();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Colors.green;
    final icon = widget.icon ?? Icons.stars;
    final message = widget.message ?? 'Puntos ganados';

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color,
                          color.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Transform.scale(
                              scale: _bounceAnimation.value,
                              child: Text(
                                '+${widget.points} puntos',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Helper para mostrar puntos ganados de forma fácil
class PointsRewardHelper {
  /// Muestra puntos ganados por confirmar reporte
  static void showConfirmReportPoints(BuildContext context, {int points = 15}) {
    PointsRewardAnimation.show(
      context,
      points: points,
      message: 'Reporte confirmado',
      icon: Icons.check_circle,
      color: Colors.green,
    );
  }

  /// Muestra puntos ganados por reporte verificado
  static void showVerifiedReportPoints(BuildContext context, {int points = 10}) {
    PointsRewardAnimation.show(
      context,
      points: points,
      message: 'Tu reporte fue verificado',
      icon: Icons.verified,
      color: Colors.blue,
    );
  }

  /// Muestra puntos ganados por reporte confirmado (autor)
  static void showReportConfirmedPoints(BuildContext context, {int points = 5}) {
    PointsRewardAnimation.show(
      context,
      points: points,
      message: 'Alguien confirmó tu reporte',
      icon: Icons.thumb_up,
      color: Colors.orange,
    );
  }

  /// Muestra puntos ganados por crear reporte
  static void showCreateReportPoints(BuildContext context, {int points = 15}) {
    PointsRewardAnimation.show(
      context,
      points: points,
      message: 'Reporte creado',
      icon: Icons.add_circle,
      color: Colors.blue,
    );
  }

  /// Muestra puntos ganados por racha
  static void showStreakPoints(BuildContext context, {int points = 2, int streak = 1}) {
    PointsRewardAnimation.show(
      context,
      points: points,
      message: 'Racha de $streak días',
      icon: Icons.local_fire_department,
      color: Colors.orange,
    );
  }

  /// Muestra puntos ganados por reporte épico
  static void showEpicReportPoints(BuildContext context, {int points = 100}) {
    PointsRewardAnimation.show(
      context,
      points: points,
      message: 'Reporte épico',
      icon: Icons.stars,
      color: Colors.purple,
    );
  }

  /// Muestra puntos ganados personalizados
  static void showCustomPoints(
    BuildContext context, {
    required int points,
    required String message,
    IconData? icon,
    Color? color,
  }) {
    PointsRewardAnimation.show(
      context,
      points: points,
      message: message,
      icon: icon ?? Icons.stars,
      color: color ?? Colors.green,
    );
  }
}

