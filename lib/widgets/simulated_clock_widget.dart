import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/simulation/simulated_time_service.dart';
import '../services/core/app_mode_service.dart';
import '../providers/auth_provider.dart';

/// Widget que muestra el tiempo simulado cuando está en modo test
class SimulatedClockWidget extends StatefulWidget {
  const SimulatedClockWidget({super.key});

  @override
  State<SimulatedClockWidget> createState() => _SimulatedClockWidgetState();
}

class _SimulatedClockWidgetState extends State<SimulatedClockWidget> {
  Timer? _timer;
  final SimulatedTimeService _simulatedTimeService = SimulatedTimeService();

  @override
  void initState() {
    super.initState();
    // Actualizar cada segundo para mostrar el reloj en tiempo real
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        if (user == null) return const SizedBox.shrink();

        return StreamBuilder(
          stream: AppModeService().watchMode(user.uid),
          builder: (context, snapshot) {
            final mode = snapshot.data ?? AppMode.development;

            if (mode != AppMode.test) {
              return const SizedBox.shrink();
            }

            final simulatedTime =
                _simulatedTimeService.getCurrentSimulatedTime();
            final hour = simulatedTime.hour.toString().padLeft(2, '0');
            final minute = simulatedTime.minute.toString().padLeft(2, '0');
            final second = simulatedTime.second.toString().padLeft(2, '0');

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$hour:$minute:$second',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
