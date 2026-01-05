import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de agregado ETA (backend-owned) para estabilizar el panel de tiempos.
///
/// Fuente: colección `eta_groups`.
class EtaGroupModel {
  final String id;
  final String stationId;
  final String line; // 'linea1' | 'linea2'
  final String directionCode; // 'A' | 'B'
  final String? directionLabel; // Solo para UI (ej: 'Albrook')

  final DateTime bucketStart;
  final DateTime? firstReportedAt; // Base estable del ETA (no cambia con presence/arrivals)
  final DateTime? etaUpdatedAt; // Solo cambia cuando entra un nuevo reporte de tiempo
  final DateTime updatedAt;
  final DateTime expiresAt;
  final String status; // 'active' | 'expired'

  final String nextEtaBucket; // '1-2'|'3-5'|'6-8'|'9+'|'unknown'
  final String? followingEtaBucket;
  final int? nextEtaMinutesP50;
  final int? followingEtaMinutesP50;
  final DateTime? nextEtaExpectedAt;
  final DateTime? followingEtaExpectedAt;

  final int reportCount;
  final int presenceCount;
  final int arrivedCount;
  final double confidence; // 0..1

  EtaGroupModel({
    required this.id,
    required this.stationId,
    required this.line,
    required this.directionCode,
    this.directionLabel,
    required this.bucketStart,
    this.firstReportedAt,
    this.etaUpdatedAt,
    required this.updatedAt,
    required this.expiresAt,
    required this.status,
    required this.nextEtaBucket,
    this.followingEtaBucket,
    this.nextEtaMinutesP50,
    this.followingEtaMinutesP50,
    this.nextEtaExpectedAt,
    this.followingEtaExpectedAt,
    required this.reportCount,
    required this.presenceCount,
    required this.arrivedCount,
    required this.confidence,
  });

  bool get isActive => status == 'active' && DateTime.now().isBefore(expiresAt);

  int get ageMinutes => DateTime.now().difference(bucketStart).inMinutes;

  factory EtaGroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime ts(dynamic v) => (v as Timestamp).toDate();
    DateTime? tsOpt(dynamic v) => v == null ? null : (v as Timestamp).toDate();

    return EtaGroupModel(
      id: doc.id,
      stationId: data['stationId'] ?? '',
      line: data['line'] ?? '',
      directionCode: data['directionCode'] ?? '',
      directionLabel: data['directionLabel'] as String?,
      bucketStart: ts(data['bucketStart']),
      firstReportedAt: tsOpt(data['firstReportedAt']),
      etaUpdatedAt: tsOpt(data['etaUpdatedAt']),
      updatedAt: ts(data['updatedAt']),
      expiresAt: ts(data['expiresAt']),
      status: data['status'] ?? 'active',
      nextEtaBucket: data['nextEtaBucket'] ?? 'unknown',
      followingEtaBucket: data['followingEtaBucket'] as String?,
      nextEtaMinutesP50: data['nextEtaMinutesP50'] as int?,
      followingEtaMinutesP50: data['followingEtaMinutesP50'] as int?,
      nextEtaExpectedAt: tsOpt(data['nextEtaExpectedAt']),
      followingEtaExpectedAt: tsOpt(data['followingEtaExpectedAt']),
      reportCount: data['reportCount'] ?? 0,
      presenceCount: data['presenceCount'] ?? 0,
      arrivedCount: data['arrivedCount'] ?? 0,
      confidence: (data['confidence'] ?? 0.0).toDouble(),
    );
  }
}


