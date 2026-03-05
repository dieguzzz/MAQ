import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/logger.dart';

class ReportProgressService {
  static const String _progressKeyPrefix = 'report_progress_';

  /// Guarda el progreso de un reporte de estación
  Future<void> saveStationReportProgress({
    required String stationId,
    String? operational,
    int? crowdLevel,
    List<String>? selectedIssues,
    bool showOptionalDetails = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_progressKeyPrefix$stationId';

      final progress = {
        'stationId': stationId,
        'operational': operational,
        'crowdLevel': crowdLevel,
        'selectedIssues': selectedIssues ?? [],
        'showOptionalDetails': showOptionalDetails,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await prefs.setString(key, jsonEncode(progress));
    } catch (e) {
      AppLogger.error('Error saving report progress: $e');
    }
  }

  /// Obtiene el progreso guardado de un reporte de estación
  Future<Map<String, dynamic>?> getStationReportProgress(
      String stationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_progressKeyPrefix$stationId';
      final progressJson = prefs.getString(key);

      if (progressJson == null) return null;

      final progress = jsonDecode(progressJson) as Map<String, dynamic>;

      // Verificar que no tenga más de 24 horas de antigüedad
      final timestampStr = progress['timestamp'] as String?;
      if (timestampStr != null) {
        final timestamp = DateTime.parse(timestampStr);
        final now = DateTime.now();
        if (now.difference(timestamp).inHours > 24) {
          // El progreso es muy antiguo, eliminarlo
          await prefs.remove(key);
          return null;
        }
      }

      return progress;
    } catch (e) {
      AppLogger.error('Error getting report progress: $e');
      return null;
    }
  }

  /// Elimina el progreso guardado después de enviar el reporte
  Future<void> clearStationReportProgress(String stationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_progressKeyPrefix$stationId';
      await prefs.remove(key);
    } catch (e) {
      AppLogger.error('Error clearing report progress: $e');
    }
  }

  /// Verifica si hay progreso guardado para una estación
  Future<bool> hasProgress(String stationId) async {
    final progress = await getStationReportProgress(stationId);
    return progress != null;
  }
}
