import 'package:flutter/material.dart';

class ConfidenceIndicator extends StatelessWidget {
  final String? confidence; // 'high'|'medium'|'low'
  final bool isEstimated;

  const ConfidenceIndicator({
    super.key,
    this.confidence,
    this.isEstimated = false,
  });

  @override
  Widget build(BuildContext context) {
    if (confidence == null) return const SizedBox.shrink();
    
    Color color;
    String label;
    IconData icon;
    
    switch (confidence) {
      case 'high':
        color = Colors.green;
        label = 'Alta Confianza';
        icon = Icons.check_circle;
        break;
      case 'medium':
        color = Colors.orange;
        label = 'Media Confianza';
        icon = Icons.info;
        break;
      case 'low':
      default:
        color = Colors.red;
        label = isEstimated ? 'Datos Estimados' : 'Baja Confianza';
        icon = Icons.warning;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
