import 'package:cloud_firestore/cloud_firestore.dart';

class PointsTransaction {
  final String id;
  final int points; // Puntos ganados (positivo) o perdidos (negativo)
  final String type; // Tipo de transacción
  final String description; // Descripción de la transacción
  final DateTime timestamp;
  final String? reportId; // ID del reporte relacionado (opcional)
  final String? relatedUserId; // ID de usuario relacionado (opcional)
  final Map<String, dynamic>? metadata; // Datos adicionales

  PointsTransaction({
    required this.id,
    required this.points,
    required this.type,
    required this.description,
    required this.timestamp,
    this.reportId,
    this.relatedUserId,
    this.metadata,
  });

  factory PointsTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PointsTransaction(
      id: doc.id,
      points: data['points'] ?? 0,
      type: data['type'] ?? 'unknown',
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reportId: data['report_id'] as String?,
      relatedUserId: data['related_user_id'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'points': points,
      'type': type,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      if (reportId != null) 'report_id': reportId,
      if (relatedUserId != null) 'related_user_id': relatedUserId,
      if (metadata != null) 'metadata': metadata,
    };
  }

  // Tipos de transacción
  static const String typeReportVerified = 'report_verified';
  static const String typeConfirmReport = 'confirm_report';
  static const String typeStreak = 'streak';
  static const String typeEpicReport = 'epic_report';
  static const String typeTeachingReport = 'teaching_report';
  static const String typeBadge = 'badge';
}

