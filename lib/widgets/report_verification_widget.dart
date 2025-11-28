import 'package:flutter/material.dart';
import '../models/report_model.dart';

class ReportVerificationWidget extends StatelessWidget {
  final ReportModel report;
  final int verificaciones;
  final Function()? onVerify;
  final bool isVerified;

  const ReportVerificationWidget({
    super.key,
    required this.report,
    this.verificaciones = 0,
    this.onVerify,
    this.isVerified = false,
  });

  int get _verificationCount => report.confirmationCount > 0 
      ? report.confirmationCount 
      : verificaciones;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con tipo de reporte
            Row(
              children: [
                Icon(
                  report.tipo == TipoReporte.estacion
                      ? Icons.train
                      : Icons.directions_transit,
                  color: _getCategoryColor(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getCategoryText(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_verificationCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          '$_verificationCount confirmaciones',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Mostrar badge de verificado si está verificado
                if (report.verificationStatus == 'verified' || 
                    report.verificationStatus == 'community_verified')
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 16, color: Colors.blue),
                        SizedBox(width: 4),
                        Text(
                          'Verificado',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (report.descripcion != null) ...[
              const SizedBox(height: 8),
              Text(
                report.descripcion!,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
            const SizedBox(height: 12),
            // Botón de verificación
            if (!isVerified && onVerify != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onVerify,
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmar este reporte'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              )
            else if (isVerified)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Ya confirmaste este reporte',
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            // Tiempo transcurrido
            Text(
              _getTimeAgo(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    switch (report.categoria) {
      case CategoriaReporte.aglomeracion:
        return Colors.orange;
      case CategoriaReporte.retraso:
        return Colors.red;
      case CategoriaReporte.fallaTecnica:
        return Colors.purple;
      case CategoriaReporte.servicioNormal:
        return Colors.green;
    }
  }

  String _getCategoryText() {
    switch (report.categoria) {
      case CategoriaReporte.aglomeracion:
        return 'Aglomeración';
      case CategoriaReporte.retraso:
        return 'Retraso';
      case CategoriaReporte.fallaTecnica:
        return 'Falla Técnica';
      case CategoriaReporte.servicioNormal:
        return 'Servicio Normal';
    }
  }

  String _getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(report.creadoEn);

    if (difference.inMinutes < 1) {
      return 'Hace un momento';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} minutos';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} horas';
    } else {
      return 'Hace ${difference.inDays} días';
    }
  }
}

