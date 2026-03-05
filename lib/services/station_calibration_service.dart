import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio para calcular y mantener la precisión del panel digital por estación
class StationCalibrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Actualizar calibración del panel cuando se valida un reporte
  Future<void> updateCalibration({
    required String stationId,
    required int errorMinutes, // Diferencia entre tiempo esperado y real
    required String etaBucket, // Bucket reportado originalmente
  }) async {
    try {
      final stationRef = _firestore.collection('stations').doc(stationId);
      final calibrationRef = stationRef.collection('panelCalibration').doc('latest');
      
      final calibrationDoc = await calibrationRef.get();
      final now = DateTime.now();
      
      if (calibrationDoc.exists) {
        final data = calibrationDoc.data()!;
        final totalReports = (data['totalReports'] ?? 0) + 1;
        final currentAvgError = (data['avgError'] ?? 0.0).toDouble();
        
        // Calcular nuevo error promedio
        final newAvgError = ((currentAvgError * (totalReports - 1)) + errorMinutes) / totalReports;
        
        // Calcular precisión (porcentaje de reportes con error ≤ 1 minuto)
        final accurateReports = (data['accurateReports'] ?? 0) + (errorMinutes.abs() <= 1 ? 1 : 0);
        final accuracy = (accurateReports / totalReports) * 100;
        
        // Calcular precisión por hora del día
        final hourOfDay = now.hour;
        final hourKey = 'hour_$hourOfDay';
        final hourData = data['byHour'] as Map<String, dynamic>? ?? {};
        final hourReports = (hourData[hourKey]?['reports'] ?? 0) + 1;
        final hourAvgError = hourData[hourKey]?['avgError'] ?? 0.0;
        final newHourAvgError = ((hourAvgError * (hourReports - 1)) + errorMinutes) / hourReports;
        final hourAccurate = (hourData[hourKey]?['accurate'] ?? 0) + (errorMinutes.abs() <= 1 ? 1 : 0);
        final hourAccuracy = (hourAccurate / hourReports) * 100;
        
        hourData[hourKey] = {
          'reports': hourReports,
          'avgError': newHourAvgError,
          'accurate': hourAccurate,
          'accuracy': hourAccuracy,
        };
        
        await calibrationRef.update({
          'totalReports': totalReports,
          'avgError': newAvgError,
          'accurateReports': accurateReports,
          'accuracy': accuracy,
          'lastUpdated': Timestamp.fromDate(now),
          'lastError': errorMinutes,
          'byHour': hourData,
        });
      } else {
        // Crear nueva calibración
        final hourOfDay = now.hour;
        final hourKey = 'hour_$hourOfDay';
        
        await calibrationRef.set({
          'totalReports': 1,
          'avgError': errorMinutes.toDouble(),
          'accurateReports': errorMinutes.abs() <= 1 ? 1 : 0,
          'accuracy': errorMinutes.abs() <= 1 ? 100.0 : 0.0,
          'lastUpdated': Timestamp.fromDate(now),
          'lastError': errorMinutes,
          'createdAt': Timestamp.fromDate(now),
          'byHour': {
            hourKey: {
              'reports': 1,
              'avgError': errorMinutes.toDouble(),
              'accurate': errorMinutes.abs() <= 1 ? 1 : 0,
              'accuracy': errorMinutes.abs() <= 1 ? 100.0 : 0.0,
            },
          },
        });
      }
    } catch (e) {
      print('Error updating station calibration: $e');
      // No lanzar error, solo loggear - la calibración es opcional
    }
  }

  /// Obtener calibración actual de una estación
  Future<Map<String, dynamic>?> getCalibration(String stationId) async {
    try {
      final calibrationRef = _firestore
          .collection('stations')
          .doc(stationId)
          .collection('panelCalibration')
          .doc('latest');
      
      final doc = await calibrationRef.get();
      if (!doc.exists) return null;
      
      return doc.data();
    } catch (e) {
      print('Error getting station calibration: $e');
      return null;
    }
  }

  /// Obtener stream de calibración en tiempo real
  Stream<Map<String, dynamic>?> getCalibrationStream(String stationId) {
    return _firestore
        .collection('stations')
        .doc(stationId)
        .collection('panelCalibration')
        .doc('latest')
        .snapshots()
        .map((snapshot) => snapshot.exists ? snapshot.data() : null);
  }

  /// Calcular precisión general del panel para una estación
  Future<double?> getAccuracy(String stationId) async {
    final calibration = await getCalibration(stationId);
    if (calibration == null) return null;
    
    return (calibration['accuracy'] as num?)?.toDouble();
  }

  /// Obtener error promedio del panel
  Future<double?> getAverageError(String stationId) async {
    final calibration = await getCalibration(stationId);
    if (calibration == null) return null;
    
    return (calibration['avgError'] as num?)?.toDouble();
  }
}

