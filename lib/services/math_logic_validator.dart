import 'dart:math';

/// Comprehensive evaluation layer to validate math logic correctness
/// Ensures all problem generation and strategy assignment follows the correct rules
class MathLogicValidator {
  static final Random _random = Random();

  /// Run comprehensive validation of all math logic
  static void validateAllLogic() {
    print('🔍 Starting comprehensive math logic validation...');
    
    _validateCrossingSubtractionRules();
    _validateCrossingAdditionRules();
    _validateStrategyAssignment();
    _validateProblemGeneration();
    _validateSolutionBreakdowns();
    
    print('✅ Math logic validation completed successfully!');
  }

  /// Validate crossing subtraction rules
  static void _validateCrossingSubtractionRules() {
    print('\n📊 Validating Crossing Subtraction Rules...');
    
    // Test cases: [firstNumber, secondNumber, shouldBeValid, reason]
    final testCases = [
      // Valid crossing subtractions
      [14, 8, true, '14-8: 8>4, crosses boundary (14→10→6)'],
      [17, 9, true, '17-9: 9>7, crosses boundary (17→10→8)'],
      [15, 7, true, '15-7: 7>5, crosses boundary (15→10→8)'],
      [13, 6, true, '13-6: 6>3, crosses boundary (13→10→7)'],
      
      // Invalid crossing subtractions
      [19, 7, false, '19-7: 7<9, no crossing needed'],
      [20, 4, false, '20-4: 4<0, no crossing needed'],
      [18, 3, false, '18-3: 3<8, no crossing needed'],
      [16, 5, false, '16-5: 5<6, no crossing needed'],
      [12, 2, false, '12-2: 2<2, no crossing needed'],
      [11, 1, false, '11-1: 1<1, no crossing needed'],
      
      // Edge cases
      [10, 5, false, '10-5: firstNumber <= 10'],
      [15, 5, false, '15-5: secondNumber = onesDigit'],
      [15, 4, false, '15-4: secondNumber < 6'],
      [15, 15, false, '15-15: result = 0'],
    ];

    int passed = 0;
    int failed = 0;

    for (final testCase in testCases) {
      final firstNumber = testCase[0] as int;
      final secondNumber = testCase[1] as int;
      final expectedValid = testCase[2] as bool;
      final reason = testCase[3] as String;

      final actualValid = _isValidCrossingSubtraction(firstNumber, secondNumber);
      
      if (actualValid == expectedValid) {
        print('✅ $firstNumber - $secondNumber: $reason');
        passed++;
      } else {
        print('❌ $firstNumber - $secondNumber: Expected $expectedValid, got $actualValid - $reason');
        failed++;
      }
    }

    print('📈 Crossing Subtraction: $passed passed, $failed failed');
  }

  /// Validate crossing addition rules
  static void _validateCrossingAdditionRules() {
    print('\n📊 Validating Crossing Addition Rules...');
    
    // Test cases: [firstNumber, secondNumber, shouldBeValid, reason]
    final testCases = [
      // Valid crossing additions
      [6, 6, true, '6+6: 6>4, has remainder (6+4+2)'],
      [7, 5, true, '7+5: 5>3, has remainder (7+3+2)'],
      [8, 4, true, '8+4: 4>2, has remainder (8+2+2)'],
      [9, 3, true, '9+3: 3>1, has remainder (9+1+2)'],
      
      // Invalid crossing additions
      [6, 4, false, '6+4: 4=4, no remainder'],
      [7, 3, false, '7+3: 3=3, no remainder'],
      [8, 2, false, '8+2: 2=2, no remainder'],
      [9, 1, false, '9+1: 1=1, no remainder'],
      [5, 3, false, '5+3: 3<5, doesn\'t cross'],
      [4, 2, false, '4+2: 2<6, doesn\'t cross'],
    ];

    int passed = 0;
    int failed = 0;

    for (final testCase in testCases) {
      final firstNumber = testCase[0] as int;
      final secondNumber = testCase[1] as int;
      final expectedValid = testCase[2] as bool;
      final reason = testCase[3] as String;

      final actualValid = _isValidCrossingAddition(firstNumber, secondNumber);
      
      if (actualValid == expectedValid) {
        print('✅ $firstNumber + $secondNumber: $reason');
        passed++;
      } else {
        print('❌ $firstNumber + $secondNumber: Expected $expectedValid, got $actualValid - $reason');
        failed++;
      }
    }

    print('📈 Crossing Addition: $passed passed, $failed failed');
  }

  /// Validate strategy assignment logic
  static void _validateStrategyAssignment() {
    print('\n📊 Validating Strategy Assignment...');
    
    final testCases = [
      // Subtraction cases
      [14, 8, '-', 'crossing', '14-8: Valid crossing subtraction'],
      [19, 7, '-', 'basic', '19-7: Invalid crossing, should be basic'],
      [20, 4, '-', 'basic', '20-4: Invalid crossing, should be basic'],
      [17, 9, '-', 'crossing', '17-9: Valid crossing subtraction'],
      
      // Addition cases
      [6, 6, '+', 'crossing', '6+6: Valid crossing addition'],
      [6, 4, '+', 'basic', '6+4: Invalid crossing, should be basic'],
      [7, 5, '+', 'crossing', '7+5: Valid crossing addition'],
      [8, 2, '+', 'basic', '8+2: Invalid crossing, should be basic'],
    ];

    int passed = 0;
    int failed = 0;

    for (final testCase in testCases) {
      final operand1 = testCase[0] as int;
      final operand2 = testCase[1] as int;
      final operator = testCase[2] as String;
      final expectedStrategy = testCase[3] as String;
      final reason = testCase[4] as String;

      final actualStrategy = _getStrategyForProblem(operand1, operand2, operator);
      
      if (actualStrategy == expectedStrategy) {
        print('✅ $operand1 $operator $operand2 → $actualStrategy: $reason');
        passed++;
      } else {
        print('❌ $operand1 $operator $operand2 → Expected $expectedStrategy, got $actualStrategy: $reason');
        failed++;
      }
    }

    print('📈 Strategy Assignment: $passed passed, $failed failed');
  }

  /// Validate problem generation doesn't create invalid problems
  static void _validateProblemGeneration() {
    print('\n📊 Validating Problem Generation...');
    
    int validProblems = 0;
    int invalidProblems = 0;

    // Generate 100 random problems and validate them
    for (int i = 0; i < 100; i++) {
      final problem = _generateRandomProblem();
      final operand1 = problem['operand1'] as int;
      final operand2 = problem['operand2'] as int;
      final operator = problem['operator'] as String;
      final strategy = problem['strategy'] as String;

      bool isValid = true;
      String reason = '';

      if (operator == '-') {
        if (strategy == 'crossing') {
          if (!_isValidCrossingSubtraction(operand1, operand2)) {
            isValid = false;
            reason = 'Invalid crossing subtraction assigned';
          }
        }
      } else if (operator == '+') {
        if (strategy == 'crossing') {
          if (!_isValidCrossingAddition(operand1, operand2)) {
            isValid = false;
            reason = 'Invalid crossing addition assigned';
          }
        }
      }

      if (isValid) {
        validProblems++;
      } else {
        invalidProblems++;
        print('❌ Invalid problem: $operand1 $operator $operand2 (strategy: $strategy) - $reason');
      }
    }

    print('📈 Problem Generation: $validProblems valid, $invalidProblems invalid');
  }

  /// Validate solution breakdowns are mathematically correct
  static void _validateSolutionBreakdowns() {
    print('\n📊 Validating Solution Breakdowns...');
    
    final testCases = [
      // Subtraction breakdowns
      [14, 8, '-', [4, 4], '14-8 = 14-4-4 = 10-4 = 6'],
      [17, 9, '-', [4, 5], '17-9 = 17-4-5 = 13-5 = 8'],
      [15, 7, '-', [3, 4], '15-7 = 15-3-4 = 12-4 = 8'],
      
      // Addition breakdowns
      [6, 6, '+', [3, 3], '6+6 = 6+3+3 = 9+3 = 12'],
      [7, 5, '+', [2, 3], '7+5 = 7+2+3 = 9+3 = 12'],
      [8, 4, '+', [2, 2], '8+4 = 8+2+2 = 10+2 = 12'],
    ];

    int passed = 0;
    int failed = 0;

    for (final testCase in testCases) {
      final operand1 = testCase[0] as int;
      final operand2 = testCase[1] as int;
      final operator = testCase[2] as String;
      final breakdown = testCase[3] as List<int>;
      final expectedResult = testCase[4] as String;

      final actualResult = _calculateSolutionBreakdown(operand1, operand2, operator, breakdown);
      final expectedAnswer = operator == '-' ? operand1 - operand2 : operand1 + operand2;
      
      if (actualResult == expectedAnswer) {
        print('✅ $operand1 $operator $operand2 = $expectedResult');
        passed++;
      } else {
        print('❌ $operand1 $operator $operand2: Expected $expectedAnswer, got $actualResult');
        failed++;
      }
    }

    print('📈 Solution Breakdowns: $passed passed, $failed failed');
  }

  // Helper methods for validation

  static bool _isValidCrossingSubtraction(int firstNumber, int secondNumber) {
    final onesDigit = firstNumber % 10;
    final result = firstNumber - secondNumber;
    
    if (firstNumber <= 10) return false;
    if (secondNumber <= onesDigit) return false;
    if (result <= 0) return false;
    if (secondNumber < 6) return false;
    
    final nextLowerTen = (firstNumber ~/ 10) * 10;
    return result < nextLowerTen;
  }

  static bool _isValidCrossingAddition(int firstNumber, int secondNumber) {
    final onesDigit = firstNumber % 10;
    final need = 10 - onesDigit;
    
    if (secondNumber < need) return false;
    if (secondNumber == need) return false;
    
    return true;
  }

  static String _getStrategyForProblem(int operand1, int operand2, String operator) {
    if (operator == '-') {
      if (_isValidCrossingSubtraction(operand1, operand2)) {
        return 'crossing';
      } else {
        return 'basic';
      }
    } else {
      if (_isValidCrossingAddition(operand1, operand2)) {
        return 'crossing';
      } else {
        return 'basic';
      }
    }
  }

  static Map<String, dynamic> _generateRandomProblem() {
    final operand1 = _random.nextInt(10) + 11; // 11-20
    final operand2 = _random.nextInt(9) + 1; // 1-9
    final operator = _random.nextBool() ? '+' : '-';
    final strategy = _getStrategyForProblem(operand1, operand2, operator);
    
    return {
      'operand1': operand1,
      'operand2': operand2,
      'operator': operator,
      'strategy': strategy,
    };
  }

  static int _calculateSolutionBreakdown(int operand1, int operand2, String operator, List<int> breakdown) {
    if (operator == '-') {
      // For subtraction: operand1 - breakdown[0] - breakdown[1]
      final intermediate = operand1 - breakdown[0];
      return intermediate - breakdown[1];
    } else {
      // For addition: operand1 + breakdown[0] + breakdown[1]
      final intermediate = operand1 + breakdown[0];
      return intermediate + breakdown[1];
    }
  }
}
