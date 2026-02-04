import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';
import '../providers/metro_data_provider.dart';
import '../services/firebase_service.dart';
import '../services/simplified_report_service.dart';
import '../services/simplified_report_confidence_service.dart';
import '../services/debug_log_service.dart';
import '../models/simplified_report_model.dart';
import '../models/user_model.dart';
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
        child: const Center(
          child: Text(
            'Debes iniciar sesión para confirmar reportes',
            style: TextStyle(color: Colors.black),
          ),
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle superior
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header Duolingo-style
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confirmar Reportes',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: MetroColors.grayDark,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                              ),
                    ),
                    Text(
                      'Ayuda a la comunidad ✨',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: MetroColors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: MetroColors.grayMedium),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          // Tabs modernos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: MetroColors.blue,
                unselectedLabelColor: MetroColors.grayMedium,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'TODOS'),
                  Tab(text: 'ESTACIÓN'),
                  Tab(text: 'TRENES'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
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
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final allReports = snapshot.data ?? [];
                final logService = DebugLogService();
                logService.addLog(
                  'ConfirmReports',
                  '${allReports.length} reportes recibidos del stream',
                  level: LogLevel.info,
                );
                for (var report in allReports) {
                  logService.addLog(
                    'ConfirmReports',
                    '  - ${report.id}: scope=${report.scope}, stationId=${report.stationId}, status=${report.status}',
                    level: LogLevel.info,
                  );
                }

                // Separar reportes generales y problemas específicos
                var filteredReports = allReports.toList();
                logService.addLog(
                  'ConfirmReports',
                  'Antes del filtro por tipo: ${filteredReports.length} reportes',
                  level: LogLevel.info,
                );

                // Filtrar por tipo si está seleccionado
                if (_selectedReportType != null) {
                  filteredReports = filteredReports
                      .where((report) => report.scope == _selectedReportType)
                      .toList();
                  logService.addLog(
                    'ConfirmReports',
                    'Después del filtro por tipo ($_selectedReportType): ${filteredReports.length} reportes',
                    level: LogLevel.info,
                  );
                }

                // Separar reportes generales de problemas específicos
                final generalReports =
                    filteredReports.where((r) => !r.isSpecificIssue).toList();
                final specificIssueReports =
                    filteredReports.where((r) => r.isSpecificIssue).toList();

                // Ordenar ambas listas por más recientes primero
                int sortByConfidenceAndDate(
                    SimplifiedReportModel a, SimplifiedReportModel b) {
                  // 1. Por confianza (descendente)
                  final aConf = a.confidence ?? 0.0;
                  final bConf = b.confidence ?? 0.0;
                  final confidenceCompare = bConf.compareTo(aConf);
                  if (confidenceCompare != 0) return confidenceCompare;

                  // 2. Por fecha (más recientes primero)
                  final dateCompare = b.createdAt.compareTo(a.createdAt);
                  if (dateCompare != 0) return dateCompare;

                  // 3. Por confirmaciones (más confirmaciones primero)
                  return b.confirmations.compareTo(a.confirmations);
                }

                generalReports.sort(sortByConfidenceAndDate);
                specificIssueReports.sort(sortByConfidenceAndDate);

                final List<SimplifiedReportModel> combinedReports = [
                  ...generalReports,
                  ...specificIssueReports,
                ];

                if (combinedReports.isEmpty) {
                  return _buildEmptyState();
                }

                return Column(
                  children: [
                    // Barra de progreso de revisión
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      child: Stack(
                        children: [
                          Container(
                            height: 6,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 6,
                            width: MediaQuery.of(context).size.width *
                                0.8 *
                                (1 /
                                    combinedReports
                                        .length), // Placeholder for current index
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [MetroColors.blue, MetroColors.green],
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        itemCount: combinedReports.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final report = combinedReports[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                            child: _buildReportCard(context, report, user.uid),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Desliza para ver más reportes 👈',
                      style: TextStyle(
                        color: MetroColors.grayMedium,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[100],
            ),
            child: Icon(
              Icons.done_all_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '¡Todo al día!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: MetroColors.grayDark,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              _selectedReportType == null
                  ? 'No hay reportes pendientes para confirmar en este momento.'
                  : 'No hay nuevos reportes de ${_selectedReportType == 'station' ? 'estaciones' : 'trenes'}.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: MetroColors.grayMedium,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getIssueTypeName(String type) {
    switch (type) {
      case 'ac':
        return 'Aire Acondicionado';
      case 'escalator':
        return 'Escalera Eléctrica';
      case 'elevator':
        return 'Elevador';
      case 'atm':
        return 'Cajero/ATM';
      case 'recharge':
        return 'Máquina de Recarga';
      case 'bathroom':
        return 'Baño';
      case 'lights':
        return 'Iluminación';
      default:
        return type;
    }
  }

  String _getStatusName(String status) {
    switch (status) {
      case 'not_working':
        return '🔴 No Funciona';
      case 'working_poorly':
        return '🟡 Funciona Mal';
      case 'out_of_service':
        return '⚫ Fuera de Servicio';
      default:
        return status;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Hace un momento';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else {
      return 'Hace ${difference.inDays}d';
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                color: MetroColors.grayDark,
              ),
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
            final stationName =
                station?.nombre ?? 'Estación ${report.stationId}';

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
                              .withValues(alpha: 0.03),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (report.scope == 'station'
                                  ? MetroColors.blue
                                  : MetroColors.green)
                              .withValues(alpha: 0.1),
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
                          _showReportDetails(context, report, stationName,
                              metroProvider, currentUserId);
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
                                            ? [
                                                MetroColors.blue,
                                                MetroColors.blue
                                                    .withValues(alpha: 0.7)
                                              ]
                                            : [
                                                MetroColors.green,
                                                MetroColors.green
                                                    .withValues(alpha: 0.7)
                                              ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (report.scope == 'station'
                                                  ? MetroColors.blue
                                                  : MetroColors.green)
                                              .withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      report.isSpecificIssue
                                          ? Icons.warning_amber_rounded
                                          : report.scope == 'station'
                                              ? Icons.train
                                              : Icons.directions_transit,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            report.isSpecificIssue
                                                ? 'Problema Específico'
                                                : report.scope == 'station'
                                                    ? 'Reporte de Estación'
                                                    : 'Reporte de Tren',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: report.isSpecificIssue
                                                  ? Colors.orange[700]
                                                  : report.scope == 'station'
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
                                      duration:
                                          const Duration(milliseconds: 400),
                                      curve: Curves.elasticOut,
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: value,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  MetroColors.green,
                                                  Colors.green[700]!
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: MetroColors.green
                                                      .withValues(alpha: 0.4),
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
                                                  await _confirmReport(context,
                                                      report.id, currentUserId);
                                                },
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: const Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 10,
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.check_circle,
                                                          size: 18,
                                                          color: Colors.white),
                                                      SizedBox(width: 6),
                                                      Text(
                                                        'Confirmar',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
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
                                          colors: [
                                            Colors.green,
                                            Colors.green[700]!
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_circle,
                                              size: 18, color: Colors.white),
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
                              // Chips de confianza
                              FutureBuilder<UserModel?>(
                                future: _firebaseService.getUser(report.userId),
                                builder: (context, userSnapshot) {
                                  return _buildConfidenceChips(
                                    context,
                                    report,
                                    userSnapshot.data,
                                  );
                                },
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
                                      if (report.stationOperational !=
                                          null) ...[
                                        _buildModernInfoRow(
                                          Icons.info_outline,
                                          'Estado',
                                          report.stationOperational == 'yes'
                                              ? 'Operativa'
                                              : report.stationOperational ==
                                                      'partial'
                                                  ? 'Parcialmente operativa'
                                                  : 'No operativa',
                                          report.stationOperational == 'yes'
                                              ? Colors.green
                                              : report.stationOperational ==
                                                      'partial'
                                                  ? Colors.orange
                                                  : Colors.red,
                                        ),
                                        if (report.stationCrowd != null ||
                                            (report.stationIssues?.isNotEmpty ??
                                                false))
                                          const SizedBox(height: 12),
                                      ],
                                      if (report.stationCrowd != null) ...[
                                        _buildModernInfoRow(
                                          Icons.people,
                                          'Aglomeración',
                                          'Nivel ${report.stationCrowd}/5',
                                          Colors.blue,
                                        ),
                                        if (report.stationIssues?.isNotEmpty ??
                                            false)
                                          const SizedBox(height: 12),
                                      ],
                                      if (report.stationIssues?.isNotEmpty ??
                                          false) ...[
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: (report.stationIssues ?? [])
                                              .take(3)
                                              .map((issue) {
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.orange
                                                        .withOpacity(0.2),
                                                    Colors.orange
                                                        .withOpacity(0.1),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.orange
                                                      .withOpacity(0.3),
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
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                          (report.etaBucket == null ||
                                              report.etaBucket ==
                                                  'unknown')) ...[
                                        _buildModernInfoRow(
                                          Icons.check_circle,
                                          'Llegada confirmada',
                                          'Llegó a las ${_formatTime(report.arrivalTime!)}',
                                          Colors.green,
                                        ),
                                        if (report.trainCrowd != null ||
                                            report.trainStatus != null)
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
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
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
                                      style: const TextStyle(
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
                                      style: const TextStyle(
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

  /// Construye los 3 chips de confianza: Confianza, Fuente, Autor
  Widget _buildConfidenceChips(
    BuildContext context,
    SimplifiedReportModel report,
    UserModel? author,
  ) {
    final confidence = report.confidence ?? 0.0;
    final confidenceLevel =
        SimplifiedReportConfidenceService.getConfidenceLevel(confidence);
    final confidenceColor =
        SimplifiedReportConfidenceService.getConfidenceColor(confidence);
    final explanation =
        SimplifiedReportConfidenceService.getConfidenceExplanation(
            report.confidenceReasons ?? []);

    // Determinar chip de autor
    String authorChipText;
    IconData authorIcon;
    Color authorColor;

    if (author == null) {
      authorChipText = '👤 Usuario';
      authorIcon = Icons.person;
      authorColor = Colors.grey;
    } else {
      // Obtener total de reportes del autor
      final totalReports = author.reportesCount;
      if (totalReports < 5) {
        authorChipText = '📝 Nuevo';
        authorIcon = Icons.edit;
        authorColor = Colors.blue;
      } else if (author.precision >= 85) {
        authorChipText = '🎯 ${author.precision.toStringAsFixed(0)}%';
        authorIcon = Icons.verified;
        authorColor = Colors.green;
      } else {
        authorChipText = '👤 ${author.precision.toStringAsFixed(0)}%';
        authorIcon = Icons.person;
        authorColor = Colors.blue;
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Chip de Confianza
        Tooltip(
          message: explanation.isNotEmpty
              ? 'Confianza: $explanation'
              : 'Confianza: ${(confidence * 100).toStringAsFixed(0)}%',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: confidenceColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: confidenceColor.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  confidenceLevel == 'Alta'
                      ? Icons.verified
                      : confidenceLevel == 'Media'
                          ? Icons.info
                          : Icons.warning,
                  size: 14,
                  color: confidenceColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Confianza: $confidenceLevel',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: confidenceColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Chip de Fuente
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (report.confidenceReasons?.contains('panel') ?? false)
                ? Colors.blue.withOpacity(0.15)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (report.confidenceReasons?.contains('panel') ?? false)
                  ? Colors.blue.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                (report.confidenceReasons?.contains('panel') ?? false)
                    ? Icons.tv
                    : Icons.people,
                size: 14,
                color: (report.confidenceReasons?.contains('panel') ?? false)
                    ? Colors.blue
                    : Colors.grey[700],
              ),
              const SizedBox(width: 6),
              Text(
                (report.confidenceReasons?.contains('panel') ?? false)
                    ? 'Panel Digital'
                    : 'Comunidad',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: (report.confidenceReasons?.contains('panel') ?? false)
                      ? Colors.blue
                      : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        // Chip de Autor
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: authorColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: authorColor.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                authorIcon,
                size: 14,
                color: authorColor,
              ),
              const SizedBox(width: 6),
              Text(
                authorChipText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: authorColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernInfoRow(
      IconData icon, String label, String value, Color color) {
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
                style: const TextStyle(
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
                          style: const TextStyle(
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
                'Fecha',
                _formatDateTime(report.createdAt),
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Confirmaciones',
                '${report.confirmations} usuarios confirmaron este reporte',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Puntos',
                '${report.totalPoints} puntos (${report.basePoints} base + ${report.bonusPoints} bonus)',
              ),
              if (report.scope == 'station') ...[
                if (report.stationOperational != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
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
                    'Aglomeración',
                    'Nivel ${report.stationCrowd}/5',
                  ),
                ],
                if (report.stationIssues?.isNotEmpty ?? false) ...[
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
                    children: (report.stationIssues ?? []).map((issue) {
                      return Chip(
                        label: Text(_getProblemaTexto(issue)),
                        backgroundColor:
                            MetroColors.energyOrange.withOpacity(0.1),
                      );
                    }).toList(),
                  ),
                ],
              ] else if (report.scope == 'train') ...[
                // Si es un reporte de llegada directa
                if (report.arrivalTime != null &&
                    (report.etaBucket == null ||
                        report.etaBucket == 'unknown')) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Llegada confirmada',
                    'Llegó a las ${_formatTime(report.arrivalTime!)}',
                  ),
                ],
                if (report.trainCrowd != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Aglomeración',
                    'Nivel ${report.trainCrowd}/5',
                  ),
                ],
                if (report.trainStatus != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
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
                            await _confirmReport(
                                context, report.id, currentUserId);
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
