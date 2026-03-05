import 'package:flutter/material.dart';
import '../../models/badge_model.dart';
import '../../data/badges_data.dart';
import '../../widgets/badge_grid.dart';
import '../../widgets/achievement_modal.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  BadgeFilter _currentFilter = BadgeFilter.all;

  int get _unlockedCount {
    return BadgesData.allBadges.where((b) => b.unlocked).length;
  }

  int get _totalCount => BadgesData.allBadges.length;

  Map<BadgeRarity, int> get _badgesByRarity {
    final unlocked = BadgesData.allBadges.where((b) => b.unlocked).toList();
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
    final badgesByRarity = _badgesByRarity;
    final progress = (_unlockedCount / _totalCount * 100).round();

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
                          Colors.amber,
                        ),
                        _buildRarityStat(
                          'Épicos',
                          badgesByRarity[BadgeRarity.epic] ?? 0,
                          Colors.purple,
                        ),
                        _buildRarityStat(
                          'Raros',
                          badgesByRarity[BadgeRarity.rare] ?? 0,
                          Colors.blue,
                        ),
                        _buildRarityStat(
                          'Comunes',
                          badgesByRarity[BadgeRarity.common] ?? 0,
                          Colors.grey,
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
                            Colors.blue.shade50,
                            Colors.purple.shade50,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
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
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
