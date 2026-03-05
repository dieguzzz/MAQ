import 'package:flutter/material.dart';
import '../models/gamification_model.dart' as gamification show Badge;

/// Widget que muestra un preview de los últimos badges desbloqueados
class ProfileBadgesPreview extends StatelessWidget {
  final List<gamification.Badge> badges;

  const ProfileBadgesPreview({
    super.key,
    required this.badges,
  });

  @override
  Widget build(BuildContext context) {
    // Ordenar badges por fecha de desbloqueo (más recientes primero)
    final sortedBadges = List<gamification.Badge>.from(badges)
      ..sort((gamification.Badge a, gamification.Badge b) {
        if (a.desbloqueadoEn == null && b.desbloqueadoEn == null) return 0;
        if (a.desbloqueadoEn == null) return 1;
        if (b.desbloqueadoEn == null) return -1;
        return b.desbloqueadoEn!.compareTo(a.desbloqueadoEn!);
      });

    // Tomar los últimos 6
    final recentBadges = sortedBadges.take(6).toList();

    if (recentBadges.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              const Text(
                'Logros',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Aún no has desbloqueado ningún logro',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Logros Recientes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (badges.length > 6)
                  TextButton(
                    onPressed: () {
                      // TODO: Navegar a pantalla completa de badges
                    },
                    child: const Text('Ver todos'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 85,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recentBadges.length,
                itemBuilder: (context, index) {
                  final badge = recentBadges[index];
                  return _buildBadgeItem(badge);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeItem(gamification.Badge badge) {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 10),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.amber[100],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber[300]!, width: 1.5),
            ),
            child: Center(
              child: Text(
                badge.icono,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            badge.nombre,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
