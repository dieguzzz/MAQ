import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';
import '../providers/metro_data_provider.dart';
import '../services/firebase_service.dart';
import '../services/simplified_report_service.dart';
import '../models/simplified_report_model.dart';
import '../theme/metro_theme.dart';

/// Bottom sheet para confirmar reportes de otros usuarios
/// Similar a StationReportSheet pero enfocado en confirmación
class ConfirmReportsSheet extends StatefulWidget {
  const ConfirmReportsSheet({super.key});

  @override
  State<ConfirmReportsSheet> createState() => _ConfirmReportsSheetState();
}

class _ConfirmReportsSheetState extends State<ConfirmReportsSheet>
    with TickerProviderStateMixin {
  final SimplifiedReportService _reportService = SimplifiedReportService();
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;
  String? _selectedReportType; // 'station', 'train', null = todos

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _selectedReportType = null; // Todos
              break;
            case 1:
              _selectedReportType = 'station';
              break;
            case 2:
              _selectedReportType = 'train';
              break;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Center(
          child: Text('Debes iniciar sesión para confirmar reportes'),
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header con título y botón cerrar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.people, color: MetroColors.blue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Confirmar Reportes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Tabs para filtrar por tipo
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.all_inclusive), text: 'Todos'),
                Tab(icon: Icon(Icons.train), text: 'Estaciones'),
                Tab(icon: Icon(Icons.directions_transit), text: 'Trenes'),
              ],
            ),
          ),
          // Lista de reportes
          Expanded(
            child: StreamBuilder<List<SimplifiedReportModel>>(
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
                // Filtrar reportes de otros usuarios y por tipo
                var otherUsersReports = allReports
                    .where((report) => report.userId != user.uid)
                    .toList();

                // Filtrar por tipo si está seleccionado
                if (_selectedReportType != null) {
                  otherUsersReports = otherUsersReports
                      .where((report) => report.scope == _selectedReportType)
                      .toList();
                }

                // Ordenar por más recientes primero
                otherUsersReports.sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
                          _selectedReportType == null
                              ? 'Los reportes de otros usuarios aparecerán aquí'
                              : 'No hay reportes de ${_selectedReportType == 'station' ? 'estaciones' : 'trenes'} para confirmar',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: otherUsersReports.length,
                  itemBuilder: (context, index) {
                    final report = otherUsersReports[index];
                    return _buildReportCard(context, report, user.uid);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    SimplifiedReportModel report,
    String currentUserId,
  ) {
    return FutureBuilder<bool>(
      future: _firebaseService.hasUserConfirmedReport(report.id, currentUserId),
      builder: (context, confirmationSnapshot) {
        final isVerified = confirmationSnapshot.data ?? false;

        return Consumer<MetroDataProvider>(
          builder: (context, metroProvider, child) {
            final station = metroProvider.getStationById(report.stationId);
            final stationName = station?.nombre ?? 'Estación ${report.stationId}';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              child: InkWell(
                onTap: () {
                  _showReportDetails(context, report, stationName, metroProvider, currentUserId);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header con tipo y botón de confirmar
                      Row(
                        children: [
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
                                  stationName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  report.scope == 'station'
                                      ? 'Reporte de Estación'
                                      : 'Reporte de Tren',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isVerified)
                            ElevatedButton.icon(
                              onPressed: () async {
                                await _confirmReport(context, report.id, currentUserId);
                              },
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Confirmar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: MetroColors.green,
                                foregroundColor: Colors.white,
                              ),
                            )
                          else
                            const Chip(
                              label: Text('Confirmado'),
                              backgroundColor: Colors.green,
                              avatar: Icon(Icons.check_circle, size: 18, color: Colors.white),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Información del reporte
                      if (report.scope == 'station') ...[
                        if (report.stationOperational != null) ...[
                          _buildInfoRow(
                            Icons.info_outline,
                            'Estado',
                            report.stationOperational == 'yes'
                                ? 'Operativa'
                                : report.stationOperational == 'partial'
                                    ? 'Parcialmente operativa'
                                    : 'No operativa',
                            report.stationOperational == 'yes'
                                ? Colors.green
                                : report.stationOperational == 'partial'
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (report.stationCrowd != null) ...[
                          _buildInfoRow(
                            Icons.people,
                            'Aglomeración',
                            'Nivel ${report.stationCrowd}/5',
                            Colors.blue,
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (report.stationIssues.isNotEmpty) ...[
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
                                backgroundColor: Colors.orange.withOpacity(0.1),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ] else if (report.scope == 'train') ...[
                        if (report.trainCrowd != null) ...[
                          _buildInfoRow(
                            Icons.people,
                            'Aglomeración',
                            'Nivel ${report.trainCrowd}/5',
                            Colors.blue,
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (report.trainStatus != null) ...[
                          _buildInfoRow(
                            Icons.speed,
                            'Estado',
                            report.trainStatus == 'normal'
                                ? 'Normal'
                                : report.trainStatus == 'slow'
                                    ? 'Lento'
                                    : 'Detenido',
                            report.trainStatus == 'normal'
                                ? Colors.green
                                : report.trainStatus == 'slow'
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (report.etaBucket != null &&
                            report.etaBucket != 'unknown') ...[
                          _buildInfoRow(
                            Icons.schedule,
                            'ETA',
                            '${report.etaBucket} minutos',
                            Colors.purple,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                      // Footer con confirmaciones y fecha
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
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _confirmReport(
    BuildContext context,
    String reportId,
    String userId,
  ) async {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final success = await reportProvider.confirmReport(reportId, userId);
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
  }

  void _showReportDetails(
    BuildContext context,
    SimplifiedReportModel report,
    String stationName,
    MetroDataProvider metroProvider,
    String currentUserId,
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
                      color: report.scope == 'station'
                          ? MetroColors.blue.withOpacity(0.1)
                          : MetroColors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      report.scope == 'station'
                          ? Icons.train
                          : Icons.directions_transit,
                      color: report.scope == 'station'
                          ? MetroColors.blue
                          : MetroColors.green,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stationName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report.scope == 'station'
                              ? 'Reporte de Estación'
                              : 'Reporte de Tren',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(report.status),
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
              if (report.scope == 'station') ...[
                if (report.stationOperational != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.info_outline,
                    'Estado operacional',
                    report.stationOperational == 'yes'
                        ? 'Operativa'
                        : report.stationOperational == 'partial'
                            ? 'Parcialmente operativa'
                            : 'No operativa',
                  ),
                ],
                if (report.stationCrowd != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.people,
                    'Aglomeración',
                    'Nivel ${report.stationCrowd}/5',
                  ),
                ],
                if (report.stationIssues.isNotEmpty) ...[
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
              ] else if (report.scope == 'train') ...[
                if (report.trainCrowd != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.people,
                    'Aglomeración',
                    'Nivel ${report.trainCrowd}/5',
                  ),
                ],
                if (report.trainStatus != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.speed,
                    'Estado del tren',
                    report.trainStatus == 'normal'
                        ? 'Normal'
                        : report.trainStatus == 'slow'
                            ? 'Lento'
                            : 'Detenido',
                  ),
                ],
                if (report.etaBucket != null &&
                    report.etaBucket != 'unknown') ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.schedule,
                    'Tiempo estimado',
                    '${report.etaBucket} minutos',
                  ),
                ],
              ],
              const SizedBox(height: 24),
              FutureBuilder<bool>(
                future: _firebaseService.hasUserConfirmedReport(
                    report.id, currentUserId),
                builder: (context, snapshot) {
                  final isConfirmed = snapshot.data ?? false;
                  if (!isConfirmed) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop(); // Cerrar bottom sheet
                          await _confirmReport(context, report.id, currentUserId);
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Confirmar este reporte'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MetroColors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    );
                  }
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Ya confirmaste este reporte',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
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

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Hace unos momentos';
        }
        return 'Hace ${difference.inMinutes} minutos';
      }
      return 'Hace ${difference.inHours} horas';
    } else if (difference.inDays == 1) {
      return 'Ayer a las ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
