import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio para almacenar logs de depuración que se pueden ver en modo test
class DebugLogService {
  static final DebugLogService _instance = DebugLogService._internal();
  factory DebugLogService() => _instance;
  DebugLogService._internal();

  // Almacenar los últimos 200 logs
  final Queue<DebugLogEntry> _logs = Queue<DebugLogEntry>();
  final int _maxLogs = 200;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _firestoreEnabled = false;

  /// Habilita el guardado de logs en Firestore
  void enableFirestore() {
    _firestoreEnabled = true;
  }

  /// Deshabilita el guardado de logs en Firestore
  void disableFirestore() {
    _firestoreEnabled = false;
  }

  /// Agrega un log de depuración
  void addLog(String category, String message, {LogLevel level = LogLevel.info}) {
    final entry = DebugLogEntry(
      timestamp: DateTime.now(),
      category: category,
      message: message,
      level: level,
    );
    
    _logs.add(entry);
    
    // Mantener solo los últimos _maxLogs
    while (_logs.length > _maxLogs) {
      _logs.removeFirst();
    }
    
    // También imprimir en consola
    final emoji = _getEmojiForLevel(level);
    debugPrint('$emoji [$category] $message');

    // Guardar en Firestore si está habilitado
    if (_firestoreEnabled) {
      _saveToFirestore(entry);
    }
  }

  /// Guarda un log en Firestore
  Future<void> _saveToFirestore(DebugLogEntry entry) async {
    try {
      await _firestore.collection('debug_logs').add({
        'timestamp': Timestamp.fromDate(entry.timestamp),
        'category': entry.category,
        'message': entry.message,
        'level': entry.level.name,
      });
    } catch (e) {
      // Silenciar errores de Firestore para no afectar la app
      debugPrint('Error guardando log en Firestore: $e');
    }
  }

  /// Obtiene todos los logs
  List<DebugLogEntry> getLogs() {
    return _logs.toList().reversed.toList(); // Más recientes primero
  }

  /// Obtiene logs filtrados por categoría
  List<DebugLogEntry> getLogsByCategory(String category) {
    return _logs.where((log) => log.category == category).toList().reversed.toList();
  }

  /// Limpia todos los logs
  void clearLogs() {
    _logs.clear();
  }

  String _getEmojiForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return '📊';
      case LogLevel.success:
        return '✅';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }
}

enum LogLevel {
  info,
  success,
  warning,
  error,
}

class DebugLogEntry {
  final DateTime timestamp;
  final String category;
  final String message;
  final LogLevel level;

  DebugLogEntry({
    required this.timestamp,
    required this.category,
    required this.message,
    required this.level,
  });

  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}:'
           '${timestamp.second.toString().padLeft(2, '0')}';
  }
}

