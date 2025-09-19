import 'dart:math';

/// CENTRAL PROBLEM GENERATOR
/// Single source of truth for ALL problem generation
class CentralProblemGenerator {
  static final _random = Random();
  
  /// Main function to generate problems
  /// This is the ONLY function that should be called for new challenges
  static Map<String, dynamic> generateProblem({
    required String action, // 'addition' or 'subtraction'
    required int level,     // 1, 2, 3, 4
  }) {
    print('🎯 CENTRAL GENERATOR: Generating $action problem for level $level');
    
    if (action == 'addition') {
      return _generateAdditionProblem(level);
    } else if (action == 'subtraction') {
      return _generateSubtractionProblem(level);
    } else {
      throw Exception('Invalid action: $action. Must be "addition" or "subtraction"');
    }
  }
  
  /// Generate addition problems by level
  static Map<String, dynamic> _generateAdditionProblem(int level) {
    switch (level) {
      case 1:
        return _generateLevel1Addition(); // Single digit, crosses 10
      case 2:
        return _generateLevel2Addition(); // 2-digit + 1-digit, crosses 10
      case 3:
        return _generateLevel3Addition(); // 2-digit + 2-digit, crosses 10
      case 4:
        return _generateLevel4Addition(); // Up to 3-digit
      default:
        return _generateLevel1Addition();
    }
  }
  
  /// Generate subtraction problems by level
  static Map<String, dynamic> _generateSubtractionProblem(int level) {
    switch (level) {
      case 1:
        return _generateLevel1Subtraction(); // 2-digit - 1-digit, crosses 10
      case 2:
        return _generateLevel2Subtraction(); // 2-digit - 1-digit, crosses 10
      case 3:
        return _generateLevel3Subtraction(); // 2-digit - 2-digit, crosses 10
      case 4:
        return _generateLevel4Subtraction(); // Up to 3-digit
      default:
        return _generateLevel1Subtraction();
    }
  }
  
  // ADDITION LEVELS
  
  static Map<String, dynamic> _generateLevel1Addition() {
    // Single digit addition that crosses 10
    int firstNumber = _random.nextInt(9) + 1; // 1-9
    int secondNumber = _random.nextInt(9) + 1; // 1-9
    
    // Ensure it crosses 10
    if (firstNumber + secondNumber <= 10) {
      secondNumber = 11 - firstNumber;
    }
    
    final answer = firstNumber + secondNumber;
    final bondSteps = _generateAdditionBondSteps(firstNumber, secondNumber);
    
    print('🎯 Level 1 Addition: $firstNumber + $secondNumber = $answer');
    return _createProblemMap(firstNumber, secondNumber, '+', answer, bondSteps);
  }
  
  static Map<String, dynamic> _generateLevel2Addition() {
    // 2-digit + 1-digit that crosses 10
    int firstNumber = _random.nextInt(90) + 10; // 10-99
    
    final firstNumberOnes = firstNumber % 10;
    final nextTen = firstNumber - firstNumberOnes + 10;
    final minSecondNumber = nextTen - firstNumber + 1;
    
    int secondNumber = _random.nextInt(9 - minSecondNumber + 1) + minSecondNumber;
    
    final answer = firstNumber + secondNumber;
    final bondSteps = _generateAdditionBondSteps(firstNumber, secondNumber);
    
    print('🎯 Level 2 Addition: $firstNumber + $secondNumber = $answer');
    return _createProblemMap(firstNumber, secondNumber, '+', answer, bondSteps);
  }
  
  static Map<String, dynamic> _generateLevel3Addition() {
    // 2-digit + 2-digit that crosses 10
    int firstNumber = _random.nextInt(90) + 10; // 10-99
    int secondNumber = _random.nextInt(90) + 10; // 10-99
    
    // Ensure crossing
    final firstNumberOnes = firstNumber % 10;
    final nextTen = firstNumber - firstNumberOnes + 10;
    if (firstNumber + secondNumber < nextTen) {
      secondNumber = nextTen - firstNumber + _random.nextInt(5) + 1;
    }
    
    final answer = firstNumber + secondNumber;
    final bondSteps = _generateAdditionBondSteps(firstNumber, secondNumber);
    
    print('🎯 Level 3 Addition: $firstNumber + $secondNumber = $answer');
    return _createProblemMap(firstNumber, secondNumber, '+', answer, bondSteps);
  }
  
  static Map<String, dynamic> _generateLevel4Addition() {
    // Up to 3-digit addition
    int firstNumber = _random.nextInt(900) + 100; // 100-999
    int secondNumber = _random.nextInt(99) + 1; // 1-99
    
    final answer = firstNumber + secondNumber;
    final bondSteps = _generateAdditionBondSteps(firstNumber, secondNumber);
    
    print('🎯 Level 4 Addition: $firstNumber + $secondNumber = $answer');
    return _createProblemMap(firstNumber, secondNumber, '+', answer, bondSteps);
  }
  
  // SUBTRACTION LEVELS
  
  static Map<String, dynamic> _generateLevel1Subtraction() {
    return _generateCrossingSubtraction(10, 20); // 10-20 range
  }
  
  static Map<String, dynamic> _generateLevel2Subtraction() {
    return _generateCrossingSubtraction(20, 99); // 20-99 range
  }
  
  static Map<String, dynamic> _generateLevel3Subtraction() {
    return _generateCrossingSubtraction(50, 99); // 50-99 range
  }
  
  static Map<String, dynamic> _generateLevel4Subtraction() {
    return _generateCrossingSubtraction(100, 999); // 100-999 range
  }
  
  /// Generate subtraction that ALWAYS crosses ten boundary
  static Map<String, dynamic> _generateCrossingSubtraction(int minFirst, int maxFirst) {
    int firstNumber = _random.nextInt(maxFirst - minFirst + 1) + minFirst;
    final firstNumberOnes = firstNumber % 10;
    
    int secondNumber;
    int attempts = 0;
    
    do {
      attempts++;
      if (attempts > 20) {
        // Failsafe: regenerate first number
        firstNumber = _random.nextInt(maxFirst - minFirst + 1) + minFirst;
        attempts = 0;
      }
      
      if (firstNumberOnes == 0) {
        // For numbers ending in 0: must subtract > 10
        final minSubtraction = 11;
        final maxSubtraction = min(18, firstNumber - 1);
        if (maxSubtraction >= minSubtraction) {
          secondNumber = _random.nextInt(maxSubtraction - minSubtraction + 1) + minSubtraction;
        } else {
          secondNumber = minSubtraction;
        }
      } else {
        // For other numbers: must cross to next lower ten
        // Example: 92 needs to cross from 90s to 80s, so result must be < 90
        // 92 - X < 90, so X > 2, minimum is 3
        // But we need to cross a full ten boundary, so we need to go to 80s
        // 92 - X < 80, so X > 12, minimum is 13
        final currentTen = (firstNumber ~/ 10) * 10; // 90 for 92
        final nextLowerTen = currentTen - 10; // 80 for 92
        final minSubtraction = firstNumber - nextLowerTen + 1; // 92 - 80 + 1 = 13
        final maxSubtraction = min(18, minSubtraction + 5);
        
        if (maxSubtraction >= minSubtraction) {
          secondNumber = _random.nextInt(maxSubtraction - minSubtraction + 1) + minSubtraction;
        } else {
          secondNumber = minSubtraction;
        }
      }
      
      // Verify crossing and ensure positive result
      final result = firstNumber - secondNumber;
      
      // CRITICAL: Never allow negative results
      if (result <= 0) {
        continue; // Skip this combination
      }
      
      final nextLowerTen = firstNumberOnes == 0 ? firstNumber - 10 : (firstNumber ~/ 10) * 10 - 10;
      final crossesTen = result < nextLowerTen;
      
      if (crossesTen && secondNumber <= 18 && result > 0) {
        break; // Valid problem found
      }
    } while (true);
    
    final answer = firstNumber - secondNumber;
    final bondSteps = _generateSubtractionBondSteps(firstNumber, secondNumber);
    
    print('🎯 *** CENTRAL GENERATOR CREATED: $firstNumber - $secondNumber = $answer (crosses ten boundary) ***');
    return _createProblemMap(firstNumber, secondNumber, '-', answer, bondSteps);
  }
  
  // HELPER METHODS
  
  static Map<String, dynamic> _createProblemMap(int operand1, int operand2, String operator, int answer, String bondSteps) {
    return {
      'problemText': '$operand1 $operator $operand2 = ?',
      'operand1': operand1,
      'operand2': operand2,
      'operator': operator,
      'correctAnswer': answer,
      'bondSteps': bondSteps,
    };
  }
  
  static String _generateAdditionBondSteps(int firstNumber, int secondNumber) {
    final firstNumberOnes = firstNumber % 10;
    final neededToMakeTen = 10 - firstNumberOnes;
    
    if (neededToMakeTen > 0 && neededToMakeTen <= secondNumber) {
      final remaining = secondNumber - neededToMakeTen;
      return '$secondNumber → $neededToMakeTen + $remaining';
    } else {
      final half = secondNumber ~/ 2;
      return '$secondNumber → $half + ${secondNumber - half}';
    }
  }
  
  static String _generateSubtractionBondSteps(int firstNumber, int secondNumber) {
    final firstNumberOnes = firstNumber % 10;
    
    if (firstNumberOnes > 0 && firstNumberOnes <= secondNumber) {
      final remaining = secondNumber - firstNumberOnes;
      return '$secondNumber → $firstNumberOnes + $remaining';
    } else {
      final half = secondNumber ~/ 2;
      return '$secondNumber → $half + ${secondNumber - half}';
    }
  }
}
