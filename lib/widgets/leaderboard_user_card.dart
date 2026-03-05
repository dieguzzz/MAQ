import 'package:flutter/material.dart';
import '../models/user_model.dart';

/// Widget que muestra un usuario en el leaderboard
class LeaderboardUserCard extends StatelessWidget {
  final UserModel user;
  final int position;
  final bool isCurrentUser;
  final String?
      displayValue; // Valor personalizado para mostrar (puntos, precisión, streak, etc.)

  const LeaderboardUserCard({
    super.key,
    required this.user,
    required this.position,
    this.isCurrentUser = false,
    this.displayValue,
  });

  Color _getPositionColor() {
    switch (position) {
      case 1:
        return Colors.amber[700]!; // Oro
      case 2:
        return Colors.grey[400]!; // Plata
      case 3:
        return Colors.orange[700]!; // Bronce
      default:
        return Colors.blue[100]!;
    }
  }

  IconData _getPositionIcon() {
    switch (position) {
      case 1:
        return Icons.looks_one;
      case 2:
        return Icons.looks_two;
      case 3:
        return Icons.looks_3;
      default:
        return Icons.emoji_events;
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = user.level;
    final levelName = user.levelName;
    final puntos = user.gamification?.puntos ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isCurrentUser ? 4 : 1,
      color: isCurrentUser ? Colors.blue[50] : null,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getPositionColor(),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: position <= 3
                ? Icon(
                    _getPositionIcon(),
                    color: Colors.white,
                    size: 28,
                  )
                : Text(
                    '#$position',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.nombre,
                style: TextStyle(
                  fontWeight:
                      isCurrentUser ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ),
            if (isCurrentUser)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Tú',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              levelName,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              displayValue ?? '$puntos puntos',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Nivel $level',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              displayValue ?? '$puntos pts',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
