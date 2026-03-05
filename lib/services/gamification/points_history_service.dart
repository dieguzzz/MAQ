import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/points_transaction_model.dart';
import '../../core/logger.dart';

class PointsHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Guarda una transacción de puntos en el historial
  Future<void> saveTransaction({
    required String userId,
    required int points,
    required String type,
    required String description,
    String? reportId,
    String? relatedUserId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final transactionRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('points_history')
          .doc();

      await transactionRef.set({
        'points': points,
        'type': type,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
        if (reportId != null) 'report_id': reportId,
        if (relatedUserId != null) 'related_user_id': relatedUserId,
        if (metadata != null) 'metadata': metadata,
      });
    } catch (e) {
      AppLogger.error('Error saving points transaction: $e');
      // No lanzar error para no interrumpir el flujo principal
    }
  }

  /// Obtiene el historial de puntos del usuario
  Stream<List<PointsTransaction>> getPointsHistory(String userId,
      {int limit = 50}) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('points_history')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PointsTransaction.fromFirestore(doc))
            .toList());
  }

  /// Obtiene el historial de puntos del usuario de forma asíncrona
  Future<List<PointsTransaction>> getPointsHistoryOnce(String userId,
      {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('points_history')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => PointsTransaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting points history: $e');
      return [];
    }
  }

  /// Obtiene estadísticas de puntos por tipo
  Future<Map<String, int>> getPointsByType(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('points_history')
          .get();

      final Map<String, int> pointsByType = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type'] ?? 'unknown';
        final pointsValue = data['points'];
        final points = pointsValue is int
            ? pointsValue
            : (pointsValue as num?)?.toInt() ?? 0;
        pointsByType[type] = (pointsByType[type] ?? 0) + points;
      }
      return pointsByType;
    } catch (e) {
      AppLogger.error('Error getting points by type: $e');
      return {};
    }
  }
}
