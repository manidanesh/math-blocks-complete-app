import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_log.dart';
import '../models/kid_profile.dart';
import '../services/adaptive_challenge_engine.dart';
import '../services/insights_engine.dart';
import '../services/insight_delivery_service.dart';
import '../services/pending_completion_service.dart';
import '../services/problem_attempt_service.dart';
import '../services/rewards_service.dart';

/// Device-local calendar time, replaceable in year-rollover tests.
final profileNowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

class ProfileNotifier extends AsyncNotifier<KidProfile?> {
  late DateTime Function() _clock;

  @override
  Future<KidProfile?> build() {
    _clock = ref.read(profileNowProvider);
    return _loadProfile();
  }

  static const String _profileKey = 'current_profile';
  static const String _outcomeReceiptsKey = 'challengeOutcomeReceipts';
  Future<void>? _pendingMutation;

  /// Read each mutation's profile only after the previous save has finished.
  /// A rejected save must not stop subsequent updates from running.
  Future<void> _mutate(Future<void> Function() operation) {
    final previous = _pendingMutation;
    final next = previous == null
        ? Future<void>.sync(operation)
        : previous.then(
            (_) => operation(),
            onError: (Object _, StackTrace _) => operation(),
          );
    late final Future<void> queued;
    queued = next.whenComplete(() {
      if (identical(_pendingMutation, queued)) _pendingMutation = null;
    });
    _pendingMutation = queued;
    return queued;
  }

  Future<KidProfile?> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_profileKey);

      if (profileJson != null) {
        final profileData = jsonDecode(profileJson) as Map<String, dynamic>;
        final profile = KidProfile.fromJson(profileData, now: _clock);
        await _persistAgeSnapshot(profile);
        debugLog('📱 Profile loaded: ${profile.name} (${profile.language})');
        return profile;
      } else {
        debugLog('📱 No profile found');
        return null;
      }
    } catch (e) {
      debugLog('❌ Error loading profile: $e');
      // Keep unreadable saved data intact and expose a recoverable load error.
      rethrow;
    }
  }

  KidProfile _withCurrentClock(KidProfile profile) {
    final year = profile.birthYear;
    if (year != null && (year <= 0 || year > _clock().year)) {
      throw ArgumentError.value(
        year,
        'birthYear',
        'Must be a past or current year',
      );
    }
    return profile.copyWith(now: _clock);
  }

  /// Keep the compatibility age field current without replacing other data.
  Future<void> _persistAgeSnapshot(KidProfile profile) async {
    if (!profile.hasBirthYear) return;
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_profileKey);
      if (stored == null) return;
      final data = jsonDecode(stored) as Map<String, dynamic>;
      if (data['id'] != profile.id || data['birthYear'] != profile.birthYear) {
        return;
      }
      final age = profile.age;
      if (data['age'] == age) return;
      final saved = await prefs.setString(
        _profileKey,
        jsonEncode({...data, 'age': age}),
      );
      if (!saved) throw StateError('Could not refresh the saved age.');
    } catch (error) {
      // A failed compatibility write must not hide a readable profile.
      // Reload the cache so another refresh can retry the rejected snapshot.
      try {
        await prefs?.reload();
      } catch (reloadError) {
        debugLog(
          'Could not reload preferences after an age refresh: $reloadError',
        );
      }
      debugLog('Could not refresh saved age: $error');
    }
  }

  /// Notify age displays when the app resumes or crosses a calendar day.
  Future<void> refreshAge() => _mutate(() async {
    if (!ref.mounted) return;
    final profile = state.value;
    if (profile == null || !profile.hasBirthYear) return;
    final refreshed = profile.copyWith(now: _clock);
    state = AsyncValue.data(refreshed);
    await _persistAgeSnapshot(refreshed);
  });

  Future<void> createProfile(KidProfile profile) => _mutate(() async {
    try {
      final currentProfile = await _persistProfile(
        profile,
        clearOutcomeReceipts: true,
      );
      if (ref.mounted) state = AsyncValue.data(currentProfile);
      debugLog('✅ Profile created: ${profile.name} (${profile.language})');
    } catch (e) {
      debugLog('❌ Error creating profile: $e');
      rethrow;
    }
  });

  Future<void> updateProfile(KidProfile profile) {
    final original = state.value;
    return _mutate(() async {
      try {
        final latest = state.value;
        final updated = _mergeQueuedEdit(profile, original, latest);
        final currentProfile = await _persistProfile(updated);
        if (ref.mounted) state = AsyncValue.data(currentProfile);
        debugLog('📝 Profile updated: ${profile.name}');
      } catch (e) {
        debugLog('❌ Error updating profile: $e');
        rethrow;
      }
    });
  }

  /// Preserve unrelated fields committed while this edit waited in the queue.
  KidProfile _mergeQueuedEdit(
    KidProfile requested,
    KidProfile? original,
    KidProfile? latest,
  ) {
    if (latest == null || latest.id != requested.id) {
      throw StateError(
        'The current profile changed before the edit was saved.',
      );
    }
    if (original == null || original.id != requested.id) return requested;
    return requested.copyWith(
      name: requested.name == original.name ? latest.name : requested.name,
      age: requested.age == original.age ? latest.age : requested.age,
      birthYear: requested.birthYear == original.birthYear
          ? latest.birthYear
          : requested.birthYear,
      avatarId: requested.avatarId == original.avatarId
          ? latest.avatarId
          : requested.avatarId,
      language: requested.language == original.language
          ? latest.language
          : requested.language,
      isCurrent: requested.isCurrent == original.isCurrent
          ? latest.isCurrent
          : requested.isCurrent,
      createdAt: requested.createdAt == original.createdAt
          ? latest.createdAt
          : requested.createdAt,
      lastPlayed: requested.lastPlayed == original.lastPlayed
          ? latest.lastPlayed
          : requested.lastPlayed,
      totalStars: requested.totalStars == original.totalStars
          ? latest.totalStars
          : requested.totalStars,
      totalProblemsCompleted:
          requested.totalProblemsCompleted == original.totalProblemsCompleted
          ? latest.totalProblemsCompleted
          : requested.totalProblemsCompleted,
      overallAccuracy: requested.overallAccuracy == original.overallAccuracy
          ? latest.overallAccuracy
          : requested.overallAccuracy,
      favoriteNumbers:
          listEquals(requested.favoriteNumbers, original.favoriteNumbers)
          ? latest.favoriteNumbers
          : requested.favoriteNumbers,
      preferredOperation:
          requested.preferredOperation == original.preferredOperation
          ? latest.preferredOperation
          : requested.preferredOperation,
    );
  }

  Future<KidProfile> _persistProfile(
    KidProfile profile, {
    Set<String>? outcomeReceipts,
    bool clearOutcomeReceipts = false,
  }) async {
    final currentProfile = _withCurrentClock(profile);
    final prefs = await SharedPreferences.getInstance();
    try {
      final receipts = clearOutcomeReceipts
          ? <String>{}
          : outcomeReceipts ?? _outcomeReceipts(prefs, currentProfile.id);
      final saved = await prefs.setString(
        _profileKey,
        jsonEncode({
          ...currentProfile.toJson(),
          if (receipts.isNotEmpty) _outcomeReceiptsKey: receipts.toList(),
        }),
      );
      if (!saved) throw StateError('Could not save the profile.');
    } catch (_) {
      // SharedPreferences changes its memory cache before the platform write.
      // Restore that cache so a failed edit cannot appear saved on reopening.
      try {
        await prefs.reload();
      } catch (error) {
        debugLog('Could not reload preferences after a failed save: $error');
      }
      rethrow;
    }
    return currentProfile;
  }

  Set<String> _outcomeReceipts(SharedPreferences prefs, String childId) {
    final stored = prefs.getString(_profileKey);
    if (stored == null) return {};
    final data = jsonDecode(stored) as Map<String, dynamic>;
    if (data['id'] != childId) return {};
    return (data[_outcomeReceiptsKey] as List<dynamic>? ?? const [])
        .cast<String>()
        .toSet();
  }

  Future<void> updateProgress(
    int stars,
    int problemsCompleted,
    double accuracy,
  ) => _mutate(() async {
    final currentProfile = state.value;
    if (currentProfile != null) {
      final updatedProfile = currentProfile.copyWith(
        totalStars: currentProfile.totalStars + stars,
        totalProblemsCompleted:
            currentProfile.totalProblemsCompleted + problemsCompleted,
        overallAccuracy: accuracy,
        lastPlayed: _clock(),
      );
      final saved = await _persistProfile(updatedProfile);
      if (ref.mounted) state = AsyncValue.data(saved);
    }
  });

  /// Lifetime statistics are updated at completion, independent of capped history.
  Future<void> recordChallengeOutcome({
    required String childId,
    required bool correct,
    int stars = 0,
    String? eventId,
  }) => _mutate(() async {
    final profile = state.value;
    if (profile == null || profile.id != childId) return;
    final prefs = await SharedPreferences.getInstance();
    final receipts = _outcomeReceipts(prefs, childId);
    if (eventId != null && !receipts.add(eventId)) return;
    final total = profile.totalProblemsCompleted + 1;
    final previousCorrect =
        profile.overallAccuracy.clamp(0.0, 1.0) *
        profile.totalProblemsCompleted;
    final saved = await _persistProfile(
      profile.copyWith(
        totalProblemsCompleted: total,
        totalStars: profile.totalStars + stars,
        overallAccuracy: (previousCorrect + (correct ? 1 : 0)) / total,
        lastPlayed: _clock(),
      ),
      outcomeReceipts: receipts,
    );
    if (ref.mounted) state = AsyncValue.data(saved);
  });

  Future<void> resetProgress() {
    final childId = state.value?.id;
    if (childId == null) {
      return Future<void>.error(StateError('No profile to reset.'));
    }
    // Acquire the completion/reset lock before joining the profile queue: an
    // active completion may itself need that queue to finish its outcome save.
    return PendingCompletionService.runReset(
      childId,
      () => _mutate(() => _resetProgress(childId)),
    );
  }

  Future<void> _resetProgress(String expectedChildId) async {
    final currentProfile = state.value;
    if (currentProfile == null || currentProfile.id != expectedChildId) {
      throw StateError(
        'The current profile changed before progress was reset.',
      );
    }
    final prefs = await SharedPreferences.getInstance();
    final snapshot = <String, Object>{
      for (final key in prefs.getKeys())
        if (_isResetPreference(key, currentProfile.id)) key: prefs.get(key)!,
    };
    try {
      // Reset all progress data while keeping profile information
      final resetProfile = currentProfile.copyWith(
        totalStars: 0,
        totalProblemsCompleted: 0,
        overallAccuracy: 0.0,
        lastPlayed: _clock(),
      );

      // Verify profile persistence before deleting any historical data.
      final savedProfile = await _persistProfile(
        resetProfile,
        clearOutcomeReceipts: true,
      );

      await PendingCompletionService.clear(currentProfile.id);

      // Clear problem attempts data
      await ProblemAttemptService.clearAttemptsForChild(currentProfile.id);

      // Clear adaptive challenge data
      await AdaptiveChallengeEngine.clearChildData(currentProfile.id);

      // Clear insights data
      await InsightDeliveryService.clear(currentProfile.id);
      await InsightsEngine.clearInsights(currentProfile.id);

      // Clear rewards data
      await RewardsService.resetRewards(currentProfile.id);

      if (ref.mounted) state = AsyncValue.data(savedProfile);

      debugLog(
        '🔄 Progress reset for ${currentProfile.name} - all historical data cleared',
      );
    } catch (e) {
      debugLog('❌ Error resetting progress: $e');
      try {
        await _restoreResetPreferences(prefs, currentProfile.id, snapshot);
      } catch (rollbackError) {
        debugLog('Could not restore a failed reset: $rollbackError');
      }
      rethrow;
    }
  }

  bool _isResetPreference(String key, String childId) =>
      key == _profileKey ||
      key == 'problem_attempts' ||
      key == 'insights_problem_logs' ||
      key == 'current_session' ||
      key.endsWith('_$childId');

  Future<void> _restoreResetPreferences(
    SharedPreferences prefs,
    String childId,
    Map<String, Object> snapshot,
  ) async {
    final keys = {
      ...snapshot.keys,
      ...prefs.getKeys().where((key) => _isResetPreference(key, childId)),
    };
    for (final key in keys) {
      final value = snapshot[key];
      final restored = switch (value) {
        null => await prefs.remove(key),
        String value => await prefs.setString(key, value),
        int value => await prefs.setInt(key, value),
        double value => await prefs.setDouble(key, value),
        bool value => await prefs.setBool(key, value),
        List value => await prefs.setStringList(key, value.cast<String>()),
        _ => throw StateError('Unsupported saved preference: $key'),
      };
      if (!restored) throw StateError('Could not restore preference: $key');
    }
    await prefs.reload();
  }

  Future<void> clearProfile() => _mutate(() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final cleared = await prefs.remove(_profileKey);
      if (!cleared) {
        await prefs.reload();
        throw StateError('Could not clear the profile.');
      }
      if (ref.mounted) state = const AsyncValue.data(null);
      debugLog('🧹 Profile cleared');
    } catch (e) {
      debugLog('❌ Error clearing profile: $e');
      try {
        await prefs.reload();
      } catch (reloadError) {
        debugLog(
          'Could not reload preferences after a failed clear: $reloadError',
        );
      }
      rethrow;
    }
  });
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, KidProfile?>(
  ProfileNotifier.new,
  // Device-local read/parse failures need explicit recovery, not timed retries.
  retry: (_, _) => null,
);
