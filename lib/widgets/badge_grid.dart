import 'package:flutter/material.dart';
import '../models/badge_model.dart';
import '../data/badges_data.dart';

enum BadgeFilter { all, featured, unlocked, locked }

class BadgeGrid extends StatelessWidget {
  final BadgeFilter filter;
  final Function(BadgeModel) onBadgeTap;

  const BadgeGrid({
    super.key,
    this.filter = BadgeFilter.all,
    required this.onBadgeTap,
  });

  List<BadgeModel> _getFilteredBadges(List<BadgeModel> badges) {
    switch (filter) {
      case BadgeFilter.featured:
        return badges.where((b) => b.featured).toList();
      case BadgeFilter.unlocked:
        return badges.where((b) => b.unlocked).toList();
      case BadgeFilter.locked:
        return badges.where((b) => !b.unlocked).toList();
      case BadgeFilter.all:
      default:
        return badges;
    }
  }

  MaterialColor _getCategoryColor(BadgeCategory category) {
    switch (category) {
      case BadgeCategory.animal:
        return Colors.green;
      case BadgeCategory.mythology:
        return Colors.purple;
      case BadgeCategory.culture:
        return Colors.pink;
      case BadgeCategory.hero:
        return Colors.orange;
      case BadgeCategory.architecture:
        return Colors.blue;
      case BadgeCategory.nature:
        return Colors.lime;
      case BadgeCategory.festival:
        return Colors.amber;
    }
  }

  Color _getRarityBorderColor(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return Colors.grey.shade300;
      case BadgeRarity.rare:
        return Colors.blue.shade400;
      case BadgeRarity.epic:
        return Colors.purple.shade500;
      case BadgeRarity.legendary:
        return Colors.amber.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final badges = _getFilteredBadges(BadgesData.allBadges);

    // Agrupar por categoría
    final Map<BadgeCategory, List<BadgeModel>> groupedBadges = {};
    for (var badge in badges) {
      groupedBadges.putIfAbsent(badge.category, () => []).add(badge);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupedBadges.entries.map((entry) {
        final categoryBadges = entry.value;
        final unlockedCount = categoryBadges.where((b) => b.unlocked).length;
        final totalCount = categoryBadges.length;

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Text(
                      categoryBadges.first.categoryLabel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($unlockedCount/$totalCount)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: categoryBadges.length,
                itemBuilder: (context, index) {
                  final badge = categoryBadges[index];
                  final categoryColor = _getCategoryColor(badge.category);
                  final borderColor = _getRarityBorderColor(badge.rarity);

                  return GestureDetector(
                    onTap: () => onBadgeTap(badge),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: borderColor,
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(6),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Icon
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        categoryColor[500]!,
                                        categoryColor[700]!,
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    color: badge.unlocked ? null : Colors.grey,
                                  ),
                                  child: Center(
                                    child: Text(
                                      badge.unlocked ? badge.icon : '🔒',
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Name
                                Flexible(
                                  child: Text(
                                    badge.name,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Rarity indicator
                          if (badge.rarity == BadgeRarity.legendary)
                            const Positioned(
                              top: 4,
                              right: 4,
                              child: Icon(
                                Icons.star,
                                size: 10,
                                color: Colors.amber,
                              ),
                            ),

                          // Lock overlay
                          if (!badge.unlocked)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.lock,
                                    size: 18,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
