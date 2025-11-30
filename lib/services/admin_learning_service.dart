import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/learning_report_model.dart';
import '../models/test_scenario_model.dart';
import 'firebase_service.dart';
import 'learning_report_service.dart';
import '../models/station_model.dart';

/// Servicio para operaciones administrativas de testing del sistema de aprendizaje
class AdminLearningService {
  final FirebaseService _firebaseService = FirebaseService();
  final LearningReportService _learningReportService = LearningReportService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtener ID de usuario autenticado para reportes simulados
  String? get _simulatedUserId {
    final user = _auth.currentUser;
    if (user != null) {
      // Usar el ID del usuario autenticado con prefijo para identificar como simulado
      return 'simulated_${user.uid}';
    }
    return null;
  }

  /// Simula un reporte de usuario para testing
  Future<void> simulateUserReport({
    required String stationId,
    required DateTime realArrivalTime,
    required int displayedEstimate,
    required int delayMinutes,
    String? reason,
  }) async {
    try {
      // Obtener información de la estación
      final stations = await _firebaseService.getStations();
      final station = stations.firstWhere(
        (s) => s.id == stationId,
        orElse: () => throw Exception('Estación no encontrada'),
      );

      // Verificar que hay un usuario autenticado
      final userId = _simulatedUserId;
      if (userId == null) {
        throw Exception('Debes estar autenticado para simular reportes');
      }

      // Crear reporte de aprendizaje simulado
      final simulatedReport = LearningReportModel(
        id: '', // Se genera en Firestore
        usuarioId: userId,
        estacionId: stationId,
        linea: station.linea,
        horaLlegadaReal: realArrivalTime,
        tiempoEstimadoMostrado: displayedEstimate,
        retrasoMinutos: delayMinutes,
        llegadaATiempo: delayMinutes == 0,
        razonRetraso: reason,
        creadoEn: DateTime.now(),
        calidadReporte: 1.0, // Máxima calidad para datos de prueba
      );

      // Guardar directamente en Firestore (sin validaciones de proximidad)
      // Usar el servicio de Firebase directamente para evitar validaciones de proximidad
      await _firestore
          .collection('learning_reports')
          .add(simulatedReport.toFirestore());

      // Ejecutar análisis inmediato
      await _runImmediateAnalysis(stationId);
    } catch (e) {
      print('Error simulating user report: $e');
      rethrow;
    }
  }

  /// Ejecuta un escenario de prueba predefinido
  Future<void> runTestScenario(String scenarioId) async {
    final scenario = TestScenarios.getScenario(scenarioId);
    if (scenario == null) {
      throw Exception('Escenario no encontrado: $scenarioId');
    }

    await simulateUserReport(
      stationId: scenario.estacionId,
      realArrivalTime: scenario.hora,
      displayedEstimate: scenario.tiempoEstimadoMostrado,
      delayMinutes: scenario.retrasoMinutos,
      reason: 'Simulación de prueba: ${scenario.aprendizajeEsperado}',
    );
  }

  /// Ejecuta un batch de escenarios de prueba
  Future<void> runTestBatch({List<String>? scenarioIds}) async {
    final ids = scenarioIds ?? TestScenarios.getAllScenarioIds();
    for (final scenarioId in ids) {
      try {
        await runTestScenario(scenarioId);
        // Pequeña pausa entre escenarios
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        print('Error ejecutando escenario $scenarioId: $e');
        // Continuar con el siguiente
      }
    }
  }

  /// Inicializa datos de prueba con múltiples reportes
  Future<void> initializeTestData({
    int reportsPerStation = 10,
    int days = 7,
  }) async {
    try {
      final stations = await _firebaseService.getStations();
      final now = DateTime.now();

      for (final station in stations) {
        for (int i = 0; i < reportsPerStation; i++) {
          // Crear reportes distribuidos en diferentes horas del día
          final hour = (i % 24);
          final dayOffset = (i ~/ 24) % days;
          final reportTime = DateTime(
            now.year,
            now.month,
            now.day - dayOffset,
            hour,
            (i * 5) % 60, // Minutos variados
          );

          // Variar retrasos para datos más realistas
          final delayMinutes = i % 3 == 0 ? 0 : (i % 15); // 0, 1-14 minutos

          await simulateUserReport(
            stationId: station.id,
            realArrivalTime: reportTime,
            displayedEstimate: 5, // Estimado estándar
            delayMinutes: delayMinutes,
            reason: 'Datos de prueba iniciales',
          );

          // Pausa pequeña para no sobrecargar
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
    } catch (e) {
      print('Error inicializando datos de prueba: $e');
      rethrow;
    }
  }

  /// Ejecuta análisis inmediato después de agregar datos
  Future<void> _runImmediateAnalysis(String stationId) async {
    try {
      // Analizar patrones horarios
      final patterns = await _learningReportService.analyzeHourlyPatterns(
        stationId,
        days: 7,
      );

      // Intentar actualizar métricas del modelo en Firestore
      // Si falla por permisos, simplemente continuar (es opcional)
      try {
        final metrics = await calculateCurrentMetrics();
        await _firebaseService.updateModelMetrics(metrics);
      } catch (e) {
        // Si hay error de permisos, solo loguear pero no fallar
        if (e.toString().contains('permission-denied')) {
          print('No se pueden actualizar métricas en Firestore (permisos insuficientes)');
        } else {
          print('Error actualizando métricas: $e');
        }
        // Continuar sin fallar
      }
    } catch (e) {
      print('Error en análisis inmediato: $e');
      // No rethrow, es opcional
    }
  }

  /// Calcula métricas actuales del modelo
  Future<Map<String, dynamic>> calculateCurrentMetrics() async {
    final reports = await _learningReportService.getRecentLearningReports(
      days: 30,
    );

    if (reports.isEmpty) {
      return {
        'total_learning_reports': 0,
        'average_accuracy': 0.0,
        'best_performing_stations': <String>[],
        'worst_performing_stations': <String>[],
        'learning_velocity': 0.0,
        'data_quality_score': 0.0,
        'learning_progress': 0.0,
        'last_updated': FieldValue.serverTimestamp(),
      };
    }

    // Calcular precisión promedio (reportes con ≤2 min de diferencia)
    final accurateReports = reports.where((r) => r.retrasoMinutos <= 2).length;
    final averageAccuracy = (accurateReports / reports.length) * 100.0;

    // Calcular calidad promedio de datos
    final qualitySum =
        reports.map((r) => r.calidadReporte).reduce((a, b) => a + b);
    final dataQualityScore = qualitySum / reports.length;

    // Agrupar por estación para encontrar mejores/peores
    final stationAccuracy = <String, List<int>>{};
    for (final report in reports) {
      if (!stationAccuracy.containsKey(report.estacionId)) {
        stationAccuracy[report.estacionId] = [];
      }
      stationAccuracy[report.estacionId]!.add(report.retrasoMinutos);
    }

    // Calcular precisión por estación
    final stationStats = stationAccuracy.entries.map((entry) {
      final accurate = entry.value.where((d) => d <= 2).length;
      final accuracy = (accurate / entry.value.length) * 100.0;
      return MapEntry(entry.key, accuracy);
    }).toList();

    stationStats.sort((a, b) => b.value.compareTo(a.value));

    final bestStations = stationStats.take(5).map((e) => e.key).toList();
    final worstStations =
        stationStats.reversed.take(5).map((e) => e.key).toList();

    // Calcular velocidad de aprendizaje (mejora promedio por día)
    final learningVelocity = _calculateLearningVelocity(reports);

    // Calcular progreso (0-100 basado en cantidad de datos y precisión)
    final learningProgress = _calculateLearningProgress(
      reports.length,
      averageAccuracy,
    );

    return {
      'total_learning_reports': reports.length,
      'average_accuracy': averageAccuracy,
      'best_performing_stations': bestStations,
      'worst_performing_stations': worstStations,
      'learning_velocity': learningVelocity,
      'data_quality_score': dataQualityScore,
      'learning_progress': learningProgress,
      'last_updated': FieldValue.serverTimestamp(),
    };
  }

  /// Calcula la velocidad de aprendizaje
  double _calculateLearningVelocity(List<LearningReportModel> reports) {
    if (reports.length < 2) return 0.0;

    // Agrupar por día
    final dailyAccuracy = <DateTime, List<int>>{};
    for (final report in reports) {
      final day = DateTime(
        report.creadoEn.year,
        report.creadoEn.month,
        report.creadoEn.day,
      );
      if (!dailyAccuracy.containsKey(day)) {
        dailyAccuracy[day] = [];
      }
      dailyAccuracy[day]!.add(report.retrasoMinutos);
    }

    if (dailyAccuracy.length < 2) return 0.0;

    // Calcular precisión por día
    final dailyStats = dailyAccuracy.entries.map((entry) {
      final accurate = entry.value.where((d) => d <= 2).length;
      return (accurate / entry.value.length) * 100.0;
    }).toList();

    // Calcular tendencia (mejora promedio por día)
    if (dailyStats.length < 2) return 0.0;
    
    double sumDifferences = 0.0;
    for (int i = 1; i < dailyStats.length; i++) {
      sumDifferences += dailyStats[i] - dailyStats[i - 1];
    }

    return sumDifferences / (dailyStats.length - 1);
  }

  /// Calcula el progreso de aprendizaje (0-100)
  double _calculateLearningProgress(int totalReports, double averageAccuracy) {
    // Factor de cantidad de datos (máximo en 1000 reportes)
    final dataFactor = (totalReports / 1000.0).clamp(0.0, 1.0) * 50.0;
    
    // Factor de precisión (máximo en 95% de precisión)
    final accuracyFactor = (averageAccuracy / 95.0).clamp(0.0, 1.0) * 50.0;
    
    return (dataFactor + accuracyFactor).clamp(0.0, 100.0);
  }

  /// Mide el impacto de un batch de pruebas
  Future<Map<String, dynamic>> measureImpact(
    Future<void> Function() testBatch,
  ) async {
    final beforeMetrics = await calculateCurrentMetrics();
    
    await testBatch();
    
    // Esperar un momento para que se procesen los datos
    await Future.delayed(const Duration(seconds: 2));
    
    final afterMetrics = await calculateCurrentMetrics();
    
    final improvement = afterMetrics['average_accuracy'] -
        beforeMetrics['average_accuracy'];
    
    return {
      'before': beforeMetrics,
      'after': afterMetrics,
      'improvement': improvement,
      'improvement_percentage': improvement.toStringAsFixed(2),
    };
  }
}

