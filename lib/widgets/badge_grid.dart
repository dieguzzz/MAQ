import 'package:flutter/material.dart';
import '../models/badge_model.dart';
import '../data/badges_data.dart';

class BadgeGrid extends StatelessWidget {
  final BadgeFilter filter;
  final Function(BadgeModel) onBadgeTap;

  const BadgeGrid({
    super.key,
    required this.filter,
    required this.onBadgeTap,
  });

  List<BadgeModel> _getFilteredBadges() {
    List<BadgeModel> badges = BadgesData.allBadges;

    switch (filter) {
      case BadgeFilter.all:
        return badges;
      case BadgeFilter.featured:
        return badges.where((b) => b.featured).toList();
      case BadgeFilter.unlocked:
        return badges.where((b) => b.unlocked).toList();
      case BadgeFilter.locked:
        return badges.where((b) => !b.unlocked).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredBadges = _getFilteredBadges();

    if (filteredBadges.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No hay badges para mostrar',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: filteredBadges.length,
      itemBuilder: (context, index) {
        final badge = filteredBadges[index];
        return _BadgeCard(
          badge: badge,
          onTap: () => onBadgeTap(badge),
        );
      },
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final BadgeModel badge;
  final VoidCallback onTap;

  const _BadgeCard({
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = !badge.unlocked;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isLocked ? 1 : 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isLocked ? Colors.grey[200] : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                badge.icon,
                style: TextStyle(
                  fontSize: 40,
                  color: isLocked ? Colors.grey[400] : null,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  badge.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isLocked ? Colors.grey[600] : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isLocked)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(
                    Icons.lock,
                    size: 12,
                    color: Colors.grey[500],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

