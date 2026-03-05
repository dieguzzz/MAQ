/// Servicio para calcular y gestionar el sistema de niveles (1-50)
class LevelService {
  /// Nombres de niveles con emojis
  static const Map<int, String> levelNames = {
    1: '🥚 Novato del Metro',
    2: '🥚 Novato del Metro',
    3: '🥚 Novato del Metro',
    4: '🥚 Novato del Metro',
    5: '🚶 Viajero Frecuente',
    6: '🚶 Viajero Frecuente',
    7: '🚶 Viajero Frecuente',
    8: '🚶 Viajero Frecuente',
    9: '🚶 Viajero Frecuente',
    10: '🎯 Reportero Confiable',
    11: '🎯 Reportero Confiable',
    12: '🎯 Reportero Confiable',
    13: '🎯 Reportero Confiable',
    14: '🎯 Reportero Confiable',
    15: '🎯 Reportero Confiable',
    16: '🎯 Reportero Confiable',
    17: '🎯 Reportero Confiable',
    18: '🎯 Reportero Confiable',
    19: '🎯 Reportero Confiable',
    20: '💪 Experto del Metro',
    21: '💪 Experto del Metro',
    22: '💪 Experto del Metro',
    23: '💪 Experto del Metro',
    24: '💪 Experto del Metro',
    25: '💪 Experto del Metro',
    26: '💪 Experto del Metro',
    27: '💪 Experto del Metro',
    28: '💪 Experto del Metro',
    29: '💪 Experto del Metro',
    30: '🌟 Leyenda Urbana',
    31: '🌟 Leyenda Urbana',
    32: '🌟 Leyenda Urbana',
    33: '🌟 Leyenda Urbana',
    34: '🌟 Leyenda Urbana',
    35: '🌟 Leyenda Urbana',
    36: '🌟 Leyenda Urbana',
    37: '🌟 Leyenda Urbana',
    38: '🌟 Leyenda Urbana',
    39: '🌟 Leyenda Urbana',
    40: '👑 Héroe del Metro',
    41: '👑 Héroe del Metro',
    42: '👑 Héroe del Metro',
    43: '👑 Héroe del Metro',
    44: '👑 Héroe del Metro',
    45: '👑 Héroe del Metro',
    46: '👑 Héroe del Metro',
    47: '👑 Héroe del Metro',
    48: '👑 Héroe del Metro',
    49: '👑 Héroe del Metro',
    50: '🇵🇦 Ícono Panameño',
  };

  /// Puntos requeridos para cada nivel
  static const Map<int, int> pointsRequired = {
    1: 0,
    2: 100,
    3: 250,
    4: 500,
    5: 1000,
    6: 1500,
    7: 2000,
    8: 2500,
    9: 3000,
    10: 3500,
    11: 4500,
    12: 5500,
    13: 6500,
    14: 7500,
    15: 8500,
    16: 9500,
    17: 10500,
    18: 11500,
    19: 12500,
    20: 13500,
    21: 15500,
    22: 17500,
    23: 19500,
    24: 21500,
    25: 23500,
    26: 25500,
    27: 27500,
    28: 29500,
    29: 31500,
    30: 33500,
    31: 36500,
    32: 39500,
    33: 42500,
    34: 45500,
    35: 48500,
    36: 51500,
    37: 54500,
    38: 57500,
    39: 60500,
    40: 63500,
    41: 68500,
    42: 73500,
    43: 78500,
    44: 83500,
    45: 88500,
    46: 93500,
    47: 98500,
    48: 103500,
    49: 108500,
    50: 50000, // Nivel máximo (ajustado según plan)
  };

  /// Calcula el nivel basado en los puntos totales
  static int calculateLevel(int totalPoints) {
    // Si tiene 50,000 o más puntos, retornar nivel 50
    if (totalPoints >= 50000) {
      return 50;
    }

    // Buscar el nivel más alto que el usuario puede alcanzar
    for (int level = 50; level >= 1; level--) {
      if (totalPoints >= pointsRequired[level]!) {
        return level;
      }
    }

    return 1;
  }

  /// Obtiene el nombre del nivel con emoji
  static String getLevelName(int level) {
    if (level < 1) return levelNames[1]!;
    if (level > 50) return levelNames[50]!;
    return levelNames[level] ?? levelNames[1]!;
  }

  /// Obtiene los puntos requeridos para un nivel específico
  static int getPointsForLevel(int level) {
    if (level < 1) return 0;
    if (level > 50) return pointsRequired[50]!;
    return pointsRequired[level] ?? 0;
  }

  /// Calcula el progreso (0.0-1.0) hacia el siguiente nivel
  static double getProgress(int currentPoints, int currentLevel) {
    if (currentLevel >= 50) {
      return 1.0; // Ya está en el nivel máximo
    }

    final currentLevelPoints = getPointsForLevel(currentLevel);
    final nextLevelPoints = getPointsForLevel(currentLevel + 1);
    final pointsInCurrentLevel = currentPoints - currentLevelPoints;
    final pointsNeededForNextLevel = nextLevelPoints - currentLevelPoints;

    if (pointsNeededForNextLevel <= 0) return 1.0;

    final progress = pointsInCurrentLevel / pointsNeededForNextLevel;
    return progress.clamp(0.0, 1.0);
  }

  /// Obtiene la descripción del rango de puntos para un nivel
  static String getLevelDescription(int level) {
    if (level >= 50) {
      return '${getPointsForLevel(50)}+ puntos';
    }
    final currentPoints = getPointsForLevel(level);
    final nextPoints = getPointsForLevel(level + 1);
    return '$currentPoints - ${nextPoints - 1} puntos';
  }
}
