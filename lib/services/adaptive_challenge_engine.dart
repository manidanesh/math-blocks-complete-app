import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/adaptive_challenge.dart';

/// Adaptive Challenge Engine that intelligently selects the next math challenge
/// based on performance history and learning progression
class AdaptiveChallengeEngine {
  static const String _resultsKey = 'adaptive_challenge_results';
  static const String _challengeCountKey = 'challenge_count';
  static const int _recentProblemsCount = 5;
  static const int _reviewProblemInterval = 4;

  /// Store a problem result in local storage
  static Future<void> storeProblemResult(ProblemResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final results = await getAllProblemResults(result.childId);
      
      // Add new result to the beginning (most recent first)
      results.insert(0, result);
      
      // Keep only last 100 results to prevent storage bloat
      final limitedResults = results.take(100).toList();
      
      // Save to storage
      final resultsJson = limitedResults.map((r) => r.toJson()).toList();
      await prefs.setString('${_resultsKey}_${result.childId}', jsonEncode(resultsJson));
      
      // Update challenge count
      final currentCount = await getChallengeCount(result.childId);
      await prefs.setInt('${_challengeCountKey}_${result.childId}', currentCount + 1);
      
      print('📊 Stored problem result: ${result.problemText} (Level ${result.level}) - ${result.correct ? "✓" : "✗"}');
    } catch (e) {
      print('❌ Error storing problem result: $e');
    }
  }

  /// Get all problem results for a child
  static Future<List<ProblemResult>> getAllProblemResults(String childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final resultsString = prefs.getString('${_resultsKey}_$childId');
      
      if (resultsString == null) return [];
      
      final List<dynamic> resultsJson = jsonDecode(resultsString);
      return resultsJson.map((json) => ProblemResult.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error loading problem results: $e');
      return [];
    }
  }

  /// Get challenge count for a child
  static Future<int> getChallengeCount(String childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('${_challengeCountKey}_$childId') ?? 0;
    } catch (e) {
      print('❌ Error getting challenge count: $e');
      return 0;
    }
  }

  /// Calculate performance metrics for a child
  static Future<PerformanceMetrics> calculatePerformanceMetrics(String childId) async {
    final results = await getAllProblemResults(childId);
    
    if (results.isEmpty) {
      return const PerformanceMetrics(
        accuracy: 0.0,
        averageTime: 0.0,
        consecutiveIncorrect: 0,
        recentLevels: [],
        levelAccuracy: {},
      );
    }

    // Get recent problems (last 5)
    final recentResults = results.take(_recentProblemsCount).toList();
    
    // Calculate accuracy
    final correctCount = recentResults.where((r) => r.correct).length;
    final accuracy = correctCount / recentResults.length;

    // Calculate average time
    final totalTime = recentResults.fold<double>(0.0, (sum, r) => sum + r.timeTaken);
    final averageTime = totalTime / recentResults.length;

    // Calculate consecutive incorrect
    int consecutiveIncorrect = 0;
    for (final result in recentResults) {
      if (result.correct) break;
      consecutiveIncorrect++;
    }

    // Get recent levels
    final recentLevels = recentResults.map((r) => r.level).toList();

    // Calculate level accuracy
    final Map<int, double> levelAccuracy = {};
    final levelGroups = <int, List<ProblemResult>>{};
    
    for (final result in results) {
      levelGroups[result.level] = (levelGroups[result.level] ?? [])..add(result);
    }

    for (final entry in levelGroups.entries) {
      final level = entry.key;
      final levelResults = entry.value;
      final levelCorrect = levelResults.where((r) => r.correct).length;
      levelAccuracy[level] = levelCorrect / levelResults.length;
    }

    return PerformanceMetrics(
      accuracy: accuracy,
      averageTime: averageTime,
      consecutiveIncorrect: consecutiveIncorrect,
      recentLevels: recentLevels,
      levelAccuracy: levelAccuracy,
    );
  }

  /// Determine the next challenge level based on performance
  static Future<int> determineNextLevel(String childId, int currentLevel) async {
    final metrics = await calculatePerformanceMetrics(childId);
    
    // If accuracy >= 80% → move to next harder level
    if (metrics.accuracy >= 0.8) {
      return (currentLevel + 1).clamp(1, 4);
    }
    
    // If accuracy 60-79% → stay on current level
    if (metrics.accuracy >= 0.6) {
      return currentLevel;
    }
    
    // If accuracy < 60% → move down one level (not below Level 1)
    return (currentLevel - 1).clamp(1, 4);
  }

  /// Check if we should inject a review problem
  static Future<bool> shouldInjectReviewProblem(String childId) async {
    final metrics = await calculatePerformanceMetrics(childId);
    final challengeCount = await getChallengeCount(childId);
    
    // If 2 incorrect in a row → inject review problem
    if (metrics.consecutiveIncorrect >= 2) {
      return true;
    }
    
    // Always inject 1 review problem every 4 challenges
    if (challengeCount % _reviewProblemInterval == 0) {
      return true;
    }
    
    return false;
  }

  /// Get past mistakes for review problems
  static Future<List<ProblemResult>> getPastMistakes(String childId) async {
    final results = await getAllProblemResults(childId);
    return results.where((r) => !r.correct).toList();
  }

  /// Generate a review problem from past mistakes
  static Future<AdaptiveChallenge?> generateReviewProblem(String childId, List<int> favoriteNumbers) async {
    final mistakes = await getPastMistakes(childId);
    
    if (mistakes.isEmpty) return null;
    
    // Select a random mistake to review
    final random = Random();
    final selectedMistake = mistakes[random.nextInt(mistakes.length)];
    
    // Generate a similar problem at a lower level
    final reviewLevel = (selectedMistake.level - 1).clamp(1, 4);
    final levelDef = ChallengeLevel.getByLevel(reviewLevel);
    
    final problem = _generateProblemForLevel(levelDef, favoriteNumbers);
    return AdaptiveChallenge(
      problemId: 'review_${DateTime.now().millisecondsSinceEpoch}',
      problemText: problem['problemText'] as String,
      level: reviewLevel,
      bondSteps: problem['bondSteps'] as String,
      operand1: problem['operand1'] as int,
      operand2: problem['operand2'] as int,
      operator: problem['operator'] as String,
      correctAnswer: problem['correctAnswer'] as int,
      isReviewProblem: true,
      motivationalMessage: "Let's review this concept together! 📚",
    );
  }

  /// Generate motivational feedback based on performance improvement
  static Future<String?> getMotivationalFeedback(String childId, String childName) async {
    final metrics = await calculatePerformanceMetrics(childId);
    final results = await getAllProblemResults(childId);
    
    if (results.length < 10) return null; // Not enough data yet
    
    // Compare current accuracy with earlier performance
    final recentResults = results.take(5).toList();
    final olderResults = results.skip(5).take(5).toList();
    
    if (olderResults.isEmpty) return null;
    
    final recentAccuracy = recentResults.where((r) => r.correct).length / recentResults.length;
    final olderAccuracy = olderResults.where((r) => r.correct).length / olderResults.length;
    
    // If accuracy improved significantly
    if (recentAccuracy - olderAccuracy >= 0.2) {
      return "Great job, $childName! You're ready for a tougher challenge! 🚀";
    }
    
    // If accuracy is consistently high
    if (recentAccuracy >= 0.9 && olderAccuracy >= 0.8) {
      return "Excellent work, $childName! You're mastering these concepts! ⭐";
    }
    
    return null;
  }

  /// Main method to get the next problem
  static Future<AdaptiveChallenge> getNextProblem(String childId, String childName, {int? currentLevel, List<int> favoriteNumbers = const []}) async {
    // Check if we should inject a review problem
    if (await shouldInjectReviewProblem(childId)) {
      final reviewProblem = await generateReviewProblem(childId, favoriteNumbers);
      if (reviewProblem != null) {
        return reviewProblem;
      }
    }

    // Determine the appropriate level
    final effectiveCurrentLevel = currentLevel ?? 1;
    final nextLevel = await determineNextLevel(childId, effectiveCurrentLevel);
    
    // Generate motivational feedback
    final motivationalMessage = await getMotivationalFeedback(childId, childName);
    
    // Generate problem for the determined level
    final levelDef = ChallengeLevel.getByLevel(nextLevel);
    final problem = _generateProblemForLevel(levelDef, favoriteNumbers);
    
    return AdaptiveChallenge(
      problemId: 'challenge_${DateTime.now().millisecondsSinceEpoch}',
      problemText: problem['problemText'] as String,
      level: nextLevel,
      bondSteps: problem['bondSteps'] as String,
      operand1: problem['operand1'] as int,
      operand2: problem['operand2'] as int,
      operator: problem['operator'] as String,
      correctAnswer: problem['correctAnswer'] as int,
      isReviewProblem: false,
      motivationalMessage: motivationalMessage,
    );
  }

  /// Generate a problem for a specific level
  static Map<String, dynamic> _generateProblemForLevel(ChallengeLevel levelDef, List<int> favoriteNumbers) {
    final random = Random();
    
    switch (levelDef.level) {
      case 1:
        return _generateLevel1Problem(favoriteNumbers);
      case 2:
        return _generateLevel2Problem(favoriteNumbers);
      case 3:
        return _generateLevel3Problem(favoriteNumbers);
      case 4:
        return _generateLevel4Problem(favoriteNumbers);
      default:
        return _generateLevel1Problem(favoriteNumbers);
    }
  }

  /// Generate Level 1: Single-digit addition (make-a-ten)
  static Map<String, dynamic> _generateLevel1Problem(List<int> favoriteNumbers) {
    final random = Random();
    
    // Use favorite numbers if available, otherwise generate random
    int firstNumber, secondNumber;
    if (favoriteNumbers.isNotEmpty && random.nextBool()) {
      firstNumber = favoriteNumbers[random.nextInt(favoriteNumbers.length)];
      // Generate second number that works well with make-a-ten strategy
      secondNumber = random.nextInt(9) + 1; // 1-9
    } else {
      // Generate numbers that work well with make-a-ten strategy
      firstNumber = random.nextInt(9) + 1; // 1-9
      secondNumber = random.nextInt(9) + 1; // 1-9
    }
    
    final answer = firstNumber + secondNumber;
    final bondSteps = _generateMakeTenBondSteps(firstNumber, secondNumber);
    
    return {
      'problemText': '$firstNumber + $secondNumber = ?',
      'operand1': firstNumber,
      'operand2': secondNumber,
      'operator': '+',
      'correctAnswer': answer,
      'bondSteps': bondSteps,
    };
  }

  /// Generate Level 2: 2-digit + 1-digit addition/subtraction
  static Map<String, dynamic> _generateLevel2Problem(List<int> favoriteNumbers) {
    final random = Random();
    final isSubtraction = random.nextBool();
    
    if (isSubtraction) {
      final firstNumber = random.nextInt(90) + 10; // 10-99
      int secondNumber;
      if (favoriteNumbers.isNotEmpty && random.nextBool()) {
        secondNumber = favoriteNumbers[random.nextInt(favoriteNumbers.length)];
      } else {
        secondNumber = random.nextInt(9) + 1; // 1-9
      }
      final answer = firstNumber - secondNumber;
      final bondSteps = _generateSubtractionBondSteps(firstNumber, secondNumber);
      
      return {
        'problemText': '$firstNumber - $secondNumber = ?',
        'operand1': firstNumber,
        'operand2': secondNumber,
        'operator': '-',
        'correctAnswer': answer,
        'bondSteps': bondSteps,
      };
    } else {
      // For addition, ensure it crosses the next 10
      final firstNumber = random.nextInt(90) + 10; // 10-99
      
      // Calculate what second number is needed to cross the next 10
      final firstNumberOnes = firstNumber % 10;
      final nextTen = firstNumber - firstNumberOnes + 10;
      final minSecondNumber = nextTen - firstNumber + 1; // +1 to ensure it crosses
      
      // Try to use favorite numbers if they work with the crossing logic
      int secondNumber;
      if (favoriteNumbers.isNotEmpty) {
        final validFavoriteNumbers = favoriteNumbers.where((num) => 
          num >= minSecondNumber && num <= 9).toList();
        if (validFavoriteNumbers.isNotEmpty && random.nextBool()) {
          secondNumber = validFavoriteNumbers[random.nextInt(validFavoriteNumbers.length)];
        } else {
          secondNumber = random.nextInt(10 - minSecondNumber) + minSecondNumber;
        }
      } else {
        secondNumber = random.nextInt(10 - minSecondNumber) + minSecondNumber;
      }
      
      final answer = firstNumber + secondNumber;
      final bondSteps = _generateAdditionBondSteps(firstNumber, secondNumber);
      
      return {
        'problemText': '$firstNumber + $secondNumber = ?',
        'operand1': firstNumber,
        'operand2': secondNumber,
        'operator': '+',
        'correctAnswer': answer,
        'bondSteps': bondSteps,
      };
    }
  }

  /// Generate Level 3: 2-digit + 2-digit with regrouping
  static Map<String, dynamic> _generateLevel3Problem(List<int> favoriteNumbers) {
    final random = Random();
    final isSubtraction = random.nextBool();
    
    if (isSubtraction) {
      final firstNumber = random.nextInt(90) + 10; // 10-99
      final secondNumber = random.nextInt(90) + 10; // 10-99
      final answer = firstNumber - secondNumber;
      final bondSteps = _generateSubtractionBondSteps(firstNumber, secondNumber);
      
      return {
        'problemText': '$firstNumber - $secondNumber = ?',
        'operand1': firstNumber,
        'operand2': secondNumber,
        'operator': '-',
        'correctAnswer': answer,
        'bondSteps': bondSteps,
      };
    } else {
      // For addition, ensure it crosses the next 10
      final firstNumber = random.nextInt(90) + 10; // 10-99
      
      // Calculate what second number is needed to cross the next 10
      final firstNumberOnes = firstNumber % 10;
      final nextTen = firstNumber - firstNumberOnes + 10;
      final minSecondNumber = nextTen - firstNumber + 1; // +1 to ensure it crosses
      
      // For 2-digit + 2-digit, ensure the second number is at least 2 digits
      final minTwoDigit = minSecondNumber > 9 ? minSecondNumber : 10;
      final secondNumber = random.nextInt(90 - minTwoDigit + 1) + minTwoDigit;
      
      final answer = firstNumber + secondNumber;
      final bondSteps = _generateAdditionBondSteps(firstNumber, secondNumber);
      
      return {
        'problemText': '$firstNumber + $secondNumber = ?',
        'operand1': firstNumber,
        'operand2': secondNumber,
        'operator': '+',
        'correctAnswer': answer,
        'bondSteps': bondSteps,
      };
    }
  }

  /// Generate Level 4: Up to 3-digit problems (≤1000)
  static Map<String, dynamic> _generateLevel4Problem(List<int> favoriteNumbers) {
    final random = Random();
    final isSubtraction = random.nextBool();
    
    if (isSubtraction) {
      final firstNumber = random.nextInt(900) + 100; // 100-999
      final secondNumber = random.nextInt(900) + 100; // 100-999
      final answer = firstNumber - secondNumber;
      final bondSteps = _generateSubtractionBondSteps(firstNumber, secondNumber);
      
      return {
        'problemText': '$firstNumber - $secondNumber = ?',
        'operand1': firstNumber,
        'operand2': secondNumber,
        'operator': '-',
        'correctAnswer': answer,
        'bondSteps': bondSteps,
      };
    } else {
      // For addition, ensure it crosses the next 10
      final firstNumber = random.nextInt(900) + 100; // 100-999
      
      // Calculate what second number is needed to cross the next 10
      final firstNumberOnes = firstNumber % 10;
      final nextTen = firstNumber - firstNumberOnes + 10;
      final minSecondNumber = nextTen - firstNumber + 1; // +1 to ensure it crosses
      
      // For 3-digit problems, ensure the second number is reasonable
      final minThreeDigit = minSecondNumber > 99 ? minSecondNumber : 100;
      final maxSecondNumber = 999 - firstNumber; // Ensure sum doesn't exceed 1000
      final secondNumber = random.nextInt(maxSecondNumber - minThreeDigit + 1) + minThreeDigit;
      
      final answer = firstNumber + secondNumber;
      final bondSteps = _generateAdditionBondSteps(firstNumber, secondNumber);
      
      return {
        'problemText': '$firstNumber + $secondNumber = ?',
        'operand1': firstNumber,
        'operand2': secondNumber,
        'operator': '+',
        'correctAnswer': answer,
        'bondSteps': bondSteps,
      };
    }
  }

  /// Generate make-a-ten bond steps
  static String _generateMakeTenBondSteps(int firstNumber, int secondNumber) {
    // For make-ten strategy, break the second number into equal parts when possible
    // Example: 47 + 6 = 47 + 3 + 3 = 50 + 3 = 53
    // Break 6 into 3 + 3, not 0 + 6
    
    if (secondNumber % 2 == 0) {
      // If even, split into two equal parts
      final half = secondNumber ~/ 2;
      return '$secondNumber → $half + $half';
    } else {
      // If odd, split into two parts that are as equal as possible
      final firstPart = secondNumber ~/ 2;
      final secondPart = secondNumber - firstPart;
      return '$secondNumber → $firstPart + $secondPart';
    }
  }

  /// Generate addition bond steps
  static String _generateAdditionBondSteps(int firstNumber, int secondNumber) {
    // Break down the second number into tens and ones
    final tens = (secondNumber ~/ 10) * 10;
    final ones = secondNumber % 10;
    return '$secondNumber → $tens + $ones';
  }

  /// Generate subtraction bond steps
  static String _generateSubtractionBondSteps(int firstNumber, int secondNumber) {
    // For subtraction, break the second number into parts that make calculation easier
    // Example: 45 - 6 = 45 - 5 - 1 = 40 - 1 = 39
    // Break 6 into 5 + 1 (or similar strategy)
    
    if (secondNumber <= 10) {
      // For single digits, break into a number that makes the first number end in 0
      // and the remainder
      final firstNumberOnes = firstNumber % 10;
      
      if (firstNumberOnes >= secondNumber) {
        // We can subtract directly to make it end in 0
        final firstPart = firstNumberOnes;
        final secondPart = secondNumber - firstPart;
        return '$secondNumber → $firstPart + $secondPart';
      } else {
        // Need to break it differently
        final firstPart = secondNumber - 1;
        final secondPart = 1;
        return '$secondNumber → $firstPart + $secondPart';
      }
    } else if (secondNumber <= 100) {
      // For 2-digit numbers, break into tens and ones
      final tens = (secondNumber ~/ 10) * 10;
      final ones = secondNumber % 10;
      return '$secondNumber → $tens + $ones';
    } else {
      // For 3-digit numbers, break into hundreds, tens, and ones
      final hundreds = (secondNumber ~/ 100) * 100;
      final remaining = secondNumber % 100;
      final tens = (remaining ~/ 10) * 10;
      final ones = remaining % 10;
      
      if (tens == 0) {
        return '$secondNumber → $hundreds + $ones';
      } else if (ones == 0) {
        return '$secondNumber → $hundreds + $tens';
      } else {
        return '$secondNumber → $hundreds + $tens + $ones';
      }
    }
  }

  /// Clear all data for a child (for testing or reset)
  static Future<void> clearChildData(String childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_resultsKey}_$childId');
      await prefs.remove('${_challengeCountKey}_$childId');
      print('🗑️ Cleared adaptive challenge data for child: $childId');
    } catch (e) {
      print('❌ Error clearing child data: $e');
    }
  }
}
