import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos de Servicio'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Términos de Servicio de MetroPTY',
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
              '1. Aceptación de los Términos',
              'Al usar MetroPTY, aceptas estos términos de servicio. Si no estás de acuerdo, no uses la aplicación.',
            ),
            _buildSection(
              '2. Uso del Servicio',
              'MetroPTY es una aplicación colaborativa que permite a los usuarios reportar el estado del Metro de Panamá. Debes:\n\n'
                  '• Proporcionar información precisa y honesta\n'
                  '• No usar la aplicación para fines ilegales\n'
                  '• Respetar a otros usuarios\n'
                  '• No hacer reportes falsos o maliciosos',
            ),
            _buildSection(
              '3. Aviso Importante',
              '⚠️ ESTA APLICACIÓN NO ES OFICIAL DEL METRO DE PANAMÁ\n\n'
                  '• Los datos son proporcionados por la comunidad\n'
                  '• No garantizamos la precisión absoluta de los reportes\n'
                  '• Usa la información como referencia, no como fuente oficial\n'
                  '• Siempre verifica información crítica con fuentes oficiales',
            ),
            _buildSection(
              '4. Responsabilidad del Usuario',
              'Eres responsable de:\n\n'
                  '• La veracidad de tus reportes\n'
                  '• Mantener segura tu cuenta\n'
                  '• Tu conducta en la aplicación\n'
                  '• El uso que hagas de la información proporcionada',
            ),
            _buildSection(
              '5. Limitación de Responsabilidad',
              'MetroPTY no se hace responsable de:\n\n'
                  '• Decisiones tomadas basadas en información de la app\n'
                  '• Retrasos o problemas en el servicio del metro\n'
                  '• Pérdidas o daños derivados del uso de la aplicación\n'
                  '• La precisión de reportes de otros usuarios',
            ),
            _buildSection(
              '6. Propiedad Intelectual',
              'El contenido de la aplicación, incluyendo diseño, logos y código, es propiedad de MetroPTY. Los reportes de usuarios son de su propiedad pero otorgan licencia de uso a la aplicación.',
            ),
            _buildSection(
              '7. Modificaciones del Servicio',
              'Nos reservamos el derecho de modificar, suspender o discontinuar el servicio en cualquier momento sin previo aviso.',
            ),
            _buildSection(
              '8. Terminación',
              'Podemos terminar o suspender tu acceso al servicio si violas estos términos o realizas actividades que consideremos inapropiadas.',
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'RECUERDA: Esta aplicación es una herramienta colaborativa. Los datos no son oficiales. Úsala como referencia complementaria.',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
