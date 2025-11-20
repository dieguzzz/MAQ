import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gamification_model.dart';
import '../models/user_model.dart';
import '../models/report_model.dart';

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Puntos por acciones
  static const int puntosPorReporteVerificado = 10;
  static const int puntosPorConfirmarReporte = 5;
  static const int puntosPorReporteEpico = 100;
  static const int puntosPorStreak = 2;

  // Calcular nivel basado en reportes
  UserLevel calculateLevel(int reportesCount) {
    if (reportesCount >= 201) return UserLevel.heroeMetro;
    if (reportesCount >= 51) return UserLevel.reporteroConfiable;
    if (reportesCount >= 11) return UserLevel.viajeroFrecuente;
    return UserLevel.novato;
  }

  // Calcular puntos por reporte verificado
  Future<void> awardPointsForVerifiedReport(
      String userId, String reportId, String linea) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();
      
      if (!userDoc.exists) return;

      final currentData = userDoc.data()!;
      final gamification = currentData['gamification'] as Map<String, dynamic>?;
      
      final currentPuntos = gamification?['puntos'] ?? 0;
      final puntosPorLinea = Map<String, int>.from(
          gamification?['puntos_por_linea'] ?? {});
      
      final newPuntos = currentPuntos + puntosPorReporteVerificado;
      puntosPorLinea[linea] = (puntosPorLinea[linea] ?? 0) + puntosPorReporteVerificado;

      await userRef.update({
        'gamification.puntos': newPuntos,
        'gamification.puntos_por_linea': puntosPorLinea,
        'gamification.reportes_verificados':
            (gamification?['reportes_verificados'] ?? 0) + 1,
      });

      // Verificar si desbloquea algún badge
      await _checkAndAwardBadges(userId, newPuntos);
    } catch (e) {
      print('Error awarding points: $e');
    }
  }

  // Otorgar puntos por confirmar reporte de otro
  Future<void> awardPointsForVerifying(
      String userId, String reportId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      await userRef.update({
        'gamification.puntos': FieldValue.increment(puntosPorConfirmarReporte),
        'gamification.verificaciones_hechas': FieldValue.increment(1),
      });

      // Verificar badge de Verificador
      final userDoc = await userRef.get();
      final gamification = userDoc.data()?['gamification'] as Map<String, dynamic>?;
      final verificaciones = gamification?['verificaciones_hechas'] ?? 0;
      
      if (verificaciones == 10) {
        await _awardBadge(userId, BadgeType.verificador);
      }
    } catch (e) {
      print('Error awarding verification points: $e');
    }
  }

  // Actualizar streak
  Future<void> updateStreak(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();
      
      if (!userDoc.exists) return;

      final gamification = userDoc.data()?['gamification'] as Map<String, dynamic>?;
      final ultimoReporte = gamification?['ultimo_reporte'] as Timestamp?;
      final currentStreak = gamification?['streak'] ?? 0;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (ultimoReporte != null) {
        final lastReportDate = ultimoReporte.toDate();
        final lastDate = DateTime(
            lastReportDate.year, lastReportDate.month, lastReportDate.day);

        final daysDifference = today.difference(lastDate).inDays;

        if (daysDifference == 1) {
          // Continuar streak
          await userRef.update({
            'gamification.streak': currentStreak + 1,
            'gamification.ultimo_reporte': Timestamp.now(),
            'gamification.puntos': FieldValue.increment(puntosPorStreak),
          });
        } else if (daysDifference > 1) {
          // Resetear streak
          await userRef.update({
            'gamification.streak': 1,
            'gamification.ultimo_reporte': Timestamp.now(),
          });
        }
        // Si daysDifference == 0, ya reportó hoy, no hacer nada
      } else {
        // Primer reporte
        await userRef.update({
          'gamification.streak': 1,
          'gamification.ultimo_reporte': Timestamp.now(),
        });
        await _awardBadge(userId, BadgeType.primerReporte);
      }

      // Verificar badges de streak
      final updatedDoc = await userRef.get();
      final updatedGamification =
          updatedDoc.data()?['gamification'] as Map<String, dynamic>?;
      final newStreak = updatedGamification?['streak'] ?? 0;

      if (newStreak == 7) {
        await _awardBadge(userId, BadgeType.streakSemana);
      }
      if (newStreak == 30) {
        await _awardBadge(userId, BadgeType.streakMes);
      }
    } catch (e) {
      print('Error updating streak: $e');
    }
  }

  // Otorgar badge
  Future<void> _awardBadge(String userId, BadgeType badgeType) async {
    try {
      final badge = _createBadge(badgeType);
      final userRef = _firestore.collection('users').doc(userId);
      
      final userDoc = await userRef.get();
      final gamification = userDoc.data()?['gamification'] as Map<String, dynamic>?;
      final currentBadges = (gamification?['badges'] as List<dynamic>?) ?? [];

      // Verificar si ya tiene el badge
      final hasBadge = currentBadges.any((b) => b['type'] == badgeType.toString());
      if (hasBadge) return;

      currentBadges.add(badge.toFirestore());
      
      await userRef.update({
        'gamification.badges': currentBadges,
      });
    } catch (e) {
      print('Error awarding badge: $e');
    }
  }

  // Crear badge
  Badge _createBadge(BadgeType type) {
    switch (type) {
      case BadgeType.primerReporte:
        return Badge(
          type: type,
          nombre: 'Primer Reporte',
          descripcion: 'Hiciste tu primer reporte',
          icono: '✅',
          desbloqueadoEn: DateTime.now(),
        );
      case BadgeType.verificador:
        return Badge(
          type: type,
          nombre: 'Verificador',
          descripcion: 'Confirmaste 10 reportes de otros',
          icono: '🔍',
          desbloqueadoEn: DateTime.now(),
        );
      case BadgeType.ojoDeAguila:
        return Badge(
          type: type,
          nombre: 'Ojo de Águila',
          descripcion: 'Tus reportes fueron confirmados 50 veces',
          icono: '👁️',
          desbloqueadoEn: DateTime.now(),
        );
      case BadgeType.salvavidas:
        return Badge(
          type: type,
          nombre: 'Salvavidas',
          descripcion: 'Alertaste de un cierre 30 min antes',
          icono: '🆘',
          desbloqueadoEn: DateTime.now(),
        );
      case BadgeType.metroMaster:
        return Badge(
          type: type,
          nombre: 'MetroMaster',
          descripcion: 'Top 10% de reputación',
          icono: '👑',
          desbloqueadoEn: DateTime.now(),
        );
      case BadgeType.streakSemana:
        return Badge(
          type: type,
          nombre: 'Racha Semanal',
          descripcion: '7 días consecutivos reportando',
          icono: '🔥',
          desbloqueadoEn: DateTime.now(),
        );
      case BadgeType.streakMes:
        return Badge(
          type: type,
          nombre: 'Racha Mensual',
          descripcion: '30 días consecutivos reportando',
          icono: '🔥🔥',
          desbloqueadoEn: DateTime.now(),
        );
      case BadgeType.topContribuidor:
        return Badge(
          type: type,
          nombre: 'Top Contribuidor',
          descripcion: 'Entre los mejores contribuidores',
          icono: '⭐',
          desbloqueadoEn: DateTime.now(),
        );
    }
  }

  // Verificar y otorgar badges
  Future<void> _checkAndAwardBadges(String userId, int puntos) async {
    final userRef = _firestore.collection('users').doc(userId);
    final userDoc = await userRef.get();
    final gamification = userDoc.data()?['gamification'] as Map<String, dynamic>?;
    
    final reportesVerificados = gamification?['reportes_verificados'] ?? 0;
    
    if (reportesVerificados >= 50) {
      await _awardBadge(userId, BadgeType.ojoDeAguila);
    }
  }

  // Reporte épico (cuando un reporte ayuda a muchas personas)
  Future<void> awardEpicReport(String userId, int personasAyudadas) async {
    if (personasAyudadas >= 500) {
      try {
        final userRef = _firestore.collection('users').doc(userId);
        await userRef.update({
          'gamification.puntos': FieldValue.increment(puntosPorReporteEpico),
        });
      } catch (e) {
        print('Error awarding epic report: $e');
      }
    }
  }

  // Actualizar rankings
  Future<void> updateRankings() async {
    // Esta función debería ejecutarse periódicamente (Cloud Function)
    // Calcula rankings globales y por línea
    try {
      final usersSnapshot = await _firestore
          .collection('users')
          .orderBy('gamification.puntos', descending: true)
          .get();

      int ranking = 1;
      final batch = _firestore.batch();

      for (var doc in usersSnapshot.docs) {
        final userRef = _firestore.collection('users').doc(doc.id);
        batch.update(userRef, {
          'gamification.ranking': ranking++,
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error updating rankings: $e');
    }
  }
}

