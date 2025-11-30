import 'package:flutter/material.dart';
import '../models/station_model.dart';
import '../theme/metro_theme.dart';
import '../services/firebase_service.dart';
import '../services/learning_report_service.dart';
import '../models/learning_report_model.dart';
import 'delay_report_modal.dart';

/// Diálogo para confirmar llegada a estación
class ArrivalConfirmationDialog extends StatelessWidget {
  final StationModel station;
  final int tiempoEstimadoMostrado; // Tiempo estimado que se mostró al usuario
  final int? tiempoReal; // Tiempo real de llegada (opcional, puede ser null)

  const ArrivalConfirmationDialog({
    super.key,
    required this.station,
    required this.tiempoEstimadoMostrado,
    this.tiempoReal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseService = FirebaseService();
    final learningReportService = LearningReportService();
    final currentUser = firebaseService.getCurrentUser();

    if (currentUser == null) {
      return AlertDialog(
        title: const Text('Error'),
        content: const Text('Debes iniciar sesión para confirmar llegada'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      );
    }

    final tiempoRealMostrado = tiempoReal ?? tiempoEstimadoMostrado;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: Text(
        'Confirmar Llegada',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            station.nombre,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MetroColors.grayLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tiempo estimado mostrado:',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      '$tiempoEstimadoMostrado min',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tiempo real:',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      '$tiempoRealMostrado min',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: MetroColors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '¿Cómo fue tu llegada?',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Usuario llegó a tiempo
            await _handleOnTimeArrival(
              context,
              learningReportService,
              currentUser.uid,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: MetroColors.stateNormal,
            foregroundColor: Colors.white,
          ),
          child: const Text('Llegué a tiempo'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Abrir modal de retraso
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (modalContext) => DelayReportModal(
                station: station,
                tiempoEstimadoMostrado: tiempoEstimadoMostrado,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: MetroColors.stateCritical,
            foregroundColor: Colors.white,
          ),
          child: const Text('Llegué con retraso'),
        ),
      ],
    );
  }

  Future<void> _handleOnTimeArrival(
    BuildContext context,
    LearningReportService service,
    String userId,
  ) async {
    try {
      final ahora = DateTime.now();
      final report = LearningReportModel(
        id: '', // Se genera en Firestore
        usuarioId: userId,
        estacionId: station.id,
        linea: station.linea,
        horaLlegadaReal: ahora,
        tiempoEstimadoMostrado: tiempoEstimadoMostrado,
        retrasoMinutos: 0,
        llegadaATiempo: true,
        creadoEn: ahora,
      );

      await service.createLearningReport(report);

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Llegada confirmada! Gracias por tu aporte'),
            backgroundColor: MetroColors.stateNormal,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al confirmar llegada: $e'),
            backgroundColor: MetroColors.stateCritical,
          ),
        );
      }
    }
  }
}

