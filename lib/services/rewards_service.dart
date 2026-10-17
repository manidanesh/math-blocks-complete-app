import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_log.dart';
import '../models/rewards_model.dart';

/// Service for managing rewards, stars, badges, and levels
class RewardsService {
  static const String _rewardsKeyPrefix = 'rewards_';
  static const String _badgesKeyPrefix = 'badges_';
  static const String _stickersKeyPrefix = 'stickers_';

  static const int _starsPerBadge = 10;
  static const int _maxRecentRewards = 20;

  static Future<void>? _pendingAwards;

  static Future<T> _serialize<T>(Future<T> Function() operation) async {
    final previous = _pendingAwards;
    final completed = Completer<void>();
    _pendingAwards = completed.future;
    try {
      if (previous != null) await previous;
      return await operation();
    } finally {
      if (identical(_pendingAwards, completed.future)) _pendingAwards = null;
      completed.complete();
    }
  }

  /// Award a star to a child and check for badge/level progress
  static Future<RewardResult> addStar(
    String childId, {
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    return _serialize(
      () => _addStar(childId, description: description, metadata: metadata),
    );
  }

  static Future<RewardResult> _addStar(
    String childId, {
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final rewards = await getRewards(childId);
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('$_rewardsKeyPrefix$childId');
      final receiptIds = stored == null
          ? <String>{}
          : ((jsonDecode(stored) as Map<String, dynamic>)['rewardedEventIds']
                        as List? ??
                    [])
                .cast<String>()
                .toSet();
      final eventId = metadata?['eventId'] as String?;
      if (eventId != null && receiptIds.contains(eventId)) {
        return RewardResult(success: true, rewards: rewards);
      }
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
      final newSticker = newLevel != null
          ? _createStickerForLevel(newLevel)
          : null;

      // Update rewards
      final updatedRewards = rewards.copyWith(
        totalStars: newStars,
        totalBadges: rewards.totalBadges + (newBadge != null ? 1 : 0),
        totalStickers: rewards.totalStickers + (newSticker != null ? 1 : 0),
        currentLevel: newLevel ?? rewards.currentLevel,
        recentRewards: updatedRecentRewards,
        badges: [...rewards.badges, if (newBadge != null) newBadge],
        stickers: [...rewards.stickers, if (newSticker != null) newSticker],
        lastUpdated: DateTime.now(),
      );

      // One persisted document keeps stars, badges, stickers and event receipts together.
      if (eventId != null) receiptIds.add(eventId);
      await _saveRewards(childId, updatedRewards, receiptIds);

      return RewardResult(
        success: true,
        rewards: updatedRewards,
        newBadge: newBadge,
        newSticker: newSticker,
        levelUp: newLevel != null,
      );
    } catch (e) {
      debugLog('Error adding star: $e');
      return RewardResult(success: false, error: e.toString());
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
        final rewards = ChildRewards.fromJson(rewardsData);
        // Recover badges and stickers written separately by older releases.
        final legacyBadges = prefs.getString('$_badgesKeyPrefix$childId');
        final legacyStickers = prefs.getString('$_stickersKeyPrefix$childId');
        final badges = {for (final badge in rewards.badges) badge.id: badge};
        final stickers = {
          for (final sticker in rewards.stickers) sticker.id: sticker,
        };
        if (legacyBadges != null) {
          for (final json in jsonDecode(legacyBadges) as List) {
            final badge = Badge.fromJson(Map<String, dynamic>.from(json));
            badges[badge.id] = badge;
          }
        }
        if (legacyStickers != null) {
          for (final json in jsonDecode(legacyStickers) as List) {
            final sticker = Sticker.fromJson(Map<String, dynamic>.from(json));
            stickers[sticker.id] = sticker;
          }
        }
        return rewards.copyWith(
          badges: badges.values.toList(),
          stickers: stickers.values.toList(),
        );
      }

      // Return default rewards for new child
      return _getDefaultRewards(childId);
    } catch (e) {
      debugLog('Error getting rewards: $e');
      rethrow;
    }
  }

  /// Reset all rewards for a child
  static Future<void> resetRewards(String childId) async {
    await _serialize(() => _resetRewards(childId));
  }

  static Future<void> _resetRewards(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    for (final prefix in [
      _rewardsKeyPrefix,
      _badgesKeyPrefix,
      _stickersKeyPrefix,
    ]) {
      if (!await prefs.remove('$prefix$childId')) {
        throw StateError('Could not reset rewards for $childId.');
      }
    }
    debugLog('Rewards reset for child: $childId');
  }

  /// Get badges for a child
  static Future<List<Badge>> getBadges(String childId) async =>
      (await getRewards(childId)).badges;

  /// Get stickers for a child
  static Future<List<Sticker>> getStickers(String childId) async =>
      (await getRewards(childId)).stickers;

  /// Generate motivational message for a child
  static String generateMotivationalMessage(
    String childName,
    ChildRewards rewards,
  ) {
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
        description:
            'Earned $badgeNumber badges by collecting ${badgeNumber * _starsPerBadge} stars!',
        requiredStars: badgeNumber * _starsPerBadge,
        earnedAt: DateTime.now(),
      );
    }

    return null;
  }

  /// Check if child leveled up
  static ChildLevel? _checkForNewLevel(int newStars, ChildLevel currentLevel) {
    for (final level in ChildLevel.values.reversed) {
      if (newStars >= level.minStars &&
          currentLevel.minStars < level.minStars) {
        return level;
      }
    }
    return null;
  }

  /// Create sticker for level completion
  static Sticker _createStickerForLevel(ChildLevel level) {
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
  static Future<void> _saveRewards(
    String childId,
    ChildRewards rewards,
    Set<String> receiptIds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final saved = await prefs.setString(
        '$_rewardsKeyPrefix$childId',
        jsonEncode({
          ...rewards.toJson(),
          'rewardedEventIds': receiptIds.toList(),
        }),
      );
      if (!saved) throw StateError('Could not save rewards.');
    } catch (_) {
      await prefs.reload();
      rethrow;
    }
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
