import 'package:shared_preferences/shared_preferences.dart';
import '../../models/station_knowledge_model.dart';
import '../../core/logger.dart';

/// Servicio para almacenar y cargar conocimiento aprendido
class LearningStorageService {
  static const String _prefix = 'station_knowledge_';

  /// Guarda el conocimiento de una estación
  Future<void> saveStationKnowledge(StationKnowledge knowledge) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefix${knowledge.stationId}';
      final json = knowledge.toJson();
      await prefs.setString(key, json);
    } catch (e) {
      AppLogger.error('Error guardando conocimiento de estación: $e');
    }
  }

  /// Carga el conocimiento de una estación
  Future<StationKnowledge?> loadStationKnowledge(String stationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefix$stationId';
      final json = prefs.getString(key);

      if (json == null) {
        return null;
      }

      return StationKnowledge.fromJson(json);
    } catch (e) {
      AppLogger.error('Error cargando conocimiento de estación: $e');
      return null;
    }
  }

  /// Obtiene todos los conocimientos guardados
  Future<Map<String, StationKnowledge>> getAllStationsKnowledge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final knowledgeMap = <String, StationKnowledge>{};

      for (final key in allKeys) {
        if (key.startsWith(_prefix)) {
          final stationId = key.substring(_prefix.length);
          final knowledge = await loadStationKnowledge(stationId);
          if (knowledge != null) {
            knowledgeMap[stationId] = knowledge;
          }
        }
      }

      return knowledgeMap;
    } catch (e) {
      AppLogger.error('Error obteniendo todos los conocimientos: $e');
      return {};
    }
  }

  /// Elimina el conocimiento de una estación
  Future<void> deleteStationKnowledge(String stationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefix$stationId';
      await prefs.remove(key);
    } catch (e) {
      AppLogger.error('Error eliminando conocimiento de estación: $e');
    }
  }

  /// Limpia todos los conocimientos (útil para testing)
  Future<void> clearAllKnowledge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      for (final key in allKeys) {
        if (key.startsWith(_prefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      AppLogger.error('Error limpiando conocimientos: $e');
    }
  }
}
