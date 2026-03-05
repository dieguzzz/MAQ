import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/gamification/points_history_service.dart';
import '../models/points_transaction_model.dart';
import 'points_reward_animation.dart';
import 'dart:async';

/// Widget que escucha cambios en el historial de puntos y muestra animaciones
/// Debe colocarse en la raíz de la app para detectar puntos ganados desde servicios
class PointsRewardListener extends StatefulWidget {
  final Widget child;

  const PointsRewardListener({
    super.key,
    required this.child,
  });

  @override
  State<PointsRewardListener> createState() => _PointsRewardListenerState();
}

class _PointsRewardListenerState extends State<PointsRewardListener> {
  final PointsHistoryService _pointsHistoryService = PointsHistoryService();
  final Set<String> _shownTransactions = {};
  StreamSubscription<List<PointsTransaction>>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.uid;

    if (userId != null && _subscription == null) {
      _startListening(userId);
    }
  }

  void _startListening(String userId) {
    // Cargar transacciones existentes primero para no mostrarlas
    _pointsHistoryService
        .getPointsHistory(userId, limit: 10)
        .first
        .then((initialTransactions) {
      for (var transaction in initialTransactions) {
        _shownTransactions.add(transaction.id);
      }
    }).catchError((e) {
      print('Error loading initial transactions: $e');
    });

    // Escuchar nuevas transacciones
    _subscription = _pointsHistoryService
        .getPointsHistory(userId, limit: 10)
        .listen((transactions) {
      if (!mounted) return;

      // Mostrar animación solo para transacciones nuevas (que no estén en el set)
      for (var transaction in transactions) {
        if (!_shownTransactions.contains(transaction.id)) {
          _shownTransactions.add(transaction.id);

          // Solo mostrar si la transacción es muy reciente (menos de 10 segundos)
          // Esto evita mostrar transacciones antiguas cuando el usuario inicia sesión
          final transactionAge =
              DateTime.now().difference(transaction.timestamp);
          if (transactionAge.inSeconds > 10) {
            continue; // Ignorar transacciones antiguas
          }

          // Esperar un poco para asegurar que el Overlay esté listo
          Future.delayed(const Duration(milliseconds: 800), () {
            if (!mounted) return;

            // Mostrar animación según el tipo
            switch (transaction.type) {
              case PointsTransaction.typeConfirmReport:
                PointsRewardHelper.showConfirmReportPoints(
                  context,
                  points: transaction.points,
                );
                break;
              case PointsTransaction.typeReportVerified:
                PointsRewardHelper.showVerifiedReportPoints(
                  context,
                  points: transaction.points,
                );
                break;
              case PointsTransaction.typeReportAuthorBonus:
                PointsRewardHelper.showReportConfirmedPoints(
                  context,
                  points: transaction.points,
                );
                break;
              case PointsTransaction.typeStreak:
                final streak = transaction.metadata?['streak'] ?? 1;
                PointsRewardHelper.showStreakPoints(
                  context,
                  points: transaction.points,
                  streak: streak is int ? streak : 1,
                );
                break;
              case PointsTransaction.typeEpicReport:
                PointsRewardHelper.showEpicReportPoints(
                  context,
                  points: transaction.points,
                );
                break;
              default:
                PointsRewardHelper.showCustomPoints(
                  context,
                  points: transaction.points,
                  message: transaction.description,
                );
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
