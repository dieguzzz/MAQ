import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/metro_theme.dart';
import 'google_logo.dart';

class GuestUpgradeDialog extends StatelessWidget {
  final String feature;
  final String? subtitle;

  const GuestUpgradeDialog({
    super.key,
    required this.feature,
    this.subtitle,
  });

  static const _featureMessages = {
    'reportes': 'Reporta y gana puntos por cada contribución',
    'ranking': 'Compite con otros viajeros por el top',
    'logros': 'Desbloquea medallas y sube de nivel',
    'todas las funciones': 'Accede a reportes, logros, ranking y más',
  };

  static const _featureTitles = {
    'reportes': '¡Gana puntos reportando!',
    'ranking': '¡Compite por el top!',
    'logros': '¡Desbloquea logros!',
    'todas las funciones': 'Desbloquea todo el potencial',
  };

  static Future<void> show(BuildContext context, {required String feature, String? subtitle}) {
    return showDialog(
      context: context,
      builder: (_) => GuestUpgradeDialog(feature: feature, subtitle: subtitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _featureTitles[feature] ?? 'Función exclusiva';
    final message = subtitle ?? _featureMessages[feature] ?? 'Vincula tu cuenta de Google para acceder a esta función';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/logo-ico.png', height: 64),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: MetroColors.grayDark.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _linkWithGoogle(context),
              icon: const GoogleLogo(size: 20),
              label: const Text('Vincular con Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MetroColors.blue,
                foregroundColor: MetroColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Ahora no'),
        ),
      ],
    );
  }

  Future<void> _linkWithGoogle(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final error = await authProvider.linkWithGoogle();
    if (error == null) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Cuenta vinculada exitosamente'),
          backgroundColor: MetroColors.stateNormal,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: MetroColors.stateCritical,
        ),
      );
    }
  }
}
