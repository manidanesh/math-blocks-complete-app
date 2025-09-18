import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rewards_model.dart';

/// Service for managing rewards, stars, badges, and levels
class RewardsService {
  static const String _rewardsKeyPrefix = 'rewards_';
  static const String _badgesKeyPrefix = 'badges_';
  static const String _stickersKeyPrefix = 'stickers_';
  
  static const int _starsPerBadge = 10;
  static const int _maxRecentRewards = 20;

  /// Award a star to a child and check for badge/level progress
  static Future<RewardResult> addStar(String childId, {
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final rewards = await getRewards(childId);
      final newStars = rewards.totalStars + 1;
      
      // Create star reward
      final starReward = Reward(
        id: _generateId(),
        type: RewardType.star,
        childId: childId,
        earnedAt: DateTime.now(),
        description: description ?? 'Correct answer!',
        metadata: metadata,
      );

      // Add to recent rewards
      final updatedRecentRewards = [
        starReward,
        ...rewards.recentRewards,
      ].take(_maxRecentRewards).toList();

      // Check for new badge
      final newBadge = _checkForNewBadge(newStars, rewards.totalStars);
      
      // Check for level up
      final newLevel = _checkForNewLevel(newStars, rewards.currentLevel);
      final newSticker = newLevel != null ? _createStickerForLevel(newLevel, childId) : null;

      // Update rewards
      final updatedRewards = rewards.copyWith(
        totalStars: newStars,
        totalBadges: rewards.totalBadges + (newBadge != null ? 1 : 0),
        totalStickers: rewards.totalStickers + (newSticker != null ? 1 : 0),
        currentLevel: newLevel ?? rewards.currentLevel,
        recentRewards: updatedRecentRewards,
        lastUpdated: DateTime.now(),
      );

      // Save rewards
      await _saveRewards(childId, updatedRewards);
      
      // Save new badge if earned
      if (newBadge != null) {
        await _saveBadge(childId, newBadge);
        updatedRewards.badges.add(newBadge);
      }
      
      // Save new sticker if earned
      if (newSticker != null) {
        await _saveSticker(childId, newSticker);
        updatedRewards.stickers.add(newSticker);
      }

      return RewardResult(
        success: true,
        rewards: updatedRewards,
        newBadge: newBadge,
        newSticker: newSticker,
        levelUp: newLevel != null,
      );
    } catch (e) {
      print('Error adding star: $e');
      return RewardResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Get all rewards for a child
  static Future<ChildRewards> getRewards(String childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rewardsKey = '$_rewardsKeyPrefix$childId';
      final rewardsJson = prefs.getString(rewardsKey);
      
      if (rewardsJson != null) {
        final rewardsData = jsonDecode(rewardsJson) as Map<String, dynamic>;
        return ChildRewards.fromJson(rewardsData);
      }
      
      // Return default rewards for new child
      return _getDefaultRewards(childId);
    } catch (e) {
      print('Error getting rewards: $e');
      return _getDefaultRewards(childId);
    }
  }

  /// Reset all rewards for a child
  static Future<void> resetRewards(String childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove all reward data for this child
      await prefs.remove('$_rewardsKeyPrefix$childId');
      await prefs.remove('$_badgesKeyPrefix$childId');
      await prefs.remove('$_stickersKeyPrefix$childId');
      
      print('Rewards reset for child: $childId');
    } catch (e) {
      print('Error resetting rewards: $e');
    }
  }

  /// Get badges for a child
  static Future<List<Badge>> getBadges(String childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final badgesKey = '$_badgesKeyPrefix$childId';
      final badgesJson = prefs.getString(badgesKey);
      
      if (badgesJson != null) {
        final badgesList = jsonDecode(badgesJson) as List<dynamic>;
        return badgesList
            .map((b) => Badge.fromJson(b as Map<String, dynamic>))
            .toList();
      }
      
      return [];
    } catch (e) {
      print('Error getting badges: $e');
      return [];
    }
  }

  /// Get stickers for a child
  static Future<List<Sticker>> getStickers(String childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stickersKey = '$_stickersKeyPrefix$childId';
      final stickersJson = prefs.getString(stickersKey);
      
      if (stickersJson != null) {
        final stickersList = jsonDecode(stickersJson) as List<dynamic>;
        return stickersList
            .map((s) => Sticker.fromJson(s as Map<String, dynamic>))
            .toList();
      }
      
      return [];
    } catch (e) {
      print('Error getting stickers: $e');
      return [];
    }
  }

  /// Generate motivational message for a child
  static String generateMotivationalMessage(String childName, ChildRewards rewards) {
    final messages = [
      'Great job, $childName! You now have ${rewards.totalStars} stars ⭐',
      'Amazing work, $childName! ${rewards.totalStars} stars and ${rewards.totalBadges} badges 🏅',
      'Fantastic, $childName! You\'re a ${rewards.currentLevel.name} ${rewards.currentLevel.emoji}',
      'Incredible, $childName! ${rewards.totalStars} stars earned! 🌟',
      'Outstanding, $childName! You have ${rewards.totalBadges} badges! 🏆',
    ];
    
    final random = Random();
    return messages[random.nextInt(messages.length)];
  }

  /// Check if child earned a new badge
  static Badge? _checkForNewBadge(int newStars, int oldStars) {
    final oldBadges = oldStars ~/ _starsPerBadge;
    final newBadges = newStars ~/ _starsPerBadge;
    
    if (newBadges > oldBadges) {
      final badgeNumber = newBadges;
      return Badge(
        id: _generateId(),
        name: 'Star Collector #$badgeNumber',
        emoji: '🏅',
        description: 'Earned $badgeNumber badges by collecting ${badgeNumber * _starsPerBadge} stars!',
        requiredStars: badgeNumber * _starsPerBadge,
        earnedAt: DateTime.now(),
      );
    }
    
    return null;
  }

  /// Check if child leveled up
  static ChildLevel? _checkForNewLevel(int newStars, ChildLevel currentLevel) {
    for (final level in ChildLevel.values) {
      if (newStars >= level.minStars && 
          currentLevel.minStars < level.minStars) {
        return level;
      }
    }
    return null;
  }

  /// Create sticker for level completion
  static Sticker _createStickerForLevel(ChildLevel level, String childId) {
    return Sticker(
      id: _generateId(),
      name: '${level.name} Sticker',
      emoji: level.emoji,
      description: 'Completed ${level.name} level!',
      level: level,
      earnedAt: DateTime.now(),
    );
  }

  /// Get default rewards for new child
  static ChildRewards _getDefaultRewards(String childId) {
    return ChildRewards(
      childId: childId,
      totalStars: 0,
      totalBadges: 0,
      totalStickers: 0,
      currentLevel: ChildLevel.onesExplorer,
      recentRewards: [],
      badges: [],
      stickers: [],
      lastUpdated: DateTime.now(),
    );
  }

  /// Save rewards to local storage
  static Future<void> _saveRewards(String childId, ChildRewards rewards) async {
    final prefs = await SharedPreferences.getInstance();
    final rewardsKey = '$_rewardsKeyPrefix$childId';
    final rewardsJson = jsonEncode(rewards.toJson());
    await prefs.setString(rewardsKey, rewardsJson);
  }

  /// Save badge to local storage
  static Future<void> _saveBadge(String childId, Badge badge) async {
    final badges = await getBadges(childId);
    badges.add(badge);
    
    final prefs = await SharedPreferences.getInstance();
    final badgesKey = '$_badgesKeyPrefix$childId';
    final badgesJson = jsonEncode(badges.map((b) => b.toJson()).toList());
    await prefs.setString(badgesKey, badgesJson);
  }

  /// Save sticker to local storage
  static Future<void> _saveSticker(String childId, Sticker sticker) async {
    final stickers = await getStickers(childId);
    stickers.add(sticker);
    
    final prefs = await SharedPreferences.getInstance();
    final stickersKey = '$_stickersKeyPrefix$childId';
    final stickersJson = jsonEncode(stickers.map((s) => s.toJson()).toList());
    await prefs.setString(stickersKey, stickersJson);
  }

  /// Generate unique ID
  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }
}

/// Result of adding a reward
class RewardResult {
  final bool success;
  final ChildRewards? rewards;
  final Badge? newBadge;
  final Sticker? newSticker;
  final bool levelUp;
  final String? error;

  const RewardResult({
    required this.success,
    this.rewards,
    this.newBadge,
    this.newSticker,
    this.levelUp = false,
    this.error,
  });
}
