import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo simplificado de reporte para el nuevo sistema
/// Soporta reportes de estación (scope='station') y de tren (scope='train')
class SimplifiedReportModel {
  final String id;
  final String scope; // 'station' | 'train'
  final String stationId;
  final String userId;
  
  // Campos para reportes de estación (scope='station')
  final String? stationOperational; // 'yes' | 'partial' | 'no'
  final int? stationCrowd; // 1-5
  final List<String>? stationIssues; // Lista de problemas
  
  // Campos para reportes de tren (scope='train')
  final int? trainCrowd; // 1-5
  final List<String>? trainIssues; // ['recharge', 'atm', 'ac', 'escalator', 'elevator']
  final String? trainLine; // 'L1' | 'L2'
  final String? direction; // 'A' | 'B'
  final String? etaBucket; // '1-2' | '3-5' | '6-8' | '9+' | 'unknown'
  final DateTime? etaExpectedAt;
  final DateTime? arrivalTime;
  final String? trainStatus; // 'normal' | 'slow' | 'stopped'
  final bool? isPanelTime; // true si el tiempo viene del panel digital oficial
  
  // Campos comunes
  final DateTime createdAt;
  final int basePoints;
  final int bonusPoints;
  final int totalPoints;
  final GeoPoint? userLocation;
  final double? accuracy;
  final String status; // 'active' | 'resolved' | 'expired'
  final int confirmations; // Número de confirmaciones
  final double? confidence; // 0.0-1.0 (nivel de confianza numérico)
  final List<String>? confidenceReasons; // Razones de confianza

  SimplifiedReportModel({
    required this.id,
    required this.scope,
    required this.stationId,
    required this.userId,
    this.stationOperational,
    this.stationCrowd,
    this.stationIssues,
    this.trainCrowd,
    this.trainIssues,
    this.trainLine,
    this.direction,
    this.etaBucket,
    this.etaExpectedAt,
    this.arrivalTime,
    this.trainStatus,
    this.isPanelTime,
    required this.createdAt,
    required this.basePoints,
    required this.bonusPoints,
    required this.totalPoints,
    this.userLocation,
    this.accuracy,
    this.status = 'active',
    this.confirmations = 0,
    this.confidence,
    this.confidenceReasons,
  });

  factory SimplifiedReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return SimplifiedReportModel(
      id: doc.id,
      scope: data['scope'] ?? 'train',
      stationId: data['stationId'] ?? '',
      userId: data['userId'] ?? '',
      stationOperational: data['stationOperational'] as String?,
      stationCrowd: data['stationCrowd'] as int?,
      stationIssues: data['stationIssues'] != null
          ? List<String>.from(data['stationIssues'])
          : null,
      trainCrowd: data['trainCrowd'] as int?,
      trainIssues: data['trainIssues'] != null
          ? List<String>.from(data['trainIssues'])
          : null,
      trainLine: data['trainLine'] as String?,
      direction: data['direction'] as String?,
      etaBucket: data['etaBucket'] as String?,
      etaExpectedAt: data['etaExpectedAt'] != null
          ? (data['etaExpectedAt'] as Timestamp).toDate()
          : null,
      arrivalTime: data['arrivalTime'] != null
          ? (data['arrivalTime'] as Timestamp).toDate()
          : null,
      trainStatus: data['trainStatus'] as String?,
      isPanelTime: data['isPanelTime'] as bool?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      basePoints: data['basePoints'] ?? 0,
      bonusPoints: data['bonusPoints'] ?? 0,
      totalPoints: data['totalPoints'] ?? 0,
      userLocation: data['userLocation'] as GeoPoint?,
      accuracy: data['accuracy'] != null
          ? (data['accuracy'] as num).toDouble()
          : null,
      status: data['status'] ?? 'active',
      confirmations: data['confirmations'] ?? 0,
      confidence: data['confidence'] != null
          ? (data['confidence'] as num).toDouble()
          : null,
      confidenceReasons: data['confidenceReasons'] != null
          ? List<String>.from(data['confidenceReasons'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'scope': scope,
      'stationId': stationId,
      'userId': userId,
      if (stationOperational != null) 'stationOperational': stationOperational,
      if (stationCrowd != null) 'stationCrowd': stationCrowd,
      if (stationIssues != null) 'stationIssues': stationIssues,
      if (trainCrowd != null) 'trainCrowd': trainCrowd,
      if (trainIssues != null) 'trainIssues': trainIssues,
      if (trainLine != null) 'trainLine': trainLine,
      if (direction != null) 'direction': direction,
      if (etaBucket != null) 'etaBucket': etaBucket,
      if (etaExpectedAt != null)
        'etaExpectedAt': Timestamp.fromDate(etaExpectedAt!),
      if (arrivalTime != null)
        'arrivalTime': Timestamp.fromDate(arrivalTime!),
      if (trainStatus != null) 'trainStatus': trainStatus,
      if (isPanelTime != null) 'isPanelTime': isPanelTime,
      'createdAt': Timestamp.fromDate(createdAt),
      'basePoints': basePoints,
      'bonusPoints': bonusPoints,
      'totalPoints': totalPoints,
      if (userLocation != null) 'userLocation': userLocation,
      if (accuracy != null) 'accuracy': accuracy,
      'status': status,
      'confirmations': confirmations,
      if (confidence != null) 'confidence': confidence,
      if (confidenceReasons != null) 'confidenceReasons': confidenceReasons,
    };
  }
}

