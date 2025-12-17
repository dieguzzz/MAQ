import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Callback para navegación cuando se recibe notificación
  Function(Map<String, dynamic>)? onNotificationTapped;

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings =
        await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Initialize local notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Get FCM token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveFCMToken(token);
      }

      // Listen to token refresh
      _firebaseMessaging.onTokenRefresh.listen(_saveFCMToken);

      // Listen to foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
      
      // Handle notification when app was closed
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotification(initialMessage, fromBackground: true);
      }
    }
  }

  Future<void> _saveFCMToken(String token) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;
      
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      print('FCM Token guardado para usuario $userId');
    } catch (e) {
      print('Error guardando FCM token: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    print('Notification tapped: ${response.payload}');
    if (response.payload != null && onNotificationTapped != null) {
      // Parse payload si es necesario
      onNotificationTapped!({'payload': response.payload});
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Manejar notificación en primer plano
    _handleNotification(message, fromBackground: false);
    
    // Mostrar notificación local
    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'MetroPTY',
      message.notification?.body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'metropty_channel',
          'MetroPTY Notifications',
          channelDescription: 'Notificaciones del Metro de Panamá',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: message.data.toString(),
    );
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    // Handle notification tap when app was in background
    _handleNotification(message, fromBackground: true);
  }
  
  void _handleNotification(RemoteMessage message, {bool fromBackground = false}) {
    final data = message.data;
    final type = data['type'];
    
    print('Notificación recibida: $type');
    
    switch (type) {
      case 'eta_validation':
        _handleETAValidation(data, fromBackground);
        break;
      case 'confirmation_request':
        // TODO: Manejar solicitudes de confirmación
        break;
      case 'achievement_unlocked':
        // TODO: Manejar logros desbloqueados
        break;
      case 'station_alert':
        // TODO: Manejar alertas de estación
        break;
      default:
        print('Tipo de notificación desconocido: $type');
    }
  }
  
  void _handleETAValidation(Map<String, dynamic> data, bool fromBackground) {
    final reportId = data['reportId'];
    final stationId = data['stationId'];
    final stationName = data['stationName'] ?? 'la estación';
    
    if (onNotificationTapped != null) {
      onNotificationTapped!({
        'type': 'eta_validation',
        'reportId': reportId,
        'stationId': stationId,
        'stationName': stationName,
        'fromBackground': fromBackground,
      });
    }
  }

  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'metropty_channel',
          'MetroPTY Notifications',
          channelDescription: 'Notificaciones del Metro de Panamá',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: payload,
    );
  }
}

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message received: ${message.messageId}');
}

