import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/report_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../models/report_model.dart';
import 'report_type_selector.dart';

class ReportScreen extends StatefulWidget {
  final TipoReporte? tipoInicial;
  final String? objetivoId;

  const ReportScreen({
    super.key,
    this.tipoInicial,
    this.objetivoId,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  TipoReporte? _selectedTipo;
  String? _selectedObjetivoId;
  CategoriaReporte? _selectedCategoria;
  final TextEditingController _descripcionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTipo = widget.tipoInicial;
    _selectedObjetivoId = widget.objetivoId;
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedTipo == null ||
        _selectedObjetivoId == null ||
        _selectedCategoria == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos requeridos'),
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);

    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para reportar')),
      );
      return;
    }

    if (locationProvider.currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Necesitamos tu ubicación para crear el reporte'),
        ),
      );
      return;
    }

    final geoPoint = GeoPoint(
      locationProvider.currentPosition!.latitude,
      locationProvider.currentPosition!.longitude,
    );

    String? reportId;
    String? errorMessage;
    
    try {
      reportId = await reportProvider.createReport(
        usuarioId: authProvider.currentUser!.uid,
        tipo: _selectedTipo!,
        objetivoId: _selectedObjetivoId!,
        categoria: _selectedCategoria!,
        descripcion: _descripcionController.text.isEmpty
            ? null
            : _descripcionController.text,
        ubicacion: geoPoint,
      );
    } on Exception catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      print('Error al crear reporte: $e');
    } catch (e) {
      errorMessage = 'Ocurrió un error inesperado. Por favor intenta de nuevo.';
      print('Error inesperado al crear reporte: $e');
    }

    if (!mounted) return;

    if (reportId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reporte creado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Error al crear el reporte'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Reporte'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selector de tipo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tipo de Reporte',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ReportTypeSelector(
                      selectedTipo: _selectedTipo,
                      onTipoSelected: (tipo) {
                        setState(() {
                          _selectedTipo = tipo;
                          _selectedCategoria = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Selector de categoría (si hay tipo seleccionado)
            if (_selectedTipo != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Categoría',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildCategoriaSelector(),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Descripción
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Descripción (opcional)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descripcionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Agrega detalles adicionales...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botón de envío
            ElevatedButton(
              onPressed: _submitReport,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Enviar Reporte'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriaSelector() {
    if (_selectedTipo == null) return const SizedBox.shrink();

    final categorias = _selectedTipo == TipoReporte.estacion
        ? [
            CategoriaReporte.aglomeracion,
            CategoriaReporte.fallaTecnica,
            CategoriaReporte.servicioNormal,
          ]
        : [
            CategoriaReporte.aglomeracion,
            CategoriaReporte.retraso,
            CategoriaReporte.fallaTecnica,
          ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categorias.map((categoria) {
        final isSelected = _selectedCategoria == categoria;
        return ChoiceChip(
          label: Text(_getCategoriaText(categoria)),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedCategoria = selected ? categoria : null;
            });
          },
        );
      }).toList(),
    );
  }

  String _getCategoriaText(CategoriaReporte categoria) {
    switch (categoria) {
      case CategoriaReporte.aglomeracion:
        return 'Aglomeración';
      case CategoriaReporte.retraso:
        return 'Retraso';
      case CategoriaReporte.servicioNormal:
        return 'Servicio Normal';
      case CategoriaReporte.fallaTecnica:
        return 'Falla Técnica';
    }
  }
}

