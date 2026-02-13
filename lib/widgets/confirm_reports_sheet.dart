import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';
import '../providers/metro_data_provider.dart';
import '../services/firebase_service.dart';
import '../services/simplified_report_service.dart';
import '../services/debug_log_service.dart';
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
  String? _selectedFilter; // null=todos, 'status', 'crowd', 'issues'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _selectedFilter = null; // Todos
              break;
            case 1:
              _selectedFilter = 'status';
              break;
            case 2:
              _selectedFilter = 'crowd';
              break;
            case 3:
              _selectedFilter = 'issues';
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
                  Tab(text: 'ESTADO'),
                  Tab(text: 'NIVEL'),
                  Tab(text: 'FALLAS'),
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

                // Excluir reportes de tren (solo estación y fallas específicas)
                var filteredReports = allReports
                    .where((report) => report.scope != 'train')
                    .toList();
                logService.addLog(
                  'ConfirmReports',
                  'Reportes de estación (sin trenes): ${filteredReports.length}',
                  level: LogLevel.info,
                );

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

                // Desglosar reportes de estación en items individuales
                final confirmableItems = <_ConfirmableItem>[];
                for (final report in combinedReports) {
                  if (report.scope == 'station' && !report.isSpecificIssue) {
                    // Desglosar reporte de estación en items separados
                    if (report.stationOperational != null) {
                      confirmableItems.add(_ConfirmableItem(
                        report: report,
                        type: _ItemType.stationStatus,
                      ));
                    }
                    if (report.stationCrowd != null) {
                      confirmableItems.add(_ConfirmableItem(
                        report: report,
                        type: _ItemType.stationCrowd,
                      ));
                    }
                    if (report.stationIssues?.isNotEmpty ?? false) {
                      confirmableItems.add(_ConfirmableItem(
                        report: report,
                        type: _ItemType.stationIssues,
                      ));
                    }
                  } else if (report.isSpecificIssue) {
                    confirmableItems.add(_ConfirmableItem(
                      report: report,
                      type: _ItemType.specificIssue,
                    ));
                  }
                }

                // Filtrar items por tab seleccionado
                final displayItems = _selectedFilter == null
                    ? confirmableItems
                    : confirmableItems.where((item) {
                        switch (_selectedFilter) {
                          case 'status':
                            return item.type == _ItemType.stationStatus;
                          case 'crowd':
                            return item.type == _ItemType.stationCrowd;
                          case 'issues':
                            return item.type == _ItemType.stationIssues ||
                                item.type == _ItemType.specificIssue;
                          default:
                            return true;
                        }
                      }).toList();

                if (displayItems.isEmpty) {
                  return _buildEmptyState();
                }

                return Column(
                  children: [
                    // Contador de items
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: MetroColors.blue
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${displayItems.length} items',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: MetroColors.blue,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Confirma lo que ves correcto',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        itemCount: displayItems.length,
                        itemBuilder: (context, index) {
                          final item = displayItems[index];
                          return _buildConfirmableItemCard(
                              context, item, user.uid);
                        },
                      ),
                    ),
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
              _selectedFilter == null
                  ? 'No hay reportes pendientes para confirmar en este momento.'
                  : 'No hay reportes de ${_selectedFilter == 'status' ? 'estado' : _selectedFilter == 'crowd' ? 'aglomeración' : 'fallas'} para confirmar.',
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

  Widget _buildConfirmableItemCard(
    BuildContext context,
    _ConfirmableItem item,
    String currentUserId,
  ) {
    final report = item.report;
    final isOwnReport = report.userId == currentUserId;

    return FutureBuilder<bool>(
      future: isOwnReport
          ? Future.value(false)
          : _firebaseService.hasUserConfirmedReport(report.id, currentUserId),
      builder: (context, confirmSnapshot) {
        final isConfirmed = confirmSnapshot.data ?? false;

        return Consumer<MetroDataProvider>(
          builder: (context, metroProvider, child) {
            final station = metroProvider.getStationById(report.stationId);
            final stationName =
                station?.nombre ?? 'Estación ${report.stationId}';

            // Construir contenido según tipo de item
            final itemInfo = _getItemInfo(item, stationName);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isConfirmed
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.grey[200]!,
                  width: isConfirmed ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icono del tipo
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: itemInfo.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      itemInfo.icon,
                      color: itemInfo.color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Contenido
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stationName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: MetroColors.grayMedium,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          itemInfo.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: MetroColors.grayDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          itemInfo.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: itemInfo.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatDate(report.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Botón confirmar
                  if (isConfirmed || isOwnReport)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isConfirmed
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isConfirmed
                            ? Icons.check_circle_rounded
                            : Icons.block_rounded,
                        color: isConfirmed ? Colors.green : Colors.grey[400],
                        size: 24,
                      ),
                    )
                  else
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          await _confirmReport(
                              context, report.id, currentUserId);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                MetroColors.green,
                                Colors.green[700]!,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: MetroColors.green
                                    .withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_rounded,
                                  size: 16, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Sí',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  _ItemInfo _getItemInfo(_ConfirmableItem item, String stationName) {
    final report = item.report;
    switch (item.type) {
      case _ItemType.stationStatus:
        final statusText = report.stationOperational == 'yes'
            ? 'Operativa'
            : report.stationOperational == 'partial'
                ? 'Parcialmente operativa'
                : 'No operativa';
        final color = report.stationOperational == 'yes'
            ? Colors.green
            : report.stationOperational == 'partial'
                ? Colors.orange
                : Colors.red;
        return _ItemInfo(
          icon: Icons.info_rounded,
          title: 'Estado: $statusText',
          subtitle: 'Reporte de estación',
          color: color,
        );
      case _ItemType.stationCrowd:
        return _ItemInfo(
          icon: Icons.people_rounded,
          title: 'Aglomeración: ${report.stationCrowd}/5',
          subtitle: 'Reporte de estación',
          color: MetroColors.blue,
        );
      case _ItemType.stationIssues:
        final issuesText = (report.stationIssues ?? [])
            .take(3)
            .map(_getProblemaTexto)
            .join(', ');
        return _ItemInfo(
          icon: Icons.warning_amber_rounded,
          title: 'Problemas: $issuesText',
          subtitle: 'Reporte de estación',
          color: Colors.orange,
        );
      case _ItemType.specificIssue:
        return _ItemInfo(
          icon: Icons.build_rounded,
          title:
              '${_getIssueTypeName(report.issueType ?? '')} - ${_getStatusName(report.issueStatus ?? '')}',
          subtitle: report.issueLocation ?? 'Problema específico',
          color: Colors.orange,
        );
    }
  }

}

enum _ItemType {
  stationStatus,
  stationCrowd,
  stationIssues,
  specificIssue,
}

class _ConfirmableItem {
  final SimplifiedReportModel report;
  final _ItemType type;

  const _ConfirmableItem({required this.report, required this.type});
}

class _ItemInfo {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _ItemInfo({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
