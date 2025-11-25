import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../models/report_model.dart';
import '../../models/station_model.dart';
import '../../models/train_model.dart';
import '../../providers/metro_data_provider.dart';
import '../../theme/metro_theme.dart';

class ReportHistoryScreen extends StatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  EstadoReporte? _selectedEstado;
  String _sortBy = 'reciente'; // 'reciente', 'verificado'
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ReportModel> _filterAndSortReports(
    List<ReportModel> reports,
    MetroDataProvider? metroProvider,
  ) {
    var filtered = reports;

    // Filtrar por estado
    if (_selectedEstado != null) {
      filtered = filtered.where((r) => r.estado == _selectedEstado).toList();
    }

    // Filtrar por búsqueda
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((report) {
        // Buscar en categoría
        final categoriaMatch = _getCategoriaText(report.categoria)
            .toLowerCase()
            .contains(searchTerm);
        
        // Buscar en descripción
        final descripcionMatch = report.descripcion?.toLowerCase().contains(searchTerm) ?? false;
        
        // Buscar en nombre de estación/tren si tenemos el provider
        bool nombreMatch = false;
        if (metroProvider != null) {
          try {
            final nombre = _getObjetivoNombre(report, metroProvider);
            nombreMatch = nombre.toLowerCase().contains(searchTerm);
          } catch (e) {
            // Si hay error, ignorar
          }
        }
        
        return categoriaMatch || descripcionMatch || nombreMatch;
      }).toList();
    }

    // Ordenar
    if (_sortBy == 'reciente') {
      filtered.sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
    } else if (_sortBy == 'verificado') {
      filtered.sort((a, b) => b.verificaciones.compareTo(a.verificaciones));
    }

    return filtered;
  }

  String _getObjetivoNombre(ReportModel report, MetroDataProvider metroProvider) {
    if (report.tipo == TipoReporte.estacion) {
      final station = metroProvider.stations
          .firstWhere(
            (s) => s.id == report.objetivoId,
            orElse: () => StationModel(
              id: '',
              nombre: 'Estación desconocida',
              linea: 'linea1',
              ubicacion: const GeoPoint(0, 0),
              ultimaActualizacion: DateTime.now(),
            ),
          );
      return station.nombre;
    } else {
      final train = metroProvider.trains
          .firstWhere(
            (t) => t.id == report.objetivoId,
            orElse: () => TrainModel(
              id: 'desconocido',
              linea: 'linea1',
              direccion: DireccionTren.norte,
              ubicacionActual: const GeoPoint(0, 0),
              velocidad: 0,
              ultimaActualizacion: DateTime.now(),
            ),
          );
      return 'Tren ${train.id}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Historial de Reportes')),
        body: const Center(
          child: Text('Debes iniciar sesión para ver tu historial'),
        ),
      );
    }

    final firebaseService = FirebaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reportes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(150),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título de la sección de búsqueda
                Row(
                  children: [
                    const Icon(Icons.search, size: 18, color: MetroColors.blue),
                    const SizedBox(width: 6),
                    Text(
                      'Buscar y Filtrar',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Barra de búsqueda
                TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Buscar por estación, tren o categoría...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 10),
                // Título de filtros
                Row(
                  children: [
                    const Icon(Icons.filter_list, size: 16, color: MetroColors.blue),
                    const SizedBox(width: 6),
                    Text(
                      'Filtrar por estado:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Filtros por estado
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Todos', null),
                      const SizedBox(width: 8),
                      _buildFilterChip('Activo', EstadoReporte.activo),
                      const SizedBox(width: 8),
                      _buildFilterChip('Resuelto', EstadoReporte.resuelto),
                      const SizedBox(width: 8),
                      _buildFilterChip('Falso', EstadoReporte.falso),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reciente',
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 20),
                    SizedBox(width: 8),
                    Text('Más reciente'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'verificado',
                child: Row(
                  children: [
                    Icon(Icons.verified, size: 20),
                    SizedBox(width: 8),
                    Text('Más verificado'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Lista de reportes
          Expanded(
            child: Consumer<MetroDataProvider>(
              builder: (context, metroProvider, child) {
                return StreamBuilder<List<ReportModel>>(
                  stream: firebaseService.getUserReportsStream(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('Error: ${snapshot.error}'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Volver'),
                            ),
                          ],
                        ),
                      );
                    }

                    final allReports = snapshot.data ?? [];
                    final filteredReports = _filterAndSortReports(allReports, metroProvider);

                if (allReports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.report_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No has creado reportes aún',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Crea tu primer reporte desde el mapa',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (filteredReports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_alt_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron reportes',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Intenta con otros filtros o términos de búsqueda',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedEstado = null;
                              _searchController.clear();
                            });
                          },
                          child: const Text('Limpiar filtros'),
                        ),
                      ],
                    ),
                  );
                }

                    return RefreshIndicator(
                      key: _refreshIndicatorKey,
                      onRefresh: () async {
                        // El StreamBuilder se actualizará automáticamente
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredReports.length,
                        itemBuilder: (context, index) {
                          final report = filteredReports[index];
                          return _buildReportCard(context, report);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, EstadoReporte? estado) {
    final isSelected = _selectedEstado == estado;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedEstado = selected ? estado : null;
        });
      },
      selectedColor: MetroColors.blue.withOpacity(0.2),
      checkmarkColor: MetroColors.blue,
      labelStyle: TextStyle(
        color: isSelected ? MetroColors.blue : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, ReportModel report) {
    return Consumer<MetroDataProvider>(
      builder: (context, metroProvider, child) {
        final objetivoNombre = _getObjetivoNombre(report, metroProvider);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _showReportDetails(context, report, objetivoNombre),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Icono según tipo
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: report.tipo == TipoReporte.estacion
                              ? MetroColors.blue.withOpacity(0.1)
                              : MetroColors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          report.tipo == TipoReporte.estacion
                              ? Icons.train
                              : Icons.directions_transit,
                          color: report.tipo == TipoReporte.estacion
                              ? MetroColors.blue
                              : MetroColors.green,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              objetivoNombre,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: MetroColors.grayDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getCategoriaText(report.categoria),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Estado del reporte
                      _buildEstadoChip(report.estado),
                    ],
                  ),
                  if (report.descripcion != null && report.descripcion!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      report.descripcion!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.verified, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${report.verificaciones} verificaciones',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(report.creadoEn),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEstadoChip(EstadoReporte estado) {
    Color color;
    String text;
    IconData icon;

    switch (estado) {
      case EstadoReporte.activo:
        color = MetroColors.green;
        text = 'Activo';
        icon = Icons.check_circle;
        break;
      case EstadoReporte.resuelto:
        color = Colors.blue;
        text = 'Resuelto';
        icon = Icons.done_all;
        break;
      case EstadoReporte.falso:
        color = Colors.red;
        text = 'Falso';
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDetails(
    BuildContext context,
    ReportModel report,
    String objetivoNombre,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: MetroColors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      report.tipo == TipoReporte.estacion
                          ? Icons.train
                          : Icons.directions_transit,
                      color: MetroColors.blue,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          objetivoNombre,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getCategoriaText(report.categoria),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildEstadoChip(report.estado),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow(
                Icons.access_time,
                'Fecha',
                _formatDateTime(report.creadoEn),
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.verified,
                'Verificaciones',
                '${report.verificaciones} usuarios confirmaron este reporte',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.location_on,
                'Ubicación',
                '${report.ubicacion.latitude.toStringAsFixed(4)}, ${report.ubicacion.longitude.toStringAsFixed(4)}',
              ),
              if (report.descripcion != null && report.descripcion!.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Descripción',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: MetroColors.grayLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report.descripcion!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Hace unos momentos';
        }
        return 'Hace ${difference.inMinutes} min';
      }
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      final months = [
        'Ene',
        'Feb',
        'Mar',
        'Abr',
        'May',
        'Jun',
        'Jul',
        'Ago',
        'Sep',
        'Oct',
        'Nov',
        'Dic'
      ];
      return '${date.day} ${months[date.month - 1]}';
    }
  }

  String _formatDateTime(DateTime date) {
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]}, ${date.year} a las ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
