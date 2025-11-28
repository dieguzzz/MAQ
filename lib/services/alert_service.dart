import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import 'notification_service.dart';

class AlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();

  /// Envía alertas a usuarios afectados por un reporte
  Future<void> sendRelevantAlerts(ReportModel report) async {
    try {
      final objetivoId = report.objetivoId;
      final estadoPrincipal = report.estadoPrincipal;
      final prioridad = report.prioridad;

      // Solo alertar reportes críticos o prioritarios
      final isCritical = prioridad || 
          estadoPrincipal == 'lleno' || 
          estadoPrincipal == 'cerrado' || 
          estadoPrincipal == 'detenido' ||
          estadoPrincipal == 'sardina';

      if (!isCritical) {
        return; // No alertar reportes normales
      }

      // 1. Usuarios que tienen esta estación como favorita
      final favoriteUsers = await _getUsersWithFavoriteStation(objetivoId);

      // 2. Usuarios cercanos (dentro de 5 km)
      final nearbyUsers = await _getUsersNearLocation(
        report.ubicacion,
        radiusKm: 5.0,
      );

      // 3. Combinar y eliminar duplicados
      final allAffectedUsers = <String, UserModel>{};
      for (final user in favoriteUsers) {
        allAffectedUsers[user.uid] = user;
      }
      for (final user in nearbyUsers) {
        allAffectedUsers[user.uid] = user;
      }

      // 4. Enviar notificaciones
      for (final user in allAffectedUsers.values) {
        await _sendAlertToUser(user, report);
      }
    } catch (e) {
      print('Error sending alerts: $e');
    }
  }

  /// Envía alerta prioritaria para reportes críticos
  Future<void> sendPriorityAlert(ReportModel report) async {
    try {
      // Expandir radio de notificación para reportes prioritarios
      final nearbyUsers = await _getUsersNearLocation(
        report.ubicacion,
        radiusKm: 10.0, // Radio más amplio para reportes prioritarios
      );

      for (final user in nearbyUsers) {
        await _sendPriorityAlertToUser(user, report);
      }
    } catch (e) {
      print('Error sending priority alert: $e');
    }
  }

  /// Obtiene usuarios que tienen una estación como favorita
  Future<List<UserModel>> _getUsersWithFavoriteStation(String stationId) async {
    try {
      // Nota: Esto requeriría un campo 'favorite_stations' en el modelo de usuario
      // Por ahora, retornamos lista vacía
      // En el futuro, se podría implementar así:
      // final snapshot = await _firestore
      //     .collection('users')
      //     .where('favorite_stations', 'array-contains', stationId)
      //     .get();
      // return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
      return [];
    } catch (e) {
      print('Error getting users with favorite station: $e');
      return [];
    }
  }

  /// Obtiene usuarios cercanos a una ubicación
  Future<List<UserModel>> _getUsersNearLocation(
    GeoPoint location, {
    required double radiusKm,
  }) async {
    try {
      // Obtener todos los usuarios con ubicación reciente
      final snapshot = await _firestore
          .collection('users')
          .where('ultima_ubicacion', isNotEqualTo: null)
          .get();

      final nearbyUsers = <UserModel>[];
      for (final doc in snapshot.docs) {
        final user = UserModel.fromFirestore(doc);
        if (user.ultimaUbicacion == null) continue;

        final distance = _calculateDistance(
          location.latitude,
          location.longitude,
          user.ultimaUbicacion!.latitude,
          user.ultimaUbicacion!.longitude,
        );

        if (distance <= radiusKm) {
          nearbyUsers.add(user);
        }
      }

      return nearbyUsers;
    } catch (e) {
      print('Error getting nearby users: $e');
      return [];
    }
  }

  /// Envía alerta a un usuario
  Future<void> _sendAlertToUser(UserModel user, ReportModel report) async {
    try {
      final tipo = report.tipo == TipoReporte.estacion ? 'Estación' : 'Tren';
      final estadoText = _getEstadoText(report.estadoPrincipal ?? '');

      await _notificationService.showLocalNotification(
        title: '🚨 Alerta en $tipo',
        body: 'Nuevo reporte: $estadoText',
        payload: 'report_${report.id}',
      );
    } catch (e) {
      print('Error sending alert to user: $e');
    }
  }

  /// Envía alerta prioritaria a un usuario
  Future<void> _sendPriorityAlertToUser(UserModel user, ReportModel report) async {
    try {
      final tipo = report.tipo == TipoReporte.estacion ? 'Estación' : 'Tren';
      final estadoText = _getEstadoText(report.estadoPrincipal ?? '');

      await _notificationService.showLocalNotification(
        title: '🚨🚨 ALERTA PRIORITARIA - $tipo',
        body: 'Reporte crítico: $estadoText. ¡Revisa tu ruta!',
        payload: 'priority_report_${report.id}',
      );
    } catch (e) {
      print('Error sending priority alert to user: $e');
    }
  }

  /// Calcula distancia entre dos puntos (Haversine)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final sinDLat = math.sin(dLat / 2);
    final sinDLon = math.sin(dLon / 2);
    final cosLat1 = math.cos(_toRadians(lat1));
    final cosLat2 = math.cos(_toRadians(lat2));

    final a = sinDLat * sinDLat +
        cosLat1 * cosLat2 * sinDLon * sinDLon;
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  String _getEstadoText(String estadoPrincipal) {
    const estados = {
      'normal': 'Normal',
      'moderado': 'Moderado',
      'lleno': 'Lleno',
      'retraso': 'Retraso',
      'cerrado': 'Cerrado',
      'asientos_disponibles': 'Asientos Disponibles',
      'de_pie_comodo': 'De Pie Cómodo',
      'sardina': 'Sardina',
      'express': 'Express',
      'lento': 'Lento',
      'detenido': 'Detenido',
    };
    return estados[estadoPrincipal] ?? estadoPrincipal;
  }
}

