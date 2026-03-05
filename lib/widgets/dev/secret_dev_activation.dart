import 'package:flutter/material.dart';
import '../../services/core/dev_service.dart';

/// Widget que detecta gesto secreto (1 tap) para activar modo desarrollador
class SecretDevActivation extends StatefulWidget {
  final Widget child;

  const SecretDevActivation({
    super.key,
    required this.child,
  });

  @override
  State<SecretDevActivation> createState() => _SecretDevActivationState();
}

class _SecretDevActivationState extends State<SecretDevActivation> {
  int tapCount = 0;
  DateTime? lastTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final now = DateTime.now();

        // Reset si pasó más de 2 segundos desde el último tap
        if (lastTap != null &&
            now.difference(lastTap!) > const Duration(seconds: 2)) {
          tapCount = 0;
        }

        tapCount++;
        lastTap = now;

        // 1 tap activa modo dev
        if (tapCount >= 1) {
          DevService.toggleDevMode();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  DevService.devModeEnabled
                      ? '🧪 Modo Desarrollador Activado'
                      : '🧪 Modo Desarrollador Desactivado',
                ),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 2),
              ),
            );
          }

          tapCount = 0;
        }
      },
      child: widget.child,
    );
  }
}
