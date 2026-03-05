import 'dart:async';
import 'package:flutter/foundation.dart';

/// Servicio para manejar tiempo simulado acelerado en modo test
/// 3 segundos reales = 1 minuto simulado
class SimulatedTimeService extends ChangeNotifier {
  static final SimulatedTimeService _instance =
      SimulatedTimeService._internal();
  factory SimulatedTimeService() => _instance;
  SimulatedTimeService._internal();

  DateTime _baseRealTime = DateTime.now();
  DateTime _simulatedTime = DateTime.now();
  bool _isActive = false;
  Timer? _timer;

  // 3 segundos reales = 1 minuto simulado
  // Esto significa: 1 segundo real = 20 segundos simulados
  static const int realSecondsPerSimulatedMinute = 3;
  static const double simulatedSecondsPerRealSecond = 20.0;

  DateTime get simulatedTime => _simulatedTime;
  bool get isActive => _isActive;

  /// Inicia el tiempo simulado desde la hora actual
  void start() {
    if (_isActive) return;

    _baseRealTime = DateTime.now();
    _simulatedTime = DateTime.now();
    _isActive = true;

    // Actualizar cada segundo real
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateSimulatedTime();
    });

    notifyListeners();
  }

  /// Detiene el tiempo simulado
  void stop() {
    if (!_isActive) return;

    _timer?.cancel();
    _timer = null;
    _isActive = false;
    notifyListeners();
  }

  /// Reinicia el tiempo simulado a la hora actual
  void reset() {
    _baseRealTime = DateTime.now();
    _simulatedTime = DateTime.now();
    notifyListeners();
  }

  void _updateSimulatedTime() {
    if (!_isActive) return;

    final now = DateTime.now();
    final realElapsed = now.difference(_baseRealTime).inSeconds;

    // Calcular tiempo simulado: cada segundo real = 20 segundos simulados
    final simulatedElapsedSeconds =
        (realElapsed * simulatedSecondsPerRealSecond).round();
    _simulatedTime =
        _baseRealTime.add(Duration(seconds: simulatedElapsedSeconds));

    notifyListeners();
  }

  /// Obtiene el tiempo simulado actual sin iniciar el servicio
  DateTime getCurrentSimulatedTime() {
    if (!_isActive) {
      return DateTime.now();
    }

    final now = DateTime.now();
    final realElapsed = now.difference(_baseRealTime).inSeconds;
    final simulatedElapsedSeconds =
        (realElapsed * simulatedSecondsPerRealSecond).round();
    return _baseRealTime.add(Duration(seconds: simulatedElapsedSeconds));
  }

  /// Convierte minutos simulados a segundos reales
  static int simulatedMinutesToRealSeconds(int simulatedMinutes) {
    return simulatedMinutes * realSecondsPerSimulatedMinute;
  }

  /// Convierte segundos reales a minutos simulados
  static double realSecondsToSimulatedMinutes(int realSeconds) {
    return realSeconds / realSecondsPerSimulatedMinute;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
