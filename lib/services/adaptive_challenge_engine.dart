import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/adaptive_challenge.dart';
import 'central_problem_generator.dart';

/// Adaptive Challenge Engine that intelligently selects the next math challenge
/// based on performance history and learning progression
class AdaptiveChallengeEngine {
  static const String _resultsKey = 'adaptive_challenge_results';
  static const String _challengeCountKey = 'challenge_count';
  static const int _recentProblemsCount = 10; // Increased from 5 to 10 for better analysis
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

  /// Enhanced Level Progression Constants
  static const double _levelUpAccuracyThreshold = 0.9; // 90% accuracy required
  static const int _stabilityBufferSets = 3; // Must sustain performance across 3 sets
  static const int _setSize = 10; // Each set is 10 problems
  static const int _minScoreForLevelUp = 35; // Minimum weighted score
  
  /// Determine the next challenge level based on enhanced algorithm
  static Future<int> determineNextLevel(String childId, int currentLevel) async {
    final metrics = await calculatePerformanceMetrics(childId);
    
    // Enhanced Level Progression Algorithm
    // 1. Require 90% accuracy over last 10 problems
    // 2. Must sustain across multiple sets (stability buffer)
    // 3. Use weighted scoring system
    if (await _shouldLevelUp(childId, currentLevel, metrics)) {
      return (currentLevel + 1).clamp(1, 4);
    }
    
    // If accuracy 60-79% → stay on current level
    if (metrics.accuracy >= 0.6) {
      return currentLevel;
    }
    
    // If accuracy < 60% → move down one level (not below Level 1)
    return (currentLevel - 1).clamp(1, 4);
  }

  /// Enhanced level up decision with stability buffer and weighted scoring
  static Future<bool> _shouldLevelUp(String childId, int currentLevel, PerformanceMetrics metrics) async {
    print('🎯 ENHANCED LEVEL UP CHECK for Level $currentLevel → ${currentLevel + 1}');
    
    // Don't level up if already at max level
    if (currentLevel >= 4) {
      print('❌ Already at max level');
      return false;
    }
    
    final results = await getAllProblemResults(childId);
    final requiredProblems = _setSize * _stabilityBufferSets; // 30 problems
    
    if (results.length < requiredProblems) {
      print('❌ Not enough problems: ${results.length}/$requiredProblems needed');
      return false; // Not enough data for stability analysis
    }
    
    // Check weighted scoring system
    final weightedScore = await _calculateWeightedScore(childId);
    print('📊 Weighted Score: $weightedScore/$_minScoreForLevelUp required');
    if (weightedScore < _minScoreForLevelUp) {
      print('❌ Score too low: $weightedScore < $_minScoreForLevelUp');
      return false; // Doesn't meet weighted score threshold
    }
    
    // Check stability buffer: must maintain 90%+ across 3 consecutive sets
    print('🔍 Checking stability across $_stabilityBufferSets sets:');
    for (int setIndex = 0; setIndex < _stabilityBufferSets; setIndex++) {
      final setStart = setIndex * _setSize;
      final setResults = results.skip(setStart).take(_setSize).toList();
      
      if (setResults.length < _setSize) {
        print('❌ Set ${setIndex + 1}: Not enough problems (${setResults.length}/$_setSize)');
        return false; // Not enough problems in this set
      }
      
      final setAccuracy = setResults.where((r) => r.correct).length / setResults.length;
      final setPercentage = (setAccuracy * 100).toStringAsFixed(1);
      print('📈 Set ${setIndex + 1}: $setPercentage% accuracy');
      
      if (setAccuracy < _levelUpAccuracyThreshold) {
        print('❌ Set ${setIndex + 1}: Failed threshold ($setPercentage% < 90%)');
        return false; // Failed to maintain 90% in this set
      }
    }
    
    print('✅ LEVEL UP APPROVED! All criteria met');
    return true; // Passed all criteria!
  }

  /// Calculate weighted score based on attempt efficiency
  static Future<double> _calculateWeightedScore(String childId) async {
    final results = await getAllProblemResults(childId);
    final recentResults = results.take(_setSize * _stabilityBufferSets).toList();
    
    double totalScore = 0.0;
    
    for (final result in recentResults) {
      if (result.correct) {
        // Award points based on attempt count (simulated from time/accuracy)
        // Fast solve (< 10s) = first attempt = +3 points
        // Medium solve (10-20s) = second attempt = +2 points  
        // Slow solve (> 20s) = third attempt = +1 point
        if (result.timeTaken <= 10.0) {
          totalScore += 3.0; // First attempt
        } else if (result.timeTaken <= 20.0) {
          totalScore += 2.0; // Second attempt
        } else {
          totalScore += 1.0; // Third attempt
        }
      } else {
        totalScore -= 2.0; // Failure after 3 attempts = -2 points
      }
    }
    
    return totalScore;
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
    
    final problem = CentralProblemGenerator.generateProblem(
      action: 'subtraction',
      level: reviewLevel,
    );
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
      return null; // Disabled to eliminate duplicate issue
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
    
    // Generate problem using central generator - randomly choose addition or subtraction
    final problem = CentralProblemGenerator.generateProblem(
      level: nextLevel, // Don't specify action - let it randomly choose
    );
    
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

  // OLD PROBLEM GENERATION REMOVED - USING CENTRAL GENERATOR NOW

  /// OLD METHOD - REPLACED BY CENTRAL GENERATOR
  static Map<String, dynamic> _generateCrossingSubtractionProblem(int firstNumberMin, int firstNumberMax) {
    // FORCE USE OF CENTRAL GENERATOR
    return CentralProblemGenerator.generateProblem(
      action: 'subtraction',
      level: 2,
    );
  }

  /// Generate Level 1: Single-digit addition (make-a-ten)
  static Map<String, dynamic> _generateLevel1Problem(List<int> favoriteNumbers) {
    final random = Random();
    
    // Generate numbers that work well with make-a-ten strategy (no favorite numbers dependency)
    int firstNumber = random.nextInt(9) + 1; // 1-9
    int secondNumber = random.nextInt(9) + 1; // 1-9
    
    // Ensure sum > 10 for make-ten strategy
    if (firstNumber + secondNumber <= 10) {
      secondNumber = 11 - firstNumber;
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
      // Level 2: 2-digit - 1-digit subtraction that crosses the ten boundary
      return _generateCrossingSubtractionProblem(10, 99);
    } else {
      // For addition, ensure it crosses the next 10
      int firstNumber = random.nextInt(90) + 10; // 10-99
      
      // Calculate what second number is needed to cross the next 10
      final firstNumberOnes = firstNumber % 10;
      final nextTen = firstNumber - firstNumberOnes + 10;
      final minSecondNumber = nextTen - firstNumber + 1; // +1 to ensure it crosses
      
      // Generate second number that ensures crossing the next 10 (no favorite numbers dependency)
      final secondNumber = random.nextInt(9 - minSecondNumber + 1) + minSecondNumber;
      
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
      // Level 3: 2-digit - 2-digit subtraction that crosses the ten boundary
      return _generateCrossingSubtractionProblem(10, 99);
    } else {
      // Enhanced favorite numbers logic for Level 3 addition
      int firstNumber = random.nextInt(90) + 10; // 10-99
      
      // Calculate what second number is needed to cross the next 10
      final firstNumberOnes = firstNumber % 10;
      final nextTen = firstNumber - firstNumberOnes + 10;
      final minSecondNumber = nextTen - firstNumber + 1; // +1 to ensure it crosses
      
      // For 2-digit + 2-digit, ensure the second number is at least 2 digits
      final minTwoDigit = minSecondNumber > 9 ? minSecondNumber : 10;
      int secondNumber = random.nextInt(90 - minTwoDigit + 1) + minTwoDigit;
      
      // Try to use favorite numbers
      if (favoriteNumbers.isNotEmpty && random.nextBool()) {
        final validFavoriteNumbers = favoriteNumbers.where((num) => 
          num >= minTwoDigit && num <= 99).toList();
        if (validFavoriteNumbers.isNotEmpty) {
          secondNumber = validFavoriteNumbers[random.nextInt(validFavoriteNumbers.length)];
        } else {
          // Try using favorite number as first operand
          final favoriteFirst = favoriteNumbers[random.nextInt(favoriteNumbers.length)];
          if (favoriteFirst >= 10 && favoriteFirst <= 99) {
            firstNumber = favoriteFirst;
            final newFirstOnes = firstNumber % 10;
            final newNextTen = firstNumber - newFirstOnes + 10;
            final newMinSecond = newNextTen - firstNumber + 1;
            final newMinTwoDigit = newMinSecond > 9 ? newMinSecond : 10;
            secondNumber = random.nextInt(90 - newMinTwoDigit + 1) + newMinTwoDigit;
          }
        }
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

  /// Generate Level 4: Up to 3-digit problems (≤1000)
  static Map<String, dynamic> _generateLevel4Problem(List<int> favoriteNumbers) {
    final random = Random();
    final isSubtraction = random.nextBool();
    
    if (isSubtraction) {
      // Level 4: 3-digit - 3-digit subtraction that crosses the ten boundary
      return _generateCrossingSubtractionProblem(100, 999);
    } else {
      // Enhanced favorite numbers logic for Level 4 addition (sums > 100)
      int firstNumber = random.nextInt(900) + 100; // 100-999
      
      // Calculate what second number is needed to cross the next 10
      final firstNumberOnes = firstNumber % 10;
      final nextTen = firstNumber - firstNumberOnes + 10;
      final minSecondNumber = nextTen - firstNumber + 1; // +1 to ensure it crosses
      
      // For 3-digit problems, ensure the second number is reasonable
      final minThreeDigit = minSecondNumber > 99 ? minSecondNumber : 100;
      final maxSecondNumber = 999 - firstNumber; // Ensure sum doesn't exceed 1000
      int secondNumber = random.nextInt(maxSecondNumber - minThreeDigit + 1) + minThreeDigit;
      
      // Try to use favorite numbers
      if (favoriteNumbers.isNotEmpty && random.nextBool()) {
        final validFavoriteNumbers = favoriteNumbers.where((num) => 
          num >= minThreeDigit && num <= maxSecondNumber).toList();
        if (validFavoriteNumbers.isNotEmpty) {
          secondNumber = validFavoriteNumbers[random.nextInt(validFavoriteNumbers.length)];
        } else {
          // Try using favorite number as first operand
          final favoriteFirst = favoriteNumbers[random.nextInt(favoriteNumbers.length)];
          if (favoriteFirst >= 100 && favoriteFirst <= 999) {
            firstNumber = favoriteFirst;
            final newFirstOnes = firstNumber % 10;
            final newNextTen = firstNumber - newFirstOnes + 10;
            final newMinSecond = newNextTen - firstNumber + 1;
            final newMinThreeDigit = newMinSecond > 99 ? newMinSecond : 100;
            final newMaxSecond = 999 - firstNumber;
            secondNumber = random.nextInt(newMaxSecond - newMinThreeDigit + 1) + newMinThreeDigit;
          }
        }
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

  /// Generate make-a-ten bond steps
  static String _generateMakeTenBondSteps(int firstNumber, int secondNumber) {
    // CORRECT LOGIC: For Make Ten strategy, break the second number to help cross the next 10
    // Example: 89 + 8 → break 8 into 1 + 7 (to make 89 + 1 = 90)
    // Example: 89 + 2 → break 2 into 1 + 1
    // Example: 47 + 6 → break 6 into 3 + 3  
    // Example: 43 + 8 → break 8 into 7 + 1
    
    if (secondNumber <= 1) {
      // For very small numbers, just return as is
      return '$secondNumber → $secondNumber';
    } else if (secondNumber == 2) {
      // For 2, always break into 1 + 1
      return '$secondNumber → 1 + 1';
    } else {
      // For Make Ten strategy: break to help cross the next 10
      // Find what number is needed to make firstNumber reach the next 10
      final firstNumberOnes = firstNumber % 10;
      final neededToMakeTen = 10 - firstNumberOnes;
      
      if (neededToMakeTen > 0 && neededToMakeTen < secondNumber) {
        // Break secondNumber to include the number needed to make ten
        final remaining = secondNumber - neededToMakeTen;
        return '$secondNumber → $neededToMakeTen + $remaining';
      } else {
        // Fallback to simple breakdown
        if (secondNumber % 2 == 0) {
          final half = secondNumber ~/ 2;
          return '$secondNumber → $half + $half';
        } else {
          final firstPart = secondNumber - 1;
          return '$secondNumber → $firstPart + 1';
        }
      }
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
    // CORRECT LOGIC: For subtraction crossing the ten, break the second number
    // Example: 53 - 6 → break 6 into 3 + 3 → 53 - 3 - 3 = 50 - 3 = 47
    // Example: 67 - 9 → break 9 into 7 + 2 → 67 - 7 - 2 = 60 - 2 = 58
    
    if (secondNumber <= 18) { // Most single-digit and some teen numbers
      final firstNumberOnes = firstNumber % 10;
      
      // Strategy: Break secondNumber to help cross to the next lower ten
      // We want the first part to take us exactly to the next lower ten
      final neededToReachLowerTen = firstNumberOnes;
      
      if (neededToReachLowerTen > 0 && neededToReachLowerTen <= secondNumber) {
        // Break secondNumber into: part that reaches lower ten + remaining part
        // Example: 53 - 6 → break 6 into 3 + 3 (3 gets us from 53 to 50)
        final firstPart = neededToReachLowerTen;
        final secondPart = secondNumber - firstPart;
        
        if (secondPart == 0) {
          return '$secondNumber → $firstPart';
        } else {
          return '$secondNumber → $firstPart + $secondPart';
        }
      } else {
        // Fallback: simple breakdown
        if (secondNumber % 2 == 0) {
          final half = secondNumber ~/ 2;
          return '$secondNumber → $half + $half';
        } else {
          final firstPart = secondNumber - 1;
          return '$secondNumber → $firstPart + 1';
        }
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
