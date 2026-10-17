import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_log.dart';
import '../models/problem_attempt.dart';
import 'adaptive_engine.dart';

/// Service for managing problem attempts and performance analytics
class ProblemAttemptService {
  static const String _attemptsKey = 'problem_attempts';
  static const String _sessionKey = 'current_session';

  static Future<void>? _pendingWrite;

  static Future<void> _write(Future<void> Function() operation) {
    Future<void> run() async {
      try {
        await operation();
      } catch (_) {
        // SharedPreferences updates its cache before the platform confirms a
        // write. Restore disk-backed state before allowing a retry.
        await (await SharedPreferences.getInstance()).reload();
        rethrow;
      }
    }

    final previous = _pendingWrite;
    final next = previous == null
        ? Future<void>.sync(run)
        : previous.then(
            (_) => run(),
            onError: (Object _, StackTrace _) => run(),
          );
    late final Future<void> queued;
    queued = next.whenComplete(() {
      if (identical(_pendingWrite, queued)) _pendingWrite = null;
    });
    _pendingWrite = queued;
    return queued;
  }

  static void _requireSaved(bool saved) {
    if (!saved) throw StateError('Could not save problem attempts.');
  }

  /// Event identity prevents duplicate callbacks while allowing another
  /// challenge with the same operands or a successful retry after failure.
  static Future<void> recordAttempt(ProblemAttempt attempt) => _write(() async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = await getAllAttempts();
    final isDuplicate = attempts.any(
      (existing) =>
          existing.childId == attempt.childId &&
          existing.id == attempt.id &&
          existing.isCorrect == attempt.isCorrect,
    );
    if (isDuplicate) return;
    attempts.insert(0, attempt);
    final retainedPerChild = <String, int>{};
    final retained = attempts.where((attempt) {
      final count = retainedPerChild.update(
        attempt.childId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      return count <= 100;
    }).toList();
    _requireSaved(
      await prefs.setString(
        _attemptsKey,
        jsonEncode(retained.map((attempt) => attempt.toJson()).toList()),
      ),
    );
  });

  /// Get all stored problem attempts
  static Future<List<ProblemAttempt>> getAllAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final attemptsString = prefs.getString(_attemptsKey);

      if (attemptsString == null) return [];

      final List<dynamic> attemptsJson = jsonDecode(attemptsString);
      return attemptsJson.map((json) => ProblemAttempt.fromJson(json)).toList();
    } catch (e) {
      debugLog('❌ Error loading attempts: $e');
      rethrow;
    }
  }

  /// Get attempts for a specific child
  static Future<List<ProblemAttempt>> getAttemptsForChild(
    String childId,
  ) async {
    final allAttempts = await getAllAttempts();
    return allAttempts.where((attempt) => attempt.childId == childId).toList();
  }

  /// Get failed attempts (for failure transaction history)
  static Future<List<ProblemAttempt>> getFailedAttempts(String childId) async {
    final attempts = await getAttemptsForChild(childId);
    return attempts.where((attempt) => !attempt.isCorrect).toList();
  }

  /// Get unique failed attempts (removing duplicates by problem)
  static Future<List<ProblemAttempt>> getUniqueFailedAttempts(
    String childId,
  ) async {
    final attempts = await getAttemptsForChild(childId);
    final failedAttempts = attempts
        .where((attempt) => !attempt.isCorrect)
        .toList();

    // Group by problem text and keep only the most recent attempt for each problem
    final Map<String, ProblemAttempt> uniqueAttempts = {};

    for (final attempt in failedAttempts) {
      final problemKey =
          '${attempt.operand1}${attempt.operator}${attempt.operand2}';
      if (!uniqueAttempts.containsKey(problemKey) ||
          attempt.timestamp.isAfter(uniqueAttempts[problemKey]!.timestamp)) {
        uniqueAttempts[problemKey] = attempt;
      }
    }

    return uniqueAttempts.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Most recent first
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

      debugLog('🎯 Started new session for child: $childId at $sessionId');
    } catch (e) {
      debugLog('❌ Error starting session: $e');
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

      debugLog('🎯 Adaptive recommendation for $childId: $recommendation');
      return recommendation;
    } catch (e) {
      debugLog('❌ Error getting adaptive recommendation: $e');
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
  static Future<Map<String, dynamic>> generateProgressReport(
    String childId,
  ) async {
    try {
      final attempts = await getAttemptsForChild(childId);
      final report = AdaptiveEngine.generateProgressReport(attempts);

      // Add additional child-specific metrics
      report['childId'] = childId;
      report['lastActivity'] = attempts.isNotEmpty
          ? attempts.first.timestamp.toIso8601String()
          : null;
      report['totalSessions'] = _countUniqueSessions(attempts);
      report['averageSessionLength'] = _calculateAverageSessionLength(attempts);

      debugLog(
        '📈 Generated progress report for $childId: ${report['totalAttempts']} attempts',
      );
      return report;
    } catch (e) {
      debugLog('❌ Error generating progress report: $e');
      return {
        'childId': childId,
        'totalAttempts': 0,
        'accuracy': 0.0,
        'error': e.toString(),
      };
    }
  }

  /// Count unique learning sessions
  static int _countUniqueSessions(List<ProblemAttempt> attempts) {
    if (attempts.isEmpty) return 0;

    final sessions = <String>{};
    for (final attempt in attempts) {
      final sessionKey =
          '${attempt.timestamp.year}-${attempt.timestamp.month}-${attempt.timestamp.day}-${attempt.timestamp.hour}';
      sessions.add(sessionKey);
    }

    return sessions.length;
  }

  /// Calculate average session length in minutes
  static double _calculateAverageSessionLength(List<ProblemAttempt> attempts) {
    if (attempts.isEmpty) return 0.0;

    // Group attempts by session (same hour)
    final sessions = <String, List<ProblemAttempt>>{};
    for (final attempt in attempts) {
      final sessionKey =
          '${attempt.timestamp.year}-${attempt.timestamp.month}-${attempt.timestamp.day}-${attempt.timestamp.hour}';
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

        if (duration > 0 && duration < 120) {
          // Valid session: 0-120 minutes
          totalDuration += duration;
          validSessions++;
        }
      }
    }

    return validSessions > 0 ? totalDuration / validSessions : 0.0;
  }

  /// Reset only this child's history; other profiles retain their attempts.
  static Future<void> clearAttemptsForChild(String childId) => _write(() async {
    final prefs = await SharedPreferences.getInstance();
    final remaining = (await getAllAttempts())
        .where((attempt) => attempt.childId != childId)
        .toList();
    _requireSaved(
      await prefs.setString(
        _attemptsKey,
        jsonEncode(remaining.map((attempt) => attempt.toJson()).toList()),
      ),
    );
  });

  /// Clear all attempts for testing or an explicit device-wide reset.
  static Future<void> clearAllAttempts() => _write(() async {
    final prefs = await SharedPreferences.getInstance();
    _requireSaved(await prefs.remove(_attemptsKey));
    _requireSaved(await prefs.remove(_sessionKey));
  });

  /// Get performance summary for dashboard
  static Future<Map<String, dynamic>> getPerformanceSummary(
    String childId,
  ) async {
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

      final totalTime = recentAttempts.fold<double>(
        0.0,
        (sum, a) => sum + a.timeSpentSeconds,
      );
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
      debugLog('❌ Error getting performance summary: $e');
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
