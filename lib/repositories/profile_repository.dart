import 'dart:convert';
import '../models/kid_profile.dart';
import '../core/constants.dart';
import 'base_repository.dart';

/// Repository for managing user profiles
class ProfileRepository extends EntityRepository<KidProfile> {
  ProfileRepository() : super(AppConstants.profileStorageKey);

  @override
  String serialize(KidProfile item) {
    return jsonEncode(item.toJson());
  }

  @override
  KidProfile deserialize(String json) {
    return KidProfile.fromJson(jsonDecode(json));
  }

  /// Get the current active profile
  Future<KidProfile?> getCurrentProfile() async {
    final profiles = await loadList();
    try {
      return profiles.firstWhere((profile) => profile.isCurrent);
    } catch (e) {
      return profiles.isNotEmpty ? profiles.first : null;
    }
  }

  /// Set a profile as current
  Future<void> setCurrentProfile(String profileId) async {
    final profiles = await loadList();
    
    // Mark all profiles as not current
    for (var i = 0; i < profiles.length; i++) {
      profiles[i] = profiles[i].copyWith(isCurrent: false);
    }
    
    // Mark the selected profile as current
    final targetIndex = profiles.indexWhere((p) => p.id == profileId);
    if (targetIndex >= 0) {
      profiles[targetIndex] = profiles[targetIndex].copyWith(isCurrent: true);
      await saveList(profiles);
    }
  }

  /// Create a new profile and set it as current
  Future<void> createProfile(KidProfile profile) async {
    final profiles = await loadList();
    
    // Mark all existing profiles as not current
    for (var i = 0; i < profiles.length; i++) {
      profiles[i] = profiles[i].copyWith(isCurrent: false);
    }
    
    // Add new profile as current
    final newProfile = profile.copyWith(isCurrent: true);
    profiles.add(newProfile);
    
    await saveList(profiles);
  }

  /// Update profile data
  Future<bool> updateProfile(KidProfile profile) async {
    final profiles = await loadList();
    final index = profiles.indexWhere((p) => p.id == profile.id);
    
    if (index >= 0) {
      profiles[index] = profile.copyWith(lastPlayed: DateTime.now());
      await saveList(profiles);
      return true;
    }
    
    return false;
  }

  /// Update profile stats (stars, problems completed, etc.)
  Future<bool> updateProfileStats({
    required String profileId,
    int? additionalStars,
    int? additionalProblems,
    double? newAccuracy,
  }) async {
    final profiles = await loadList();
    final index = profiles.indexWhere((p) => p.id == profileId);
    
    if (index >= 0) {
      final profile = profiles[index];
      profiles[index] = profile.copyWith(
        totalStars: additionalStars != null 
            ? profile.totalStars + additionalStars 
            : profile.totalStars,
        totalProblemsCompleted: additionalProblems != null 
            ? profile.totalProblemsCompleted + additionalProblems 
            : profile.totalProblemsCompleted,
        lastPlayed: DateTime.now(),
      );
      
      await saveList(profiles);
      return true;
    }
    
    return false;
  }

  /// Get profiles by age range
  Future<List<KidProfile>> getProfilesByAgeRange(int minAge, int maxAge) async {
    final profiles = await loadList();
    return profiles.where((p) => p.age >= minAge && p.age <= maxAge).toList();
  }

  /// Get profiles by language
  Future<List<KidProfile>> getProfilesByLanguage(String language) async {
    final profiles = await loadList();
    return profiles.where((p) => p.language == language).toList();
  }

  /// Reset profile data (for reset functionality)
  Future<bool> resetProfileData(String profileId) async {
    final profiles = await loadList();
    final index = profiles.indexWhere((p) => p.id == profileId);
    
    if (index >= 0) {
      final profile = profiles[index];
      profiles[index] = profile.copyWith(
        totalStars: 0,
        totalProblemsCompleted: 0,
        lastPlayed: DateTime.now(),
      );
      
      await saveList(profiles);
      return true;
    }
    
    return false;
  }

  /// Get profile statistics
  Future<Map<String, dynamic>> getProfileStatistics() async {
    final profiles = await loadList();
    
    if (profiles.isEmpty) {
      return {
        'totalProfiles': 0,
        'averageAge': 0.0,
        'totalStars': 0,
        'totalProblems': 0,
        'languageDistribution': <String, int>{},
      };
    }

    final totalStars = profiles.fold<int>(0, (sum, p) => sum + p.totalStars);
    final totalProblems = profiles.fold<int>(0, (sum, p) => sum + p.totalProblemsCompleted);
    final averageAge = profiles.fold<int>(0, (sum, p) => sum + p.age) / profiles.length;
    
    final languageDistribution = <String, int>{};
    for (final profile in profiles) {
      languageDistribution[profile.language] = 
          (languageDistribution[profile.language] ?? 0) + 1;
    }

    return {
      'totalProfiles': profiles.length,
      'averageAge': averageAge,
      'totalStars': totalStars,
      'totalProblems': totalProblems,
      'languageDistribution': languageDistribution,
      'mostActiveProfile': profiles
          .reduce((a, b) => a.totalProblemsCompleted > b.totalProblemsCompleted ? a : b)
          .name,
    };
  }
}

