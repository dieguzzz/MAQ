import 'package:flutter/material.dart';
import '../../models/station_model.dart';
import '../../services/core/firebase_service.dart';
import '../../services/core/dev_service.dart';
import '../../providers/report_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/report_model.dart';
import 'package:provider/provider.dart';

/// Tab de estaciones para el panel de desarrollador
class DevStationsTab extends StatefulWidget {
  const DevStationsTab({super.key});

  @override
  State<DevStationsTab> createState() => _DevStationsTabState();
}

class _DevStationsTabState extends State<DevStationsTab> {
  final FirebaseService _firebaseService = FirebaseService();
  List<StationModel> _stations = [];
  List<StationModel> _filteredStations = [];
  String _selectedLinea = 'all';
  bool _isLoading = false;
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() => _isLoading = true);
    try {
      final stations = await _firebaseService.getStations();
      setState(() {
        _stations = stations;
        _filteredStations = stations;
      });
    } catch (e) {
      _showError('Error cargando estaciones: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterStations(String linea) {
    setState(() {
      _selectedLinea = linea;
      if (linea == 'all') {
        _filteredStations = _stations;
      } else {
        _filteredStations = _stations.where((s) => s.linea == linea).toList();
      }
    });
  }

  Future<void> _testStationReport(StationModel station) async {
    // Mostrar diálogo para seleccionar estado
    final estado = await showDialog<EstadoPrincipalEstacion>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reportar Estado: ${station.nombre}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEstadoOption(
              context,
              EstadoPrincipalEstacion.normal,
              '🟢 Normal',
              Colors.green,
            ),
            _buildEstadoOption(
              context,
              EstadoPrincipalEstacion.moderado,
              '🟡 Moderado',
              Colors.orange,
            ),
            _buildEstadoOption(
              context,
              EstadoPrincipalEstacion.lleno,
              '🔴 Lleno',
              Colors.red,
            ),
            _buildEstadoOption(
              context,
              EstadoPrincipalEstacion.retraso,
              '⚠️ Retraso',
              Colors.yellow,
            ),
            _buildEstadoOption(
              context,
              EstadoPrincipalEstacion.cerrado,
              '🚫 Cerrado',
              Colors.grey,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (estado == null) return;

    if (!mounted) return;

    // Obtener usuario actual
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) {
      _showError('Debes estar autenticado para reportar');
      return;
    }

    // Crear reporte de prueba
    setState(() => _isLoading = true);
    try {
      if (!mounted) return;
      final reportProvider =
          Provider.of<ReportProvider>(context, listen: false);

      // Mapear estado a string
      String estadoString;
      switch (estado) {
        case EstadoPrincipalEstacion.normal:
          estadoString = 'normal';
          break;
        case EstadoPrincipalEstacion.moderado:
          estadoString = 'moderado';
          break;
        case EstadoPrincipalEstacion.lleno:
          estadoString = 'lleno';
          break;
        case EstadoPrincipalEstacion.retraso:
          estadoString = 'retraso';
          break;
        case EstadoPrincipalEstacion.cerrado:
          estadoString = 'cerrado';
          break;
      }

      // Crear reporte usando el provider con usuario autenticado
      // Usar prefijo especial en descripción para identificar reportes de prueba
      await reportProvider.createReport(
        usuarioId: user.uid,
        tipo: TipoReporte.estacion,
        objetivoId: station.id,
        categoria: CategoriaReporte.aglomeracion,
        ubicacion: station.ubicacion,
        estadoPrincipal: estadoString,
        descripcion: '[DEV_TEST] Reporte de prueba desde panel desarrollador',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Reporte de estado creado: $estadoString'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Error creando reporte: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildEstadoOption(
    BuildContext context,
    EstadoPrincipalEstacion estado,
    String label,
    Color color,
  ) {
    return ListTile(
      leading: Icon(Icons.circle, color: color),
      title: Text(label),
      onTap: () => Navigator.of(context).pop(estado),
    );
  }

  Future<void> _clearTestData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar Datos de Prueba'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar todos los datos de prueba?\n\n'
          'Esto eliminará:\n'
          '• Reportes de aprendizaje de prueba\n'
          '• Reportes de prueba\n'
          '• Métricas de desarrollo\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isClearing = true);
    try {
      await DevService.clearTestData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Datos de prueba eliminados'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Error limpiando datos: $e');
    } finally {
      setState(() => _isClearing = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getEstadoColor(EstadoEstacion estado) {
    switch (estado) {
      case EstadoEstacion.normal:
        return Colors.green;
      case EstadoEstacion.moderado:
        return Colors.orange;
      case EstadoEstacion.lleno:
        return Colors.red;
      case EstadoEstacion.cerrado:
        return Colors.grey;
    }
  }

  String _getEstadoText(EstadoEstacion estado) {
    switch (estado) {
      case EstadoEstacion.normal:
        return '🟢 Normal';
      case EstadoEstacion.moderado:
        return '🟡 Moderado';
      case EstadoEstacion.lleno:
        return '🔴 Lleno';
      case EstadoEstacion.cerrado:
        return '🚫 Cerrado';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _stations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        // Filtro por línea - más compacto
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text(
                'Línea:',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey(_selectedLinea),
                  initialValue: _selectedLinea,
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[800],
                  ),
                  dropdownColor: Colors.grey[800],
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('Todas las líneas',
                          style: TextStyle(color: Colors.white)),
                    ),
                    DropdownMenuItem(
                      value: 'linea1',
                      child: Text('Línea 1',
                          style: TextStyle(color: Colors.white)),
                    ),
                    DropdownMenuItem(
                      value: 'linea2',
                      child: Text('Línea 2',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      _filterStations(value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        // Botón de limpiar datos
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.delete_sweep, size: 18),
            label: const Text('Limpiar Datos de Prueba',
                style: TextStyle(fontSize: 12)),
            onPressed: _isClearing ? null : _clearTestData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[800],
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),

        const SizedBox(height: 4),

        // Lista de estaciones - scrollable
        Expanded(
          child: _filteredStations.isEmpty
              ? const Center(
                  child: Text(
                    'No hay estaciones disponibles',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  itemCount: _filteredStations.length,
                  itemBuilder: (context, index) {
                    final station = _filteredStations[index];
                    return Card(
                      color: Colors.grey[800],
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              _getEstadoColor(station.estadoActual),
                          child: const Icon(Icons.train,
                              color: Colors.white, size: 18),
                        ),
                        title: Text(
                          station.nombre,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Línea: ${station.linea}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              _getEstadoText(station.estadoActual),
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: SizedBox(
                          width: 70,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _testStationReport(station),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: const Size(60, 32),
                              textStyle: const TextStyle(fontSize: 11),
                            ),
                            child: const Text('Probar'),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
