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
    required int crowdLevel, // 1-5
    String? trainStatus, // 'normal' | 'slow' | 'stopped' (opcional)
    String? etaBucket, // '1-2' | '3-5' | '6-8' | '9+' | 'unknown' (opcional)
    String? trainLine, // 'L1' | 'L2' (opcional)
    String? direction, // 'A' | 'B' (opcional)
    Position? userPosition, // Opcional
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Usuario no autenticado');

    final now = DateTime.now();
    final basePoints = 20;
    final bonusPoints = etaBucket != null && etaBucket != 'unknown' ? 10 : 0;

    // Calcular etaExpectedAt si hay bucket
    DateTime? etaExpectedAt;
    if (etaBucket != null && etaBucket != 'unknown') {
      final timingConfig = {
        '1-2': 1.5, // minutos
        '3-5': 4,
        '6-8': 7,
        '9+': 10,
      };
      final minutes = timingConfig[etaBucket] ?? 4;
      etaExpectedAt = now.add(Duration(minutes: minutes.toInt()));
    }

    final report = SimplifiedReportModel(
      id: '',
      scope: 'train',
      stationId: stationId,
      userId: userId,
      trainCrowd: crowdLevel,
      trainStatus: trainStatus ?? 'normal',
      etaBucket: etaBucket,
      etaExpectedAt: etaExpectedAt,
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
  }) async {
    try {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));

      final snapshot = await _firestore
          .collection('reports')
          .where('stationId', isEqualTo: stationId)
          .where('scope', isEqualTo: 'station')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(oneHourAgo))
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => SimplifiedReportModel.fromFirestore(doc))
          .toList();
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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
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
    });
  }

  /// Stream de reportes activos (todos los usuarios)
  Stream<List<SimplifiedReportModel>> getActiveReportsStream() {
    return _firestore
        .collection('reports')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
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
    });
  }
}
