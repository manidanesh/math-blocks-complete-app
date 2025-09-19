import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/insights.dart';

/// Service for analyzing learning patterns and generating insights
class InsightsEngine {
  static const String _logsKey = 'insights_problem_logs';
  static const String _insightsKey = 'insights_generated';
  static const String _analysisKey = 'insights_analysis';
  static const int _analysisInterval = 20; // Analyze every 20 problems

  /// Log a problem attempt for insights analysis
  static Future<void> logProblem({
    required String childId,
    required String problemType,
    required List<int> numbersUsed,
    required bool correct,
    required int timeTaken,
    required bool hintUsed,
    required String level,
    required String strategy,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Create problem log
    final problemLog = ProblemLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      childId: childId,
      problemType: problemType,
      numbersUsed: numbersUsed,
      correct: correct,
      timeTaken: timeTaken,
      hintUsed: hintUsed,
      timestamp: DateTime.now(),
      level: level,
      strategy: strategy,
    );

    // Get existing logs
    final logsJson = prefs.getStringList(_logsKey) ?? [];
    final logs = logsJson
        .map((json) => ProblemLog.fromJson(jsonDecode(json)))
        .toList();

    // Add new log
    logs.add(problemLog);

    // Keep only recent logs (last 100 per child)
    final childLogs = logs.where((log) => log.childId == childId).toList();
    if (childLogs.length > 100) {
      childLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final recentLogs = childLogs.take(100).toList();
      logs.removeWhere((log) => log.childId == childId);
      logs.addAll(recentLogs);
    }

    // Save back to storage
    final updatedLogsJson = logs.map((log) => jsonEncode(log.toJson())).toList();
    await prefs.setStringList(_logsKey, updatedLogsJson);

    // Check if we should analyze (every 20 problems)
    final childRecentLogs = logs
        .where((log) => log.childId == childId)
        .where((log) => log.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .toList();

    if (childRecentLogs.length % _analysisInterval == 0 && childRecentLogs.length > 0) {
      await _analyzeAndGenerateInsights(childId, childRecentLogs);
    }
  }

  /// Analyze problem logs and generate insights
  static Future<void> _analyzeAndGenerateInsights(String childId, List<ProblemLog> logs) async {
    final analysis = _performAnalysis(childId, logs);
    final insights = _generateInsights(analysis);
    
    // Save analysis and insights
    await _saveAnalysis(analysis);
    await _saveInsights(childId, insights);
  }

  /// Perform statistical analysis on problem logs
  static InsightsAnalysis _performAnalysis(String childId, List<ProblemLog> logs) {
    if (logs.isEmpty) {
      return InsightsAnalysis(
        childId: childId,
        analyzedAt: DateTime.now(),
        totalProblems: 0,
        overallAccuracy: 0.0,
        averageTime: 0.0,
        patterns: [],
        insights: [],
        problemTypeAccuracy: {},
        strategyAccuracy: {},
        numberRangeAccuracy: {},
      );
    }

    // Calculate overall metrics
    final totalProblems = logs.length;
    final correctProblems = logs.where((log) => log.correct).length;
    final overallAccuracy = correctProblems / totalProblems;
    final averageTime = logs.map((log) => log.timeTaken).reduce((a, b) => a + b) / totalProblems;

    // Analyze by problem type
    final problemTypeAccuracy = <String, double>{};
    final problemTypes = logs.map((log) => log.problemType).toSet();
    for (final type in problemTypes) {
      final typeLogs = logs.where((log) => log.problemType == type).toList();
      final correctCount = typeLogs.where((log) => log.correct).length;
      problemTypeAccuracy[type] = correctCount / typeLogs.length;
    }

    // Analyze by strategy
    final strategyAccuracy = <String, double>{};
    final strategies = logs.map((log) => log.strategy).toSet();
    for (final strategy in strategies) {
      final strategyLogs = logs.where((log) => log.strategy == strategy).toList();
      final correctCount = strategyLogs.where((log) => log.correct).length;
      strategyAccuracy[strategy] = correctCount / strategyLogs.length;
    }

    // Analyze by number range
    final numberRangeAccuracy = <String, double>{};
    final singleDigitLogs = logs.where((log) => 
        log.numbersUsed.every((num) => num <= 9)).toList();
    final twoDigitLogs = logs.where((log) => 
        log.numbersUsed.any((num) => num >= 10 && num <= 99)).toList();
    final threeDigitLogs = logs.where((log) => 
        log.numbersUsed.any((num) => num >= 100)).toList();

    if (singleDigitLogs.isNotEmpty) {
      final correctCount = singleDigitLogs.where((log) => log.correct).length;
      numberRangeAccuracy['single_digit'] = correctCount / singleDigitLogs.length;
    }
    if (twoDigitLogs.isNotEmpty) {
      final correctCount = twoDigitLogs.where((log) => log.correct).length;
      numberRangeAccuracy['two_digit'] = correctCount / twoDigitLogs.length;
    }
    if (threeDigitLogs.isNotEmpty) {
      final correctCount = threeDigitLogs.where((log) => log.correct).length;
      numberRangeAccuracy['three_digit'] = correctCount / threeDigitLogs.length;
    }

    // Detect learning patterns
    final patterns = _detectPatterns(logs, problemTypeAccuracy, strategyAccuracy, numberRangeAccuracy);

    return InsightsAnalysis(
      childId: childId,
      analyzedAt: DateTime.now(),
      totalProblems: totalProblems,
      overallAccuracy: overallAccuracy,
      averageTime: averageTime,
      patterns: patterns,
      insights: [], // Will be populated by _generateInsights
      problemTypeAccuracy: problemTypeAccuracy,
      strategyAccuracy: strategyAccuracy,
      numberRangeAccuracy: numberRangeAccuracy,
    );
  }

  /// Detect learning patterns from the analysis
  static List<LearningPattern> _detectPatterns(
    List<ProblemLog> logs,
    Map<String, double> problemTypeAccuracy,
    Map<String, double> strategyAccuracy,
    Map<String, double> numberRangeAccuracy,
  ) {
    final patterns = <LearningPattern>[];

    // Detect strengths (≥85% accuracy, avg time ≤15s)
    for (final entry in problemTypeAccuracy.entries) {
      if (entry.value >= 0.85) {
        final typeLogs = logs.where((log) => log.problemType == entry.key).toList();
        final avgTime = typeLogs.map((log) => log.timeTaken).reduce((a, b) => a + b) / typeLogs.length;
        
        if (avgTime <= 15) {
          patterns.add(LearningPattern(
            patternType: 'strength',
            category: 'problem_type',
            description: 'Excellent performance with ${entry.key} problems',
            confidence: entry.value,
            metadata: {
              'accuracy': entry.value,
              'averageTime': avgTime,
              'problemCount': typeLogs.length,
              'problemType': entry.key,
            },
          ));
        }
      }
    }

    // Detect weaknesses (≤60% accuracy, frequent hints, or slow responses)
    for (final entry in problemTypeAccuracy.entries) {
      if (entry.value <= 0.60) {
        final typeLogs = logs.where((log) => log.problemType == entry.key).toList();
        final hintUsage = typeLogs.where((log) => log.hintUsed).length / typeLogs.length;
        final avgTime = typeLogs.map((log) => log.timeTaken).reduce((a, b) => a + b) / typeLogs.length;

        patterns.add(LearningPattern(
          patternType: 'weakness',
          category: 'problem_type',
          description: 'Struggling with ${entry.key} problems',
          confidence: 1.0 - entry.value,
          metadata: {
            'accuracy': entry.value,
            'hintUsage': hintUsage,
            'averageTime': avgTime,
            'problemCount': typeLogs.length,
            'problemType': entry.key,
          },
        ));
      }
    }

    // Detect strategy-specific patterns
    for (final entry in strategyAccuracy.entries) {
      if (entry.value >= 0.90) {
        patterns.add(LearningPattern(
          patternType: 'strength',
          category: 'strategy',
          description: 'Mastered ${entry.key} strategy',
          confidence: entry.value,
          metadata: {
            'accuracy': entry.value,
            'strategy': entry.key,
          },
        ));
      } else if (entry.value <= 0.60) {
        patterns.add(LearningPattern(
          patternType: 'weakness',
          category: 'strategy',
          description: 'Needs practice with ${entry.key} strategy',
          confidence: 1.0 - entry.value,
          metadata: {
            'accuracy': entry.value,
            'strategy': entry.key,
          },
        ));
      }
    }

    // Detect number range patterns
    for (final entry in numberRangeAccuracy.entries) {
      if (entry.value >= 0.85) {
        patterns.add(LearningPattern(
          patternType: 'strength',
          category: 'number_range',
          description: 'Strong with ${entry.key.replaceAll('_', ' ')} numbers',
          confidence: entry.value,
          metadata: {
            'accuracy': entry.value,
            'numberRange': entry.key,
          },
        ));
      } else if (entry.value <= 0.60) {
        patterns.add(LearningPattern(
          patternType: 'weakness',
          category: 'number_range',
          description: 'Needs practice with ${entry.key.replaceAll('_', ' ')} numbers',
          confidence: 1.0 - entry.value,
          metadata: {
            'accuracy': entry.value,
            'numberRange': entry.key,
          },
        ));
      }
    }

    return patterns;
  }

  /// Generate actionable insights from patterns
  static List<Insight> _generateInsights(InsightsAnalysis analysis) {
    final insights = <Insight>[];

    // Generate strength insights
    final strengthPatterns = analysis.patterns.where((p) => p.patternType == 'strength').toList();
    for (final pattern in strengthPatterns) {
      final insight = _createStrengthInsight(analysis.childId, pattern);
      if (insight != null) insights.add(insight);
    }

    // Generate weakness insights
    final weaknessPatterns = analysis.patterns.where((p) => p.patternType == 'weakness').toList();
    for (final pattern in weaknessPatterns) {
      final insight = _createWeaknessInsight(analysis.childId, pattern);
      if (insight != null) insights.add(insight);
    }

    // Generate overall performance insight
    if (analysis.overallAccuracy >= 0.80) {
      insights.add(Insight(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        childId: analysis.childId,
        type: 'strength',
        title: 'Excellent Progress! 🌟',
        message: 'You\'re doing great! Your overall accuracy is ${(analysis.overallAccuracy * 100).toStringAsFixed(0)}%. Keep up the amazing work!',
        actionableSteps: [
          'Continue practicing to maintain your skills',
          'Try more challenging problems',
          'Help others learn what you know well',
        ],
        priority: 'medium',
        generatedAt: DateTime.now(),
        relatedPatterns: [],
        correctiveActions: {
          'suggestHigherLevel': true,
          'encouragePeerTeaching': true,
        },
      ));
    } else if (analysis.overallAccuracy <= 0.60) {
      insights.add(Insight(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        childId: analysis.childId,
        type: 'weakness',
        title: 'Let\'s Practice Together! 💪',
        message: 'Don\'t worry! Math takes practice. Let\'s work on the areas that need more attention.',
        actionableSteps: [
          'Focus on the problem types that are challenging',
          'Take your time - there\'s no rush',
          'Ask for hints when you need them',
        ],
        priority: 'high',
        generatedAt: DateTime.now(),
        relatedPatterns: weaknessPatterns,
        correctiveActions: {
          'triggerReviewMode': true,
          'injectWeakProblems': true,
          'adjustDifficulty': 'lower',
        },
      ));
    }

    return insights;
  }

  /// Create a strength insight from a pattern
  static Insight? _createStrengthInsight(String childId, LearningPattern pattern) {
    switch (pattern.category) {
      case 'problem_type':
        final problemType = pattern.metadata['problemType'] as String;
        final accuracy = pattern.metadata['accuracy'] as double;
        final avgTime = pattern.metadata['averageTime'] as double;
        
        String title = '';
        String message = '';
        List<String> steps = [];
        
        switch (problemType) {
          case 'addition':
            title = 'Addition Ace! ➕';
            message = 'You\'re fantastic at addition problems! ${(accuracy * 100).toStringAsFixed(0)}% accuracy and solving them in just ${avgTime.toStringAsFixed(1)} seconds on average.';
            steps = ['Try more complex addition problems', 'Help others learn addition'];
            break;
          case 'subtraction':
            title = 'Subtraction Star! ➖';
            message = 'Subtraction is your superpower! You solve these with ${(accuracy * 100).toStringAsFixed(0)}% accuracy.';
            steps = ['Challenge yourself with bigger numbers', 'Practice word problems'];
            break;
          default:
            title = 'Math Master! 🎯';
            message = 'You\'re doing great with ${problemType} problems!';
            steps = ['Keep practicing to stay sharp'];
        }
        
        return Insight(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          childId: childId,
          type: 'strength',
          title: title,
          message: message,
          actionableSteps: steps,
          priority: 'low',
          generatedAt: DateTime.now(),
          relatedPatterns: [pattern],
          correctiveActions: {
            'suggestHigherLevel': true,
            'problemType': problemType,
          },
        );

      case 'strategy':
        final strategy = pattern.metadata['strategy'] as String;
        String title = '';
        String message = '';
        
        switch (strategy) {
          case 'make_ten':
            title = 'Make Ten Master! 🔟';
            message = 'You\'ve mastered the Make Ten strategy! This is a powerful tool for mental math.';
            break;
          case 'crossing':
            title = 'Number Crossing Expert! 🌉';
            message = 'You\'re excellent at crossing the next ten! This skill helps with larger numbers.';
            break;
          default:
            title = 'Strategy Star! ⭐';
            message = 'You\'re great at using the ${strategy} strategy!';
        }
        
        return Insight(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          childId: childId,
          type: 'strength',
          title: title,
          message: message,
          actionableSteps: [
            'Try applying this strategy to harder problems',
            'Teach someone else how to use it',
          ],
          priority: 'low',
          generatedAt: DateTime.now(),
          relatedPatterns: [pattern],
          correctiveActions: {
            'strategy': strategy,
            'suggestAdvancedProblems': true,
          },
        );

      default:
        return null;
    }
  }

  /// Create a weakness insight from a pattern
  static Insight? _createWeaknessInsight(String childId, LearningPattern pattern) {
    switch (pattern.category) {
      case 'problem_type':
        final problemType = pattern.metadata['problemType'] as String;
        final accuracy = pattern.metadata['accuracy'] as double;
        final hintUsage = pattern.metadata['hintUsage'] as double;
        
        String title = '';
        String message = '';
        List<String> steps = [];
        
        switch (problemType) {
          case 'subtraction':
            title = 'Subtraction Practice Time! 🔢';
            message = 'Subtraction can be tricky! Let\'s practice breaking numbers down step by step.';
            steps = [
              'Practice with smaller numbers first',
              'Use the number bond strategy to break down the second number',
              'Take your time - no need to rush',
            ];
            break;
          case 'addition':
            title = 'Addition Adventure! ➕';
            message = 'Let\'s make addition more fun! We\'ll practice with your favorite numbers.';
            steps = [
              'Start with problems using your favorite numbers',
              'Use the Make Ten strategy',
              'Practice counting up from the bigger number',
            ];
            break;
          default:
            title = 'Practice Makes Perfect! 💪';
            message = 'Let\'s work on ${problemType} problems together!';
            steps = ['Practice regularly', 'Use helpful strategies', 'Ask for hints when needed'];
        }
        
        return Insight(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          childId: childId,
          type: 'weakness',
          title: title,
          message: message,
          actionableSteps: steps,
          priority: hintUsage > 0.5 ? 'high' : 'medium',
          generatedAt: DateTime.now(),
          relatedPatterns: [pattern],
          correctiveActions: {
            'triggerReviewMode': true,
            'injectWeakProblems': true,
            'problemType': problemType,
            'adjustHintFrequency': hintUsage > 0.5 ? 'increase' : 'normal',
          },
        );

      case 'strategy':
        final strategy = pattern.metadata['strategy'] as String;
        String title = '';
        String message = '';
        List<String> steps = [];
        
        switch (strategy) {
          case 'make_ten':
            title = 'Let\'s Master Make Ten! 🔟';
            message = 'The Make Ten strategy is super helpful! Let\'s practice it step by step.';
            steps = [
              'Look for numbers that add up to 10',
              'Break the second number into parts',
              'Add the parts one by one',
            ];
            break;
          case 'crossing':
            title = 'Crossing the Next Ten! 🌉';
            message = 'Crossing tens is a great skill! Let\'s practice with smaller steps.';
            steps = [
              'Find what makes the first number reach the next ten',
              'Add the remaining amount',
              'Practice with your favorite numbers',
            ];
            break;
          default:
            title = 'Strategy Practice! 🎯';
            message = 'Let\'s practice the ${strategy} strategy together!';
            steps = ['Break problems into smaller steps', 'Practice regularly'];
        }
        
        return Insight(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          childId: childId,
          type: 'weakness',
          title: title,
          message: message,
          actionableSteps: steps,
          priority: 'medium',
          generatedAt: DateTime.now(),
          relatedPatterns: [pattern],
          correctiveActions: {
            'triggerReviewMode': true,
            'strategy': strategy,
            'injectStrategyProblems': true,
            'emphasizeStrategy': true,
          },
        );

      default:
        return null;
    }
  }

  /// Save analysis results
  static Future<void> _saveAnalysis(InsightsAnalysis analysis) async {
    final prefs = await SharedPreferences.getInstance();
    final analysisJson = jsonEncode(analysis.toJson());
    await prefs.setString('${_analysisKey}_${analysis.childId}', analysisJson);
  }

  /// Save generated insights
  static Future<void> _saveInsights(String childId, List<Insight> insights) async {
    final prefs = await SharedPreferences.getInstance();
    final existingInsightsJson = prefs.getStringList('${_insightsKey}_$childId') ?? [];
    final existingInsights = existingInsightsJson
        .map((json) => Insight.fromJson(jsonDecode(json)))
        .toList();

    // Add new insights
    existingInsights.addAll(insights);

    // Keep only recent insights (last 50)
    existingInsights.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
    final recentInsights = existingInsights.take(50).toList();

    // Save back
    final updatedInsightsJson = recentInsights.map((insight) => jsonEncode(insight.toJson())).toList();
    await prefs.setStringList('${_insightsKey}_$childId', updatedInsightsJson);
  }

  /// Get insights for a child
  static Future<List<Insight>> getInsights(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final insightsJson = prefs.getStringList('${_insightsKey}_$childId') ?? [];
    return insightsJson
        .map((json) => Insight.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
  }

  /// Get latest analysis for a child
  static Future<InsightsAnalysis?> getLatestAnalysis(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final analysisJson = prefs.getString('${_analysisKey}_$childId');
    if (analysisJson == null) return null;
    
    return InsightsAnalysis.fromJson(jsonDecode(analysisJson));
  }

  /// Force analysis for a child (useful for manual refresh)
  static Future<void> forceAnalysis(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final logsJson = prefs.getStringList(_logsKey) ?? [];
    final logs = logsJson
        .map((json) => ProblemLog.fromJson(jsonDecode(json)))
        .where((log) => log.childId == childId)
        .where((log) => log.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .toList();

    if (logs.isNotEmpty) {
      await _analyzeAndGenerateInsights(childId, logs);
    }
  }

  /// Clear all insights data for a child (useful for testing or reset)
  static Future<void> clearInsights(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_insightsKey}_$childId');
    await prefs.remove('${_analysisKey}_$childId');
  }

  /// Get corrective actions based on insights
  static Map<String, dynamic> getCorrectiveActions(String childId, List<Insight> insights) {
    final actions = <String, dynamic>{};
    
    for (final insight in insights) {
      if (insight.type == 'weakness' && insight.priority == 'high') {
        actions.addAll(insight.correctiveActions);
      }
    }
    
    return actions;
  }
}
