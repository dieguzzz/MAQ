import 'package:flutter/material.dart';
import '../widgets/points_reward_animation.dart';

/// Servicio global para mostrar animaciones de puntos ganados
/// Usa un GlobalKey para acceder al context desde cualquier lugar
class PointsRewardService {
  static final PointsRewardService _instance = PointsRewardService._internal();
  factory PointsRewardService() => _instance;
  PointsRewardService._internal();

  BuildContext? _context;

  /// Registra el contexto para mostrar animaciones
  void setContext(BuildContext context) {
    _context = context;
  }

  /// Limpia el contexto
  void clearContext() {
    _context = null;
  }

  /// Muestra puntos ganados por confirmar reporte
  void showConfirmReportPoints({int points = 15}) {
    if (_context != null && _context!.mounted) {
      PointsRewardHelper.showConfirmReportPoints(_context!, points: points);
    }
  }

  /// Muestra puntos ganados por reporte verificado
  void showVerifiedReportPoints({int points = 10}) {
    if (_context != null && _context!.mounted) {
      PointsRewardHelper.showVerifiedReportPoints(_context!, points: points);
    }
  }

  /// Muestra puntos ganados por reporte confirmado (autor)
  void showReportConfirmedPoints({int points = 5}) {
    if (_context != null && _context!.mounted) {
      PointsRewardHelper.showReportConfirmedPoints(_context!, points: points);
    }
  }

  /// Muestra puntos ganados por crear reporte
  void showCreateReportPoints({int points = 15}) {
    if (_context != null && _context!.mounted) {
      PointsRewardHelper.showCreateReportPoints(_context!, points: points);
    }
  }

  /// Muestra puntos ganados por racha
  void showStreakPoints({int points = 2, int streak = 1}) {
    if (_context != null && _context!.mounted) {
      PointsRewardHelper.showStreakPoints(_context!, points: points, streak: streak);
    }
  }

  /// Muestra puntos ganados por reporte épico
  void showEpicReportPoints({int points = 100}) {
    if (_context != null && _context!.mounted) {
      PointsRewardHelper.showEpicReportPoints(_context!, points: points);
    }
  }

  /// Muestra puntos personalizados
  void showCustomPoints({
    required int points,
    required String message,
    IconData? icon,
    Color? color,
  }) {
    if (_context != null && _context!.mounted) {
      PointsRewardHelper.showCustomPoints(
        _context!,
        points: points,
        message: message,
        icon: icon,
        color: color,
      );
    }
  }
}

