import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../services/firebase_service.dart';
import '../../services/simplified_report_service.dart';
import '../../models/report_model.dart';
import '../../models/simplified_report_model.dart';
import '../../models/user_model.dart';
import '../../models/station_model.dart';
import '../../models/train_model.dart';
import '../../providers/metro_data_provider.dart';
import '../../widgets/report_verification_widget.dart';
import '../../theme/metro_theme.dart';

class ReportHistoryScreen extends StatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus; // 'active', 'resolved', 'rejected'
  String _sortBy = 'reciente'; // 'reciente', 'verificado'
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  late TabController _tabController;
  final SimplifiedReportService _reportService = SimplifiedReportService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<SimplifiedReportModel> _filterAndSortReports(
    List<SimplifiedReportModel> reports,
    MetroDataProvider? metroProvider,
  ) {
    var filtered = reports;

    // Filtrar por estado
    if (_selectedStatus != null) {
      filtered = filtered.where((r) => r.status == _selectedStatus).toList();
    }

    // Filtrar por búsqueda
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((report) {
        // Buscar en scope
        final scopeMatch = (report.scope == 'station' ? 'estación' : 'tren')
            .toLowerCase()
            .contains(searchTerm);
        
        // Buscar en nombre de estación si tenemos el provider
        bool nombreMatch = false;
        if (metroProvider != null) {
          try {
            final nombre = _getObjetivoNombre(report, metroProvider);
            nombreMatch = nombre.toLowerCase().contains(searchTerm);
          } catch (e) {
            // Si hay error, ignorar
          }
        }
        
        return scopeMatch || nombreMatch;
      }).toList();
    }

    // Ordenar
    if (_sortBy == 'reciente') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortBy == 'verificado') {
      filtered.sort((a, b) => b.confirmations.compareTo(a.confirmations));
    }

    return filtered;
  }

  String _getObjetivoNombre(SimplifiedReportModel report, MetroDataProvider metroProvider) {
    try {
      final station = metroProvider.getStationById(report.stationId);
      if (station != null) {
        return station.nombre;
      }
    } catch (e) {
      // Si hay error, usar ID
    }
    return 'Estación ${report.stationId}';
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

    return PopScope(
      canPop: true, // Permitir pop normal para pantallas secundarias
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reportes'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
            Tab(icon: Icon(Icons.history), text: 'Mis Reportes'),
            Tab(icon: Icon(Icons.people), text: 'Confirmar Reportes'),
          ],
        ),
        actions: [
          if (_tabController.index == 0)
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
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pestaña 1: Mis Reportes
          _buildMyReportsTab(user, firebaseService),
          // Pestaña 2: Reportes Cercanos (para confirmar)
          _buildNearbyReportsTab(user, firebaseService),
        ],
      ),
      ),
    );
  }

  Widget _buildMyReportsTab(UserModel user, FirebaseService firebaseService) {
    return Column(
      children: [
        // Barra de búsqueda y filtros (solo en pestaña de Mis Reportes)
        Container(
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
                    _buildFilterChip('Activo', 'active'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Resuelto', 'resolved'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Rechazado', 'rejected'),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Lista de reportes
        Expanded(
          child: Consumer<MetroDataProvider>(
            builder: (context, metroProvider, child) {
              return StreamBuilder<List<SimplifiedReportModel>>(
                stream: _reportService.getUserReportsStream(user.uid),
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
                              _selectedStatus = null;
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
      );
  }

  Widget _buildNearbyReportsTab(UserModel user, FirebaseService firebaseService) {
    return Consumer<ReportProvider>(
      builder: (context, reportProvider, child) {
        return StreamBuilder<List<SimplifiedReportModel>>(
          stream: _reportService.getActiveReportsStream(),
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
                  ],
                ),
              );
            }

            final allReports = snapshot.data ?? [];
            // Filtrar reportes de otros usuarios (no del usuario actual)
            final otherUsersReports = allReports
                .where((report) => report.userId != user.uid)
                .toList();

            if (otherUsersReports.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No hay reportes para confirmar',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Los reportes de otros usuarios aparecerán aquí',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }

            // Ordenar por más recientes primero
            otherUsersReports.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: otherUsersReports.length,
                itemBuilder: (context, index) {
                  final report = otherUsersReports[index];
                  return _buildVerificationCard(context, report, reportProvider, user.uid, firebaseService);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVerificationCard(
    BuildContext context,
    SimplifiedReportModel report,
    ReportProvider reportProvider,
    String currentUserId,
    FirebaseService firebaseService,
  ) {
    return FutureBuilder<bool>(
      future: firebaseService.hasUserConfirmedReport(report.id, currentUserId),
      builder: (context, confirmationSnapshot) {
        final isVerified = confirmationSnapshot.data ?? false;

        // TODO: Actualizar ReportVerificationWidget para usar SimplifiedReportModel
        // Por ahora, mostrar un card simple
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      report.scope == 'station' ? Icons.train : Icons.directions_transit,
                      color: report.scope == 'station' ? MetroColors.blue : MetroColors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        report.scope == 'station' ? 'Reporte de Estación' : 'Reporte de Tren',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!isVerified)
                      ElevatedButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            final success = await reportProvider.confirmReport(report.id, currentUserId);
                            if (success && mounted) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('¡Reporte confirmado! +5 puntos'),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              setState(() {});
                            }
                          } catch (e) {
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(e.toString().replaceAll('Exception: ', '')),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Confirmar'),
                      )
                    else
                      const Chip(
                        label: Text('Confirmado'),
                        backgroundColor: Colors.green,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Confirmaciones: ${report.confirmations}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? status : null;
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

  Widget _buildReportCard(BuildContext context, SimplifiedReportModel report) {
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
                          color: report.scope == 'station'
                              ? MetroColors.blue.withOpacity(0.1)
                              : MetroColors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          report.scope == 'station'
                              ? Icons.train
                              : Icons.directions_transit,
                          color: report.scope == 'station'
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
                              report.scope == 'station' ? 'Reporte de Estación' : 'Reporte de Tren',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Estado del reporte
                      _buildEstadoChip(report.status),
                    ],
                  ),
                  if (report.stationIssues.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: report.stationIssues.take(3).map((issue) {
                        return Chip(
                          label: Text(
                            _getProblemaTexto(issue),
                            style: const TextStyle(fontSize: 11),
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.verified, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${report.confirmations} confirmaciones',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.stars, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${report.totalPoints} pts',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(report.createdAt),
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

  Widget _buildEstadoChip(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'active':
        color = MetroColors.green;
        text = 'Activo';
        icon = Icons.check_circle;
        break;
      case 'resolved':
        color = Colors.blue;
        text = 'Resuelto';
        icon = Icons.done_all;
        break;
      case 'rejected':
        color = Colors.red;
        text = 'Rechazado';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        text = status;
        icon = Icons.help_outline;
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

  String _getProblemaTexto(String problema) {
    final map = {
      'recharge': 'Recarga',
      'atm': 'Cajero',
      'ac': 'Aire acondicionado',
      'escalator': 'Escaleras',
      'elevator': 'Ascensor',
    };
    return map[problema] ?? problema;
  }

  void _showReportDetails(
    BuildContext context,
    SimplifiedReportModel report,
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
                      report.scope == 'station'
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
                          report.scope == 'station' ? 'Reporte de Estación' : 'Reporte de Tren',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildEstadoChip(report.status),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow(
                Icons.access_time,
                'Fecha',
                _formatDateTime(report.createdAt),
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.verified,
                'Confirmaciones',
                '${report.confirmations} usuarios confirmaron este reporte',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.stars,
                'Puntos',
                '${report.totalPoints} puntos (${report.basePoints} base + ${report.bonusPoints} bonus)',
              ),
              if (report.userLocation != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.location_on,
                  'Ubicación',
                  '${report.userLocation!.latitude.toStringAsFixed(4)}, ${report.userLocation!.longitude.toStringAsFixed(4)}',
                ),
              ],
              if (report.scope == 'station' && report.stationIssues.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Problemas reportados',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: report.stationIssues.map((issue) {
                    return Chip(
                      label: Text(_getProblemaTexto(issue)),
                      backgroundColor: MetroColors.energyOrange.withOpacity(0.1),
                    );
                  }).toList(),
                ),
              ],
              if (report.scope == 'station' && report.stationOperational != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.info_outline,
                  'Estado operacional',
                  report.stationOperational == 'yes' ? 'Operativa' : 
                  report.stationOperational == 'partial' ? 'Parcialmente operativa' : 
                  'No operativa',
                ),
              ],
              if (report.scope == 'station' && report.stationCrowd != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.people,
                  'Aglomeración',
                  'Nivel ${report.stationCrowd}/5',
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
