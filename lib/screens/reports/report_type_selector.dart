import 'package:flutter/material.dart';
import '../../models/report_model.dart';

class ReportTypeSelector extends StatelessWidget {
  final TipoReporte? selectedTipo;
  final Function(TipoReporte) onTipoSelected;

  const ReportTypeSelector({
    super.key,
    this.selectedTipo,
    required this.onTipoSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildTypeCard(
            context,
            TipoReporte.estacion,
            'Estación',
            Icons.train,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTypeCard(
            context,
            TipoReporte.tren,
            'Tren',
            Icons.directions_transit,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeCard(
    BuildContext context,
    TipoReporte tipo,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = selectedTipo == tipo;

    return InkWell(
      onTap: () => onTipoSelected(tipo),
        child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.2)
                : Colors.grey[100],
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected ? color : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

