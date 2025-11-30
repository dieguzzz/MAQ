import 'package:flutter/material.dart';
import '../models/station_model.dart';
import '../theme/metro_theme.dart';
import '../services/firebase_service.dart';
import '../services/learning_report_service.dart';
import '../models/learning_report_model.dart';

/// Modal para reportar retraso detallado
class DelayReportModal extends StatefulWidget {
  final StationModel station;
  final int tiempoEstimadoMostrado;

  const DelayReportModal({
    super.key,
    required this.station,
    required this.tiempoEstimadoMostrado,
  });

  @override
  State<DelayReportModal> createState() => _DelayReportModalState();
}

class _DelayReportModalState extends State<DelayReportModal> {
  int? _selectedDelayMinutes;
  final TextEditingController _customDelayController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  final List<int> _delayOptions = [5, 10, 15, 20, 30];

  @override
  void dispose() {
    _customDelayController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseService = FirebaseService();
    final currentUser = firebaseService.getCurrentUser();

    if (currentUser == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: MetroColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Debes iniciar sesión para reportar retraso'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: MetroColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: MetroColors.grayMedium,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          Text(
            'Reportar Retraso',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.station.nombre,
            style: theme.textTheme.titleMedium?.copyWith(
              color: MetroColors.grayDark,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Selecciona los minutos de retraso:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._delayOptions.map((minutes) {
                final isSelected = _selectedDelayMinutes == minutes;
                return ChoiceChip(
                  label: Text('$minutes min'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedDelayMinutes = selected ? minutes : null;
                    });
                  },
                  selectedColor: MetroColors.stateCritical.withOpacity(0.2),
                  checkmarkColor: MetroColors.stateCritical,
                  labelStyle: TextStyle(
                    color: isSelected ? MetroColors.stateCritical : MetroColors.grayDark,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }),
              ChoiceChip(
                label: const Text('Otro'),
                selected: _selectedDelayMinutes != null &&
                    !_delayOptions.contains(_selectedDelayMinutes),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDelayMinutes = -1; // Valor especial para "otro"
                    } else {
                      _selectedDelayMinutes = null;
                    }
                  });
                },
                selectedColor: MetroColors.stateCritical.withOpacity(0.2),
                checkmarkColor: MetroColors.stateCritical,
              ),
            ],
          ),
          if (_selectedDelayMinutes == -1) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _customDelayController,
              decoration: InputDecoration(
                labelText: 'Minutos de retraso',
                hintText: 'Ej: 45',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.access_time),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Razón del retraso (opcional):',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            decoration: InputDecoration(
              labelText: 'Describe la razón del retraso',
              hintText: 'Ej: Problemas técnicos, aglomeración, etc.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.description),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isLoading || _selectedDelayMinutes == null
                      ? null
                      : () => _handleSubmit(context, currentUser.uid),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MetroColors.stateCritical,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Enviar Reporte'),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Future<void> _handleSubmit(BuildContext context, String userId) async {
    if (_selectedDelayMinutes == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final learningReportService = LearningReportService();
      final ahora = DateTime.now();

      // Determinar minutos de retraso
      int delayMinutes;
      String? reason;

      if (_selectedDelayMinutes == -1) {
        // Usuario seleccionó "Otro" - intentar parsear del campo de texto
        final customDelay = int.tryParse(_customDelayController.text);
        if (customDelay != null && customDelay > 0) {
          delayMinutes = customDelay;
        } else {
          // Si no se puede parsear, mostrar error
          throw Exception('Por favor ingresa un número válido de minutos');
        }
      } else {
        delayMinutes = _selectedDelayMinutes!;
      }

      // Obtener razón del retraso si hay texto
      final reasonText = _reasonController.text.trim();
      if (reasonText.isNotEmpty) {
        reason = reasonText;
      }

      final report = LearningReportModel(
        id: '', // Se genera en Firestore
        usuarioId: userId,
        estacionId: widget.station.id,
        linea: widget.station.linea,
        horaLlegadaReal: ahora,
        tiempoEstimadoMostrado: widget.tiempoEstimadoMostrado,
        retrasoMinutos: delayMinutes,
        llegadaATiempo: false,
        razonRetraso: reason?.isEmpty ?? true ? null : reason,
        creadoEn: ahora,
      );

      await learningReportService.createLearningReport(report);

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Reporte enviado! Gracias por tu aporte'),
            backgroundColor: MetroColors.stateNormal,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar reporte: $e'),
            backgroundColor: MetroColors.stateCritical,
          ),
        );
      }
    }
  }
}

