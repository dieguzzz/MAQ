import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../services/firebase_service.dart';
import '../services/app_mode_service.dart';

class ReportValidationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Verifica si el usuario puede reportar (anti-spam)
  /// - Máximo 10 reportes por hora
  /// - No reportar misma estación en 5 minutos
  Future<bool> canUserReport(String userId, String? objetivoId) async {
    try {
      // Validar parámetros
      if (userId.isEmpty) {
        print('⚠️ canUserReport: userId está vacío');
        return false;
      }

      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));

      print('🔍 Validando reporte - userId: $userId, objetivoId: $objetivoId');

      // Verificar límite de reportes por hora
      try {
        final recentReportsSnapshot = await _firestore
            .collection('reports')
            .where('usuario_id', isEqualTo: userId)
            .where('creado_en', isGreaterThan: Timestamp.fromDate(oneHourAgo))
            .get();

        final recentCount = recentReportsSnapshot.docs.length;
        print('📊 Reportes en la última hora: $recentCount');

        if (recentCount >= 10) {
          print('❌ Límite de spam alcanzado: $recentCount reportes en la última hora');
          return false; // Límite de spam alcanzado
        }
      } catch (e) {
        print('⚠️ Error verificando límite de reportes por hora: $e');
        // Continuar con la validación siguiente en lugar de bloquear
      }

      // Verificar si ya reportó esta estación/tren recientemente
      if (objetivoId != null && objetivoId.isNotEmpty) {
        try {
          final recentSameTargetSnapshot = await _firestore
              .collection('reports')
              .where('usuario_id', isEqualTo: userId)
              .where('objetivo_id', isEqualTo: objetivoId)
              .where('creado_en', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
              .get();

          if (recentSameTargetSnapshot.docs.isNotEmpty) {
            print('❌ Ya reportó esta estación/tren recientemente (últimos 5 minutos)');
            return false; // Ya reportó esta estación/tren recientemente
          }
          print('✅ No hay reportes recientes para este objetivo');
        } catch (e) {
          print('⚠️ Error verificando reportes recientes del mismo objetivo: $e');
          // Continuar permitiendo el reporte si hay error de red
        }
      } else {
        print('⚠️ objetivoId es null o vacío, saltando validación de duplicados');
      }

      print('✅ Validación anti-spam pasada');
      return true;
    } catch (e, stackTrace) {
      print('❌ Error inesperado en canUserReport: $e');
      print('📍 Stack trace: $stackTrace');
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
    // En modo Test, omitir validación de ubicación
    if (appMode == AppMode.test) {
      print('🧪 Modo Test: Omitiendo validación de ubicación');
      return true;
    }

    if (userLocation == null) {
      return false; // Sin ubicación del usuario
    }

    final distance = Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      targetLocation.latitude,
      targetLocation.longitude,
    );

    // Máximo 1 km (1000 metros)
    return distance <= 1000;
  }

  /// Verifica si el usuario ya reportó recientemente para esta estación/tren
  Future<bool> hasRecentReportForStation(
    String userId,
    String objetivoId,
  ) async {
    try {
      final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));

      final recentReportsSnapshot = await _firestore
          .collection('reports')
          .where('usuario_id', isEqualTo: userId)
          .where('objetivo_id', isEqualTo: objetivoId)
          .where('creado_en', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
          .limit(1)
          .get();

      return recentReportsSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking recent report: $e');
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
          print('📊 getValidationErrorMessage - Reportes en última hora: $recentCount');

          if (recentCount >= 10) {
            return 'Has alcanzado el límite de reportes por hora (10). Intenta más tarde.';
          }

          if (objetivoId != null && objetivoId.isNotEmpty) {
            final hasRecent = await hasRecentReportForStation(userId, objetivoId);
            if (hasRecent) {
              return 'Ya reportaste esta estación/tren recientemente. Espera 5 minutos.';
            }
          }

          return 'No puedes reportar en este momento.';
        } catch (e) {
          print('⚠️ Error obteniendo mensaje específico: $e');
          return 'Error al validar el reporte. Intenta de nuevo.';
        }
      }

      // En modo Test, omitir validación de ubicación
      if (appMode == AppMode.test) {
        print('🧪 Modo Test: Omitiendo validación de ubicación');
        return null; // Sin errores
      }

      if (userLocation != null && targetLocation != null) {
        final isValid = isValidReportLocation(userLocation, targetLocation, appMode: appMode);
        if (!isValid) {
          return 'Debes estar a menos de 1 km de la estación/tren para reportar.';
        }
      }

      return null; // Sin errores
    } catch (e) {
      print('❌ Error inesperado en getValidationErrorMessage: $e');
      return 'Error al validar el reporte. Intenta de nuevo.';
    }
  }
}

