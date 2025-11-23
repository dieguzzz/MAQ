import 'package:flutter/material.dart';

import '../models/station_model.dart';
import '../theme/metro_theme.dart';
import '../utils/helpers.dart';

class StationBottomSheet extends StatelessWidget {
  const StationBottomSheet({
    super.key,
    required this.station,
  });

  final StationModel station;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.45,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: MetroColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SheetHandle(color: MetroColors.grayMedium),
                const SizedBox(height: 16),
                _HeaderSection(station: station),
                const SizedBox(height: 24),
                _EtaSection(station: station),
                const SizedBox(height: 24),
                _StatusSection(station: station),
                const SizedBox(height: 24),
                _QuickActions(station: station),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(100),
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.station});

  final StationModel station;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final estado = Helpers.getEstadoEstacionText(
      station.estadoActual.name,
    );
    final estadoColor = switch (station.estadoActual) {
      EstadoEstacion.normal => MetroColors.stateNormal,
      EstadoEstacion.moderado => MetroColors.stateModerate,
      EstadoEstacion.lleno => MetroColors.stateCritical,
      EstadoEstacion.cerrado => MetroColors.stateInactive,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                station.nombre,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: MetroColors.grayDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: estadoColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                estado,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: estadoColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _InfoChip(
              label: station.linea == 'linea1' ? 'Línea 1' : 'Línea 2',
              color:
                  station.linea == 'linea1' ? MetroColors.blue : MetroColors.green,
            ),
            const SizedBox(width: 8),
            _InfoChip(
              label: 'Actualizado ${Helpers.formatDateTime(station.ultimaActualizacion)}',
              color: MetroColors.grayMedium,
            ),
          ],
        ),
      ],
    );
  }
}

class _EtaSection extends StatelessWidget {
  const _EtaSection({required this.station});

  final StationModel station;

  List<_EtaData> get _etas => const [
        _EtaData(label: 'Próximo', minutes: 2, confidence: '✅ 8 usuarios'),
        _EtaData(label: 'Siguiente', minutes: 7, confidence: '⚠️ 3 usuarios'),
        _EtaData(label: 'Más tarde', minutes: 12, confidence: '❓ 1 usuario'),
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Próximos trenes',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ..._etas.map(
          (eta) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: MetroColors.grayLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eta.label,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: MetroColors.grayDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          eta.confidence,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: MetroColors.grayDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${eta.minutes} min',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.station});

  final StationModel station;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado actual',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aglomeración',
                    style: TextStyle(
                      color: MetroColors.grayDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildStars(station.aglomeracion),
                  const SizedBox(height: 4),
                  Text(
                    station.getAglomeracionTexto(),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Problemas activos',
                    style: TextStyle(
                      color: MetroColors.grayDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'A/C estable • Sonido OK',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStars(int value) {
    return Row(
      children: List.generate(
        5,
        (index) => Icon(
          index < value ? Icons.star_rounded : Icons.star_border_rounded,
          size: 20,
          color: MetroColors.energyOrange,
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.station});

  final StationModel station;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones rápidas',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.campaign_outlined),
                label: const Text('Reportar estado'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.info_outline),
                label: const Text('Ver detalles'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.route),
                label: const Text('Planificar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EtaData {
  const _EtaData({
    required this.label,
    required this.minutes,
    required this.confidence,
  });

  final String label;
  final int minutes;
  final String confidence;
}

