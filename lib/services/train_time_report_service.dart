import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'gamification_service.dart';
import 'simplified_report_service.dart';

/// Servicio para manejar reportes de tiempos de tren desde las pantallas de estación
class TrainTimeReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GamificationService _gamificationService = GamificationService();
  final SimplifiedReportService _simplifiedReportService =
      SimplifiedReportService();

  /// Crea un reporte de tiempos de tren desde la pantalla de la estación
  Future<String> createTrainTimeReport({
    required String stationId,
    required String line, // 'linea1' | 'linea2'
    required String
        direction, // Nombre de destino: 'Villa Zaita', 'Albrook', etc.
    required int? nextTrainMinutes, // 1..12 (o null si "No sé")
    required bool nextTrainUnknown, // true si el usuario tocó "No sé"
    int? followingTrainMinutes, // Opcional: 1..12
    Position? userPosition,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Usuario no autenticado');

    // Calcular puntos
    const basePoints =
        5; // Reporte dirección + próximo tren (aunque sea "No sé")
    final followingBonus = followingTrainMinutes != null ? 3 : 0;
    final totalPoints = basePoints + followingBonus;

    String? nextTrainRange;
    String? followingTrainRange;

    // Compatibilidad temporal: mantener campos viejos derivados para clientes/analytics.
    // (La fuente de verdad pasa a ser nextTrainMinutes/followingTrainMinutes)
    if (nextTrainUnknown || nextTrainMinutes == null) {
      nextTrainRange = 'unknown';
    } else if (nextTrainMinutes <= 1) {
      nextTrainRange = '0-1';
    } else if (nextTrainMinutes == 2) {
      nextTrainRange = '2';
    } else if (nextTrainMinutes == 3) {
      nextTrainRange = '3';
    } else if (nextTrainMinutes == 4) {
      nextTrainRange = '4';
    } else if (nextTrainMinutes == 5) {
      nextTrainRange = '5';
    } else {
      nextTrainRange = '5+';
    }

    if (followingTrainMinutes != null) {
      if (followingTrainMinutes <= 4) {
        followingTrainRange = '3-4';
      } else if (followingTrainMinutes <= 6) {
        followingTrainRange = '5-6';
      } else if (followingTrainMinutes <= 8) {
        followingTrainRange = '7-8';
      } else {
        followingTrainRange = '10+';
      }
    }

    final reportData = {
      'stationId': stationId,
      'line': line,
      'direction': direction,
      'nextTrainRange': nextTrainRange,
      'nextTrainMinutes': nextTrainMinutes,
      'followingTrainRange': followingTrainRange,
      'followingTrainMinutes': followingTrainMinutes,
      'nextTrainUnknown': nextTrainUnknown,
      'source': 'station_display', // Viene de la pantalla oficial
      'reportedAt': FieldValue.serverTimestamp(),
      'userId': userId,
      'confidenceWeight': 'high',
      'points': totalPoints,
      'userLocation': userPosition != null
          ? GeoPoint(userPosition.latitude, userPosition.longitude)
          : null,
    };

    try {
      // Crear el documento (la colección se crea automáticamente si no existe)
      final docRef =
          await _firestore.collection('train_time_reports').add(reportData);

      // Actualizar con ID (con manejo de errores)
      try {
        await docRef.update({'id': docRef.id});
      } catch (e) {
        // Si falla actualizar el ID, no es crítico, continuar
        print('Advertencia: No se pudo actualizar el campo id: $e');
      }

      // Verificar si hay reporte duplicado reciente (< 3 min)
      try {
        await _checkDuplicateReport(stationId, userId);
      } catch (e) {
        // Si falla verificar duplicados, no es crítico, continuar
        print('Advertencia: No se pudo verificar duplicados: $e');
      }

      // Otorgar puntos al usuario (ETA panel report)
      await _gamificationService.awardPointsForEtaPanelReport(
        userId: userId,
        points: totalPoints,
        stationId: stationId,
      );

      // --- NEW: Integration with SimplifiedReportService to update station panel ---
      try {
        String? etaBucket;
        if (nextTrainUnknown || nextTrainMinutes == null) {
          etaBucket = 'unknown';
        } else if (nextTrainMinutes <= 2) {
          etaBucket = '1-2';
        } else if (nextTrainMinutes <= 5) {
          etaBucket = '3-5';
        } else if (nextTrainMinutes <= 8) {
          etaBucket = '6-8';
        } else {
          etaBucket = '9+';
        }

        // Convertir formato: 'linea1' → 'L1', 'linea2' → 'L2'
      final normalizedLine = line == 'linea1' ? 'L1' : line == 'linea2' ? 'L2' : line;

      // Convertir nombre de destino a directionCode: 'A' o 'B'
      String? directionCode;
      final dirLower = direction.toLowerCase();
      if (line == 'linea1') {
        directionCode = dirLower.contains('villa zaita') ? 'A' : 'B';
      } else {
        directionCode = dirLower.contains('nuevo tocumen') ? 'A' : 'B';
      }

      await _simplifiedReportService.createTrainReport(
          stationId: stationId,
          etaBucket: etaBucket,
          crowdLevel:
              3, // Default level as it's not provided in this simplified flow
          trainLine: normalizedLine,
          direction: directionCode,
          userPosition: userPosition,
          isPanelTime: true,
        );
      } catch (e) {
        print('Warning: Could not create simplified report: $e');
      }
      // -----------------------------------------------------------------------------

      return docRef.id;
    } on FirebaseException catch (e) {
      // Manejar errores específicos de Firebase
      if (e.code == 'permission-denied') {
        throw Exception(
            'No tienes permiso para crear reportes. Verifica que estés autenticado.');
      } else if (e.code == 'unavailable') {
        throw Exception(
            'Firestore no está disponible. Verifica tu conexión a internet.');
      } else {
        throw Exception('Error al crear reporte: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado al crear reporte: $e');
    }
  }

  /// Verifica si hay un reporte duplicado reciente
  Future<void> _checkDuplicateReport(String stationId, String userId) async {
    try {
      final threeMinutesAgo =
          DateTime.now().subtract(const Duration(minutes: 3));

      // Query simplificado: solo por stationId y userId (sin orderBy para evitar índice)
      final recentReports = await _firestore
          .collection('train_time_reports')
          .where('stationId', isEqualTo: stationId)
          .where('userId', isEqualTo: userId)
          .limit(10) // Limitar resultados
          .get();

      // Filtrar en memoria los que están dentro de los últimos 3 minutos
      final filteredReports = recentReports.docs.where((doc) {
        final reportedAt = (doc.data()['reportedAt'] as Timestamp?)?.toDate();
        if (reportedAt == null) return false;
        return reportedAt.isAfter(threeMinutesAgo);
      }).toList();

      // Ordenar por fecha (más reciente primero)
      filteredReports.sort((a, b) {
        final aTime =
            (a.data()['reportedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
        final bTime =
            (b.data()['reportedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });

      // Si hay más de 1 (el que acabamos de crear), eliminar duplicados más antiguos
      if (filteredReports.length > 1) {
        // Mantener el más reciente (primero en la lista), eliminar el resto
        for (var i = 1; i < filteredReports.length; i++) {
          await filteredReports[i].reference.delete();
        }
      }
    } catch (e) {
      // Si falla (por ejemplo, falta índice), no es crítico, solo loguear
      print('Advertencia: No se pudo verificar duplicados: $e');
    }
  }

  /// Verifica si el usuario puede reportar (no ha reportado en los últimos 3 min)
  Future<bool> canUserReport(String stationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final threeMinutesAgo =
          DateTime.now().subtract(const Duration(minutes: 3));

      // Query simplificado: solo por stationId y userId (sin orderBy para evitar índice)
      final recentReports = await _firestore
          .collection('train_time_reports')
          .where('stationId', isEqualTo: stationId)
          .where('userId', isEqualTo: userId)
          .limit(5)
          .get();

      // Buscar el reporte más reciente en memoria
      DateTime? mostRecentTime;
      for (final doc in recentReports.docs) {
        final reportedAt = (doc.data()['reportedAt'] as Timestamp?)?.toDate();
        if (reportedAt != null) {
          if (mostRecentTime == null || reportedAt.isAfter(mostRecentTime)) {
            mostRecentTime = reportedAt;
          }
        }
      }

      // Si no hay reportes recientes, puede reportar
      if (mostRecentTime == null) return true;

      // Verificar si el reporte más reciente está dentro de los últimos 3 minutos
      return mostRecentTime.isBefore(threeMinutesAgo);
    } catch (e) {
      // Si falla (por ejemplo, falta índice), permitir reportar
      print('Advertencia: No se pudo verificar si puede reportar: $e');
      return true;
    }
  }
}
