import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../models/simplified_report_model.dart';
import 'gamification_service.dart';
import 'simplified_report_confidence_service.dart';
import 'debug_log_service.dart';

/// Servicio simplificado para reportes según nuevo diseño
class SimplifiedReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _cleanupTimer;
  static const Duration _cleanupInterval =
      Duration(minutes: 5); // Ejecutar cada 5 minutos

  /// Crear reporte de estación (simplificado)
  Future<String> createStationReport({
    required String stationId,
    required String operational, // 'yes' | 'partial' | 'no'
    required int crowdLevel, // 1-5
    List<String>? issues, // Opcional
    Position? userPosition, // Opcional - solo si tiene permisos
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Usuario no autenticado');

    final now = DateTime.now();
    final basePoints = 15;
    final bonusPoints = (issues?.length ?? 0) * 5;

    final report = SimplifiedReportModel(
      id: '', // Se generará automáticamente
      scope: 'station',
      stationId: stationId,
      userId: userId,
      stationOperational: operational,
      stationCrowd: crowdLevel,
      stationIssues: issues ?? [],
      createdAt: now,
      basePoints: basePoints,
      bonusPoints: bonusPoints,
      totalPoints: basePoints + bonusPoints,
      userLocation: userPosition != null
          ? GeoPoint(userPosition.latitude, userPosition.longitude)
          : null,
      accuracy: userPosition?.accuracy,
    );

    final docRef =
        await _firestore.collection('reports').add(report.toFirestore());
    await docRef.update({'id': docRef.id});

    // Calcular y guardar confianza inicial
    final confidenceService = SimplifiedReportConfidenceService();
    final confidenceResult = await confidenceService.calculateConfidence(
      SimplifiedReportModel.fromFirestore(await docRef.get()),
    );
    await docRef.update({
      'confidence': confidenceResult.confidence,
      'confidenceReasons': confidenceResult.reasons,
    });

    // Otorgar puntos al usuario
    final gamificationService = GamificationService();
    await gamificationService.awardPointsForSimplifiedReport(
      userId: userId,
      points: basePoints + bonusPoints,
      stationId: stationId,
      reportId: docRef.id,
    );

    return docRef.id;
  }

  /// Crear reporte de estación con problemas específicos (nuevo sistema detallado)
  /// Retorna lista de IDs de reportes creados: [generalReportId, issue1Id, issue2Id, ...]
  Future<List<String>> createStationReportWithIssues({
    required String stationId,
    required String operational,
    required int crowdLevel,
    List<SpecificIssue>? specificIssues,
    Position? userPosition,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Usuario no autenticado');

    final reportIds = <String>[];
    final now = DateTime.now();

    // 1. Crear reporte general (siempre se crea)
    final basePoints = 15;
    final bonusPoints =
        0; // En el nuevo sistema, los puntos bonus vienen de cada problema específico

    final generalReport = SimplifiedReportModel(
      id: '',
      scope: 'station',
      stationId: stationId,
      userId: userId,
      stationOperational: operational,
      stationCrowd: crowdLevel,
      isSpecificIssue: false,
      createdAt: now,
      basePoints: basePoints,
      bonusPoints: bonusPoints,
      totalPoints: basePoints + bonusPoints,
      userLocation: userPosition != null
          ? GeoPoint(userPosition.latitude, userPosition.longitude)
          : null,
      accuracy: userPosition?.accuracy,
    );

    final generalDocRef =
        await _firestore.collection('reports').add(generalReport.toFirestore());
    await generalDocRef.update({'id': generalDocRef.id});

    // Calcular y guardar confianza inicial para reporte general
    final confidenceService = SimplifiedReportConfidenceService();
    final generalConfidence = await confidenceService.calculateConfidence(
      SimplifiedReportModel.fromFirestore(await generalDocRef.get()),
    );
    await generalDocRef.update({
      'confidence': generalConfidence.confidence,
      'confidenceReasons': generalConfidence.reasons,
    });

    reportIds.add(generalDocRef.id);

    // 2. Crear un reporte separado por cada problema específico
    if (specificIssues != null && specificIssues.isNotEmpty) {
      for (final issue in specificIssues) {
        final issueReportId = await _createSpecificIssueReport(
          stationId: stationId,
          parentReportId: generalDocRef.id,
          issue: issue,
          userPosition: userPosition,
          userId: userId,
          now: now,
        );
        reportIds.add(issueReportId);
      }
    }

    // 3. Otorgar puntos al usuario (total de todos los reportes)
    final gamificationService = GamificationService();
    final totalIssuePoints =
        (specificIssues?.length ?? 0) * 10; // 10 puntos por problema específico
    final totalPoints = basePoints + totalIssuePoints;

    await gamificationService.awardPointsForSimplifiedReport(
      userId: userId,
      points: totalPoints,
      stationId: stationId,
      reportId: generalDocRef.id,
    );

    return reportIds;
  }

  /// Método privado para crear un reporte de problema específico
  Future<String> _createSpecificIssueReport({
    required String stationId,
    required String parentReportId,
    required SpecificIssue issue,
    required Position? userPosition,
    required String userId,
    required DateTime now,
  }) async {
    final basePoints = 10; // 10 puntos por reportar un problema específico

    final issueReport = SimplifiedReportModel(
      id: '',
      scope: 'station',
      stationId: stationId,
      userId: userId,
      issueType: issue.type,
      issueLocation: issue.location,
      issueStatus: issue.status,
      parentReportId: parentReportId,
      isSpecificIssue: true,
      createdAt: now,
      basePoints: basePoints,
      bonusPoints: 0,
      totalPoints: basePoints,
      userLocation: userPosition != null
          ? GeoPoint(userPosition.latitude, userPosition.longitude)
          : null,
      accuracy: userPosition?.accuracy,
    );

    final docRef =
        await _firestore.collection('reports').add(issueReport.toFirestore());
    await docRef.update({'id': docRef.id});

    // Calcular y guardar confianza inicial
    final confidenceService = SimplifiedReportConfidenceService();
    final confidenceResult = await confidenceService.calculateConfidence(
      SimplifiedReportModel.fromFirestore(await docRef.get()),
    );
    await docRef.update({
      'confidence': confidenceResult.confidence,
      'confidenceReasons': confidenceResult.reasons,
    });

    return docRef.id;
  }

  /// Crear reporte de tren (simplificado)
  Future<String> createTrainReport({
    required String stationId,
    required String
        etaBucket, // '1-2' | '3-5' | '6-8' | '9+' | 'unknown' (tiempo del panel)
    required int crowdLevel, // 1-5
    List<String>? issues, // ['recharge', 'atm', 'ac', 'escalator', 'elevator']
    String? trainLine, // 'L1' | 'L2' (opcional)
    String? direction, // 'A' | 'B' (opcional)
    Position? userPosition, // Opcional
    bool? isPanelTime, // true si el tiempo viene del panel digital oficial
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Usuario no autenticado');

    final now = DateTime.now();

    // Calcular etaExpectedAt basado en el bucket (punto medio del rango)
    DateTime? etaExpectedAt;
    if (etaBucket != 'unknown') {
      final timingConfig = {
        '1-2': 1.5, // minutos (punto medio de 1-2)
        '3-5': 4.0, // minutos (punto medio de 3-5)
        '6-8': 7.0, // minutos (punto medio de 6-8)
        '9+': 10.0, // minutos (estimación conservadora)
      };
      final minutes = timingConfig[etaBucket] ?? 4.0;
      etaExpectedAt = now.add(Duration(minutes: minutes.toInt()));
    }

    // Sistema de puntos: 10 base por copiar panel + 5 por cada problema
    final basePoints = 10;
    final bonusPoints = (issues?.length ?? 0) * 5;
    // Nota: +20 puntos adicionales se otorgan cuando el usuario valida la llegada

    final report = SimplifiedReportModel(
      id: '',
      scope: 'train',
      stationId: stationId,
      userId: userId,
      trainCrowd: crowdLevel,
      trainIssues: issues ?? [],
      trainLine: trainLine,
      direction: direction,
      etaBucket: etaBucket,
      etaExpectedAt: etaExpectedAt,
      isPanelTime:
          isPanelTime ?? false, // Marcar si viene del panel digital oficial
      createdAt: now,
      basePoints: basePoints,
      bonusPoints: bonusPoints,
      totalPoints: basePoints + bonusPoints,
      userLocation: userPosition != null
          ? GeoPoint(userPosition.latitude, userPosition.longitude)
          : null,
      accuracy: userPosition?.accuracy,
    );

    final docRef =
        await _firestore.collection('reports').add(report.toFirestore());
    await docRef.update({'id': docRef.id});

    // Calcular y guardar confianza inicial
    final confidenceService = SimplifiedReportConfidenceService();
    final confidenceResult = await confidenceService.calculateConfidence(
      SimplifiedReportModel.fromFirestore(await docRef.get()),
    );
    await docRef.update({
      'confidence': confidenceResult.confidence,
      'confidenceReasons': confidenceResult.reasons,
    });

    // Otorgar puntos al usuario
    final gamificationService = GamificationService();
    await gamificationService.awardPointsForSimplifiedReport(
      userId: userId,
      points: basePoints + bonusPoints,
      stationId: stationId,
      reportId: docRef.id,
    );

    return docRef.id;
  }

  /// Actualizar reporte de tren cuando llega (completa con ocupación y estado)
  /// Calcula el error del panel y otorga puntos basados en precisión
  Future<void> updateTrainReportOnArrival({
    required String reportId,
    required DateTime arrivalTime,
    int? crowdLevel, // 1-5 (opcional)
    String? trainStatus, // 'normal' | 'slow' | 'stopped' (opcional)
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Usuario no autenticado');

    try {
      final reportDoc =
          await _firestore.collection('reports').doc(reportId).get();
      if (!reportDoc.exists) {
        throw Exception('Reporte no encontrado');
      }

      final report = SimplifiedReportModel.fromFirestore(reportDoc);

      // Verificar que el reporte pertenece al usuario
      if (report.userId != userId) {
        throw Exception('No tienes permiso para actualizar este reporte');
      }

      // Calcular error del panel si hay etaExpectedAt
      int? errorMinutes;
      int precisionBonus = 0;
      if (report.etaExpectedAt != null && report.isPanelTime == true) {
        final error = arrivalTime.difference(report.etaExpectedAt!).inMinutes;
        errorMinutes = error;

        // Sistema de puntos por precisión:
        // ±1 min = +15 puntos (panel preciso)
        // ±2-3 min = +5 puntos (error pequeño)
        // Mayor error = +0 puntos (pero igual ayuda al sistema)
        final absError = error.abs();
        if (absError <= 1) {
          precisionBonus = 15;
        } else if (absError <= 3) {
          precisionBonus = 5;
        }
      }

      // Actualizar el reporte con la hora de llegada y datos adicionales
      final updates = <String, dynamic>{
        'arrivalTime': Timestamp.fromDate(arrivalTime),
      };

      if (crowdLevel != null) {
        updates['trainCrowd'] = crowdLevel;
      }

      if (trainStatus != null) {
        updates['trainStatus'] = trainStatus;
      }

      // Actualizar puntos: +20 base por validar + bonus por precisión
      final validationPoints = 20;
      final newBonusPoints = (report.bonusPoints) + precisionBonus;
      final newTotalPoints =
          report.basePoints + validationPoints + newBonusPoints;

      updates['bonusPoints'] = newBonusPoints;
      updates['totalPoints'] = newTotalPoints;

      await _firestore.collection('reports').doc(reportId).update(updates);

      // Otorgar puntos adicionales al usuario (20 + bonus precisión)
      final gamificationService = GamificationService();
      await gamificationService.awardPointsForArrivalValidation(
        userId: userId,
        additionalPoints: validationPoints + precisionBonus,
        stationId: report.stationId,
      );

      // Actualizar calibración de la estación si es reporte del panel
      if (report.isPanelTime == true && errorMinutes != null) {
        await _updateStationCalibration(
          report.stationId,
          errorMinutes,
          report.etaBucket ?? 'unknown',
        );
      }
    } catch (e) {
      print('Error updating train report on arrival: $e');
      rethrow;
    }
  }

  /// Actualizar calibración del panel por estación
  Future<void> _updateStationCalibration(
    String stationId,
    int errorMinutes,
    String etaBucket,
  ) async {
    try {
      final stationRef = _firestore.collection('stations').doc(stationId);
      final calibrationRef =
          stationRef.collection('panelCalibration').doc('latest');

      final calibrationDoc = await calibrationRef.get();
      final now = DateTime.now();

      if (calibrationDoc.exists) {
        final data = calibrationDoc.data()!;
        final totalReports = (data['totalReports'] ?? 0) + 1;
        final currentAvgError = (data['avgError'] ?? 0.0).toDouble();
        final newAvgError =
            ((currentAvgError * (totalReports - 1)) + errorMinutes) /
                totalReports;

        // Calcular precisión (porcentaje de reportes con error ≤ 1 minuto)
        final accurateReports =
            (data['accurateReports'] ?? 0) + (errorMinutes.abs() <= 1 ? 1 : 0);
        final accuracy = (accurateReports / totalReports) * 100;

        await calibrationRef.update({
          'totalReports': totalReports,
          'avgError': newAvgError,
          'accurateReports': accurateReports,
          'accuracy': accuracy,
          'lastUpdated': Timestamp.fromDate(now),
          'lastError': errorMinutes,
        });
      } else {
        // Crear nueva calibración
        await calibrationRef.set({
          'totalReports': 1,
          'avgError': errorMinutes.toDouble(),
          'accurateReports': errorMinutes.abs() <= 1 ? 1 : 0,
          'accuracy': errorMinutes.abs() <= 1 ? 100.0 : 0.0,
          'lastUpdated': Timestamp.fromDate(now),
          'lastError': errorMinutes,
          'createdAt': Timestamp.fromDate(now),
        });
      }
    } catch (e) {
      print('Error updating station calibration: $e');
      // No lanzar error, solo loggear - la calibración es opcional
    }
  }

  /// Crear reporte directo de llegada (sin ETA previo) - 15 puntos
  Future<String> createDirectArrivalReport({
    required String stationId,
    required DateTime arrivalTime,
    int? crowdLevel, // 1-5 (opcional)
    String? trainStatus, // 'normal' | 'slow' | 'stopped' (opcional)
    String? trainLine, // 'L1' | 'L2' (opcional)
    String? direction, // 'A' | 'B' (opcional)
    Position? userPosition, // Opcional
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Usuario no autenticado');

    final now = DateTime.now();
    final basePoints = 15; // Reporte directo de llegada
    final bonusPoints = 0;

    final report = SimplifiedReportModel(
      id: '',
      scope: 'train',
      stationId: stationId,
      userId: userId,
      trainCrowd: crowdLevel,
      trainStatus: trainStatus,
      etaBucket: null, // Sin ETA previo
      etaExpectedAt: null,
      arrivalTime: arrivalTime,
      trainLine: trainLine,
      direction: direction,
      createdAt: now,
      basePoints: basePoints,
      bonusPoints: bonusPoints,
      totalPoints: basePoints + bonusPoints,
      userLocation: userPosition != null
          ? GeoPoint(userPosition.latitude, userPosition.longitude)
          : null,
      accuracy: userPosition?.accuracy,
    );

    final docRef =
        await _firestore.collection('reports').add(report.toFirestore());
    await docRef.update({'id': docRef.id});

    // Calcular y guardar confianza inicial
    final confidenceService = SimplifiedReportConfidenceService();
    final confidenceResult = await confidenceService.calculateConfidence(
      SimplifiedReportModel.fromFirestore(await docRef.get()),
    );
    await docRef.update({
      'confidence': confidenceResult.confidence,
      'confidenceReasons': confidenceResult.reasons,
    });

    // Otorgar puntos al usuario
    final gamificationService = GamificationService();
    await gamificationService.awardPointsForSimplifiedReport(
      userId: userId,
      points: basePoints + bonusPoints,
      stationId: stationId,
      reportId: docRef.id,
    );

    return docRef.id;
  }

  /// Obtener reporte pendiente del usuario (con ETA pero sin arrivalTime)
  Future<SimplifiedReportModel?> getPendingTrainReport(String stationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    try {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));

      final snapshot = await _firestore
          .collection('reports')
          .where('userId', isEqualTo: userId)
          .where('stationId', isEqualTo: stationId)
          .where('scope', isEqualTo: 'train')
          .where('status', isEqualTo: 'active')
          .get();

      // Buscar reporte con ETA pero sin arrivalTime, creado en la última hora
      for (var doc in snapshot.docs) {
        try {
          final report = SimplifiedReportModel.fromFirestore(doc);
          if (report.etaBucket != null &&
              report.etaBucket != 'unknown' &&
              report.arrivalTime == null &&
              report.createdAt.isAfter(oneHourAgo)) {
            return report;
          }
        } catch (e) {
          print('Error parsing report ${doc.id}: $e');
        }
      }

      return null;
    } catch (e) {
      print('Error getting pending train report: $e');
      return null;
    }
  }

  /// Obtener reporte por ID
  Future<SimplifiedReportModel?> getReport(String reportId) async {
    try {
      final doc = await _firestore.collection('reports').doc(reportId).get();
      if (doc.exists) {
        return SimplifiedReportModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting report: $e');
      return null;
    }
  }

  /// Enviar validación ETA
  Future<Map<String, dynamic>> submitETAValidation({
    required String reportId,
    required String
        validationResult, // 'arrived' | 'not_arrived' | 'cant_confirm'
    DateTime? actualArrivalTime,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Usuario no autenticado');

    try {
      // Llamar a Cloud Function
      final callable =
          FirebaseFunctions.instance.httpsCallable('processValidationResponse');
      final callResult = await callable.call({
        'reportId': reportId,
        'result': validationResult,
        'actualArrivalTime': actualArrivalTime?.toIso8601String(),
      });

      return callResult.data as Map<String, dynamic>;
    } catch (e) {
      print('Error submitting validation: $e');
      rethrow;
    }
  }

  /// Obtener reportes recientes de una estación
  Future<List<SimplifiedReportModel>> getRecentStationReports(
    String stationId, {
    int limit = 10,
    DateTime? since,
  }) async {
    try {
      final cutoffDate =
          since ?? DateTime.now().subtract(const Duration(hours: 1));

      // Consulta sin orderBy para evitar índice compuesto
      final snapshot = await _firestore
          .collection('reports')
          .where('stationId', isEqualTo: stationId)
          .where('scope', isEqualTo: 'station')
          .where('status', isEqualTo: 'active')
          .get();

      // Filtrar por fecha y ordenar en memoria
      final reports = snapshot.docs
          .map((doc) => SimplifiedReportModel.fromFirestore(doc))
          .where((report) => report.createdAt.isAfter(cutoffDate))
          .toList();

      // Ordenar por fecha (más reciente primero) y limitar
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reports.take(limit).toList();
    } catch (e) {
      print('Error getting recent reports: $e');
      return [];
    }
  }

  /// Stream de reportes del usuario actual
  Stream<List<SimplifiedReportModel>> getUserReportsStream(String userId) {
    return _firestore
        .collection('reports')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final reports = snapshot.docs
          .map((doc) {
            try {
              return SimplifiedReportModel.fromFirestore(doc);
            } catch (e) {
              print('Error parsing report ${doc.id}: $e');
              return null;
            }
          })
          .whereType<SimplifiedReportModel>()
          .toList();

      // Ordenar en memoria por fecha (más reciente primero)
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reports;
    });
  }

  /// Obtener reportes recientes de trenes para una estación
  Future<List<SimplifiedReportModel>> getRecentTrainReports(
    String stationId, {
    int limit = 10,
    DateTime? since,
  }) async {
    try {
      final cutoffDate =
          since ?? DateTime.now().subtract(const Duration(hours: 1));

      // Consulta sin orderBy para evitar índice compuesto
      final snapshot = await _firestore
          .collection('reports')
          .where('stationId', isEqualTo: stationId)
          .where('scope', isEqualTo: 'train')
          .where('status', isEqualTo: 'active')
          .get();

      // Filtrar por fecha y ordenar en memoria
      final reports = snapshot.docs
          .map((doc) => SimplifiedReportModel.fromFirestore(doc))
          .where((report) => report.createdAt.isAfter(cutoffDate))
          .toList();

      // Ordenar por fecha (más reciente primero) y limitar
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reports.take(limit).toList();
    } catch (e) {
      print('Error getting recent train reports: $e');
      return [];
    }
  }

  /// Stream de reportes activos (todos los usuarios)
  /// Filtra reportes muy antiguos (más de 15 minutos) para eficiencia
  /// Solo filtra por status en Firestore para evitar problemas de índice compuesto
  Stream<List<SimplifiedReportModel>> getActiveReportsStream() {
    final cutoffTime = DateTime.now().subtract(const Duration(minutes: 15));

    return _firestore
        .collection('reports')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final reports = snapshot.docs
          .map((doc) {
            try {
              final report = SimplifiedReportModel.fromFirestore(doc);

              // Filtrar reportes muy antiguos en memoria (más de 15 minutos)
              if (report.createdAt.isBefore(cutoffTime)) {
                return null;
              }

              // Validar expiración de ETAs futuros
              // Si tiene etaExpectedAt pero ya pasó y no tiene arrivalTime, excluirlo
              if (report.etaExpectedAt != null &&
                  report.arrivalTime == null &&
                  now.isAfter(
                      report.etaExpectedAt!.add(const Duration(minutes: 5)))) {
                // ETA expirado (más de 5 min después del tiempo esperado)
                return null;
              }

              return report;
            } catch (e) {
              print('Error parsing report ${doc.id}: $e');
              return null;
            }
          })
          .whereType<SimplifiedReportModel>()
          .toList();

      // Ordenar en memoria por fecha (más reciente primero) y limitar a 100
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reports.take(100).toList();
    });
  }

  /// Stream de reportes activos para confirmar (sin filtro de tiempo ni límite de cantidad)
  /// Usado en la pantalla de confirmar reportes para mostrar TODOS los reportes activos
  /// Obtiene todos los reportes y filtra en memoria para compatibilidad
  /// con reportes que pueden tener 'status' o 'estado' o ninguno
  Stream<List<SimplifiedReportModel>> getReportsForConfirmationStream() {
    return _firestore
        .collection('reports')
        .snapshots() // Sin filtro en Firestore para obtener todos
        .map((snapshot) {
      // Note: 'now' removed as it was unused
      final logService = DebugLogService();
      logService.addLog(
        'ReportsStream',
        '${snapshot.docs.length} documentos recibidos de Firestore',
        level: LogLevel.info,
      );

      final reports = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();

              // Filtrar reportes eliminados o resueltos
              final status = data['status'] as String?;
              final estado = data['estado'] as String?;

              // Si tiene status y no es 'active', saltarlo
              if (status != null && status != 'active') {
                logService.addLog(
                  'ReportsStream',
                  'Reporte ${doc.id} filtrado: status=$status (no es active)',
                  level: LogLevel.info,
                );
                return null;
              }

              // Si tiene estado (sistema viejo) y no es 'activo', saltarlo
              if (estado != null && estado != 'activo') {
                logService.addLog(
                  'ReportsStream',
                  'Reporte ${doc.id} filtrado: estado=$estado (no es activo)',
                  level: LogLevel.info,
                );
                return null;
              }

              // Si no tiene ni status ni estado, asumir que está activo (compatibilidad)
              // o si tiene status='active' o estado='activo', incluirlo

              final report = SimplifiedReportModel.fromFirestore(doc);
              // No filtrar por ETAs expirados - mostrar todos los reportes activos
              // para que puedan ser confirmados por otros usuarios
              logService.addLog(
                'ReportsStream',
                'Reporte ${doc.id} incluido: scope=${report.scope}, status=${report.status}',
                level: LogLevel.success,
              );
              return report;
            } catch (e, stackTrace) {
              logService.addLog(
                'ReportsStream',
                'Error parsing report ${doc.id}: $e\nStack trace: $stackTrace',
                level: LogLevel.error,
              );
              return null;
            }
          })
          .whereType<SimplifiedReportModel>()
          .toList();

      logService.addLog(
        'ReportsStream',
        'Total reportes válidos después del filtrado: ${reports.length}',
        level: LogLevel.info,
      );

      // Ordenar en memoria por fecha (más reciente primero) - sin límite de cantidad
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reports;
    });
  }

  /// Limpia reportes obsoletos marcándolos como 'resolved'
  /// Reportes con arrivalTime > 15 min o ETAs expirados > 20 min
  Future<int> cleanupOldReports() async {
    try {
      final now = DateTime.now();
      final cutoffTime = now.subtract(const Duration(minutes: 15));
      // Note: etaExpiredTime removed as unused - inline calculations use Duration directly

      // Buscar reportes obsoletos
      final oldReportsQuery = await _firestore
          .collection('reports')
          .where('status', isEqualTo: 'active')
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffTime))
          .limit(50) // Procesar en lotes
          .get();

      int cleanedCount = 0;
      final batch = _firestore.batch();

      for (final doc in oldReportsQuery.docs) {
        try {
          final report = SimplifiedReportModel.fromFirestore(doc);

          bool shouldClean = false;

          // Caso 1: Reporte con arrivalTime muy antiguo (>15 min)
          if (report.arrivalTime != null) {
            final ageMin = now.difference(report.arrivalTime!).inMinutes;
            if (ageMin > 15) {
              shouldClean = true;
            }
          }
          // Caso 2: ETA futuro expirado (etaExpectedAt pasó hace >20 min y no tiene arrivalTime)
          else if (report.etaExpectedAt != null && report.arrivalTime == null) {
            if (now.isAfter(
                report.etaExpectedAt!.add(const Duration(minutes: 20)))) {
              shouldClean = true;
            }
          }
          // Caso 3: Reporte muy antiguo sin arrivalTime ni etaExpectedAt (>15 min desde creación)
          else {
            final ageMin = now.difference(report.createdAt).inMinutes;
            if (ageMin > 15) {
              shouldClean = true;
            }
          }

          if (shouldClean) {
            batch.update(doc.reference, {'status': 'resolved'});
            cleanedCount++;
          }
        } catch (e) {
          print('Error processing report ${doc.id} for cleanup: $e');
        }
      }

      if (cleanedCount > 0) {
        await batch.commit();
        print('🧹 Limpiados $cleanedCount reportes obsoletos');
      }

      return cleanedCount;
    } catch (e) {
      print('Error en cleanupOldReports: $e');
      return 0;
    }
  }

  /// Inicia el timer de limpieza automática
  void startAutoCleanup() {
    // Cancelar timer existente si hay uno
    _cleanupTimer?.cancel();

    // Ejecutar limpieza inmediatamente la primera vez
    cleanupOldReports().catchError((e) {
      print('Error en limpieza automática inicial: $e');
      return 0;
    });

    // Configurar timer periódico
    _cleanupTimer = Timer.periodic(_cleanupInterval, (timer) {
      cleanupOldReports().catchError((e) {
        print('Error en limpieza automática periódica: $e');
        return 0;
      });
    });

    print(
        '🧹 Limpieza automática de reportes iniciada (cada ${_cleanupInterval.inMinutes} min)');
  }

  /// Detiene el timer de limpieza automática
  void stopAutoCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    print('🧹 Limpieza automática de reportes detenida');
  }

  /// Dispose: cancelar timer al destruir el servicio
  void dispose() {
    stopAutoCleanup();
  }
}
