import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/problem_attempt.dart';
import 'adaptive_engine.dart';

/// Service for managing problem attempts and performance analytics
class ProblemAttemptService {
  static const String _attemptsKey = 'problem_attempts';
  static const String _sessionKey = 'current_session';

  /// Record a new problem attempt
  static Future<void> recordAttempt(ProblemAttempt attempt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final attempts = await getAllAttempts();
      
      // Add new attempt to the beginning (most recent first)
      attempts.insert(0, attempt);
      
      // Keep only last 100 attempts to prevent storage bloat
      final limitedAttempts = attempts.take(100).toList();
      
      // Save to storage
      final attemptsJson = limitedAttempts.map((a) => a.toJson()).toList();
      await prefs.setString(_attemptsKey, jsonEncode(attemptsJson));
      
      print('📊 Recorded attempt: ${attempt.problemText} = ${attempt.userAnswer} '
            '(${attempt.isCorrect ? "✓" : "✗"}) in ${attempt.timeSpentSeconds.toStringAsFixed(1)}s');
    } catch (e) {
      print('❌ Error recording attempt: $e');
    }
  }

  /// Get all stored problem attempts
  static Future<List<ProblemAttempt>> getAllAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final attemptsString = prefs.getString(_attemptsKey);
      
      if (attemptsString == null) return [];
      
      final List<dynamic> attemptsJson = jsonDecode(attemptsString);
      return attemptsJson.map((json) => ProblemAttempt.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error loading attempts: $e');
      return [];
    }
  }

  /// Get attempts for a specific child
  static Future<List<ProblemAttempt>> getAttemptsForChild(String childId) async {
    final allAttempts = await getAllAttempts();
    return allAttempts.where((attempt) => attempt.childId == childId).toList();
  }

  /// Get failed attempts (for failure transaction history)
  static Future<List<ProblemAttempt>> getFailedAttempts(String childId) async {
    final attempts = await getAttemptsForChild(childId);
    return attempts.where((attempt) => !attempt.isCorrect).toList();
  }

  /// Get attempts for current session
  static Future<List<ProblemAttempt>> getSessionAttempts(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString(_sessionKey) ?? '';
    
    if (sessionId.isEmpty) return [];
    
    final attempts = await getAttemptsForChild(childId);
    return attempts.where((attempt) {
      // Check if attempt is from current session (same day/hour)
      final attemptTime = attempt.timestamp;
      final sessionTime = DateTime.tryParse(sessionId);
      
      if (sessionTime == null) return false;
      
      return attemptTime.year == sessionTime.year &&
             attemptTime.month == sessionTime.month &&
             attemptTime.day == sessionTime.day &&
             attemptTime.hour == sessionTime.hour;
    }).toList();
  }

  /// Start a new learning session
  static Future<void> startSession(String childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = DateTime.now().toIso8601String();
      await prefs.setString(_sessionKey, sessionId);
      
      print('🎯 Started new session for child: $childId at $sessionId');
    } catch (e) {
      print('❌ Error starting session: $e');
    }
  }

  /// Get adaptive recommendation based on recent performance
  static Future<AdaptiveRecommendation> getAdaptiveRecommendation({
    required String childId,
    required int currentLevel,
  }) async {
    try {
      final attempts = await getAttemptsForChild(childId);
      final sessionAttempts = await getSessionAttempts(childId);
      
      final recommendation = AdaptiveEngine.analyzePerformance(
        recentAttempts: attempts,
        currentLevel: currentLevel,
        currentSession: sessionAttempts.isNotEmpty ? 'current' : null,
      );
      
      print('🎯 Adaptive recommendation for $childId: $recommendation');
      return recommendation;
    } catch (e) {
      print('❌ Error getting adaptive recommendation: $e');
      // Return safe default
      return AdaptiveRecommendation(
        recommendedLevel: currentLevel,
        action: LearningAction.maintain,
        reasoning: "Error in analysis, maintaining current level",
        accuracy: 0.0,
        averageTime: 0.0,
        hintRate: 0.0,
        shouldEnterReviewMode: false,
        strugglingConcepts: [],
      );
    }
  }

  /// Generate comprehensive progress report
  static Future<Map<String, dynamic>> generateProgressReport(String childId) async {
    try {
      final attempts = await getAttemptsForChild(childId);
      final report = AdaptiveEngine.generateProgressReport(attempts);
      
      // Add additional child-specific metrics
      report['childId'] = childId;
      report['lastActivity'] = attempts.isNotEmpty 
          ? attempts.first.timestamp.toIso8601String()
          : null;
      report['totalSessions'] = await _countUniqueSessions(attempts);
      report['averageSessionLength'] = await _calculateAverageSessionLength(attempts);
      
      print('📈 Generated progress report for $childId: ${report['totalAttempts']} attempts');
      return report;
    } catch (e) {
      print('❌ Error generating progress report: $e');
      return {
        'childId': childId,
        'totalAttempts': 0,
        'accuracy': 0.0,
        'error': e.toString(),
      };
    }
  }

  /// Count unique learning sessions
  static Future<int> _countUniqueSessions(List<ProblemAttempt> attempts) async {
    if (attempts.isEmpty) return 0;
    
    final sessions = <String>{};
    for (final attempt in attempts) {
      final sessionKey = '${attempt.timestamp.year}-${attempt.timestamp.month}-${attempt.timestamp.day}-${attempt.timestamp.hour}';
      sessions.add(sessionKey);
    }
    
    return sessions.length;
  }

  /// Calculate average session length in minutes
  static Future<double> _calculateAverageSessionLength(List<ProblemAttempt> attempts) async {
    if (attempts.isEmpty) return 0.0;
    
    // Group attempts by session (same hour)
    final sessions = <String, List<ProblemAttempt>>{};
    for (final attempt in attempts) {
      final sessionKey = '${attempt.timestamp.year}-${attempt.timestamp.month}-${attempt.timestamp.day}-${attempt.timestamp.hour}';
      sessions[sessionKey] = (sessions[sessionKey] ?? [])..add(attempt);
    }
    
    // Calculate duration for each session
    double totalDuration = 0.0;
    int validSessions = 0;
    
    for (final sessionAttempts in sessions.values) {
      if (sessionAttempts.length > 1) {
        sessionAttempts.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        final duration = sessionAttempts.last.timestamp
            .difference(sessionAttempts.first.timestamp)
            .inMinutes
            .toDouble();
        
        if (duration > 0 && duration < 120) { // Valid session: 0-120 minutes
          totalDuration += duration;
          validSessions++;
        }
      }
    }
    
    return validSessions > 0 ? totalDuration / validSessions : 0.0;
  }

  /// Clear all attempts (for testing or reset)
  static Future<void> clearAllAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_attemptsKey);
      await prefs.remove(_sessionKey);
      print('🗑️ Cleared all problem attempts');
    } catch (e) {
      print('❌ Error clearing attempts: $e');
    }
  }

  /// Get performance summary for dashboard
  static Future<Map<String, dynamic>> getPerformanceSummary(String childId) async {
    try {
      final attempts = await getAttemptsForChild(childId);
      final recentAttempts = attempts.take(20).toList();
      
      if (recentAttempts.isEmpty) {
        return {
          'totalProblems': 0,
          'accuracy': 0.0,
          'averageTime': 0.0,
          'streak': 0,
          'level': 1,
        };
      }
      
      final correctCount = recentAttempts.where((a) => a.isCorrect).length;
      final accuracy = correctCount / recentAttempts.length;
      
      final totalTime = recentAttempts.fold<double>(0.0, (sum, a) => sum + a.timeSpentSeconds);
      final averageTime = totalTime / recentAttempts.length;
      
      // Calculate current streak
      int streak = 0;
      for (final attempt in recentAttempts) {
        if (attempt.isCorrect) {
          streak++;
        } else {
          break;
        }
      }
      
      return {
        'totalProblems': attempts.length,
        'accuracy': accuracy,
        'averageTime': averageTime,
        'streak': streak,
        'recentCorrect': correctCount,
        'recentTotal': recentAttempts.length,
      };
    } catch (e) {
      print('❌ Error getting performance summary: $e');
      return {
        'totalProblems': 0,
        'accuracy': 0.0,
        'averageTime': 0.0,
        'streak': 0,
        'error': e.toString(),
      };
    }
  }
}
