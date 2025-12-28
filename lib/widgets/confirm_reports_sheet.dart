import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';
import '../providers/metro_data_provider.dart';
import '../services/firebase_service.dart';
import '../services/simplified_report_service.dart';
import '../models/simplified_report_model.dart';
import '../theme/metro_theme.dart';
import 'points_reward_animation.dart';

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
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Center(
          child: Text(
            'Debes iniciar sesión para confirmar reportes',
            style: const TextStyle(color: Colors.black),
          ),
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Header moderno con gradiente
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  MetroColors.blue.withOpacity(0.1),
                  Colors.orange.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [MetroColors.blue, Colors.orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: MetroColors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.verified_user, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirmar Reportes',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Ayuda a la comunidad',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: MetroColors.grayDark),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
          // Tabs modernos con animación
          Container(
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
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [MetroColors.blue, Colors.orange],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.all_inclusive, size: 20), text: 'Todos'),
                Tab(icon: Icon(Icons.train, size: 20), text: 'Estaciones'),
                Tab(icon: Icon(Icons.directions_transit, size: 20), text: 'Trenes'),
              ],
            ),
          ),
          // Lista de reportes
          Expanded(
            child: StreamBuilder<List<SimplifiedReportModel>>(
              stream: _reportService.getReportsForConfirmationStream(),
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
                // Mostrar todos los reportes (propios y de otros)
                var filteredReports = allReports.toList();

                // Filtrar por tipo si está seleccionado
                if (_selectedReportType != null) {
                  filteredReports = filteredReports
                      .where((report) => report.scope == _selectedReportType)
                      .toList();
                }

                // Ordenar por más recientes primero
                filteredReports.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                if (filteredReports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Opacity(
                                opacity: value,
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.orange.withOpacity(0.1),
                                        MetroColors.blue.withOpacity(0.1),
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.people_outline,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No hay reportes para confirmar',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedReportType == null
                              ? 'Los reportes aparecerán aquí'
                              : 'No hay reportes de ${_selectedReportType == 'station' ? 'estaciones' : 'trenes'} para confirmar',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredReports.length,
                  itemBuilder: (context, index) {
                    final report = filteredReports[index];
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 300 + (index * 50)),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: _buildReportCard(context, report, user.uid),
                          ),
                        );
                      },
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

  Widget _buildReportCard(
    BuildContext context,
    SimplifiedReportModel report,
    String currentUserId,
  ) {
    final isOwnReport = report.userId == currentUserId;
    
    return FutureBuilder<bool>(
      future: isOwnReport 
          ? Future.value(false) 
          : _firebaseService.hasUserConfirmedReport(report.id, currentUserId),
      builder: (context, confirmationSnapshot) {
        final isVerified = confirmationSnapshot.data ?? false;

        return Consumer<MetroDataProvider>(
          builder: (context, metroProvider, child) {
            final station = metroProvider.getStationById(report.stationId);
            final stationName = station?.nombre ?? 'Estación ${report.stationId}';

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.95, end: 1.0),
              duration: const Duration(milliseconds: 200),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          (report.scope == 'station'
                                  ? MetroColors.blue
                                  : MetroColors.green)
                              .withOpacity(0.03),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (report.scope == 'station'
                                  ? MetroColors.blue
                                  : MetroColors.green)
                              .withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _showReportDetails(context, report, stationName, metroProvider, currentUserId);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header con tipo y botón de confirmar
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: report.scope == 'station'
                                            ? [MetroColors.blue, MetroColors.blue.withOpacity(0.7)]
                                            : [MetroColors.green, MetroColors.green.withOpacity(0.7)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (report.scope == 'station'
                                                  ? MetroColors.blue
                                                  : MetroColors.green)
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      report.scope == 'station'
                                          ? Icons.train
                                          : Icons.directions_transit,
                                      color: Colors.white,
                                      size: 24,
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
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: (report.scope == 'station'
                                                    ? MetroColors.blue
                                                    : MetroColors.green)
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            report.scope == 'station'
                                                ? 'Reporte de Estación'
                                                : 'Reporte de Tren',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: report.scope == 'station'
                                                  ? MetroColors.blue
                                                  : MetroColors.green,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isVerified && !isOwnReport)
                                    TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      duration: const Duration(milliseconds: 400),
                                      curve: Curves.elasticOut,
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: value,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [MetroColors.green, Colors.green[700]!],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: MetroColors.green.withOpacity(0.4),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () async {
                                                  HapticFeedback.mediumImpact();
                                                  await _confirmReport(context, report.id, currentUserId);
                                                },
                                                borderRadius: BorderRadius.circular(12),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 10,
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.check_circle, size: 18, color: Colors.white),
                                                      SizedBox(width: 6),
                                                      Text(
                                                        'Confirmar',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.green, Colors.green[700]!],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_circle, size: 18, color: Colors.white),
                                          SizedBox(width: 6),
                                          Text(
                                            'Confirmado',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Información del reporte con diseño moderno
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                            if (report.scope == 'station') ...[
                              if (report.stationOperational != null) ...[
                                _buildModernInfoRow(
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
                                if (report.stationCrowd != null ||
                                    report.stationIssues.isNotEmpty)
                                  const SizedBox(height: 12),
                              ],
                              if (report.stationCrowd != null) ...[
                                _buildModernInfoRow(
                                  Icons.people,
                                  'Aglomeración',
                                  'Nivel ${report.stationCrowd}/5',
                                  Colors.blue,
                                ),
                                if (report.stationIssues.isNotEmpty)
                                  const SizedBox(height: 12),
                              ],
                              if (report.stationIssues.isNotEmpty) ...[
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: report.stationIssues.take(3).map((issue) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.orange.withOpacity(0.2),
                                            Colors.orange.withOpacity(0.1),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.orange.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            size: 14,
                                            color: Colors.orange[700],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _getProblemaTexto(issue),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.orange[900],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ] else if (report.scope == 'train') ...[
                              // Si es un reporte de llegada directa (tiene arrivalTime pero no etaBucket)
                              if (report.arrivalTime != null && 
                                  (report.etaBucket == null || report.etaBucket == 'unknown')) ...[
                                _buildModernInfoRow(
                                  Icons.check_circle,
                                  'Llegada confirmada',
                                  'Llegó a las ${_formatTime(report.arrivalTime!)}',
                                  Colors.green,
                                ),
                                if (report.trainCrowd != null || report.trainStatus != null)
                                  const SizedBox(height: 12),
                              ],
                              if (report.trainCrowd != null) ...[
                                _buildModernInfoRow(
                                  Icons.people,
                                  'Aglomeración',
                                  'Nivel ${report.trainCrowd}/5',
                                  Colors.blue,
                                ),
                                if (report.trainStatus != null ||
                                    (report.etaBucket != null &&
                                        report.etaBucket != 'unknown'))
                                  const SizedBox(height: 12),
                              ],
                              if (report.trainStatus != null) ...[
                                _buildModernInfoRow(
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
                                if (report.etaBucket != null &&
                                    report.etaBucket != 'unknown')
                                  const SizedBox(height: 12),
                              ],
                              if (report.etaBucket != null &&
                                  report.etaBucket != 'unknown') ...[
                                _buildModernInfoRow(
                                  Icons.schedule,
                                  'ETA',
                                  '${report.etaBucket} minutos',
                                  Colors.purple,
                                ),
                              ],
                            ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Footer moderno con confirmaciones y fecha
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.grey[100]!,
                                    Colors.grey[50]!,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.verified,
                                        size: 16,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${report.confirmations} confirmaciones',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDate(report.createdAt),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              );
            },
            );
          },
        );
      },
    );
  }

  Widget _buildModernInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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
      if (success) {
        if (!mounted) return;
        // Mostrar animación de puntos ganados
        PointsRewardHelper.showConfirmReportPoints(context, points: 15);
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showReportDetails(
    BuildContext context,
    SimplifiedReportModel report,
    String stationName,
    MetroDataProvider metroProvider,
    String currentUserId,
  ) {
    final isOwnReport = report.userId == currentUserId;
    
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
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report.scope == 'station'
                              ? 'Reporte de Estación'
                              : 'Reporte de Tren',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
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
                      color: Colors.black,
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
                // Si es un reporte de llegada directa
                if (report.arrivalTime != null && 
                    (report.etaBucket == null || report.etaBucket == 'unknown')) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.check_circle,
                    'Llegada confirmada',
                    'Llegó a las ${_formatTime(report.arrivalTime!)}',
                  ),
                ],
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
              if (!isOwnReport)
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
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'No puedes confirmar tu propio reporte',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
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
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
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
