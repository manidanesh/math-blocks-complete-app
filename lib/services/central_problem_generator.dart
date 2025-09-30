import 'dart:math';

/// CENTRAL PROBLEM GENERATOR
/// Single source of truth for ALL problem generation
class CentralProblemGenerator {
  static final _random = Random();
  
  /// Main function to generate problems
  /// This is the ONLY function that should be called for new challenges
  static Map<String, dynamic> generateProblem({
    String? action, // 'addition' or 'subtraction' - if null, randomly choose
    required int level,     // 1, 2, 3, 4
  }) {
    // Randomly choose addition or subtraction if not specified
    final selectedAction = action ?? (_random.nextBool() ? 'addition' : 'subtraction');
    
    print('🎯🎯🎯 CENTRAL GENERATOR: Generating $selectedAction problem for level $level 🎯🎯🎯');
    
    if (selectedAction == 'addition') {
      return _generateAdditionProblem(level);
    } else if (selectedAction == 'subtraction') {
      return _generateSubtractionProblem(level);
    } else {
      throw Exception('Invalid action: $selectedAction. Must be "addition" or "subtraction"');
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
    // Enhanced Level 1: Mix of regular problems, stretch problems, and review
    final problemType = _random.nextInt(10); // 0-9 for different problem types
    
    if (problemType < 2) {
      // 20% chance: Stretch problems (harder single-digit additions)
      return _generateLevel1StretchAddition();
    } else if (problemType < 4) {
      // 20% chance: Review problems (easier variations)
      return _generateLevel1ReviewAddition();
    } else {
      // 60% chance: Standard Level 1 crossing problems
      return _generateLevel1StandardAddition();
    }
  }
  
  /// Standard Level 1 crossing addition
  static Map<String, dynamic> _generateLevel1StandardAddition() {
    int firstNumber = _random.nextInt(9) + 11; // 11-19 to ensure crossing potential
    int secondNumber;
    int attempts = 0;
    
    do {
      attempts++;
      if (attempts > 20) {
        firstNumber = _random.nextInt(9) + 11; // Regenerate if stuck
        attempts = 0;
      }
      
      final onesDigit = firstNumber % 10;
      final need = 10 - onesDigit; // Amount needed to reach next 10
      final minSecond = need + 1; // Must be > need to have remainder
      final maxSecond = min(15, minSecond + 8); // Keep reasonable range
      
      secondNumber = _random.nextInt(maxSecond - minSecond + 1) + minSecond;
      
    } while (!_isValidCrossingAddition(firstNumber, secondNumber));

    final answer = firstNumber + secondNumber;
    final bondSteps = _generateAdditionBondSteps(firstNumber, secondNumber);
    
    print('🎯 Level 1 Addition (Standard Crossing): $firstNumber + $secondNumber = $answer');
    return _createProblemMap(firstNumber, secondNumber, '+', answer, bondSteps);
  }
  
  /// Stretch problems: bigger single-digit additions at edge of Level 1
  static Map<String, dynamic> _generateLevel1StretchAddition() {
    // Challenging single-digit combinations: 8+9, 7+8, 6+9, etc.
    final stretchCombos = [
      [8, 9], [9, 8], [7, 8], [8, 7], [6, 9], [9, 6],
      [7, 9], [9, 7], [6, 8], [8, 6], [5, 9], [9, 5]
    ];
    
    final combo = stretchCombos[_random.nextInt(stretchCombos.length)];
    final firstNumber = combo[0];
    final secondNumber = combo[1];
    final answer = firstNumber + secondNumber;
    
    final bondSteps = 'Stretch strategy: $firstNumber + $secondNumber = ${firstNumber + (10 - firstNumber)} + ${secondNumber - (10 - firstNumber)} = 10 + ${answer - 10} = $answer';
    
    print('🎯 Level 1 Addition (Stretch): $firstNumber + $secondNumber = $answer');
    return _createProblemMap(firstNumber, secondNumber, '+', answer, bondSteps);
  }
  
  /// Review problems: easier variations from previous successes
  static Map<String, dynamic> _generateLevel1ReviewAddition() {
    // Easier make-ten combinations for review
    final reviewCombos = [
      [6, 5], [5, 6], [7, 4], [4, 7], [8, 3], [3, 8],
      [9, 2], [2, 9], [6, 6], [7, 5], [5, 7], [8, 4]
    ];
    
    final combo = reviewCombos[_random.nextInt(reviewCombos.length)];
    final firstNumber = combo[0];
    final secondNumber = combo[1];
    final answer = firstNumber + secondNumber;
    
    final bondSteps = 'Review strategy: $firstNumber + $secondNumber = $answer (building confidence!)';
    
    print('🎯 Level 1 Addition (Review): $firstNumber + $secondNumber = $answer');
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
    // Enhanced Level 1 Subtraction: Mix of problems like addition
    final problemType = _random.nextInt(10); // 0-9 for different problem types
    
    if (problemType < 2) {
      // 20% chance: Stretch problems (harder subtractions)
      return _generateLevel1StretchSubtraction();
    } else if (problemType < 4) {
      // 20% chance: Review problems (easier variations)
      return _generateLevel1ReviewSubtraction();
    } else {
      // 60% chance: Standard Level 1 crossing subtraction
      return _generateLevel1StandardSubtraction();
    }
  }
  
  /// Standard Level 1 crossing subtraction
  static Map<String, dynamic> _generateLevel1StandardSubtraction() {
    print('🔧 _generateLevel1StandardSubtraction called');
    // Generate valid crossing subtraction for Level 1
    int firstNumber = _random.nextInt(10) + 11; // 11-20 for Level 1
    int secondNumber = 2; // Initialize with default
    int attempts = 0;
    
    print('🔧 Starting with firstNumber: $firstNumber');
    
    do {
      attempts++;
      if (attempts > 20) {
        firstNumber = _random.nextInt(10) + 11; // Regenerate if stuck
        attempts = 0;
        print('🔧 Regenerated firstNumber: $firstNumber');
      }
      
      final onesDigit = firstNumber % 10;
      // secondNumber must be > onesDigit for valid crossing
      final minSecond = onesDigit + 1;
      final maxSecond = min(9, firstNumber - 1);
      
      print('🔧 onesDigit: $onesDigit, minSecond: $minSecond, maxSecond: $maxSecond');
      
      if (minSecond > maxSecond) {
        // No valid crossing possible for this firstNumber, try another
        firstNumber = _random.nextInt(10) + 11;
        secondNumber = 2; // Reset default
        print('🔧 No valid crossing, trying new firstNumber: $firstNumber');
        continue;
      }
      
      secondNumber = _random.nextInt(maxSecond - minSecond + 1) + minSecond;
      print('🔧 Generated secondNumber: $secondNumber');
      
    } while (!_isValidCrossingSubtraction(firstNumber, secondNumber));

    final answer = firstNumber - secondNumber;
    final bondSteps = _generateSimpleSubtractionBondSteps(firstNumber, secondNumber);
    
    print('🎯 Level 1 Subtraction (Valid Crossing): $firstNumber - $secondNumber = $answer');
    return _createProblemMap(firstNumber, secondNumber, '-', answer, bondSteps);
  }
  
  /// Stretch problems: bigger subtraction challenges at edge of Level 1
  static Map<String, dynamic> _generateLevel1StretchSubtraction() {
    // Challenging subtractions: 20-8, 19-7, 18-9, etc.
    final stretchCombos = [
      [20, 8], [19, 7], [18, 9], [17, 8], [16, 9], [15, 8],
      [20, 9], [19, 8], [18, 7], [17, 9], [16, 7], [15, 9]
    ];
    
    final combo = stretchCombos[_random.nextInt(stretchCombos.length)];
    final firstNumber = combo[0];
    final secondNumber = combo[1];
    final answer = firstNumber - secondNumber;
    
    final bondSteps = 'Stretch strategy: $firstNumber - $secondNumber = crossing tens to get $answer';
    
    print('🎯 Level 1 Subtraction (Stretch): $firstNumber - $secondNumber = $answer');
    return _createProblemMap(firstNumber, secondNumber, '-', answer, bondSteps);
  }
  
  /// Review problems: easier subtraction variations
  static Map<String, dynamic> _generateLevel1ReviewSubtraction() {
    // ONLY valid crossing subtractions for review - secondNumber > onesDigit
    final reviewCombos = [
      [15, 6], [14, 5], [16, 7], [17, 8], [18, 9], // Valid crossing
      [12, 3], [12, 4], [13, 4], [13, 5], [14, 6]  // Valid crossing
    ];
    
    final combo = reviewCombos[_random.nextInt(reviewCombos.length)];
    final firstNumber = combo[0];
    final secondNumber = combo[1];
    final answer = firstNumber - secondNumber;
    
    final bondSteps = 'Review strategy: $firstNumber - $secondNumber = $answer (building confidence!)';
    
    print('🎯 Level 1 Subtraction (Review): $firstNumber - $secondNumber = $answer');
    return _createProblemMap(firstNumber, secondNumber, '-', answer, bondSteps);
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
  
  /// Generate Level 1 simple subtraction: two-digit minus single digit
  static Map<String, dynamic> _generateLevel1SimpleSubtraction() {
    // Generate two-digit number (10-19 for easier Level 1)
    int firstNumber = _random.nextInt(10) + 10; // 10-19
    
    // Generate single digit (1-9, but not larger than firstNumber)
    int secondNumber = _random.nextInt(min(9, firstNumber - 1)) + 1; // 1 to min(9, firstNumber-1)
    
    final answer = firstNumber - secondNumber;
    final bondSteps = _generateSimpleSubtractionBondSteps(firstNumber, secondNumber);
    
    print('🎯 Level 1 Subtraction (Simple): $firstNumber - $secondNumber = $answer');
    return _createProblemMap(firstNumber, secondNumber, '-', answer, bondSteps);
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
        // SIMPLE RULE: For valid crossing, secondNumber must be > onesDigit
        // Example: 18 needs secondNumber > 8, so minimum is 9
        final minSubtraction = firstNumberOnes + 1; // Must be > onesDigit to force crossing
        final maxSubtraction = min(18, firstNumber - 1); // Don't exceed firstNumber
        
        if (maxSubtraction >= minSubtraction) {
          secondNumber = _random.nextInt(maxSubtraction - minSubtraction + 1) + minSubtraction;
        } else {
          // If we can't generate a valid crossing problem, regenerate firstNumber
          continue;
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
      
      if (_isValidCrossingSubtraction(firstNumber, secondNumber)) {
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
    final onesDigit = firstNumber % 10;
    final need = 10 - onesDigit; // Amount needed to reach next 10
    final remainder = secondNumber - need;
    final nextTen = ((firstNumber ~/ 10) + 1) * 10;
    final finalAnswer = firstNumber + secondNumber;
    
    // Follow the crossing addition breakdown format
    // Example: 45 + 12 → Break 12 = 5 + 7 → 45 + 5 = 50 → 50 + 7 = 57
    return 'Crossing strategy: $firstNumber + $secondNumber = $firstNumber + $need + $remainder = $nextTen + $remainder = $finalAnswer';
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
  
  /// Validate if an addition problem is suitable for crossing strategy
  static bool _isValidCrossingAddition(int firstNumber, int secondNumber) {
    final onesDigit = firstNumber % 10;
    final need = 10 - onesDigit; // Amount needed to reach next 10
    
    // Rules for valid crossing addition:
    // 1. secondNumber must be > need (to have remainder after crossing)
    // 2. secondNumber cannot equal need (must have remainder to break down)
    // 3. Must actually cross a ten boundary
    
    if (secondNumber < need) return false;  // Doesn't cross 10
    if (secondNumber == need) return false; // No remainder to break down
    
    return true;
  }

  /// Validate if a subtraction problem is suitable for crossing strategy
  static bool _isValidCrossingSubtraction(int firstNumber, int secondNumber) {
    final onesDigit = firstNumber % 10;
    final result = firstNumber - secondNumber;
    
    // Rules for valid crossing subtraction:
    // 1. secondNumber must be > onesDigit (to force crossing)
    // 2. Result must be positive  
    // 3. First number must be > 10 (multi-digit)
    // 4. secondNumber must be large enough to be meaningfully broken down (>= 6)
    // 5. Must actually cross a ten boundary
    
    if (firstNumber <= 10) return false;  // Must be multi-digit
    if (secondNumber <= onesDigit) return false;  // Must require crossing
    if (result <= 0) return false;  // Must be positive
    if (secondNumber < 6) return false;  // Too small to break down meaningfully
    
    // Check if it actually crosses a ten boundary
    final nextLowerTen = (firstNumber ~/ 10) * 10;
    return result < nextLowerTen;
  }

  static String _generateSimpleSubtractionBondSteps(int firstNumber, int secondNumber) {
    // For Level 1 simple subtraction, provide basic counting steps
    final onesDigit = firstNumber % 10;
    final tensDigit = firstNumber ~/ 10;
    
    if (secondNumber <= onesDigit) {
      // Simple subtraction within the ones place
      return 'Count back: $firstNumber → ${firstNumber - secondNumber}';
    } else {
      // Valid crossing subtraction: split secondNumber into (onesDigit + remainder)
      final remainder = secondNumber - onesDigit;
      return 'Crossing strategy: $firstNumber - $secondNumber = $firstNumber - $onesDigit - $remainder = ${firstNumber - onesDigit} - $remainder = ${firstNumber - secondNumber}';
    }
  }
}
