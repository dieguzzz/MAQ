import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo simplificado de reporte según nuevo diseño
class SimplifiedReportModel {
  final String id;
  final String scope; // 'station' | 'train'
  final String stationId;
  final String userId;
  final String? trainLine; // 'L1' | 'L2' | null
  final String? direction; // 'A' | 'B' | null
  
  // Station core (solo si scope === 'station')
  final String? stationOperational; // 'yes' | 'partial' | 'no' | null
  final int? stationCrowd; // 1..5 | null
  final List<String> stationIssues; // ['recharge', 'atm', 'ac', 'escalator', 'elevator'] | []
  
  // Train core (solo si scope === 'train')
  final String? trainOperational; // 'yes' | 'partial' | 'no' | null
  final int? trainCrowd; // 1..5 | null
  final List<String> trainIssues; // ['recharge', 'atm', 'ac', 'escalator', 'elevator'] | []
  final String? trainStatus; // 'normal' | 'slow' | 'stopped' | null
  
  // ETA reported (solo si scope === 'train')
  final String? etaBucket; // '1-2' | '3-5' | '6-8' | '9+' | 'unknown' | null
  final DateTime? etaExpectedAt; // server-side: now + bucket mid-point
  final DateTime? arrivalTime; // Hora exacta cuando el tren llegó
  final bool? isPanelTime; // true si el tiempo viene del panel digital oficial
  
  // Metadata
  final DateTime createdAt;
  final String status; // 'active' | 'resolved' | 'rejected'
  final int confirmations;
  final double confidence; // 0..1
  final List<String> confidenceReasons; // ['panel', '3_confirms', 'fresh', 'high_precision_author', 'new_user']
  
  // Puntos
  final int basePoints;
  final int bonusPoints;
  final int totalPoints;
  
  // Ubicación (opcional)
  final GeoPoint? userLocation;
  final double? accuracy;

  SimplifiedReportModel({
    required this.id,
    required this.scope,
    required this.stationId,
    required this.userId,
    this.trainLine,
    this.direction,
    this.stationOperational,
    this.stationCrowd,
    this.stationIssues = const [],
    this.trainOperational,
    this.trainCrowd,
    this.trainIssues = const [],
    this.trainStatus,
    this.etaBucket,
    this.etaExpectedAt,
    this.arrivalTime,
    this.isPanelTime,
    required this.createdAt,
    this.status = 'active',
    this.confirmations = 0,
    this.confidence = 0.5,
    this.confidenceReasons = const [],
    this.basePoints = 0,
    this.bonusPoints = 0,
    this.totalPoints = 0,
    this.userLocation,
    this.accuracy,
  });

  factory SimplifiedReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return SimplifiedReportModel(
      id: doc.id,
      scope: data['scope'] ?? 'station',
      stationId: data['stationId'] ?? '',
      userId: data['userId'] ?? '',
      trainLine: data['trainLine'],
      direction: data['direction'],
      stationOperational: data['stationOperational'],
      stationCrowd: data['stationCrowd'] as int?,
      stationIssues: List<String>.from(data['stationIssues'] ?? []),
      trainOperational: data['trainOperational'],
      trainCrowd: data['trainCrowd'] as int?,
      trainIssues: List<String>.from(data['trainIssues'] ?? []),
      trainStatus: data['trainStatus'],
      etaBucket: data['etaBucket'],
      etaExpectedAt: data['etaExpectedAt'] != null
          ? (data['etaExpectedAt'] as Timestamp).toDate()
          : null,
      arrivalTime: data['arrivalTime'] != null
          ? (data['arrivalTime'] as Timestamp).toDate()
          : null,
      isPanelTime: data['isPanelTime'] as bool?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'active',
      confirmations: data['confirmations'] ?? 0,
      confidence: (data['confidence'] ?? 0.5).toDouble(),
      confidenceReasons: List<String>.from(data['confidenceReasons'] ?? []),
      basePoints: data['basePoints'] ?? 0,
      bonusPoints: data['bonusPoints'] ?? 0,
      totalPoints: data['totalPoints'] ?? 0,
      userLocation: data['userLocation'] != null ? data['userLocation'] as GeoPoint : null,
      accuracy: data['accuracy'] != null ? (data['accuracy'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'scope': scope,
      'stationId': stationId,
      'userId': userId,
      if (trainLine != null) 'trainLine': trainLine,
      if (direction != null) 'direction': direction,
      if (stationOperational != null) 'stationOperational': stationOperational,
      if (stationCrowd != null) 'stationCrowd': stationCrowd,
      'stationIssues': stationIssues,
      if (trainOperational != null) 'trainOperational': trainOperational,
      if (trainCrowd != null) 'trainCrowd': trainCrowd,
      'trainIssues': trainIssues,
      if (trainStatus != null) 'trainStatus': trainStatus,
      if (etaBucket != null) 'etaBucket': etaBucket,
      if (etaExpectedAt != null) 'etaExpectedAt': Timestamp.fromDate(etaExpectedAt!),
      if (arrivalTime != null) 'arrivalTime': Timestamp.fromDate(arrivalTime!),
      if (isPanelTime != null) 'isPanelTime': isPanelTime,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'confirmations': confirmations,
      'confidence': confidence,
      'confidenceReasons': confidenceReasons,
      'basePoints': basePoints,
      'bonusPoints': bonusPoints,
      'totalPoints': totalPoints,
      if (userLocation != null) 'userLocation': userLocation,
      if (accuracy != null) 'accuracy': accuracy,
    };
  }
}

/// Modelo para validaciones ETA (subcolección)
class ETAValidationModel {
  final String userId;
  final String result; // 'arrived' | 'not_arrived' | 'cant_confirm'
  final DateTime answeredAt;
  final int? deltaSeconds; // arrivedAt - expectedAt (si aplica)
  final int pointsAwarded;

  ETAValidationModel({
    required this.userId,
    required this.result,
    required this.answeredAt,
    this.deltaSeconds,
    required this.pointsAwarded,
  });

  factory ETAValidationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ETAValidationModel(
      userId: data['userId'] ?? '',
      result: data['result'] ?? 'cant_confirm',
      answeredAt: (data['answeredAt'] as Timestamp).toDate(),
      deltaSeconds: data['deltaSeconds'] as int?,
      pointsAwarded: data['pointsAwarded'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'result': result,
      'answeredAt': Timestamp.fromDate(answeredAt),
      if (deltaSeconds != null) 'deltaSeconds': deltaSeconds,
      'pointsAwarded': pointsAwarded,
    };
  }
}
