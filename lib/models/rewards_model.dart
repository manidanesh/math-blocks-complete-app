/// Enum for different types of rewards
enum RewardType {
  star,
  badge,
  sticker,
}

/// Enum for different levels a child can achieve
enum ChildLevel {
  onesExplorer('Ones Explorer', '🌟', 0, 50),
  tensBuilder('Tens Builder', '🏗️', 50, 100),
  hundredsHero('Hundreds Hero', '🦸', 100, 200),
  thousandsChampion('Thousands Champion', '🏆', 200, 500);

  const ChildLevel(this.name, this.emoji, this.minStars, this.maxStars);
  
  final String name;
  final String emoji;
  final int minStars;
  final int maxStars;
}

/// Represents a single reward (star, badge, or sticker)
class Reward {
  final String id;
  final RewardType type;
  final String childId;
  final DateTime earnedAt;
  final String? description;
  final Map<String, dynamic>? metadata;

  const Reward({
    required this.id,
    required this.type,
    required this.childId,
    required this.earnedAt,
    this.description,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'childId': childId,
      'earnedAt': earnedAt.toIso8601String(),
      'description': description,
      'metadata': metadata,
    };
  }

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] as String,
      type: RewardType.values.firstWhere((e) => e.name == json['type']),
      childId: json['childId'] as String,
      earnedAt: DateTime.parse(json['earnedAt'] as String),
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Represents a badge earned by a child
class Badge {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final int requiredStars;
  final DateTime earnedAt;

  const Badge({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.requiredStars,
    required this.earnedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'description': description,
      'requiredStars': requiredStars,
      'earnedAt': earnedAt.toIso8601String(),
    };
  }

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      description: json['description'] as String,
      requiredStars: json['requiredStars'] as int,
      earnedAt: DateTime.parse(json['earnedAt'] as String),
    );
  }
}

/// Represents a sticker earned by completing a level
class Sticker {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final ChildLevel level;
  final DateTime earnedAt;

  const Sticker({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.level,
    required this.earnedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'description': description,
      'level': level.name,
      'earnedAt': earnedAt.toIso8601String(),
    };
  }

  factory Sticker.fromJson(Map<String, dynamic> json) {
    return Sticker(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      description: json['description'] as String,
      level: ChildLevel.values.firstWhere((e) => e.name == json['level']),
      earnedAt: DateTime.parse(json['earnedAt'] as String),
    );
  }
}

/// Complete rewards summary for a child
class ChildRewards {
  final String childId;
  final int totalStars;
  final int totalBadges;
  final int totalStickers;
  final ChildLevel currentLevel;
  final List<Reward> recentRewards;
  final List<Badge> badges;
  final List<Sticker> stickers;
  final DateTime lastUpdated;

  const ChildRewards({
    required this.childId,
    required this.totalStars,
    required this.totalBadges,
    required this.totalStickers,
    required this.currentLevel,
    required this.recentRewards,
    required this.badges,
    required this.stickers,
    required this.lastUpdated,
  });

  /// Calculate progress towards next level (0.0 to 1.0)
  double get levelProgress {
    final currentLevelStars = currentLevel.minStars;
    final nextLevelStars = _getNextLevelStars();
    final progressStars = totalStars - currentLevelStars;
    final neededStars = nextLevelStars - currentLevelStars;
    
    if (neededStars <= 0) return 1.0;
    return (progressStars / neededStars).clamp(0.0, 1.0);
  }

  /// Get stars needed for next level
  int get starsToNextLevel {
    final nextLevelStars = _getNextLevelStars();
    return (nextLevelStars - totalStars).clamp(0, 999);
  }

  /// Get next level or null if at max level
  ChildLevel? get nextLevel {
    final levels = ChildLevel.values;
    final currentIndex = levels.indexOf(currentLevel);
    if (currentIndex < levels.length - 1) {
      return levels[currentIndex + 1];
    }
    return null;
  }

  int _getNextLevelStars() {
    final next = nextLevel;
    return next?.minStars ?? currentLevel.maxStars;
  }

  Map<String, dynamic> toJson() {
    return {
      'childId': childId,
      'totalStars': totalStars,
      'totalBadges': totalBadges,
      'totalStickers': totalStickers,
      'currentLevel': currentLevel.name,
      'recentRewards': recentRewards.map((r) => r.toJson()).toList(),
      'badges': badges.map((b) => b.toJson()).toList(),
      'stickers': stickers.map((s) => s.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory ChildRewards.fromJson(Map<String, dynamic> json) {
    return ChildRewards(
      childId: json['childId'] as String,
      totalStars: json['totalStars'] as int,
      totalBadges: json['totalBadges'] as int,
      totalStickers: json['totalStickers'] as int,
      currentLevel: ChildLevel.values.firstWhere((e) => e.name == json['currentLevel']),
      recentRewards: (json['recentRewards'] as List<dynamic>)
          .map((r) => Reward.fromJson(r as Map<String, dynamic>))
          .toList(),
      badges: (json['badges'] as List<dynamic>)
          .map((b) => Badge.fromJson(b as Map<String, dynamic>))
          .toList(),
      stickers: (json['stickers'] as List<dynamic>)
          .map((s) => Sticker.fromJson(s as Map<String, dynamic>))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  ChildRewards copyWith({
    String? childId,
    int? totalStars,
    int? totalBadges,
    int? totalStickers,
    ChildLevel? currentLevel,
    List<Reward>? recentRewards,
    List<Badge>? badges,
    List<Sticker>? stickers,
    DateTime? lastUpdated,
  }) {
    return ChildRewards(
      childId: childId ?? this.childId,
      totalStars: totalStars ?? this.totalStars,
      totalBadges: totalBadges ?? this.totalBadges,
      totalStickers: totalStickers ?? this.totalStickers,
      currentLevel: currentLevel ?? this.currentLevel,
      recentRewards: recentRewards ?? this.recentRewards,
      badges: badges ?? this.badges,
      stickers: stickers ?? this.stickers,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
