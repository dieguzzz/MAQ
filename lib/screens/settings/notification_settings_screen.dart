import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:app_settings/app_settings.dart';
import '../../theme/metro_theme.dart';
import '../../services/core/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // Claves para SharedPreferences
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyReportNotifications = 'notifications_reports';
  static const String _keyDelayNotifications = 'notifications_delays';
  static const String _keyConfirmationNotifications =
      'notifications_confirmations';
  static const String _keyAchievementNotifications =
      'notifications_achievements';

  bool _notificationsEnabled = true;
  bool _reportNotifications = true;
  bool _delayNotifications = true;
  bool _confirmationNotifications = true;
  bool _achievementNotifications = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool(_keyNotificationsEnabled) ?? true;
      _reportNotifications = prefs.getBool(_keyReportNotifications) ?? true;
      _delayNotifications = prefs.getBool(_keyDelayNotifications) ?? true;
      _confirmationNotifications =
          prefs.getBool(_keyConfirmationNotifications) ?? true;
      _achievementNotifications =
          prefs.getBool(_keyAchievementNotifications) ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    await _saveSetting(_keyNotificationsEnabled, value);

    if (!value) {
      // Si se desactivan todas, desactivar también las individuales
      setState(() {
        _reportNotifications = false;
        _delayNotifications = false;
        _confirmationNotifications = false;
        _achievementNotifications = false;
      });
      await Future.wait([
        _saveSetting(_keyReportNotifications, false),
        _saveSetting(_keyDelayNotifications, false),
        _saveSetting(_keyConfirmationNotifications, false),
        _saveSetting(_keyAchievementNotifications, false),
      ]);
    } else {
      // Si se activan, activar también las individuales por defecto
      setState(() {
        _reportNotifications = true;
        _delayNotifications = true;
        _confirmationNotifications = true;
        _achievementNotifications = true;
      });
      await Future.wait([
        _saveSetting(_keyReportNotifications, true),
        _saveSetting(_keyDelayNotifications, true),
        _saveSetting(_keyConfirmationNotifications, true),
        _saveSetting(_keyAchievementNotifications, true),
      ]);
    }

    // Verificar permisos del sistema
    await _checkNotificationPermissions();
  }

  Future<void> _toggleReportNotifications(bool value) async {
    setState(() {
      _reportNotifications = value;
    });
    await _saveSetting(_keyReportNotifications, value);
  }

  Future<void> _toggleDelayNotifications(bool value) async {
    setState(() {
      _delayNotifications = value;
    });
    await _saveSetting(_keyDelayNotifications, value);
  }

  Future<void> _toggleConfirmationNotifications(bool value) async {
    setState(() {
      _confirmationNotifications = value;
    });
    await _saveSetting(_keyConfirmationNotifications, value);
  }

  Future<void> _toggleAchievementNotifications(bool value) async {
    setState(() {
      _achievementNotifications = value;
    });
    await _saveSetting(_keyAchievementNotifications, value);
  }

  Future<void> _checkNotificationPermissions() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.getNotificationSettings();

    if (settings.authorizationStatus == AuthorizationStatus.denied ||
        settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      if (mounted) {
        _showPermissionDialog();
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permisos de Notificaciones'),
        content: const Text(
          'Para recibir notificaciones, necesitas habilitar los permisos en la configuración del sistema.\n\n'
          '¿Deseas abrir la configuración ahora?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _openAppSettings();
            },
            child: const Text('Abrir Configuración'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notificaciones')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Toggle principal
          Card(
            child: SwitchListTile(
              title: const Text(
                'Notificaciones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                _notificationsEnabled
                    ? 'Las notificaciones están activadas'
                    : 'Las notificaciones están desactivadas',
              ),
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
              secondary: Icon(
                _notificationsEnabled
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                color: _notificationsEnabled ? MetroColors.blue : Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tipos de notificaciones
          if (_notificationsEnabled) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Tipos de Notificaciones',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: MetroColors.grayDark,
                ),
              ),
            ),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Reportes Nuevos'),
                    subtitle: const Text(
                      'Recibe notificaciones cuando hay nuevos reportes cerca de ti',
                    ),
                    value: _reportNotifications,
                    onChanged: _toggleReportNotifications,
                    secondary: const Icon(Icons.report),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Retrasos y Alertas'),
                    subtitle: const Text(
                      'Notificaciones sobre retrasos en el servicio del metro',
                    ),
                    value: _delayNotifications,
                    onChanged: _toggleDelayNotifications,
                    secondary: const Icon(Icons.schedule),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Confirmaciones'),
                    subtitle: const Text(
                      'Notificaciones cuando otros usuarios confirman tus reportes',
                    ),
                    value: _confirmationNotifications,
                    onChanged: _toggleConfirmationNotifications,
                    secondary: const Icon(Icons.check_circle),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Logros y Badges'),
                    subtitle: const Text(
                      'Notificaciones cuando desbloqueas nuevos badges o logros',
                    ),
                    value: _achievementNotifications,
                    onChanged: _toggleAchievementNotifications,
                    secondary: const Icon(Icons.stars),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Información adicional
          const Card(
            color: MetroColors.grayLight,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: MetroColors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Información',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Las notificaciones te ayudan a estar al día con:\n'
                    '• Nuevos reportes en tu área\n'
                    '• Retrasos en el servicio\n'
                    '• Confirmaciones de tus reportes\n'
                    '• Logros y badges desbloqueados',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Botón para probar notificación
          if (_notificationsEnabled)
            ElevatedButton.icon(
              onPressed: () async {
                final notificationService = NotificationService();
                await notificationService.showLocalNotification(
                  title: 'Notificación de Prueba',
                  body: '¡Las notificaciones están funcionando correctamente!',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notificación de prueba enviada'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.send),
              label: const Text('Enviar Notificación de Prueba'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
        ],
      ),
    );
  }

  /// Abre la configuración de la app en el sistema para notificaciones
  Future<void> _openAppSettings() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await AppSettings.openAppSettings(type: AppSettingsType.notification);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('No se puede abrir la configuración en esta plataforma'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir configuración: $e'),
          ),
        );
      }
    }
  }
}
