import 'package:flutter/material.dart';
import '../services/gamification/level_service.dart';

/// Widget que muestra una barra de progreso animada hacia el siguiente nivel
class LevelProgressBar extends StatelessWidget {
  final int currentPoints;
  final int currentLevel;

  const LevelProgressBar({
    super.key,
    required this.currentPoints,
    required this.currentLevel,
  });

  @override
  Widget build(BuildContext context) {
    final progress = LevelService.getProgress(currentPoints, currentLevel);
    final currentLevelPoints = LevelService.getPointsForLevel(currentLevel);
    final nextLevelPoints = LevelService.getPointsForLevel(currentLevel + 1);
    final pointsInCurrentLevel = currentPoints - currentLevelPoints;
    final pointsNeededForNextLevel = nextLevelPoints - currentLevelPoints;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Nivel $currentLevel',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            if (currentLevel < 50)
              Text(
                'Nivel ${currentLevel + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey[300],
          ),
          child: Stack(
            children: [
              // Barra de progreso animada
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                width: MediaQuery.of(context).size.width * progress,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue[400]!,
                      Colors.blue[700]!,
                    ],
                  ),
                ),
              ),
              // Texto de progreso
              Center(
                child: Text(
                  currentLevel >= 50
                      ? 'Nivel máximo alcanzado'
                      : '$pointsInCurrentLevel / $pointsNeededForNextLevel puntos',
                  style: TextStyle(
                    color: progress > 0.5 ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
