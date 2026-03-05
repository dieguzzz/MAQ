import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'gamification_service.dart';

/// Resultado de un tap “Ya llegó” procesado por backend.
class EtaArrivalResult {
  final bool success;
  final String reason; // 'ok' | 'no_active_group' | 'out_of_geofence' | 'cooldown' | 'no_gps' | 'ambiguous_direction' | 'already_counted'
  final String? groupId;
  final String? directionCode;
  final int pointsAwarded;
  final int? cooldownSeconds;

  EtaArrivalResult({
    required this.success,
    required this.reason,
    this.groupId,
    this.directionCode,
    required this.pointsAwarded,
    this.cooldownSeconds,
  });

  factory EtaArrivalResult.fromMap(Map<String, dynamic> data) {
    return EtaArrivalResult(
      success: data['success'] == true,
      reason: (data['reason'] as String?) ?? 'unknown',
      groupId: data['groupId'] as String?,
      directionCode: data['directionCode'] as String?,
      pointsAwarded: (data['pointsAwarded'] as int?) ?? 0,
      cooldownSeconds: data['cooldownSeconds'] as int?,
    );
  }
}

/// Servicio para enviar “Ya llegó” al backend.
class EtaArrivalService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GamificationService _gamificationService = GamificationService();

  /// Envía un tap “Ya llegó” al backend. Para que cuente y dé puntos, el backend
  /// exige geofence + GPS confiable.
  Future<EtaArrivalResult> submitArrivalTap({
    required String stationId,
    required Position? userPosition,
    String? directionCode,
  }) async {
    final callable = _functions.httpsCallable('submitArrivalTap');

    final payload = <String, dynamic>{
      'stationId': stationId,
      if (directionCode != null) 'directionCode': directionCode,
      'userLocation': userPosition != null
          ? <String, dynamic>{
              'lat': userPosition.latitude,
              'lng': userPosition.longitude,
              'accuracy': userPosition.accuracy,
              'timestampMs': userPosition.timestamp.millisecondsSinceEpoch,
            }
          : null,
    };

    final result = await callable.call(payload);
    final parsed = EtaArrivalResult.fromMap(result.data as Map<String, dynamic>);

    // Aplicar puntos localmente usando el servicio existente (las reglas actuales
    // permiten al usuario actualizar sus propios puntos).
    if (parsed.success && parsed.pointsAwarded > 0) {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _gamificationService.awardPointsForArrivalValidation(
          userId: userId,
          additionalPoints: parsed.pointsAwarded,
          stationId: stationId,
        );
      }
    }

    return parsed;
  }
}


