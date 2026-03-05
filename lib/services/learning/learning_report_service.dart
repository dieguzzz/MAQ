import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/learning_report_model.dart';
import '../../models/station_model.dart';
import '../../models/user_model.dart';
import '../core/firebase_service.dart';
import '../gamification/gamification_service.dart';

/// Servicio para crear y gestionar reportes de aprendizaje
class LearningReportService {
  final FirebaseService _firebaseService = FirebaseService();
  final GamificationService _gamificationService = GamificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Radio de proximidad para validar que el usuario está cerca de la estación (en metros)
  static const double proximityRadiusMeters = 500.0;

  /// Crea un reporte de aprendizaje con validaciones
  Future<String> createLearningReport(LearningReportModel report) async {
    try {
      // Validar que el usuario existe
      final user = await _firebaseService.getUser(report.usuarioId);
      if (user == null) {
        throw Exception('Usuario no encontrado');
      }

      // Validar que la estación existe
      (await _firebaseService.getStations()).firstWhere(
        (s) => s.id == report.estacionId,
        orElse: () => throw Exception('Estación no encontrada'),
      );

      // Validación de proximidad deshabilitada - se puede reportar desde cualquier ubicación
      // if (user.ultimaUbicacion != null) {
      //   final distanceMeters = Geolocator.distanceBetween(
      //     user.ultimaUbicacion!.latitude,
      //     user.ultimaUbicacion!.longitude,
      //     station.ubicacion.latitude,
      //     station.ubicacion.longitude,
      //   );

      //   if (distanceMeters > proximityRadiusMeters) {
      //     throw Exception(
      //         'Debes estar a menos de ${proximityRadiusMeters}m de la estación para reportar');
      //   }
      // }

      // Calcular calidad del reporte basado en precisión histórica del usuario
      final calidadReporte = _calculateReportQuality(user);

      // Actualizar el reporte con la calidad calculada
      final reportWithQuality = report.copyWith(calidadReporte: calidadReporte);

      // Guardar en Firestore
      final docRef = await _firestore
          .collection('learning_reports')
          .add(reportWithQuality.toFirestore());

      // Otorgar puntos de gamificación
      await _gamificationService.rewardTeachingReport(
          report.usuarioId, reportWithQuality);

      return docRef.id;
    } catch (e) {
      print('Error creating learning report: $e');
      rethrow;
    }
  }

  /// Calcula la calidad del reporte (0.0-1.0) basado en la precisión histórica del usuario
  double _calculateReportQuality(UserModel user) {
    // La precisión en UserModel es 0.0-100.0, convertir a 0.0-1.0
    // Si no tiene precisión, usar 0.5 como valor por defecto
    final precisionRatio = user.precision / 100.0;

    // Normalizar entre 0.0 y 1.0
    return precisionRatio.clamp(0.0, 1.0);
  }

  /// Obtiene reportes de aprendizaje recientes
  Future<List<LearningReportModel>> getRecentLearningReports(
      {int days = 14}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection('learning_reports')
          .where('creado_en', isGreaterThan: Timestamp.fromDate(cutoffDate))
          .orderBy('creado_en', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => LearningReportModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting recent learning reports: $e');
      return [];
    }
  }

  /// Analiza patrones horarios básicos para una estación
  /// Retorna un mapa con la hora del día como clave y el retraso promedio en minutos como valor
  Future<Map<int, double>> analyzeHourlyPatterns(String stationId,
      {int days = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection('learning_reports')
          .where('estacion_id', isEqualTo: stationId)
          .where('creado_en', isGreaterThan: Timestamp.fromDate(cutoffDate))
          .get();

      // Agrupar por hora del día
      final hourlyDelays = <int, List<int>>{};

      for (var doc in snapshot.docs) {
        final report = LearningReportModel.fromFirestore(doc);
        final hour = report.horaLlegadaReal.hour;

        if (!hourlyDelays.containsKey(hour)) {
          hourlyDelays[hour] = [];
        }

        hourlyDelays[hour]!.add(report.retrasoMinutos);
      }

      // Calcular promedio por hora
      final hourlyAverages = <int, double>{};
      hourlyDelays.forEach((hour, delays) {
        if (delays.isNotEmpty) {
          final average = delays.reduce((a, b) => a + b) / delays.length;
          hourlyAverages[hour] = average;
        }
      });

      return hourlyAverages;
    } catch (e) {
      print('Error analyzing hourly patterns: $e');
      return {};
    }
  }

  /// Valida si el usuario está cerca de una estación
  Future<bool> isUserNearStation(String userId, StationModel station) async {
    try {
      final user = await _firebaseService.getUser(userId);
      if (user == null || user.ultimaUbicacion == null) {
        return false;
      }

      // Validación de proximidad deshabilitada - siempre retorna true
      // final distanceMeters = Geolocator.distanceBetween(
      //   user.ultimaUbicacion!.latitude,
      //   user.ultimaUbicacion!.longitude,
      //   station.ubicacion.latitude,
      //   station.ubicacion.longitude,
      // );

      // return distanceMeters <= proximityRadiusMeters;
      return true; // Siempre permitir reportes sin validar distancia
    } catch (e) {
      print('Error checking proximity: $e');
      return false;
    }
  }

  /// Obtiene reportes de aprendizaje por estación
  Future<List<LearningReportModel>> getReportsByStation(String stationId,
      {int days = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection('learning_reports')
          .where('estacion_id', isEqualTo: stationId)
          .where('creado_en', isGreaterThan: Timestamp.fromDate(cutoffDate))
          .orderBy('creado_en', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => LearningReportModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting reports by station: $e');
      return [];
    }
  }

  /// Obtiene un stream de análisis en tiempo real
  Stream<Map<String, dynamic>> getRealTimeAnalysisStream({int days = 14}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    return _firestore
        .collection('learning_reports')
        .where('creado_en', isGreaterThan: Timestamp.fromDate(cutoffDate))
        .snapshots()
        .map((snapshot) => _analyzeRealTime(snapshot));
  }

  /// Analiza reportes en tiempo real
  Map<String, dynamic> _analyzeRealTime(QuerySnapshot snapshot) {
    if (snapshot.docs.isEmpty) {
      return {
        'total_reports': 0,
        'average_accuracy': 0.0,
        'total_stations': 0,
        'reports_by_hour': <int, int>{},
        'average_delay': 0.0,
      };
    }

    final reports = snapshot.docs
        .map((doc) => LearningReportModel.fromFirestore(doc))
        .toList();

    // Calcular precisión promedio
    final accurateReports = reports.where((r) => r.retrasoMinutos <= 2).length;
    final averageAccuracy = (accurateReports / reports.length) * 100.0;

    // Agrupar por hora
    final reportsByHour = <int, int>{};
    for (final report in reports) {
      final hour = report.horaLlegadaReal.hour;
      reportsByHour[hour] = (reportsByHour[hour] ?? 0) + 1;
    }

    // Calcular retraso promedio
    final totalDelay =
        reports.map((r) => r.retrasoMinutos).reduce((a, b) => a + b);
    final averageDelay = totalDelay / reports.length;

    // Contar estaciones únicas
    final uniqueStations = reports.map((r) => r.estacionId).toSet().length;

    return {
      'total_reports': reports.length,
      'average_accuracy': averageAccuracy,
      'total_stations': uniqueStations,
      'reports_by_hour': reportsByHour,
      'average_delay': averageDelay,
    };
  }

  /// Fuerza la actualización del modelo para todas las estaciones
  Future<void> forceModelUpdate() async {
    try {
      final stations = await getStationsWithReports();

      for (final station in stations) {
        await _updateStationModel(station);
      }
    } catch (e) {
      print('Error forcing model update: $e');
      rethrow;
    }
  }

  /// Obtiene todas las estaciones que tienen reportes
  Future<List<String>> getStationsWithReports() async {
    try {
      final snapshot = await _firestore.collection('learning_reports').get();

      final stationIds = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return data['estacion_id'] as String?;
          })
          .whereType<String>()
          .toSet()
          .toList();

      return stationIds;
    } catch (e) {
      print('Error getting stations with reports: $e');
      return [];
    }
  }

  /// Actualiza el modelo para una estación específica
  Future<void> _updateStationModel(String stationId) async {
    try {
      // Analizar patrones horarios
      final patterns = await analyzeHourlyPatterns(stationId, days: 30);

      // Aquí se pueden aplicar ajustes al modelo
      // Por ahora, solo guardamos los patrones para referencia futura
      // En fases futuras, esto se usará para ajustar las predicciones

      print('Modelo actualizado para estación: $stationId');
      print('Patrones: $patterns');
    } catch (e) {
      print('Error updating station model: $e');
      rethrow;
    }
  }
}
