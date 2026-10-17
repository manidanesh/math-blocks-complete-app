import 'dart:math';

import '../core/app_log.dart';
import '../models/adaptive_challenge.dart';
import '../models/problem_attempt.dart';
import 'adaptive_challenge_engine.dart';
import 'insights_engine.dart';
import 'problem_attempt_service.dart';
import 'problem_generator.dart';

/// Service that integrates the Adaptive Challenge Engine with the existing problem system
class AdaptiveProblemService {
  /// Record a problem attempt and store it in the adaptive system
  static Future<void> recordAttempt({
    required String childId,
    required String problemId,
    required String problemText,
    required int level,
    required bool correct,
    required double timeTaken,
    required bool bondCorrect,
    required int operand1,
    required int operand2,
    required String operator,
    required int correctAnswer,
    int attemptNumber = 1,
    bool usedHint = false,
    String? strategy,
    String? hintType,
    String? explanation,
    bool isReviewProblem = false,
  }) async {
    // Create problem result for adaptive engine
    final problemResult = ProblemResult(
      problemId: problemId,
      level: level,
      correct: correct,
      timeTaken: timeTaken,
      bondCorrect: bondCorrect,
      timestamp: DateTime.now(),
      problemText: problemText,
      childId: childId,
      isReviewProblem: isReviewProblem,
    );

    // Store in adaptive engine
    await AdaptiveChallengeEngine.storeProblemResult(problemResult);

    // Also create a ProblemAttempt for the existing system
    final attempt = ProblemAttempt(
      id: problemId,
      childId: childId,
      problemText: problemText,
      operand1: operand1,
      operand2: operand2,
      operator: operator,
      correctAnswer: correctAnswer,
      userAnswer: correct ? correctAnswer : null,
      isCorrect: correct,
      timestamp: DateTime.now(),
      attemptNumber: attemptNumber,
      timeSpentSeconds: timeTaken,
      strategy: strategy ?? _getStrategyForLevel(level).name,
      difficultyLevel: level,
      skillArea: 'adaptive_level_$level',
      usedHint: usedHint,
      hintType: hintType,
      explanation: explanation,
    );

    // Store in existing problem attempt service
    await ProblemAttemptService.recordAttempt(attempt);

    // Insights are secondary analytics. A failure here must not make the
    // already persisted terminal event look unrecorded to the challenge UI.
    try {
      await InsightsEngine.logProblem(
        childId: childId,
        eventId: '$problemId:$correct',
        problemType: operator == '-' ? 'subtraction' : 'addition',
        numbersUsed: [operand1, operand2],
        correct: correct,
        timeTaken: timeTaken,
        hintUsed: usedHint,
        level: 'Level $level',
        strategy: attempt.strategy,
      );
    } catch (error) {
      debugLog('Could not update learning insights: $error');
    }
  }

  /// Get the next adaptive challenge
  static Future<AdaptiveChallenge> getNextChallenge(
    String childId,
    String childName, {
    List<int> favoriteNumbers = const [],
    String preferredOperation = 'both',
  }) async {
    return await AdaptiveChallengeEngine.getNextProblem(
      childId,
      childName,
      favoriteNumbers: favoriteNumbers,
      preferredOperation: preferredOperation,
    );
  }

  /// Convert AdaptiveChallenge to MathProblem format for existing widgets
  static MathProblem convertToMathProblem(AdaptiveChallenge challenge) {
    return MathProblem(
      operand1: challenge.operand1,
      operand2: challenge.operand2,
      operator: challenge.operator,
      correctAnswer: challenge.correctAnswer,
      problemText: challenge.problemText,
      options: _generateOptions(challenge.correctAnswer),
      strategy: _getBestStrategyForProblem(challenge),
      level: challenge.level,
      explanation: challenge.isReviewProblem
          ? 'This is a review problem to help you practice this concept.'
          : 'Solve this problem using the number bond strategy.',
    );
  }

  /// Get performance metrics for a child
  static Future<PerformanceMetrics> getPerformanceMetrics(
    String childId,
  ) async {
    return await AdaptiveChallengeEngine.calculatePerformanceMetrics(childId);
  }

  /// Check if we should show motivational feedback
  static Future<String?> getMotivationalFeedback(
    String childId,
    String childName,
  ) async {
    return await AdaptiveChallengeEngine.getMotivationalFeedback(
      childId,
      childName,
    );
  }

  /// Clear all adaptive data for a child
  static Future<void> clearChildData(String childId) async {
    await AdaptiveChallengeEngine.clearChildData(childId);
  }

  /// Get the best strategy for a specific problem based on its numbers
  static ProblemStrategy _getBestStrategyForProblem(
    AdaptiveChallenge challenge,
  ) {
    final operand1 = challenge.operand1;
    final operand2 = challenge.operand2;
    final isSubtraction = challenge.operator == '-';

    if (isSubtraction) {
      final onesDigit = operand1 % 10;
      final result = operand1 - operand2;

      // For valid crossing subtraction:
      // 1. operand2 must be > onesDigit (to force crossing)
      // 2. result must be positive
      // 3. operand1 must be > 10 (multi-digit)
      if (operand2 > onesDigit && result > 0 && operand1 > 10) {
        return ProblemStrategy.crossing;
      } else {
        return ProblemStrategy
            .basic; // Subtraction such as 19 - 7 that does not cross ten.
      }
    } else {
      // Addition - following the new rules
      final onesDigit = operand1 % 10;
      final need = 10 - onesDigit; // Amount needed to reach next 10

      // For valid crossing addition: operand2 must be > need (and != need)
      // This allows us to split operand2 into (need + remainder)
      // Example: 45 + 12 → split 12 into 5 + 7 → 45 + 5 = 50, then 50 + 7 = 57
      if (operand2 > need) {
        return ProblemStrategy.crossing;
      } else {
        return ProblemStrategy
            .basic; // Simple addition like 45 + 4 (invalid for crossing)
      }
    }
  }

  /// Get strategy enum for level and problem type
  static ProblemStrategy _getStrategyForLevel(int level) {
    // Fallback strategy by level
    switch (level) {
      case 1:
        return ProblemStrategy.basic;
      case 2:
        return ProblemStrategy.makeTen;
      case 3:
      case 4:
        return ProblemStrategy.crossing;
      default:
        return ProblemStrategy.basic;
    }
  }

  /// Generate options for the problem
  static List<int> _generateOptions(int correctAnswer) {
    final options = <int>[];
    final random = Random();

    // Add correct answer
    options.add(correctAnswer);

    // Add some wrong options
    while (options.length < 4) {
      final wrongAnswer = correctAnswer + random.nextInt(20) - 10;
      if (wrongAnswer != correctAnswer &&
          !options.contains(wrongAnswer) &&
          wrongAnswer > 0) {
        options.add(wrongAnswer);
      }
    }

    // Shuffle options
    options.shuffle();
    return options;
  }
}
