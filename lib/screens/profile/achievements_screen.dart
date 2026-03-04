import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/badge_model.dart';
import '../../data/badges_data.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/badge_grid.dart';
import '../../widgets/achievement_modal.dart';
import '../../theme/metro_theme.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  BadgeFilter _currentFilter = BadgeFilter.all;
  List<BadgeModel> _dynamicBadges = [];
  bool _isLoading = true;

  /// Maps Firestore BadgeType names to BadgesData IDs.
  /// This bridges the two badge systems: gamification_model.dart enums
  /// and the static Panamanian-themed badges in badges_data.dart.
  static const Map<String, String> _badgeTypeToStaticId = {
    'BadgeType.primerReporte': 'gecko',
    'BadgeType.verificador': 'mono-titi',
    'BadgeType.ojoDeAguila': 'aguila-harpia',
    'BadgeType.salvavidas': 'madre-agua',
    'BadgeType.metroMaster': 'canal',
    'BadgeType.streakSemana': 'tamborito',
    'BadgeType.streakMes': 'pollera',
    'BadgeType.topContribuidor': 'victoriano',
    'BadgeType.francotirador': 'rana-dorada',
    'BadgeType.detective': 'guacamaya',
    'BadgeType.observador': 'palma-real',
    'BadgeType.ojoDeAguila80': 'arbol-panama',
    'BadgeType.ayudanteComunidad': 'puente-americas',
    'BadgeType.influencerMetro': 'congos',
    'BadgeType.expertoLinea1': 'casco-antiguo',
    'BadgeType.maestroLinea2': 'san-blas',
    'BadgeType.almaPollera': 'mejorana',
    'BadgeType.reyCarnaval': 'carnavales',
    'BadgeType.profesorDelMetro': 'amador',
    'BadgeType.fundador': 'la-guali',
    'BadgeType.fundadorPlatino': 'urraca',
    'BadgeType.pioneroEstacion': 'espiritu-santo',
    'BadgeType.mejoradorDatos': 'tulivieja',
    'BadgeType.confirmadorConfiable': 'darien',
    'BadgeType.exploradorUrbano': 'volcan-baru',
    'BadgeType.heroeHoraPico': 'diablicos',
    'BadgeType.verificadorElite': 'mojadera',
    'BadgeType.maestroL1': 'feria-david',
    'BadgeType.maestroL2': 'torrijos',
    'BadgeType.leyendaFundadora': 'chorcha',
  };

  @override
  void initState() {
    super.initState();
    _loadUserBadges();
  }

  Future<void> _loadUserBadges() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.uid;

      if (userId == null) {
        _setStaticBadges();
        return;
      }

      final firebaseService = FirebaseService();
      final user = await firebaseService.getUser(userId);

      if (user == null || user.gamification == null) {
        _setStaticBadges();
        return;
      }

      // Get the set of static badge IDs that the user has unlocked
      final unlockedStaticIds = <String>{};
      for (final badge in user.gamification!.badges) {
        final typeKey = badge.type.toString();
        final staticId = _badgeTypeToStaticId[typeKey];
        if (staticId != null) {
          unlockedStaticIds.add(staticId);
        }
      }

      // Create dynamic badges with real unlock state
      setState(() {
        _dynamicBadges = BadgesData.allBadges.map((badge) {
          return badge.copyWith(
            unlocked: unlockedStaticIds.contains(badge.id),
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user badges: $e');
      _setStaticBadges();
    }
  }

  void _setStaticBadges() {
    setState(() {
      // Fallback: all badges locked if we can't load user data
      _dynamicBadges = BadgesData.allBadges.map((badge) {
        return badge.copyWith(unlocked: false);
      }).toList();
      _isLoading = false;
    });
  }

  int get _unlockedCount {
    return _dynamicBadges.where((b) => b.unlocked).length;
  }

  int get _totalCount => _dynamicBadges.length;

  Map<BadgeRarity, int> get _badgesByRarity {
    final unlocked = _dynamicBadges.where((b) => b.unlocked).toList();
    return {
      BadgeRarity.legendary:
          unlocked.where((b) => b.rarity == BadgeRarity.legendary).length,
      BadgeRarity.epic:
          unlocked.where((b) => b.rarity == BadgeRarity.epic).length,
      BadgeRarity.rare:
          unlocked.where((b) => b.rarity == BadgeRarity.rare).length,
      BadgeRarity.common:
          unlocked.where((b) => b.rarity == BadgeRarity.common).length,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Colección de Logros'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final badgesByRarity = _badgesByRarity;
    final progress =
        _totalCount > 0 ? (_unlockedCount / _totalCount * 100).round() : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Colección de Logros'),
        actions: [
          PopupMenuButton<BadgeFilter>(
            icon: const Icon(Icons.filter_list),
            onSelected: (filter) {
              setState(() {
                _currentFilter = filter;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: BadgeFilter.all,
                child: Text('Todos'),
              ),
              const PopupMenuItem(
                value: BadgeFilter.featured,
                child: Text('Destacados'),
              ),
              const PopupMenuItem(
                value: BadgeFilter.unlocked,
                child: Text('Desbloqueados'),
              ),
              const PopupMenuItem(
                value: BadgeFilter.locked,
                child: Text('Bloqueados'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary Card
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Colección de Logros',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Rarity breakdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildRarityStat(
                          'Legendarios',
                          badgesByRarity[BadgeRarity.legendary] ?? 0,
                          MetroColors.energyOrange,
                        ),
                        _buildRarityStat(
                          'Épicos',
                          badgesByRarity[BadgeRarity.epic] ?? 0,
                          MetroColors.blue,
                        ),
                        _buildRarityStat(
                          'Raros',
                          badgesByRarity[BadgeRarity.rare] ?? 0,
                          MetroColors.green,
                        ),
                        _buildRarityStat(
                          'Comunes',
                          badgesByRarity[BadgeRarity.common] ?? 0,
                          MetroColors.grayMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Progress
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            MetroColors.blue.withValues(alpha: 0.08),
                            MetroColors.green.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: MetroColors.blue.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🎯', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Text(
                            'Has completado el $progress% de la colección',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Badge Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: BadgeGrid(
                badges: _dynamicBadges,
                filter: _currentFilter,
                onBadgeTap: (badge) {
                  showDialog(
                    context: context,
                    builder: (context) => AchievementModal(
                      badge: badge,
                      onClose: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRarityStat(String label, int count, Color color) {
    return Column(
      children: [
        Icon(
          Icons.star,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: MetroColors.grayDark.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
