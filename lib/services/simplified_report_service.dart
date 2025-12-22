import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../models/simplified_report_model.dart';
import 'firebase_service.dart';

/// Servicio simplificado para reportes según nuevo diseño
class SimplifiedReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

    final docRef = await _firestore.collection('reports').add(report.toFirestore());
    await docRef.update({'id': docRef.id});

    return docRef.id;
  }

  /// Crear reporte de tren (simplificado)
  Future<String> createTrainReport({
    required String stationId,
    required String operational, // 'yes' | 'partial' | 'no'
    required int crowdLevel, // 1-5
    List<String>? issues, // ['recharge', 'atm', 'ac', 'escalator', 'elevator']
    String? trainLine, // 'L1' | 'L2' (opcional)
    String? direction, // 'A' | 'B' (opcional)
    Position? userPosition, // Opcional
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Usuario no autenticado');

    final now = DateTime.now();
    final basePoints = 15;
    final bonusPoints = (issues?.length ?? 0) * 5;

    final report = SimplifiedReportModel(
      id: '',
      scope: 'train',
      stationId: stationId,
      userId: userId,
      trainOperational: operational,
      trainCrowd: crowdLevel,
      trainIssues: issues ?? [],
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

    final docRef = await _firestore.collection('reports').add(report.toFirestore());
    await docRef.update({'id': docRef.id});

    return docRef.id;
  }

  /// Actualizar reporte de tren cuando llega (completa con ocupación y estado)
  Future<void> updateTrainReportOnArrival({
    required String reportId,
    required DateTime arrivalTime,
    int? crowdLevel, // 1-5 (opcional)
    String? trainStatus, // 'normal' | 'slow' | 'stopped' (opcional)
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Usuario no autenticado');

    try {
      final reportDoc = await _firestore.collection('reports').doc(reportId).get();
      if (!reportDoc.exists) {
        throw Exception('Reporte no encontrado');
      }

      final report = SimplifiedReportModel.fromFirestore(reportDoc);
      
      // Verificar que el reporte pertenece al usuario
      if (report.userId != userId) {
        throw Exception('No tienes permiso para actualizar este reporte');
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

      await _firestore.collection('reports').doc(reportId).update(updates);
    } catch (e) {
      print('Error updating train report on arrival: $e');
      rethrow;
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

    final docRef = await _firestore.collection('reports').add(report.toFirestore());
    await docRef.update({'id': docRef.id});

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
    required String validationResult, // 'arrived' | 'not_arrived' | 'cant_confirm'
    DateTime? actualArrivalTime,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Usuario no autenticado');

    try {
      // Llamar a Cloud Function
      final callable = FirebaseFunctions.instance.httpsCallable('processValidationResponse');
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
      final cutoffDate = since ?? DateTime.now().subtract(const Duration(hours: 1));

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
      final cutoffDate = since ?? DateTime.now().subtract(const Duration(hours: 1));

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
  Stream<List<SimplifiedReportModel>> getActiveReportsStream() {
    return _firestore
        .collection('reports')
        .where('status', isEqualTo: 'active')
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
      
      // Ordenar en memoria por fecha (más reciente primero) y limitar a 100
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reports.take(100).toList();
    });
  }
}
