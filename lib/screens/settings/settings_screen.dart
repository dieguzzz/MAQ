import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_screen.dart';
import '../premium/premium_screen.dart';
import '../profile/edit_profile_screen.dart';
import 'notification_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Cuenta',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Editar Perfil'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Privacidad',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Permisos de Ubicación'),
            subtitle: const Text('Gestionar consentimiento de ubicación'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showLocationConsentDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notificaciones'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.star, color: Colors.amber),
            title: const Text('Premium'),
            subtitle: const Text('Desbloquea funciones exclusivas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PremiumScreen(),
                ),
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Legal',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Política de Privacidad'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Términos de Servicio'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Datos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'Borrar mis Datos',
                  style: TextStyle(color: Colors.red),
                ),
                subtitle: const Text('Eliminar cuenta y todos los datos asociados'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showDeleteDataDialog(context, authProvider);
                },
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Acerca de',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Versión'),
            subtitle: const Text('1.0.0'),
          ),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Esta aplicación NO es oficial del Metro de Panamá. Los datos son proporcionados por la comunidad.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationConsentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permisos de Ubicación'),
        content: const Text(
          'MetroPTY necesita tu ubicación para:\n\n'
          '• Mostrar tu posición en el mapa\n'
          '• Sugerir estaciones cercanas\n'
          '• Mejorar la precisión de reportes\n\n'
          'Tu ubicación se usa solo cuando la app está en uso y se comparte de forma agregada y anónima.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _openAppSettings(context);
            },
            child: const Text('Configurar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDataDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar mis Datos'),
        content: const Text(
          'Esta acción eliminará permanentemente:\n\n'
          '• Tu cuenta\n'
          '• Todos tus reportes\n'
          '• Tu historial y estadísticas\n'
          '• Tus badges y logros\n\n'
          'Esta acción NO se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Mostrar confirmación final con campo de texto
              final confirmText = await showDialog<String>(
                context: context,
                barrierDismissible: false,
                builder: (context) => _DeleteAccountDialog(),
              );

              if (confirmText == 'ELIMINAR' && context.mounted) {
                // Mostrar indicador de carga
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final success = await authProvider.deleteAccount();

                if (context.mounted) {
                  Navigator.pop(context); // Cerrar indicador de carga

                  if (success) {
                    // Navegar a la pantalla de login
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tu cuenta ha sido eliminada exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error al eliminar la cuenta. Por favor, intenta de nuevo.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  /// Abre la configuración de la app en el sistema
  static Future<void> _openAppSettings(BuildContext context) async {
    try {
      Uri settingsUri;
      
      if (Platform.isAndroid) {
        // Android: Abrir configuración de la app específica
        const packageName = 'com.example.metropty';
        settingsUri = Uri.parse('package:$packageName');
      } else if (Platform.isIOS) {
        // iOS: Abrir configuración de la app
        settingsUri = Uri.parse('app-settings:');
      } else {
        // Web u otra plataforma
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se puede abrir la configuración en esta plataforma'),
            ),
          );
        }
        return;
      }

      if (await canLaunchUrl(settingsUri)) {
        await launchUrl(settingsUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir la configuración del sistema'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir configuración: $e'),
          ),
        );
      }
    }
  }
}

/// Diálogo para confirmar eliminación de cuenta con campo de texto
class _DeleteAccountDialog extends StatefulWidget {
  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final TextEditingController _confirmController = TextEditingController();
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(() {
      setState(() {
        _canDelete = _confirmController.text.trim() == 'ELIMINAR';
      });
    });
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        '¿Estás seguro?',
        style: TextStyle(color: Colors.red),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Esta acción no se puede deshacer. Se eliminarán permanentemente:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          const Text('• Tu cuenta de usuario'),
          const Text('• Tu perfil y datos personales'),
          const Text('• Tu foto de perfil'),
          const SizedBox(height: 16),
          const Text(
            'Escribe "ELIMINAR" para confirmar:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmController,
            decoration: InputDecoration(
              hintText: 'Escribe ELIMINAR',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              errorText: _confirmController.text.isNotEmpty &&
                      _confirmController.text.trim() != 'ELIMINAR'
                  ? 'Debes escribir exactamente "ELIMINAR"'
                  : null,
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _canDelete
              ? () => Navigator.pop(context, _confirmController.text.trim())
              : null,
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Eliminar cuenta'),
        ),
      ],
    );
  }
}

