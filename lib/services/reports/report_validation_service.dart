import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/logger.dart';
import '../core/app_mode_service.dart';

class ReportValidationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Verifica si el usuario puede reportar (anti-spam)
  /// - Máximo 10 reportes por hora
  /// - No reportar misma estación en 5 minutos
  Future<bool> canUserReport(String userId, String? objetivoId) async {
    try {
      // Validar parámetros
      if (userId.isEmpty) {
        AppLogger.warning('⚠️ canUserReport: userId está vacío');
        return false;
      }

      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));

      AppLogger.debug('🔍 Validando reporte - userId: $userId, objetivoId: $objetivoId');

      // Verificar límite de reportes por hora
      try {
        final recentReportsSnapshot = await _firestore
            .collection('reports')
            .where('usuario_id', isEqualTo: userId)
            .where('creado_en', isGreaterThan: Timestamp.fromDate(oneHourAgo))
            .get();

        final recentCount = recentReportsSnapshot.docs.length;
        AppLogger.debug('📊 Reportes en la última hora: $recentCount');

        if (recentCount >= 10) {
          AppLogger.error(
              '❌ Límite de spam alcanzado: $recentCount reportes en la última hora');
          return false; // Límite de spam alcanzado
        }
      } catch (e) {
        AppLogger.warning('⚠️ Error verificando límite de reportes por hora: $e');
        // Continuar con la validación siguiente en lugar de bloquear
      }

      // Verificar si ya reportó esta estación/tren recientemente
      if (objetivoId != null && objetivoId.isNotEmpty) {
        try {
          final recentSameTargetSnapshot = await _firestore
              .collection('reports')
              .where('usuario_id', isEqualTo: userId)
              .where('objetivo_id', isEqualTo: objetivoId)
              .where('creado_en',
                  isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
              .get();

          if (recentSameTargetSnapshot.docs.isNotEmpty) {
            AppLogger.error(
                '❌ Ya reportó esta estación/tren recientemente (últimos 5 minutos)');
            return false; // Ya reportó esta estación/tren recientemente
          }
          AppLogger.debug('✅ No hay reportes recientes para este objetivo');
        } catch (e) {
          AppLogger.warning(
              '⚠️ Error verificando reportes recientes del mismo objetivo: $e');
          // Continuar permitiendo el reporte si hay error de red
        }
      } else {
        AppLogger.warning(
            '⚠️ objetivoId es null o vacío, saltando validación de duplicados');
      }

      AppLogger.debug('✅ Validación anti-spam pasada');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Error inesperado en canUserReport: $e', e, stackTrace);
      // En caso de error inesperado, permitir el reporte para no bloquear usuarios legítimos
      // pero loggear el error para investigar
      return true;
    }
  }

  /// Valida que el usuario esté cerca de la ubicación del reporte
  /// Máximo 1 km de distancia
  /// En modo Test, siempre retorna true (omite validación)
  bool isValidReportLocation(
    Position? userLocation,
    GeoPoint targetLocation, {
    AppMode? appMode,
  }) {
    // Test mode bypass ONLY in debug builds
    if (kDebugMode && appMode == AppMode.test) {
      AppLogger.debug('Test mode: skipping location validation');
      return true;
    }

    if (userLocation == null) {
      return false; // Sin ubicación del usuario
    }

    // Block mock/fake GPS locations
    if (userLocation.isMocked) {
      AppLogger.warning('Mock location detected');
      return false;
    }

    final distance = Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      targetLocation.latitude,
      targetLocation.longitude,
    );

    // Máximo 500 metros
    return distance <= 500;
  }

  /// Verifica si el usuario ya reportó recientemente para esta estación/tren
  Future<bool> hasRecentReportForStation(
    String userId,
    String objetivoId,
  ) async {
    try {
      final fiveMinutesAgo =
          DateTime.now().subtract(const Duration(minutes: 5));

      final recentReportsSnapshot = await _firestore
          .collection('reports')
          .where('usuario_id', isEqualTo: userId)
          .where('objetivo_id', isEqualTo: objetivoId)
          .where('creado_en', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
          .limit(1)
          .get();

      return recentReportsSnapshot.docs.isNotEmpty;
    } catch (e) {
      AppLogger.error('Error checking recent report: $e');
      return false;
    }
  }

  /// Obtiene el mensaje de error de validación
  Future<String?> getValidationErrorMessage(
    String userId,
    String? objetivoId,
    Position? userLocation,
    GeoPoint? targetLocation, {
    AppMode? appMode,
  }) async {
    try {
      final canReport = await canUserReport(userId, objetivoId);
      if (!canReport) {
        // Verificar cuál es el problema específico
        try {
          final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
          final recentReportsSnapshot = await _firestore
              .collection('reports')
              .where('usuario_id', isEqualTo: userId)
              .where('creado_en', isGreaterThan: Timestamp.fromDate(oneHourAgo))
              .get();

          final recentCount = recentReportsSnapshot.docs.length;
          AppLogger.debug(
              '📊 getValidationErrorMessage - Reportes en última hora: $recentCount');

          if (recentCount >= 10) {
            return 'Has alcanzado el límite de reportes por hora (10). Intenta más tarde.';
          }

          if (objetivoId != null && objetivoId.isNotEmpty) {
            final hasRecent =
                await hasRecentReportForStation(userId, objetivoId);
            if (hasRecent) {
              return 'Ya reportaste esta estación/tren recientemente. Espera 5 minutos.';
            }
          }

          return 'No puedes reportar en este momento.';
        } catch (e) {
          AppLogger.warning('⚠️ Error obteniendo mensaje específico: $e');
          return 'Error al validar el reporte. Intenta de nuevo.';
        }
      }

      // Test mode bypass ONLY in debug builds
      if (kDebugMode && appMode == AppMode.test) {
        AppLogger.debug('Test mode: skipping location validation');
        return null; // Sin errores
      }

      if (userLocation != null && targetLocation != null) {
        // Bloquear Fake GPS explícitamente
        if (userLocation.isMocked) {
          return 'Ubicación falsa detectada. Por favor, desactive simuladores GPS o aplicaciones emuladoras para poder reportar.';
        }

        final isValid = isValidReportLocation(userLocation, targetLocation,
            appMode: appMode);
        if (!isValid) {
          return 'Debes estar a menos de 500m de la estación/tren para reportar.';
        }
      }

      return null; // Sin errores
    } catch (e) {
      AppLogger.error('❌ Error inesperado en getValidationErrorMessage: $e');
      return 'Error al validar el reporte. Intenta de nuevo.';
    }
  }
}
