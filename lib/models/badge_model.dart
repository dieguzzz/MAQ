enum BadgeCategory {
  animal,
  mythology,
  culture,
  hero,
  architecture,
  nature,
  festival,
}

enum BadgeRarity {
  common,
  rare,
  epic,
  legendary,
}

class BadgeModel {
  final String id;
  final String name;
  final String icon;
  final BadgeCategory category;
  final String description;
  final String culturalInfo;
  final String unlockCondition;
  final BadgeRarity rarity;
  final bool unlocked;
  final bool featured;

  BadgeModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.category,
    required this.description,
    required this.culturalInfo,
    required this.unlockCondition,
    required this.rarity,
    this.unlocked = false,
    this.featured = false,
  });

  static BadgeCategory categoryFromString(String category) {
    switch (category) {
      case 'animal':
        return BadgeCategory.animal;
      case 'mythology':
        return BadgeCategory.mythology;
      case 'culture':
        return BadgeCategory.culture;
      case 'hero':
        return BadgeCategory.hero;
      case 'architecture':
        return BadgeCategory.architecture;
      case 'nature':
        return BadgeCategory.nature;
      case 'festival':
        return BadgeCategory.festival;
      default:
        return BadgeCategory.animal;
    }
  }

  static BadgeRarity rarityFromString(String rarity) {
    switch (rarity) {
      case 'common':
        return BadgeRarity.common;
      case 'rare':
        return BadgeRarity.rare;
      case 'epic':
        return BadgeRarity.epic;
      case 'legendary':
        return BadgeRarity.legendary;
      default:
        return BadgeRarity.common;
    }
  }

  String get categoryLabel {
    switch (category) {
      case BadgeCategory.animal:
        return 'Fauna';
      case BadgeCategory.mythology:
        return 'Mitología';
      case BadgeCategory.culture:
        return 'Cultura';
      case BadgeCategory.hero:
        return 'Héroes';
      case BadgeCategory.architecture:
        return 'Arquitectura';
      case BadgeCategory.nature:
        return 'Naturaleza';
      case BadgeCategory.festival:
        return 'Festividades';
    }
  }

  String get rarityLabel {
    switch (rarity) {
      case BadgeRarity.common:
        return 'Común';
      case BadgeRarity.rare:
        return 'Raro';
      case BadgeRarity.epic:
        return 'Épico';
      case BadgeRarity.legendary:
        return 'Legendario';
    }
  }
}



