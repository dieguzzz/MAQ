import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/enhanced_report_model.dart';
import 'firebase_service.dart';

/// Servicio mejorado para manejar reportes con validaciones ETA
class EnhancedReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();

  /// Crear reporte de estación
  Future<String> createStationReport({
    required String stationId,
    required String operational, // 'yes' | 'partial' | 'no'
    required int crowdLevel, // 1-5
    List<String>? issues,
    required GeoPoint userLocation,
    double accuracy = 0.0,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Usuario no autenticado');

    final now = DateTime.now();
    final expiresAt = now.add(const Duration(minutes: 25));

    final report = EnhancedReportModel(
      id: '', // Se generará automáticamente
      scope: 'station',
      stationId: stationId,
      userId: userId,
      createdAt: now,
      updatedAt: now,
      expiresAt: expiresAt,
      status: 'active',
      basePoints: 15, // Puntos base por reporte de estación
      bonusPoints: (issues?.length ?? 0) * 5, // +5 por problema
      totalPoints: 15 + ((issues?.length ?? 0) * 5),
      stationData: StationReportData(
        operational: operational,
        crowdLevel: crowdLevel,
        issues: issues ?? [],
        issuesCount: issues?.length ?? 0,
      ),
      userLocation: userLocation,
      accuracy: accuracy,
      userConfidence: 0.5, // Se calculará desde el perfil del usuario
      confidence: 0.5, // Se calculará por Cloud Function
    );

    final docRef = await _firestore.collection('reports').add(report.toFirestore());
    
    // Actualizar ID del reporte
    await docRef.update({'id': docRef.id});

    return docRef.id;
  }

  /// Crear reporte de tren
  Future<String> createTrainReport({
    required String stationId,
    required int crowdLevel, // 1-5
    required String trainStatus, // 'normal' | 'slow' | 'stopped' | 'express'
    required String etaBucket, // '<1' | '1-2' | '3-5' | '6-10' | '10+' | 'unknown'
    String trainType = 'normal',
    required GeoPoint userLocation,
    double accuracy = 0.0,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Usuario no autenticado');

    final now = DateTime.now();
    final expiresAt = now.add(const Duration(minutes: 25));

    final report = EnhancedReportModel(
      id: '',
      scope: 'train',
      stationId: stationId,
      userId: userId,
      createdAt: now,
      updatedAt: now,
      expiresAt: expiresAt,
      status: 'active',
      basePoints: 20, // Puntos base por reporte de tren
      bonusPoints: etaBucket != 'unknown' ? 10 : 0, // +10 si estimó tiempo
      totalPoints: 20 + (etaBucket != 'unknown' ? 10 : 0),
      trainData: TrainReportData(
        crowdLevel: crowdLevel,
        trainStatus: trainStatus,
        trainType: trainType,
        etaBucket: etaBucket,
        needsValidation: etaBucket != 'unknown',
        validationStatus: etaBucket != 'unknown' ? 'pending' : 'expired',
      ),
      userLocation: userLocation,
      accuracy: accuracy,
      userConfidence: 0.5,
      confidence: 0.5,
    );

    final docRef = await _firestore.collection('reports').add(report.toFirestore());
    await docRef.update({'id': docRef.id});

    return docRef.id;
  }

  /// Obtener reporte por ID
  Future<EnhancedReportModel?> getReport(String reportId) async {
    try {
      final doc = await _firestore.collection('reports').doc(reportId).get();
      if (doc.exists) {
        return EnhancedReportModel.fromFirestore(doc);
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

    // Llamar a Cloud Function
    try {
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
  Future<List<EnhancedReportModel>> getRecentStationReports(
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
          .map((doc) => EnhancedReportModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting recent reports: $e');
      return [];
    }
  }

  /// Obtener reportes pendientes de validación del usuario actual
  Stream<List<EnhancedReportModel>> getPendingValidations() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('reports')
        .where('userId', isEqualTo: userId)
        .where('scope', isEqualTo: 'train')
        .where('trainData.needsValidation', isEqualTo: true)
        .where('trainData.validationStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EnhancedReportModel.fromFirestore(doc))
            .toList());
  }
}
