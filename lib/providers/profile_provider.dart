import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/kid_profile.dart';
import '../services/adaptive_challenge_engine.dart';
import '../services/problem_attempt_service.dart';
import '../services/insights_engine.dart';
import '../services/rewards_service.dart';

class ProfileNotifier extends AsyncNotifier<KidProfile?> {
  @override
  Future<KidProfile?> build() async {
    return await _loadProfile();
  }

  static const String _profileKey = 'current_profile';

  Future<KidProfile?> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_profileKey);
      
      if (profileJson != null) {
        final profileData = jsonDecode(profileJson) as Map<String, dynamic>;
        final profile = KidProfile.fromJson(profileData);
        print('📱 Profile loaded: ${profile.name} (${profile.language})');
        return profile;
      } else {
        print('📱 No profile found');
        return null;
      }
    } catch (e) {
      print('❌ Error loading profile: $e');
      throw e;
    }
  }

  Future<void> createProfile(KidProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
      
      state = AsyncValue.data(profile);
      print('✅ Profile created: ${profile.name} (${profile.language})');
    } catch (e, stack) {
      print('❌ Error creating profile: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateProfile(KidProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
      
      state = AsyncValue.data(profile);
      print('📝 Profile updated: ${profile.name}');
    } catch (e, stack) {
      print('❌ Error updating profile: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateProgress(int stars, int problemsCompleted, double accuracy) async {
    final currentProfile = state.value;
    if (currentProfile != null) {
      final updatedProfile = currentProfile.copyWith(
        totalStars: currentProfile.totalStars + stars,
        totalProblemsCompleted: currentProfile.totalProblemsCompleted + problemsCompleted,
        overallAccuracy: accuracy,
        lastPlayed: DateTime.now(),
      );
      await updateProfile(updatedProfile);
    }
  }

  Future<void> resetProgress() async {
    final currentProfile = state.value;
    if (currentProfile != null) {
      try {
        // Reset all progress data while keeping profile information
        final resetProfile = currentProfile.copyWith(
          totalStars: 0,
          totalProblemsCompleted: 0,
          overallAccuracy: 0.0,
          lastPlayed: DateTime.now(),
        );
        
        // Clear all historical data using proper service methods
        
        // Clear problem attempts data
        await ProblemAttemptService.clearAllAttempts();
        
        // Clear adaptive challenge data
        await AdaptiveChallengeEngine.clearChildData(currentProfile.id);
        
        // Clear insights data
        await InsightsEngine.clearInsights(currentProfile.id);
        
        // Clear rewards data
        await RewardsService.resetRewards(currentProfile.id);
        
        // Update the profile with reset data
        await updateProfile(resetProfile);
        
        print('🔄 Progress reset for ${currentProfile.name} - all historical data cleared');
      } catch (e, stack) {
        print('❌ Error resetting progress: $e');
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> clearProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileKey);
      state = const AsyncValue.data(null);
      print('🧹 Profile cleared');
    } catch (e, stack) {
      print('❌ Error clearing profile: $e');
      state = AsyncValue.error(e, stack);
    }
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, KidProfile?>(() {
  return ProfileNotifier();
});
