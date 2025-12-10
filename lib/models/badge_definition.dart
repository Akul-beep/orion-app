/// Badge definitions with categories, requirements, and metadata
/// Similar to Duolingo's achievement system
class BadgeDefinition {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final BadgeCategory category;
  final BadgeRarity rarity;
  final Map<String, dynamic> requirements;
  final int xpReward;
  final String? icon;

  BadgeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.category,
    required this.rarity,
    required this.requirements,
    this.xpReward = 0,
    this.icon,
  });

  /// Check if user meets the requirements for this badge
  /// Requirements format: {'statName': minimumValue}
  /// All requirements must be met (AND logic)
  bool checkRequirements(Map<String, dynamic> userStats) {
    for (final entry in requirements.entries) {
      final statKey = entry.key;
      final requiredValue = entry.value as int;
      final userValue = (userStats[statKey] ?? 0) as int;

      // Default: >= comparison (user value must be >= required value)
      if (userValue < requiredValue) {
        return false;
      }
    }
    return true;
  }
}

enum BadgeCategory {
  learning,    // Lesson and course completion
  trading,     // Trading achievements
  streak,      // Daily activity streaks
  milestone,   // Level and XP milestones
  social,      // Social features (future)
  special,     // Special events and challenges
}

enum BadgeRarity {
  common,      // Easy to get
  rare,        // Moderate difficulty
  epic,        // Hard to achieve
  legendary,   // Very rare
}

/// All badge definitions in the system
class BadgeDefinitions {
  static final List<BadgeDefinition> allBadges = [
    // LEARNING BADGES
    BadgeDefinition(
      id: 'first_lesson',
      name: 'First Steps',
      description: 'Complete your first lesson',
      emoji: '🎯',
      category: BadgeCategory.learning,
      rarity: BadgeRarity.common,
      requirements: {'lessonsCompleted': 1},
      xpReward: 50,
    ),
    BadgeDefinition(
      id: 'week_1_champion',
      name: 'Week 1 Champion',
      description: 'Complete 7 lessons',
      emoji: '🏆',
      category: BadgeCategory.learning,
      rarity: BadgeRarity.rare,
      requirements: {'lessonsCompleted': 7},
      xpReward: 200,
    ),
    BadgeDefinition(
      id: 'month_master',
      name: 'Month Master',
      description: 'Complete 30 lessons',
      emoji: '👑',
      category: BadgeCategory.learning,
      rarity: BadgeRarity.epic,
      requirements: {'lessonsCompleted': 30},
      xpReward: 500,
    ),
    BadgeDefinition(
      id: 'course_completer',
      name: 'Course Completer',
      description: 'Complete all 30 lessons in the course',
      emoji: '🎓',
      category: BadgeCategory.learning,
      rarity: BadgeRarity.legendary,
      requirements: {'lessonsCompleted': 30},
      xpReward: 1000,
    ),
    BadgeDefinition(
      id: 'perfect_lesson',
      name: 'Perfect Score',
      description: 'Complete a lesson with 100% accuracy',
      emoji: '⭐',
      category: BadgeCategory.learning,
      rarity: BadgeRarity.rare,
      requirements: {'perfectLessons': 1},
      xpReward: 100,
    ),
    BadgeDefinition(
      id: 'perfect_week',
      name: 'Perfect Week',
      description: 'Complete 7 lessons with perfect scores',
      emoji: '🌟',
      category: BadgeCategory.learning,
      rarity: BadgeRarity.epic,
      requirements: {'perfectLessons': 7},
      xpReward: 500,
    ),

    // TRADING BADGES
    BadgeDefinition(
      id: 'first_trader',
      name: 'First Trader',
      description: 'Make your first trade',
      emoji: '💼',
      category: BadgeCategory.trading,
      rarity: BadgeRarity.common,
      requirements: {'totalTrades': 1},
      xpReward: 50,
    ),
    BadgeDefinition(
      id: 'active_trader',
      name: 'Active Trader',
      description: 'Make 10 trades',
      emoji: '📈',
      category: BadgeCategory.trading,
      rarity: BadgeRarity.rare,
      requirements: {'totalTrades': 10},
      xpReward: 200,
    ),
    BadgeDefinition(
      id: 'experienced_trader',
      name: 'Experienced Trader',
      description: 'Make 50 trades',
      emoji: '📊',
      category: BadgeCategory.trading,
      rarity: BadgeRarity.epic,
      requirements: {'totalTrades': 50},
      xpReward: 500,
    ),
    BadgeDefinition(
      id: 'trading_master',
      name: 'Trading Master',
      description: 'Make 100 trades',
      emoji: '🚀',
      category: BadgeCategory.trading,
      rarity: BadgeRarity.legendary,
      requirements: {'totalTrades': 100},
      xpReward: 1000,
    ),

    // STREAK BADGES
    BadgeDefinition(
      id: 'streak_3',
      name: '3-Day Streak',
      description: 'Maintain a 3-day learning streak',
      emoji: '🔥',
      category: BadgeCategory.streak,
      rarity: BadgeRarity.common,
      requirements: {'streak': 3},
      xpReward: 50,
    ),
    BadgeDefinition(
      id: 'streak_7',
      name: 'Week Warrior',
      description: 'Maintain a 7-day learning streak',
      emoji: '🔥🔥',
      category: BadgeCategory.streak,
      rarity: BadgeRarity.rare,
      requirements: {'streak': 7},
      xpReward: 200,
    ),
    BadgeDefinition(
      id: 'streak_14',
      name: 'Two Week Champion',
      description: 'Maintain a 14-day learning streak',
      emoji: '🔥🔥🔥',
      category: BadgeCategory.streak,
      rarity: BadgeRarity.epic,
      requirements: {'streak': 14},
      xpReward: 500,
    ),
    BadgeDefinition(
      id: 'streak_30',
      name: 'Month Warrior',
      description: 'Maintain a 30-day learning streak',
      emoji: '🔥🔥🔥🔥',
      category: BadgeCategory.streak,
      rarity: BadgeRarity.legendary,
      requirements: {'streak': 30},
      xpReward: 1000,
    ),
    BadgeDefinition(
      id: 'streak_100',
      name: 'Centurion',
      description: 'Maintain a 100-day learning streak',
      emoji: '👑🔥',
      category: BadgeCategory.streak,
      rarity: BadgeRarity.legendary,
      requirements: {'streak': 100},
      xpReward: 2000,
    ),

    // MILESTONE BADGES (Level-based)
    BadgeDefinition(
      id: 'level_5',
      name: 'Level 5',
      description: 'Reach level 5',
      emoji: '⭐',
      category: BadgeCategory.milestone,
      rarity: BadgeRarity.common,
      requirements: {'level': 5},
      xpReward: 100,
    ),
    BadgeDefinition(
      id: 'level_10',
      name: 'Level 10',
      description: 'Reach level 10',
      emoji: '⭐⭐',
      category: BadgeCategory.milestone,
      rarity: BadgeRarity.rare,
      requirements: {'level': 10},
      xpReward: 300,
    ),
    BadgeDefinition(
      id: 'level_20',
      name: 'Level 20',
      description: 'Reach level 20',
      emoji: '⭐⭐⭐',
      category: BadgeCategory.milestone,
      rarity: BadgeRarity.epic,
      requirements: {'level': 20},
      xpReward: 500,
    ),
    BadgeDefinition(
      id: 'level_30',
      name: 'Level 30',
      description: 'Reach level 30',
      emoji: '⭐⭐⭐⭐',
      category: BadgeCategory.milestone,
      rarity: BadgeRarity.legendary,
      requirements: {'level': 30},
      xpReward: 1000,
    ),
    BadgeDefinition(
      id: 'level_50',
      name: 'Level 50',
      description: 'Reach level 50',
      emoji: '👑',
      category: BadgeCategory.milestone,
      rarity: BadgeRarity.legendary,
      requirements: {'level': 50},
      xpReward: 2000,
    ),

    // XP MILESTONE BADGES
    BadgeDefinition(
      id: 'xp_1000',
      name: 'XP Novice',
      description: 'Earn 1,000 total XP',
      emoji: '💎',
      category: BadgeCategory.milestone,
      rarity: BadgeRarity.common,
      requirements: {'totalXP': 1000},
      xpReward: 100,
    ),
    BadgeDefinition(
      id: 'xp_5000',
      name: 'XP Master',
      description: 'Earn 5,000 total XP',
      emoji: '💎💎',
      category: BadgeCategory.milestone,
      rarity: BadgeRarity.rare,
      requirements: {'totalXP': 5000},
      xpReward: 300,
    ),
    BadgeDefinition(
      id: 'xp_10000',
      name: 'XP Legend',
      description: 'Earn 10,000 total XP',
      emoji: '💎💎💎',
      category: BadgeCategory.milestone,
      rarity: BadgeRarity.epic,
      requirements: {'totalXP': 10000},
      xpReward: 500,
    ),
    BadgeDefinition(
      id: 'xp_25000',
      name: 'XP Champion',
      description: 'Earn 25,000 total XP',
      emoji: '💎💎💎💎',
      category: BadgeCategory.milestone,
      rarity: BadgeRarity.legendary,
      requirements: {'totalXP': 25000},
      xpReward: 1000,
    ),
    BadgeDefinition(
      id: 'xp_50000',
      name: 'XP God',
      description: 'Earn 50,000 total XP',
      emoji: '👑💎',
      category: BadgeCategory.milestone,
      rarity: BadgeRarity.legendary,
      requirements: {'totalXP': 50000},
      xpReward: 2000,
    ),

    // SPECIAL BADGES
    BadgeDefinition(
      id: 'early_adopter',
      name: 'Early Adopter',
      description: 'Join during the first month',
      emoji: '🌱',
      category: BadgeCategory.special,
      rarity: BadgeRarity.rare,
      requirements: {'daysSinceJoin': 30},
      xpReward: 200,
    ),
    BadgeDefinition(
      id: 'daily_learner',
      name: 'Daily Learner',
      description: 'Complete lessons for 7 consecutive days',
      emoji: '📚',
      category: BadgeCategory.learning,
      rarity: BadgeRarity.rare,
      requirements: {'consecutiveLearningDays': 7},
      xpReward: 200,
    ),
  ];

  /// Get badge by ID
  static BadgeDefinition? getBadgeById(String id) {
    try {
      return allBadges.firstWhere((badge) => badge.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get badges by category
  static List<BadgeDefinition> getBadgesByCategory(BadgeCategory category) {
    return allBadges.where((badge) => badge.category == category).toList();
  }

  /// Get badges by rarity
  static List<BadgeDefinition> getBadgesByRarity(BadgeRarity rarity) {
    return allBadges.where((badge) => badge.rarity == rarity).toList();
  }
}

