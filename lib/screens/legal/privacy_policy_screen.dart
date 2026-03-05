import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidad'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Política de Privacidad de MetroPTY',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Última actualización: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Información que Recopilamos',
              'MetroPTY recopila la siguiente información:\n\n'
                  '• Información de cuenta: nombre, email (si te registras)\n'
                  '• Ubicación: tu ubicación GPS cuando usas la aplicación para reportar el estado del metro\n'
                  '• Reportes: información sobre estaciones y trenes que reportas\n'
                  '• Datos de uso: cómo interactúas con la aplicación',
            ),
            _buildSection(
              '2. Cómo Usamos tu Información',
              'Utilizamos tu información para:\n\n'
                  '• Proporcionar el servicio de reportes en tiempo real\n'
                  '• Mejorar la precisión de los reportes mediante verificación comunitaria\n'
                  '• Personalizar tu experiencia (niveles, badges, rankings)\n'
                  '• Enviar notificaciones relevantes sobre el estado del metro',
            ),
            _buildSection(
              '3. Compartir Información',
              'No vendemos tu información personal. Compartimos información de forma agregada y anónima para:\n\n'
                  '• Mostrar el estado general de estaciones y trenes\n'
                  '• Calcular tiempos estimados\n'
                  '• Generar rankings y estadísticas comunitarias',
            ),
            _buildSection(
              '4. Seguridad de Datos',
              'Implementamos medidas de seguridad para proteger tu información:\n\n'
                  '• Encriptación de datos en tránsito y en reposo\n'
                  '• Autenticación segura mediante Firebase\n'
                  '• Acceso limitado a datos personales',
            ),
            _buildSection(
              '5. Tus Derechos',
              'Tienes derecho a:\n\n'
                  '• Acceder a tus datos personales\n'
                  '• Solicitar la eliminación de tu cuenta y datos\n'
                  '• Retirar tu consentimiento en cualquier momento\n'
                  '• Exportar tus datos',
            ),
            _buildSection(
              '6. Contacto',
              'Para preguntas sobre esta política de privacidad, contáctanos a través de la aplicación o en el perfil de usuario.',
            ),
            const SizedBox(height: 32),
            Container(
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
                      'Esta aplicación NO es oficial del Metro de Panamá. Los datos son proporcionados por la comunidad de usuarios.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
