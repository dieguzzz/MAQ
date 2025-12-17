import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gamification_model.dart';
import '../models/learning_report_model.dart';
import '../models/user_model.dart';
import 'accuracy_service.dart';
import 'level_service.dart';
import 'schedule_service.dart';
import 'firebase_service.dart';
import 'points_history_service.dart';
import '../models/points_transaction_model.dart';

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AccuracyService _accuracyService = AccuracyService();
  final PointsHistoryService _pointsHistoryService = PointsHistoryService();

  // Puntos por acciones
  static const int puntosPorReporteVerificado = 10;
  static const int puntosPorConfirmarReporte = 15; // Cambiado de 5 a 15
  static const int puntosPorReporteConfirmado = 5; // Para el autor cuando alguien confirma su reporte
  static const int puntosPorReporteEpico = 100;
  static const int puntosPorStreak = 2;

  // Calcular nivel basado en puntos (usando LevelService)
  int calculateLevel(int totalPoints) {
    return LevelService.calculateLevel(totalPoints);
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

      // Calcular nuevo nivel
      final nuevoNivel = LevelService.calculateLevel(newPuntos);
      
      await userRef.update({
        'gamification.puntos': FieldValue.increment(puntosPorReporteVerificado),
        'gamification.nivel': nuevoNivel, // Actualizar nivel automáticamente
        'gamification.puntos_por_linea': puntosPorLinea,
        'gamification.reportes_verificados':
            FieldValue.increment(1),
      });

      // Guardar en historial
      await _pointsHistoryService.saveTransaction(
        userId: userId,
        points: puntosPorReporteVerificado,
        type: PointsTransaction.typeReportVerified,
        description: 'Reporte verificado por la comunidad',
        reportId: reportId,
        metadata: {'linea': linea},
      );

      // Verificar si desbloquea algún badge
      await _checkAndAwardBadges(userId, newPuntos);
      
      // Verificar badge de influencer (100+ personas ayudadas)
      final reportesVerificados = (gamification?['reportes_verificados'] ?? 0) + 1;
      // Asumimos que cada reporte verificado ayuda a ~10 personas en promedio
      // Si tiene 10+ reportes verificados, ha ayudado a ~100+ personas
      if (reportesVerificados >= 10) {
        await _awardBadge(userId, BadgeType.influencerMetro);
      }
    } catch (e) {
      print('Error awarding points: $e');
    }
  }

  // Otorgar puntos por confirmar reporte de otro
  Future<void> awardPointsForVerifying(
      String userId, String reportId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();
      final gamification = userDoc.data()?['gamification'] as Map<String, dynamic>?;
      final currentPuntos = gamification?['puntos'] ?? 0;
      final newPuntos = currentPuntos + puntosPorConfirmarReporte;
      final nuevoNivel = LevelService.calculateLevel(newPuntos);
      
      await userRef.update({
        'gamification.puntos': FieldValue.increment(puntosPorConfirmarReporte),
        'gamification.nivel': nuevoNivel, // Actualizar nivel automáticamente
        'gamification.verificaciones_hechas': FieldValue.increment(1),
      });

      // Guardar en historial
      await _pointsHistoryService.saveTransaction(
        userId: userId,
        points: puntosPorConfirmarReporte,
        type: PointsTransaction.typeConfirmReport,
        description: 'Confirmaste un reporte de otro usuario',
        reportId: reportId,
      );

      // Verificar badges de verificación
      final updatedDoc = await userRef.get();
      final updatedGamification = updatedDoc.data()?['gamification'] as Map<String, dynamic>?;
      final verificaciones = updatedGamification?['verificaciones_hechas'] ?? 0;
      
      if (verificaciones == 10) {
        await _awardBadge(userId, BadgeType.verificador);
      }
      if (verificaciones == 50) {
        await _awardBadge(userId, BadgeType.ayudanteComunidad);
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
          final currentPuntos = gamification?['puntos'] ?? 0;
          final newPuntos = currentPuntos + puntosPorStreak;
          final nuevoNivel = LevelService.calculateLevel(newPuntos);
          
          await userRef.update({
            'gamification.streak': currentStreak + 1,
            'gamification.ultimo_reporte': Timestamp.now(),
            'gamification.puntos': FieldValue.increment(puntosPorStreak),
            'gamification.nivel': nuevoNivel, // Actualizar nivel automáticamente
          });

          // Guardar en historial
          await _pointsHistoryService.saveTransaction(
            userId: userId,
            points: puntosPorStreak,
            type: PointsTransaction.typeStreak,
            description: 'Racha de ${currentStreak + 1} días consecutivos',
            metadata: {'streak': currentStreak + 1},
          );
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
      case BadgeType.francotirador:
        return Badge(
          type: type,
          nombre: 'Francotirador',
          descripcion: '95%+ de precisión en tus reportes',
          icono: '🎯',
          desbloqueadoEn: DateTime.now(),
        );
      case BadgeType.detective:
        return Badge(
          type: type,
          nombre: 'Detective',
          descripcion: '85%+ de precisión en tus reportes',
          icono: '🔍',
          desbloqueadoEn: DateTime.now(),
        );
      case BadgeType.observador:
        return Badge(
          type: type,
          nombre: 'Observador',
          descripcion: '70%+ de precisión en tus reportes',
          icono: '👀',
          desbloqueadoEn: DateTime.now(),
        );
      case BadgeType.ojoDeAguila80:
        return Badge(
          type: type,
          nombre: 'Ojo de Águila',
          descripcion: '80%+ de precisión en tus reportes',
          icono: '🎯',
          desbloqueadoEn: DateTime.now(),
        );
      case BadgeType.ayudanteComunidad:
        return Badge(
          type: type,
          nombre: 'Ayudante de la Comunidad',
          descripcion: 'Verificaste 50 reportes de otros usuarios',
          icono: '🤝',
          desbloqueadoEn: DateTime.now(),
        );
      case BadgeType.influencerMetro:
        return Badge(
          type: type,
          nombre: 'Influencer del Metro',
          descripcion: 'Tus reportes han ayudado a 100+ personas',
          icono: '📢',
          desbloqueadoEn: DateTime.now(),
        );
      case BadgeType.expertoLinea1:
        return Badge(
          type: type,
          nombre: 'Experto Línea 1',
          descripcion: '100+ reportes en Línea 1',
          icono: '🔵',
          desbloqueadoEn: DateTime.now(),
        );
      case BadgeType.maestroLinea2:
        return Badge(
          type: type,
          nombre: 'Maestro Línea 2',
          descripcion: '100+ reportes en Línea 2',
          icono: '🟢',
          desbloqueadoEn: DateTime.now(),
        );
      case BadgeType.almaPollera:
        return Badge(
          type: type,
          nombre: 'Alma Pollera',
          descripcion: 'Reportaste durante el mes patrio',
          icono: '🇵🇦',
          desbloqueadoEn: DateTime.now(),
        );
      case BadgeType.reyCarnaval:
        return Badge(
          type: type,
          nombre: 'Rey del Carnaval',
          descripcion: 'Reportaste durante carnavales',
          icono: '🎭',
          desbloqueadoEn: DateTime.now(),
        );
      case BadgeType.profesorDelMetro:
        return Badge(
          type: type,
          nombre: 'Profesor del Metro',
          descripcion: 'Realizaste 10+ reportes de enseñanza',
          icono: '🎓',
          desbloqueadoEn: DateTime.now(),
        );
      // Badges de Fundador
      case BadgeType.fundador:
        return Badge(
          type: type,
          nombre: 'Fundador',
          descripcion: 'Parte de los primeros usuarios de MetroPTY',
          icono: '🌟',
          desbloqueadoEn: DateTime.now(),
        );
      case BadgeType.fundadorPlatino:
        return Badge(
          type: type,
          nombre: 'Fundador Platino',
          descripcion: 'Completaste todas las misiones de la primera semana',
          icono: '💎',
          desbloqueadoEn: DateTime.now(),
        );
      case BadgeType.pioneroEstacion:
        return Badge(
          type: type,
          nombre: 'Pionero de Estación',
          descripcion: 'Primero en reportar en una estación',
          icono: '🏆',
          desbloqueadoEn: DateTime.now(),
        );
      case BadgeType.mejoradorDatos:
        return Badge(
          type: type,
          nombre: 'Mejorador de Datos',
          descripcion: 'Subiste la confianza de una estación',
          icono: '📈',
          desbloqueadoEn: DateTime.now(),
        );
      case BadgeType.confirmadorConfiable:
        return Badge(
          type: type,
          nombre: 'Confirmador Confiable',
          descripcion: 'Confirmaste 5 reportes de otros',
          icono: '✅',
          desbloqueadoEn: DateTime.now(),
        );
      case BadgeType.exploradorUrbano:
        return Badge(
          type: type,
          nombre: 'Explorador Urbano',
          descripcion: 'Reportaste en 3 estaciones diferentes',
          icono: '🗺️',
          desbloqueadoEn: DateTime.now(),
        );
      case BadgeType.heroeHoraPico:
        return Badge(
          type: type,
          nombre: 'Héroe de Hora Pico',
          descripcion: 'Reportaste durante hora pico (7-9 AM)',
          icono: '🌅',
          desbloqueadoEn: DateTime.now(),
        );
      case BadgeType.verificadorElite:
        return Badge(
          type: type,
          nombre: 'Verificador Élite',
          descripcion: 'Confirmaste 10 reportes',
          icono: '🔍',
          desbloqueadoEn: DateTime.now(),
        );
      case BadgeType.maestroL1:
        return Badge(
          type: type,
          nombre: 'Maestro de L1',
          descripcion: 'Reportaste en todas las estaciones de Línea 1',
          icono: '🔵',
          desbloqueadoEn: DateTime.now(),
        );
      case BadgeType.maestroL2:
        return Badge(
          type: type,
          nombre: 'Maestro de L2',
          descripcion: 'Reportaste en todas las estaciones de Línea 2',
          icono: '🟢',
          desbloqueadoEn: DateTime.now(),
        );
      case BadgeType.leyendaFundadora:
        return Badge(
          type: type,
          nombre: 'Leyenda Fundadora',
          descripcion: '20 reportes en la primera semana',
          icono: '👑',
          desbloqueadoEn: DateTime.now(),
        );
    }
  }
  
  // Verificar si usuario es fundador (primeros 7 días)
  Future<bool> isFounder(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final createdAt = userDoc.data()?['creado_en'] as Timestamp?;
      if (createdAt == null) return false;
      
      final daysSinceCreation = DateTime.now().difference(createdAt.toDate()).inDays;
      return daysSinceCreation <= 7;
    } catch (e) {
      return false;
    }
  }
  
  // Otorgar badge de fundador al crear cuenta
  Future<void> awardFounderBadge(String userId) async {
    if (await isFounder(userId)) {
      await _awardBadge(userId, BadgeType.fundador);
    }
  }
  
  // Verificar badge "Pionero de Estación"
  Future<void> checkPioneerBadge(String userId, String stationId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final reportsToday = await _firestore
          .collection('reports')
          .where('objetivo_id', isEqualTo: stationId)
          .where('tipo', isEqualTo: 'estacion')
          .where('creado_en', isGreaterThan: Timestamp.fromDate(startOfDay))
          .orderBy('creado_en')
          .limit(1)
          .get();
      
      if (reportsToday.docs.isNotEmpty) {
        final firstReport = reportsToday.docs.first;
        if (firstReport.data()['usuario_id'] == userId) {
          await _awardBadge(userId, BadgeType.pioneroEstacion);
        }
      }
    } catch (e) {
      print('Error checking pioneer badge: $e');
    }
  }
  
  // Verificar badge "Mejorador de Datos"
  Future<void> checkDataImproverBadge(String userId) async {
    await _awardBadge(userId, BadgeType.mejoradorDatos);
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

    // Verificar badges de precisión
    await _checkAccuracyBadges(userId);
    
    // Verificar badges de especialización por línea
    await _checkLineaBadges(userId);
    
    // Verificar badges de eventos panameños
    await _checkEventBadges(userId);
  }

  /// Verifica y otorga badges basados en precisión
  Future<void> _checkAccuracyBadges(String userId) async {
    try {
      final accuracy = await _accuracyService.calculateUserAccuracy(userId);
      
      // Badge de precisión alta
      if (accuracy >= 95) {
        await _awardBadge(userId, BadgeType.francotirador);
      } else if (accuracy >= 85) {
        await _awardBadge(userId, BadgeType.detective);
      } else if (accuracy >= 80) {
        await _awardBadge(userId, BadgeType.ojoDeAguila80);
      } else if (accuracy >= 70) {
        await _awardBadge(userId, BadgeType.observador);
      }
    } catch (e) {
      print('Error checking accuracy badges: $e');
    }
  }

  /// Verifica y otorga badges basados en reportes por línea
  Future<void> _checkLineaBadges(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();
      final gamification = userDoc.data()?['gamification'] as Map<String, dynamic>?;
      final puntosPorLinea = Map<String, int>.from(gamification?['puntos_por_linea'] ?? {});
      
      // Cada 10 puntos = aproximadamente 1 reporte (asumiendo 10 puntos por reporte verificado)
      final reportesLinea1 = (puntosPorLinea['Línea 1'] ?? 0) ~/ 10;
      final reportesLinea2 = (puntosPorLinea['Línea 2'] ?? 0) ~/ 10;
      
      if (reportesLinea1 >= 100) {
        await _awardBadge(userId, BadgeType.expertoLinea1);
      }
      if (reportesLinea2 >= 100) {
        await _awardBadge(userId, BadgeType.maestroLinea2);
      }
    } catch (e) {
      print('Error checking linea badges: $e');
    }
  }

  /// Verifica y otorga badges basados en eventos panameños
  Future<void> _checkEventBadges(String userId) async {
    try {
      final now = DateTime.now();
      final month = now.month;
      
      // Mes patrio (noviembre) - Panamá
      if (month == 11) {
        await _awardBadge(userId, BadgeType.almaPollera);
      }
      
      // Carnavales (febrero/marzo) - típicamente antes de miércoles de ceniza
      // Simplificado: febrero
      if (month == 2) {
        await _awardBadge(userId, BadgeType.reyCarnaval);
      }
    } catch (e) {
      print('Error checking event badges: $e');
    }
  }

  // Reporte épico (cuando un reporte ayuda a muchas personas)
  Future<void> awardEpicReport(String userId, int personasAyudadas) async {
    if (personasAyudadas >= 500) {
      try {
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await userRef.get();
        final gamification = userDoc.data()?['gamification'] as Map<String, dynamic>?;
        final currentPuntos = gamification?['puntos'] ?? 0;
        final newPuntos = currentPuntos + puntosPorReporteEpico;
        final nuevoNivel = LevelService.calculateLevel(newPuntos);
        
        await userRef.update({
          'gamification.puntos': FieldValue.increment(puntosPorReporteEpico),
          'gamification.nivel': nuevoNivel, // Actualizar nivel automáticamente
        });

        // Guardar en historial
        await _pointsHistoryService.saveTransaction(
          userId: userId,
          points: puntosPorReporteEpico,
          type: PointsTransaction.typeEpicReport,
          description: 'Reporte épico - Ayudaste a $personasAyudadas personas',
          metadata: {'personas_ayudadas': personasAyudadas},
        );
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

  /// Otorga recompensas por reportes de enseñanza
  /// Puntos base: 15
  /// Bonus por precisión histórica >80%: +10 puntos
  /// Bonus por horas críticas: +5 puntos
  Future<void> rewardTeachingReport(
      String userId, LearningReportModel report) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();

      if (!userDoc.exists) return;

      final currentData = userDoc.data()!;
      final gamification =
          currentData['gamification'] as Map<String, dynamic>?;

      final currentPuntos = gamification?['puntos'] ?? 0;
      final currentTeachingReportsCount =
          gamification?['teaching_reports_count'] ?? 0;
      final currentTeachingScore =
          gamification?['teaching_score'] ?? 0;

      // Calcular puntos
      int puntosBase = 15;

      // Bonus por precisión histórica >80%
      final user = await FirebaseService().getUser(userId);
      int bonusPrecision = 0;
      if (user != null && user.precision > 80.0) {
        bonusPrecision = 10;
      }

      // Bonus por horas críticas
      int bonusHoraCritica = 0;
      if (ScheduleService.isCriticalHour(report.horaLlegadaReal)) {
        bonusHoraCritica = 5;
      }

      final totalPuntos =
          puntosBase + bonusPrecision + bonusHoraCritica;
      final newPuntos = currentPuntos + totalPuntos;
      final nuevoNivel = LevelService.calculateLevel(newPuntos);

      // Incrementar contadores
      final newTeachingReportsCount = currentTeachingReportsCount + 1;
      // Teaching score = puntos ganados por reportes de enseñanza
      final newTeachingScore = currentTeachingScore + totalPuntos;

      await userRef.update({
        'gamification.puntos': newPuntos,
        'gamification.nivel': nuevoNivel,
        'gamification.teaching_reports_count': newTeachingReportsCount,
        'gamification.teaching_score': newTeachingScore,
      });

      // Guardar en historial
      await _pointsHistoryService.saveTransaction(
        userId: userId,
        points: totalPuntos,
        type: PointsTransaction.typeTeachingReport,
        description: 'Reporte de enseñanza${bonusPrecision > 0 ? ' + bonus precisión' : ''}${bonusHoraCritica > 0 ? ' + bonus hora crítica' : ''}',
        reportId: report.id,
        metadata: {
          'puntos_base': puntosBase,
          'bonus_precision': bonusPrecision,
          'bonus_hora_critica': bonusHoraCritica,
        },
      );

      // Verificar si otorgar badge "Profesor del Metro"
      if (newTeachingReportsCount >= 10) {
        await _awardTeachingBadge(userId);
      }
    } catch (e) {
      print('Error rewarding teaching report: $e');
    }
  }

  /// Otorga el badge "Profesor del Metro"
  Future<void> _awardTeachingBadge(String userId) async {
    await _awardBadge(userId, BadgeType.profesorDelMetro);
  }

  /// Otorga puntos al autor del reporte cuando alguien lo confirma
  Future<void> awardPointsToReportAuthor(String authorUserId, String reportId) async {
    try {
      final userRef = _firestore.collection('users').doc(authorUserId);
      final userDoc = await userRef.get();
      
      if (!userDoc.exists) return;
      
      final gamification = userDoc.data()?['gamification'] as Map<String, dynamic>?;
      final currentPuntos = gamification?['puntos'] ?? 0;
      final newPuntos = currentPuntos + puntosPorReporteConfirmado;
      final nuevoNivel = LevelService.calculateLevel(newPuntos);
      
      await userRef.update({
        'gamification.puntos': FieldValue.increment(puntosPorReporteConfirmado),
        'gamification.nivel': nuevoNivel,
      });

      // Guardar en historial del autor
      await _pointsHistoryService.saveTransaction(
        userId: authorUserId,
        points: puntosPorReporteConfirmado,
        type: PointsTransaction.typeReportAuthorBonus,
        description: 'Tu reporte fue confirmado por otro usuario',
        reportId: reportId,
      );
    } catch (e) {
      print('Error awarding points to report author: $e');
    }
  }
}

