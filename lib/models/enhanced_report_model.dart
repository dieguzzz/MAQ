import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo mejorado de reporte con soporte para validaciones ETA y datos estructurados
class EnhancedReportModel {
  final String id;
  final String scope; // 'station' | 'train'
  final String stationId;
  final String userId;
  
  // Metadata temporal
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt; // TTL: 25 minutos
  
  // Estado del reporte
  final String status; // 'active' | 'verified' | 'expired' | 'rejected'
  final int confirmations;
  final double confidence; // 0.0 a 1.0
  
  // Puntos otorgados
  final int basePoints;
  final int bonusPoints;
  final int totalPoints;
  
  // Datos específicos por scope
  final StationReportData? stationData;
  final TrainReportData? trainData;
  
  // Ubicación del usuario al reportar
  final GeoPoint userLocation;
  final double accuracy; // metros
  
  // Sistema de reputación
  final double userConfidence; // Basado en historial
  final double weightedValue; // = confidence * userConfidence

  EnhancedReportModel({
    required this.id,
    required this.scope,
    required this.stationId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
    this.status = 'active',
    this.confirmations = 0,
    this.confidence = 0.5,
    this.basePoints = 0,
    this.bonusPoints = 0,
    this.totalPoints = 0,
    this.stationData,
    this.trainData,
    required this.userLocation,
    this.accuracy = 0.0,
    this.userConfidence = 0.5,
    this.weightedValue = 0.25,
  });

  factory EnhancedReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return EnhancedReportModel(
      id: doc.id,
      scope: data['scope'] ?? 'station',
      stationId: data['stationId'] ?? '',
      userId: data['userId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null 
          ? (data['expiresAt'] as Timestamp).toDate() 
          : null,
      status: data['status'] ?? 'active',
      confirmations: data['confirmations'] ?? 0,
      confidence: (data['confidence'] ?? 0.5).toDouble(),
      basePoints: data['basePoints'] ?? 0,
      bonusPoints: data['bonusPoints'] ?? 0,
      totalPoints: data['totalPoints'] ?? 0,
      stationData: data['stationData'] != null 
          ? StationReportData.fromMap(data['stationData'])
          : null,
      trainData: data['trainData'] != null
          ? TrainReportData.fromMap(data['trainData'])
          : null,
      userLocation: data['userLocation'] as GeoPoint,
      accuracy: (data['accuracy'] ?? 0.0).toDouble(),
      userConfidence: (data['userConfidence'] ?? 0.5).toDouble(),
      weightedValue: (data['weightedValue'] ?? 0.25).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'scope': scope,
      'stationId': stationId,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
      'status': status,
      'confirmations': confirmations,
      'confidence': confidence,
      'basePoints': basePoints,
      'bonusPoints': bonusPoints,
      'totalPoints': totalPoints,
      if (stationData != null) 'stationData': stationData!.toMap(),
      if (trainData != null) 'trainData': trainData!.toMap(),
      'userLocation': userLocation,
      'accuracy': accuracy,
      'userConfidence': userConfidence,
      'weightedValue': weightedValue,
    };
  }
}

/// Datos específicos para reportes de estación
class StationReportData {
  final String operational; // 'yes' | 'partial' | 'no'
  final int crowdLevel; // 1-5 (1=vacía, 5=sardina)
  final List<String> issues; // ['ac', 'escalator', 'atm', ...]
  final int issuesCount;

  StationReportData({
    required this.operational,
    required this.crowdLevel,
    this.issues = const [],
    this.issuesCount = 0,
  });

  factory StationReportData.fromMap(Map<String, dynamic> map) {
    return StationReportData(
      operational: map['operational'] ?? 'yes',
      crowdLevel: map['crowdLevel'] ?? 1,
      issues: List<String>.from(map['issues'] ?? []),
      issuesCount: map['issuesCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'operational': operational,
      'crowdLevel': crowdLevel,
      'issues': issues,
      'issuesCount': issuesCount,
    };
  }
}

/// Datos específicos para reportes de tren
class TrainReportData {
  final int crowdLevel; // 1-5
  final String trainStatus; // 'normal' | 'slow' | 'stopped' | 'express'
  final String trainType; // 'normal' | 'express' | 'extended'
  
  // Estimación de tiempo
  final String etaBucket; // '<1' | '1-2' | '3-5' | '6-10' | '10+' | 'unknown'
  final DateTime? etaExpectedAt; // Calculado server-side
  
  // Validación
  final bool needsValidation;
  final String validationStatus; // 'pending' | 'validated' | 'corrected' | 'expired'
  final int validationPoints;
  
  // Para análisis
  final DateTime? actualArrivalTime;
  final int? timeErrorSeconds;

  TrainReportData({
    required this.crowdLevel,
    required this.trainStatus,
    this.trainType = 'normal',
    required this.etaBucket,
    this.etaExpectedAt,
    this.needsValidation = false,
    this.validationStatus = 'pending',
    this.validationPoints = 0,
    this.actualArrivalTime,
    this.timeErrorSeconds,
  });

  factory TrainReportData.fromMap(Map<String, dynamic> map) {
    return TrainReportData(
      crowdLevel: map['crowdLevel'] ?? 1,
      trainStatus: map['trainStatus'] ?? 'normal',
      trainType: map['trainType'] ?? 'normal',
      etaBucket: map['etaBucket'] ?? 'unknown',
      etaExpectedAt: map['etaExpectedAt'] != null
          ? (map['etaExpectedAt'] as Timestamp).toDate()
          : null,
      needsValidation: map['needsValidation'] ?? false,
      validationStatus: map['validationStatus'] ?? 'pending',
      validationPoints: map['validationPoints'] ?? 0,
      actualArrivalTime: map['actualArrivalTime'] != null
          ? (map['actualArrivalTime'] as Timestamp).toDate()
          : null,
      timeErrorSeconds: map['timeErrorSeconds'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'crowdLevel': crowdLevel,
      'trainStatus': trainStatus,
      'trainType': trainType,
      'etaBucket': etaBucket,
      if (etaExpectedAt != null) 'etaExpectedAt': Timestamp.fromDate(etaExpectedAt!),
      'needsValidation': needsValidation,
      'validationStatus': validationStatus,
      'validationPoints': validationPoints,
      if (actualArrivalTime != null) 'actualArrivalTime': Timestamp.fromDate(actualArrivalTime!),
      if (timeErrorSeconds != null) 'timeErrorSeconds': timeErrorSeconds,
    };
  }
}
