import 'dart:math';
import '../models/problem_attempt.dart';

/// Enum for learning actions that the adaptive engine can recommend
enum LearningAction {
  advance,    // Move to harder problems
  maintain,   // Stay at current level
  remediate,  // Move to easier problems or review
  reviewMode  // Enter focused review of struggling concepts
}

/// Recommendation from the adaptive learning engine
class AdaptiveRecommendation {
  final int recommendedLevel;
  final LearningAction action;
  final String reasoning;
  final double accuracy;
  final double averageTime;
  final double hintRate;
  final bool shouldEnterReviewMode;
  final List<String> strugglingConcepts;

  const AdaptiveRecommendation({
    required this.recommendedLevel,
    required this.action,
    required this.reasoning,
    required this.accuracy,
    required this.averageTime,
    required this.hintRate,
    required this.shouldEnterReviewMode,
    required this.strugglingConcepts,
  });

  @override
  String toString() {
    return 'AdaptiveRecommendation(level: $recommendedLevel, action: $action, '
           'accuracy: ${(accuracy * 100).toStringAsFixed(1)}%, '
           'avgTime: ${averageTime.toStringAsFixed(1)}s, '
           'hintRate: ${(hintRate * 100).toStringAsFixed(1)}%)';
  }
}

/// Adaptive Learning Engine that analyzes performance and recommends next steps
class AdaptiveEngine {
  static const int _analysisWindowSize = 20; // Last 20 problems
  static const double _advanceAccuracyThreshold = 0.80; // 80%
  static const double _advanceTimeThreshold = 15.0; // 15 seconds
  static const double _maintainAccuracyMin = 0.60; // 60%
  static const double _maintainAccuracyMax = 0.79; // 79%
  static const double _remediateHintThreshold = 0.40; // 40% hint rate
  static const int _reviewModeErrorThreshold = 3; // 3 errors in same skill
  static const double _reviewModeSessionAccuracy = 0.60; // 60% session accuracy

  /// Analyzes recent performance and returns adaptive recommendation
  static AdaptiveRecommendation analyzePerformance({
    required List<ProblemAttempt> recentAttempts,
    required int currentLevel,
    String? currentSession,
  }) {
    // If no attempts, start at level 1
    if (recentAttempts.isEmpty) {
      return AdaptiveRecommendation(
        recommendedLevel: 1,
        action: LearningAction.maintain,
        reasoning: "Starting at beginner level",
        accuracy: 0.0,
        averageTime: 0.0,
        hintRate: 0.0,
        shouldEnterReviewMode: false,
        strugglingConcepts: [],
      );
    }

    // Get last 20 attempts for analysis window
    final analysisAttempts = recentAttempts.take(_analysisWindowSize).toList();
    
    // Calculate metrics
    final metrics = _calculateMetrics(analysisAttempts);
    
    // Check for review mode triggers
    final reviewAnalysis = _analyzeReviewModeNeeds(
      recentAttempts, 
      currentSession ?? '',
    );
    
    // Determine action and level recommendation
    final recommendation = _determineRecommendation(
      metrics: metrics,
      currentLevel: currentLevel,
      reviewAnalysis: reviewAnalysis,
    );

    return recommendation;
  }

  /// Calculate performance metrics from attempts
  static Map<String, double> _calculateMetrics(List<ProblemAttempt> attempts) {
    if (attempts.isEmpty) {
      return {
        'accuracy': 0.0,
        'averageTime': 0.0,
        'hintRate': 0.0,
        'averageScore': 0.0,
      };
    }

    // Calculate accuracy
    final correctCount = attempts.where((a) => a.isCorrect).length;
    final accuracy = correctCount / attempts.length;

    // Calculate average time
    final totalTime = attempts.fold<double>(0.0, (sum, a) => sum + a.timeSpentSeconds);
    final averageTime = totalTime / attempts.length;

    // Calculate hint usage rate
    final hintCount = attempts.where((a) => a.usedHint).length;
    final hintRate = hintCount / attempts.length;

    // Calculate average score (accuracy weighted by time efficiency)
    double averageScore = 0.0;
    if (accuracy > 0) {
      final timeEfficiency = min(1.0, 15.0 / max(averageTime, 1.0));
      averageScore = (accuracy * 0.7) + (timeEfficiency * 0.3);
    }

    return {
      'accuracy': accuracy,
      'averageTime': averageTime,
      'hintRate': hintRate,
      'averageScore': averageScore,
    };
  }

  /// Analyze if review mode should be triggered
  static Map<String, dynamic> _analyzeReviewModeNeeds(
    List<ProblemAttempt> allAttempts,
    String currentSession,
  ) {
    // Check for 3 errors in same skill type
    final skillErrors = <String, int>{};
    final strugglingConcepts = <String>[];
    
    for (final attempt in allAttempts.take(10)) { // Last 10 attempts
      if (!attempt.isCorrect) {
        final skill = _identifySkillFromProblem(attempt);
        skillErrors[skill] = (skillErrors[skill] ?? 0) + 1;
        
        if (skillErrors[skill]! >= _reviewModeErrorThreshold) {
          strugglingConcepts.add(skill);
        }
      }
    }

    // Check session accuracy if we have current session data
    double sessionAccuracy = 1.0;
    if (currentSession.isNotEmpty) {
      final sessionAttempts = allAttempts
          .where((a) => a.timestamp.toString().contains(currentSession))
          .toList();
      
      if (sessionAttempts.isNotEmpty) {
        final sessionCorrect = sessionAttempts.where((a) => a.isCorrect).length;
        sessionAccuracy = sessionCorrect / sessionAttempts.length;
      }
    }

    final shouldEnterReviewMode = strugglingConcepts.isNotEmpty || 
                                  sessionAccuracy < _reviewModeSessionAccuracy;

    return {
      'shouldEnterReviewMode': shouldEnterReviewMode,
      'strugglingConcepts': strugglingConcepts,
      'sessionAccuracy': sessionAccuracy,
    };
  }

  /// Identify skill type from problem attempt
  static String _identifySkillFromProblem(ProblemAttempt attempt) {
    // Analyze problem to identify skill type
    if (attempt.operand1 <= 10 && attempt.operand2 <= 10) {
      return 'single_digit_addition';
    } else if (attempt.operand1 > 10 || attempt.operand2 > 10) {
      if (attempt.operand1 + attempt.operand2 > 20) {
        return 'crossing_twenty';
      } else {
        return 'crossing_ten';
      }
    }
    return 'basic_addition';
  }

  /// Determine final recommendation based on all analysis
  static AdaptiveRecommendation _determineRecommendation({
    required Map<String, double> metrics,
    required int currentLevel,
    required Map<String, dynamic> reviewAnalysis,
  }) {
    final accuracy = metrics['accuracy']!;
    final averageTime = metrics['averageTime']!;
    final hintRate = metrics['hintRate']!;
    final averageScore = metrics['averageScore']!;
    final shouldEnterReviewMode = reviewAnalysis['shouldEnterReviewMode'] as bool;
    final strugglingConcepts = reviewAnalysis['strugglingConcepts'] as List<String>;

    // Priority 1: Review Mode
    if (shouldEnterReviewMode) {
      return AdaptiveRecommendation(
        recommendedLevel: max(1, currentLevel - 1),
        action: LearningAction.reviewMode,
        reasoning: "Review needed: ${strugglingConcepts.join(', ')} or low session accuracy",
        accuracy: accuracy,
        averageTime: averageTime,
        hintRate: hintRate,
        shouldEnterReviewMode: true,
        strugglingConcepts: strugglingConcepts,
      );
    }

    // Priority 2: Remediate
    if (accuracy < _maintainAccuracyMin || hintRate > _remediateHintThreshold) {
      return AdaptiveRecommendation(
        recommendedLevel: max(1, currentLevel - 1),
        action: LearningAction.remediate,
        reasoning: accuracy < _maintainAccuracyMin 
          ? "Low accuracy: ${(accuracy * 100).toStringAsFixed(1)}%"
          : "High hint usage: ${(hintRate * 100).toStringAsFixed(1)}%",
        accuracy: accuracy,
        averageTime: averageTime,
        hintRate: hintRate,
        shouldEnterReviewMode: false,
        strugglingConcepts: [],
      );
    }

    // Priority 3: Advance
    if (accuracy >= _advanceAccuracyThreshold && 
        averageScore >= 0.70 && 
        averageTime <= _advanceTimeThreshold) {
      return AdaptiveRecommendation(
        recommendedLevel: currentLevel + 1,
        action: LearningAction.advance,
        reasoning: "Excellent performance: ${(accuracy * 100).toStringAsFixed(1)}% accuracy, "
                  "${averageTime.toStringAsFixed(1)}s avg time",
        accuracy: accuracy,
        averageTime: averageTime,
        hintRate: hintRate,
        shouldEnterReviewMode: false,
        strugglingConcepts: [],
      );
    }

    // Priority 4: Maintain (default)
    return AdaptiveRecommendation(
      recommendedLevel: currentLevel,
      action: LearningAction.maintain,
      reasoning: "Steady progress: ${(accuracy * 100).toStringAsFixed(1)}% accuracy, "
                "continue at current level",
      accuracy: accuracy,
      averageTime: averageTime,
      hintRate: hintRate,
      shouldEnterReviewMode: false,
      strugglingConcepts: [],
    );
  }

  /// Generate a detailed progress report
  static Map<String, dynamic> generateProgressReport(List<ProblemAttempt> attempts) {
    if (attempts.isEmpty) {
      return {
        'totalAttempts': 0,
        'accuracy': 0.0,
        'averageTime': 0.0,
        'hintRate': 0.0,
        'improvementTrend': 'No data',
        'strengths': <String>[],
        'weaknesses': <String>[],
      };
    }

    final recentMetrics = _calculateMetrics(attempts.take(10).toList());
    final olderMetrics = attempts.length > 10 
        ? _calculateMetrics(attempts.skip(10).take(10).toList())
        : recentMetrics;

    // Calculate improvement trend
    final accuracyTrend = recentMetrics['accuracy']! - olderMetrics['accuracy']!;
    final timeTrend = olderMetrics['averageTime']! - recentMetrics['averageTime']!; // Positive = improvement
    
    String improvementTrend;
    if (accuracyTrend > 0.1 || timeTrend > 2.0) {
      improvementTrend = 'Improving';
    } else if (accuracyTrend < -0.1 || timeTrend < -2.0) {
      improvementTrend = 'Declining';
    } else {
      improvementTrend = 'Stable';
    }

    // Identify strengths and weaknesses
    final strengths = <String>[];
    final weaknesses = <String>[];

    if (recentMetrics['accuracy']! >= 0.8) {
      strengths.add('High accuracy');
    } else if (recentMetrics['accuracy']! < 0.6) {
      weaknesses.add('Low accuracy');
    }

    if (recentMetrics['averageTime']! <= 10.0) {
      strengths.add('Fast problem solving');
    } else if (recentMetrics['averageTime']! > 20.0) {
      weaknesses.add('Slow problem solving');
    }

    if (recentMetrics['hintRate']! <= 0.2) {
      strengths.add('Independent problem solving');
    } else if (recentMetrics['hintRate']! > 0.4) {
      weaknesses.add('High hint dependency');
    }

    return {
      'totalAttempts': attempts.length,
      'accuracy': recentMetrics['accuracy'],
      'averageTime': recentMetrics['averageTime'],
      'hintRate': recentMetrics['hintRate'],
      'improvementTrend': improvementTrend,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'accuracyTrend': accuracyTrend,
      'timeTrend': timeTrend,
    };
  }
}
