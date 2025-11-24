import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../models/report_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EnhancedReportScreen extends StatefulWidget {
  final TipoReporte tipo;
  final String? objetivoId;

  const EnhancedReportScreen({
    super.key,
    required this.tipo,
    this.objetivoId,
  });

  @override
  State<EnhancedReportScreen> createState() => _EnhancedReportScreenState();
}

class _EnhancedReportScreenState extends State<EnhancedReportScreen> {
  CategoriaReporte? _selectedCategory;
  final TextEditingController _descripcionController = TextEditingController();

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.tipo == TipoReporte.estacion
              ? 'Reportar Estación'
              : 'Reportar Tren',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título
            Text(
              widget.tipo == TipoReporte.estacion
                  ? '¿Cómo está esta estación?'
                  : '¿Cómo está este tren?',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Opciones de reporte para estación
            if (widget.tipo == TipoReporte.estacion) ...[
              _buildOption(
                '🟢',
                'Normal',
                'Flujo normal, sin problemas',
                CategoriaReporte.servicioNormal,
              ),
              _buildOption(
                '🟡',
                'Moderado',
                'Algo lleno pero manejable',
                CategoriaReporte.aglomeracion,
              ),
              _buildOption(
                '🔴',
                'Llenísimo',
                'Extremadamente lleno',
                CategoriaReporte.aglomeracion,
              ),
              _buildOption(
                '⚠️',
                'Retraso en andén',
                'El tren está retrasado',
                CategoriaReporte.retraso,
              ),
              _buildOption(
                '🚫',
                'Cerrada',
                'Estación cerrada o sin servicio',
                CategoriaReporte.fallaTecnica,
              ),
            ],

            // Opciones de reporte para tren
            if (widget.tipo == TipoReporte.tren) ...[
              _buildOption(
                '🟢',
                'Asientos disponibles',
                'Hay asientos libres',
                CategoriaReporte.servicioNormal,
              ),
              _buildOption(
                '🟡',
                'De pie cómodo',
                'Lleno pero cómodo de pie',
                CategoriaReporte.aglomeracion,
              ),
              _buildOption(
                '🔴',
                'Sardina',
                'Extremadamente lleno',
                CategoriaReporte.aglomeracion,
              ),
              _buildOption(
                '⚠️',
                'Retrasado',
                'El tren va con retraso',
                CategoriaReporte.retraso,
              ),
              _buildOption(
                '🛑',
                'Detenido',
                'El tren está detenido',
                CategoriaReporte.retraso,
              ),
              _buildOption(
                '❌',
                'A/C roto',
                'Aire acondicionado no funciona',
                CategoriaReporte.fallaTecnica,
              ),
            ],

            const SizedBox(height: 24),

            // Descripción opcional
            TextField(
              controller: _descripcionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripción adicional (opcional)',
                border: OutlineInputBorder(),
                hintText: 'Agrega más detalles...',
              ),
            ),

            const SizedBox(height: 24),

            // Botón de envío
            ElevatedButton(
              onPressed: _selectedCategory == null ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Enviar Reporte',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    String emoji,
    String title,
    String subtitle,
    CategoriaReporte category,
  ) {
    final isSelected = _selectedCategory == category;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected ? Colors.blue[50] : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategory = category;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.blue : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_selectedCategory == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);

    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión')),
      );
      return;
    }

    if (locationProvider.currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Necesitamos tu ubicación')),
      );
      return;
    }

    final geoPoint = GeoPoint(
      locationProvider.currentPosition!.latitude,
      locationProvider.currentPosition!.longitude,
    );

    final reportId = await reportProvider.createReport(
      usuarioId: authProvider.currentUser!.uid,
      tipo: widget.tipo,
      objetivoId: widget.objetivoId ?? '',
      categoria: _selectedCategory!,
      descripcion: _descripcionController.text.isEmpty
          ? null
          : _descripcionController.text,
      ubicacion: geoPoint,
    );

    if (reportId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Reporte creado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }
}

