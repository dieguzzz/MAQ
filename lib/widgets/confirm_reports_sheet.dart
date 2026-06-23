import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/metro_theme.dart';
import '../services/simplified_report_service.dart';
import '../services/firebase_service.dart';
import '../models/simplified_report_model.dart';
import '../models/user_model.dart';
import '../providers/metro_data_provider.dart';
import '../providers/report_provider.dart';
import 'points_reward_animation.dart';

class ConfirmReportsSheet extends StatefulWidget {
  const ConfirmReportsSheet({super.key});

  @override
  State<ConfirmReportsSheet> createState() => _ConfirmReportsSheetState();

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => const ConfirmReportsSheet(),
        ),
      ),
    );
  }
}

class _ConfirmReportsSheetState extends State<ConfirmReportsSheet> {
  final _reportService = SimplifiedReportService();
  final _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    final user = _firebaseService.getCurrentUser();
    if (user == null) return const SizedBox();

    final metroProvider = Provider.of<MetroDataProvider>(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          _buildHeader(),
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
                // Solo reportes de estación o problemas específicos
                var filteredReports = allReports.where((r) => r.scope != 'train').toList();

                if (filteredReports.isEmpty) {
                  return _buildEmptyState();
                }

                final confirmableItems = <_ConfirmableItem>[];
                for (final report in filteredReports) {
                  if (report.scope == 'station' && !report.isSpecificIssue) {
                    if (report.stationOperational != null) {
                      confirmableItems.add(_ConfirmableItem(report: report, type: _ItemType.stationStatus));
                    }
                    if (report.stationCrowd != null) {
                      confirmableItems.add(_ConfirmableItem(report: report, type: _ItemType.stationCrowd));
                    }
                    if (report.stationIssues?.isNotEmpty ?? false) {
                      confirmableItems.add(_ConfirmableItem(report: report, type: _ItemType.stationIssues));
                    }
                  } else if (report.isSpecificIssue) {
                    confirmableItems.add(_ConfirmableItem(report: report, type: _ItemType.specificIssue));
                  }
                }

                if (confirmableItems.isEmpty) {
                  return _buildEmptyState();
                }

                // Generar lista de stations únicas con reportes
                final stationIds = confirmableItems.map((e) => e.report.stationId).toSet().toList();

                // Order by confidence then confirmations then date
                int sortByConfidence(SimplifiedReportModel a, SimplifiedReportModel b) {
                  final aConf = a.confidence ?? 0.0;
                  final bConf = b.confidence ?? 0.0;
                  final confidenceCompare = bConf.compareTo(aConf);
                  if (confidenceCompare != 0) return confidenceCompare;

                  final confirmCompare = b.confirmations.compareTo(a.confirmations);
                  if (confirmCompare != 0) return confirmCompare;

                  return b.createdAt.compareTo(a.createdAt);
                }

                return DefaultTabController(
                  length: stationIds.length,
                  child: Column(
                    children: [
                      // Scrollable TabBar
                      Container(
                        color: Colors.white,
                        child: TabBar(
                          isScrollable: true,
                          indicatorColor: MetroColors.red,
                          indicatorWeight: 3,
                          labelColor: MetroColors.blue,
                          unselectedLabelColor: MetroColors.grayMedium,
                          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                          dividerColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          tabAlignment: TabAlignment.start,
                          tabs: stationIds.map((id) {
                            final station = metroProvider.getStationById(id);
                            final name = station?.nombre ?? 'Estación $id';
                            final count = confirmableItems.where((i) => i.report.stationId == id).length;
                            return Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(name.toUpperCase()),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: MetroColors.red,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: const TextStyle(color: Colors.white, fontSize: 10),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // TabBarView
                      Expanded(
                        child: TabBarView(
                          children: stationIds.map((stationId) {
                            var stationItems = confirmableItems.where((i) => i.report.stationId == stationId).toList();
                            // Sort
                            stationItems.sort((a, b) => sortByConfidence(a.report, b.report));

                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              itemCount: stationItems.length,
                              itemBuilder: (context, index) {
                                return _buildConfirmableItemCard(context, stationItems[index], user.uid);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MetroColors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: MetroColors.blue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confirmar Reportes',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: MetroColors.grayDark,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ayuda y gana +15 pts',
                      style: TextStyle(
                        color: MetroColors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: MetroColors.grayMedium),
              ),
            ],
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'No hay reportes pendientes para confirmar en este momento.',
              textAlign: TextAlign.center,
              style: TextStyle(
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
      case 'ac': return 'Aire Acondicionado';
      case 'escalator': return 'Escalera Eléctrica';
      case 'elevator': return 'Elevador';
      case 'atm': return 'Cajero/ATM';
      case 'recharge': return 'Máquina de Recarga';
      case 'bathroom': return 'Baño';
      case 'lights': return 'Iluminación';
      default: return type;
    }
  }

  String _getStatusName(String status) {
    switch (status) {
      case 'not_working': return '🔴 No Funciona';
      case 'working_poorly': return '🟡 Funciona Mal';
      case 'out_of_service': return '⚫ Fuera de Servicio';
      default: return status;
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
        if (difference.inMinutes == 0) return 'Hace momentos';
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

  Future<void> _confirmReport(BuildContext context, String reportId, String userId) async {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final success = await reportProvider.confirmReport(reportId, userId);
      if (success) {
        if (!context.mounted) return;
        PointsRewardHelper.showConfirmReportPoints(context, points: 15);
      }
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildConfirmableItemCard(BuildContext context, _ConfirmableItem item, String currentUserId) {
    final report = item.report;
    final isOwnReport = report.userId == currentUserId;
    final confirmedBy = report.confirmedBy ?? [];
    final hasConfirmed = isOwnReport || confirmedBy.contains(currentUserId);
    
    return Consumer<MetroDataProvider>(
      builder: (context, metroProvider, child) {
        final station = metroProvider.getStationById(report.stationId);
        final stationName = station?.nombre ?? 'Estación ${report.stationId}';
        final itemInfo = _getItemInfo(item, stationName);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasConfirmed ? Colors.green.withValues(alpha: 0.3) : Colors.grey[200]!,
              width: hasConfirmed ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: itemInfo.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(itemInfo.icon, color: itemInfo.color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              itemInfo.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: MetroColors.grayDark,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatDate(report.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[400],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          itemInfo.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        if (report.confidence != null && report.confidence! > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                const Icon(Icons.shield_rounded, size: 12, color: MetroColors.blue),
                                const SizedBox(width: 4),
                                Text(
                                  'Confiabilidad: ${(report.confidence! * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: MetroColors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Confirmers Avatars
                  Expanded(
                    child: _buildAvatarStack(report.userId, confirmedBy),
                  ),
                  
                  // Botón confirmar
                  if (hasConfirmed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Confirmado',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          await _confirmReport(context, report.id, currentUserId);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [MetroColors.green, Colors.green[700]!],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: MetroColors.green.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_rounded, size: 16, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'Confirmar',
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarStack(String authorId, List<String> confirmedBy) {
    // Collect up to original author + 3 confirmers to display
    final displayIds = {authorId, ...confirmedBy.take(3)}.toList(); // toSet to avoid duplicate author + confirmer if any bug
    final remainingCount = confirmedBy.length > 3 ? confirmedBy.length - 3 : 0;

    return Row(
      children: [
        SizedBox(
          height: 32,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayIds.length + (remainingCount > 0 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < displayIds.length) {
                final uid = displayIds[index];
                return Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 0 : 4.0),
                  child: FutureBuilder<UserModel?>(
                    future: _firebaseService.getUser(uid),
                    builder: (context, snapshot) {
                      final url = snapshot.data?.fotoUrl;
                      final isAuthor = index == 0;
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isAuthor ? MetroColors.red : Colors.grey[300]!, 
                            width: 2
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: url != null && url.isNotEmpty ? CachedNetworkImageProvider(url) : null,
                          child: (url == null || url.isEmpty) ? Icon(Icons.person, size: 16, color: Colors.grey[400]) : null,
                        ),
                      );
                    },
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '+$remainingCount',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
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
          title: 'Estado de la estación',
          subtitle: statusText,
          color: color,
        );
      case _ItemType.stationCrowd:
        return _ItemInfo(
          icon: Icons.people_rounded,
          title: 'Aglomeración de gente',
          subtitle: 'Nivel ${report.stationCrowd}/5',
          color: MetroColors.blue,
        );
      case _ItemType.stationIssues:
        final issuesText = (report.stationIssues ?? []).take(3).map(_getProblemaTexto).join(', ');
        return _ItemInfo(
          icon: Icons.warning_amber_rounded,
          title: 'Problemas múltiples',
          subtitle: issuesText,
          color: Colors.orange,
        );
      case _ItemType.specificIssue:
        return _ItemInfo(
          icon: Icons.build_rounded,
          title: _getIssueTypeName(report.issueType ?? ''),
          subtitle: '${_getStatusName(report.issueStatus ?? '')} en ${report.issueLocation ?? ''}',
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

  const _ItemInfo({required this.icon, required this.title, required this.subtitle, required this.color});
}
