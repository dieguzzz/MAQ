import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/learning_report_model.dart';
import '../learning/learning_report_service.dart';
import '../simulation/schedule_service.dart';
import 'firebase_service.dart';

/// Servicio para modo desarrollador - testing y simulación
class DevService {
  static final ValueNotifier<bool> _devModeNotifier =
      ValueNotifier<bool>(false);
  static bool get devModeEnabled => _devModeNotifier.value;
  static ValueNotifier<bool> get devModeNotifier => _devModeNotifier;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final LearningReportService _learningReportService =
      LearningReportService();
  static final FirebaseService _firebaseService = FirebaseService();

  /// Activa o desactiva el modo desarrollador
  static void toggleDevMode() {
    _devModeNotifier.value = !_devModeNotifier.value;
    if (_devModeNotifier.value) {
      _initializeDevTools();
    }
  }

  /// Inicializa las herramientas de desarrollo
  static void _initializeDevTools() {
    // Inicializar métricas en tiempo real si no existen
    _firestore.collection('dev_metrics').doc('realtime').set({
      'accuracy': 0.0,
      'todayReports': 0,
      'learningSpeed': 0.0,
      'accuracyHistory': [],
      'problemStations': [],
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).catchError((e) {
      print('Error inicializando dev metrics: $e');
    });
  }

  /// Simula un reporte de llegada
  static Future<void> simulateArrivalReport({
    required String stationId,
    required int delayMinutes,
    bool onTime = false,
    String? userId,
  }) async {
    try {
      // Obtener estación
      final stations = await _firebaseService.getStations();
      final station = stations.firstWhere(
        (s) => s.id == stationId,
        orElse: () => throw Exception('Estación no encontrada: $stationId'),
      );

      // Usar userId proporcionado o generar uno de desarrollo
      final devUserId =
          userId ?? 'dev_user_${DateTime.now().millisecondsSinceEpoch}';

      // Obtener tiempo estimado base del horario
      final now = DateTime.now();
      final baseTime = ScheduleService.getBaseScheduleTime(
        stationId,
        station.linea,
        now,
      );

      // Crear reporte simulado
      final simulatedReport = LearningReportModel(
        id: '', // Se generará al guardar
        usuarioId: devUserId,
        estacionId: stationId,
        linea: station.linea,
        horaLlegadaReal: now,
        tiempoEstimadoMostrado: baseTime,
        retrasoMinutos: onTime ? 0 : delayMinutes,
        llegadaATiempo: onTime,
        creadoEn: now,
        calidadReporte: 1.0, // Reportes de dev tienen calidad máxima
      );

      // Guardar como reporte real
      await _learningReportService.createLearningReport(simulatedReport);

      // Forzar actualización del modelo
      await _forceModelUpdate(stationId);

      // Actualizar métricas
      await _updateMetrics();
    } catch (e) {
      print('Error simulando reporte: $e');
      rethrow;
    }
  }

  /// Obtiene métricas en tiempo real
  static Stream<Map<String, dynamic>> getRealtimeMetrics() {
    return _firestore
        .collection('dev_metrics')
        .doc('realtime')
        .snapshots()
        .map((snapshot) =>
            snapshot.data() ??
            {
              'accuracy': 0.0,
              'todayReports': 0,
              'learningSpeed': 0.0,
              'accuracyHistory': [],
              'problemStations': [],
            });
  }

  /// Ejecuta simulación masiva
  static Future<void> runMassSimulation(int count) async {
    try {
      final stations = await _firebaseService.getStations();
      if (stations.isEmpty) {
        throw Exception('No hay estaciones disponibles');
      }

      final random = Random();

      for (int i = 0; i < count; i++) {
        final randomStation = stations[random.nextInt(stations.length)];
        final randomDelay = random.nextInt(30); // 0-30 min retraso
        final onTime = random.nextDouble() > 0.3; // 70% a tiempo

        await simulateArrivalReport(
          stationId: randomStation.id,
          delayMinutes: randomDelay,
          onTime: onTime,
        );

        // Pequeño delay para no saturar
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Actualizar métricas después de la simulación masiva
      await _updateMetrics();
    } catch (e) {
      print('Error en simulación masiva: $e');
      rethrow;
    }
  }

  /// Fuerza actualización del modelo para una estación
  static Future<void> _forceModelUpdate(String stationId) async {
    try {
      // Aquí se podría llamar a un servicio de actualización del modelo
      // Por ahora solo loggeamos
      print('Forzando actualización del modelo para estación: $stationId');
    } catch (e) {
      print('Error forzando actualización del modelo: $e');
    }
  }

  /// Actualiza las métricas en tiempo real
  static Future<void> _updateMetrics() async {
    try {
      // Obtener reportes de hoy
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final todayReports = await _firestore
          .collection('learning_reports')
          .where('creado_en',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      final totalReports = todayReports.docs.length;

      // Calcular precisión (reportes con retraso <= 2 minutos)
      final accurateReports = todayReports.docs.where((doc) {
        final data = doc.data();
        final delay = data['retraso_minutos'] ?? 999;
        return delay <= 2;
      }).length;

      final accuracy =
          totalReports > 0 ? (accurateReports / totalReports) * 100.0 : 0.0;

      // Calcular velocidad de aprendizaje (simplificado)
      final learningSpeed = _calculateLearningSpeed();

      // Obtener estaciones problemáticas
      final problemStations = await _getProblemStations();

      // Obtener historial de precisión (últimos 10 valores)
      final accuracyHistory = await _getAccuracyHistory();

      // Actualizar en Firestore
      await _firestore.collection('dev_metrics').doc('realtime').set({
        'accuracy': accuracy,
        'todayReports': totalReports,
        'learningSpeed': learningSpeed,
        'problemStations': problemStations,
        'accuracyHistory': accuracyHistory,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error actualizando métricas: $e');
    }
  }

  /// Calcula la velocidad de aprendizaje (simplificado)
  static double _calculateLearningSpeed() {
    // Por ahora retorna un valor simulado
    // En producción, esto calcularía la mejora real del modelo
    return Random().nextDouble() * 10.0; // 0-10% de mejora
  }

  /// Obtiene estaciones problemáticas (con más retrasos)
  static Future<List<Map<String, dynamic>>> _getProblemStations() async {
    try {
      final stations = await _firebaseService.getStations();
      final problemStations = <Map<String, dynamic>>[];

      for (final station in stations) {
        final reports = await _firestore
            .collection('learning_reports')
            .where('estacion_id', isEqualTo: station.id)
            .where('creado_en',
                isGreaterThan: Timestamp.fromDate(
                    DateTime.now().subtract(const Duration(days: 7))))
            .get();

        if (reports.docs.isNotEmpty) {
          final delays = reports.docs
              .map((doc) => doc.data()['retraso_minutos'] ?? 0)
              .where((delay) => delay > 0)
              .toList();

          if (delays.isNotEmpty) {
            final avgDelay = delays.reduce((a, b) => a + b) / delays.length;
            if (avgDelay > 5) {
              // Más de 5 minutos de retraso promedio
              problemStations.add({
                'id': station.id,
                'name': station.nombre,
                'avgDelay': avgDelay.round(),
              });
            }
          }
        }
      }

      // Ordenar por retraso promedio descendente
      problemStations.sort(
          (a, b) => (b['avgDelay'] as int).compareTo(a['avgDelay'] as int));

      return problemStations.take(5).toList(); // Top 5
    } catch (e) {
      print('Error obteniendo estaciones problemáticas: $e');
      return [];
    }
  }

  /// Obtiene historial de precisión
  static Future<List<double>> _getAccuracyHistory() async {
    try {
      // Obtener últimos 10 días de métricas
      final history = <double>[];

      for (int i = 9; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final reports = await _firestore
            .collection('learning_reports')
            .where('creado_en',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('creado_en', isLessThan: Timestamp.fromDate(endOfDay))
            .get();

        if (reports.docs.isNotEmpty) {
          final accurateReports = reports.docs.where((doc) {
            final data = doc.data();
            final delay = data['retraso_minutos'] ?? 999;
            return delay <= 2;
          }).length;

          final accuracy = (accurateReports / reports.docs.length) * 100.0;
          history.add(accuracy);
        } else {
          history.add(0.0);
        }
      }

      return history;
    } catch (e) {
      print('Error obteniendo historial de precisión: $e');
      return List.filled(10, 0.0);
    }
  }

  /// Reinicia el modelo de aprendizaje
  static Future<void> resetModel() async {
    try {
      // Aquí se implementaría la lógica para reiniciar el modelo
      print('Reiniciando modelo de aprendizaje...');
      // Por ahora solo actualizamos métricas
      await _updateMetrics();
    } catch (e) {
      print('Error reiniciando modelo: $e');
      rethrow;
    }
  }

  /// Guarda ajustes del algoritmo
  static Future<void> saveSettings({
    required double learningRate,
    required double baseScheduleWeight,
    required double learningWeight,
  }) async {
    try {
      await _firestore.collection('dev_settings').doc('algorithm').set({
        'learningRate': learningRate,
        'baseScheduleWeight': baseScheduleWeight,
        'learningWeight': learningWeight,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error guardando ajustes: $e');
      rethrow;
    }
  }

  /// Obtiene ajustes del algoritmo
  static Future<Map<String, double>> getSettings() async {
    try {
      final doc =
          await _firestore.collection('dev_settings').doc('algorithm').get();

      if (doc.exists) {
        final data = doc.data()!;
        return {
          'learningRate': (data['learningRate'] ?? 0.1).toDouble(),
          'baseScheduleWeight': (data['baseScheduleWeight'] ?? 0.7).toDouble(),
          'learningWeight': (data['learningWeight'] ?? 0.3).toDouble(),
        };
      }

      // Valores por defecto
      return {
        'learningRate': 0.1,
        'baseScheduleWeight': 0.7,
        'learningWeight': 0.3,
      };
    } catch (e) {
      print('Error obteniendo ajustes: $e');
      return {
        'learningRate': 0.1,
        'baseScheduleWeight': 0.7,
        'learningWeight': 0.3,
      };
    }
  }

  /// Limpia todos los datos de prueba
  static Future<void> clearTestData() async {
    try {
      print('🧹 Limpiando datos de prueba...');

      // 1. Eliminar reportes de aprendizaje de prueba
      final learningReports = await _firestore
          .collection('learning_reports')
          .where('usuario_id', isGreaterThan: 'dev_user_')
          .get();

      final batch = _firestore.batch();
      for (var doc in learningReports.docs) {
        batch.delete(doc.reference);
      }

      // 2. Eliminar reportes de prueba (con prefijo [DEV_TEST])
      final testReports = await _firestore
          .collection('reports')
          .where('descripcion', isGreaterThan: '[DEV_TEST]')
          .get();

      for (var doc in testReports.docs) {
        batch.delete(doc.reference);
      }

      // 3. Limpiar métricas de desarrollo
      await _firestore.collection('dev_metrics').doc('realtime').delete();

      await batch.commit();
      print('✅ Datos de prueba eliminados');
    } catch (e) {
      print('Error limpiando datos de prueba: $e');
      rethrow;
    }
  }
}
