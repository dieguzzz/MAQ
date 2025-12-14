import 'package:flutter/material.dart';
import '../models/user_model.dart';

/// Widget que muestra estadísticas rápidas del usuario en un grid
class ProfileStatsCard extends StatelessWidget {
  final UserModel user;

  const ProfileStatsCard({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final gamification = user.gamification;
    final puntos = gamification?.puntos ?? 0;
    final streak = gamification?.streak ?? 0;
    final precision = user.precision;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadísticas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.8,
              children: [
                _buildStatItem(
                  icon: Icons.stars,
                  label: 'Puntos',
                  value: '$puntos',
                  color: Colors.amber,
                ),
                _buildStatItem(
                  icon: Icons.report,
                  label: 'Reportes',
                  value: '${user.reportesCount}',
                  color: Colors.blue,
                ),
                _buildStatItem(
                  icon: Icons.local_fire_department,
                  label: 'Racha',
                  value: '$streak días',
                  color: Colors.orange,
                ),
                _buildStatItem(
                  icon: Icons.track_changes,
                  label: 'Precisión',
                  value: '${precision.toStringAsFixed(1)}%',
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

