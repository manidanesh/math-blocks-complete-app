/// Decoupled Number Bond Validation Service
/// Handles all validation logic independently from UI
class NumberBondValidator {
  
  /// Validates a number bond breakdown for subtraction problems
  /// Returns ValidationResult with success status and details
  static ValidationResult validateSubtractionBond({
    required int firstNumber,
    required int secondNumber,
    required int userPart1,
    required int userPart2,
  }) {
    
    // Rule 1: Mathematical correctness - parts must add up to the second number
    final mathematicallyCorrect = userPart1 + userPart2 == secondNumber;
    
    // Rule 2: Strategy correctness - check both possible arrangements
    final onesDigit = firstNumber % 10;
    final strategyCorrect = userPart1 == onesDigit || userPart2 == onesDigit;
    
    // Rule 3: Problem validity - result should cross ten boundary
    final result = firstNumber - secondNumber;
    final nextLowerTen = onesDigit == 0 ? firstNumber - 10 : firstNumber - onesDigit;
    final crossesTen = result < nextLowerTen;
    
    // For now, just check mathematical correctness since problem generation ensures validity
    final isValid = mathematicallyCorrect;
    
    return ValidationResult(
      isValid: isValid,
      mathematicallyCorrect: mathematicallyCorrect,
      strategyCorrect: strategyCorrect,
      crossesTen: crossesTen,
      expectedFirstPart: onesDigit,
      expectedSecondPart: secondNumber - onesDigit,
      explanation: _generateExplanation(firstNumber, secondNumber, userPart1, userPart2),
    );
  }
  
  /// Validates if a subtraction problem should be generated
  static bool isValidSubtractionProblem({
    required int firstNumber,
    required int secondNumber,
  }) {
    final onesDigit = firstNumber % 10;
    final result = firstNumber - secondNumber;
    
    // Rules for valid crossing subtraction:
    // 1. secondNumber must be > onesDigit (to force crossing)
    // 2. secondNumber must be >= 6 (large enough to break down meaningfully)
    // 3. result must be positive
    // 4. firstNumber must be > 10 (multi-digit)
    // 5. Must actually cross a ten boundary
    
    if (firstNumber <= 10) return false;  // Must be multi-digit
    if (secondNumber <= onesDigit) return false;  // Must require crossing
    if (result <= 0) return false;  // Must be positive
    if (secondNumber < 6) return false;  // Too small to break down meaningfully
    
    // Check if it actually crosses a ten boundary
    final nextLowerTen = (firstNumber ~/ 10) * 10;
    return result < nextLowerTen;
  }
  
  /// Generates correct breakdown for a subtraction problem
  static NumberBondBreakdown generateCorrectBreakdown({
    required int firstNumber,
    required int secondNumber,
  }) {
    final onesDigit = firstNumber % 10;
    
    if (onesDigit > 0 && onesDigit <= secondNumber) {
      // Standard strategy: break to reach next lower ten
      return NumberBondBreakdown(
        firstPart: onesDigit,
        secondPart: secondNumber - onesDigit,
        explanation: '$secondNumber → $onesDigit + ${secondNumber - onesDigit}',
      );
    } else {
      // Fallback: even split or simple breakdown
      if (secondNumber % 2 == 0) {
        final half = secondNumber ~/ 2;
        return NumberBondBreakdown(
          firstPart: half,
          secondPart: half,
          explanation: '$secondNumber → $half + $half',
        );
      } else {
        return NumberBondBreakdown(
          firstPart: secondNumber - 1,
          secondPart: 1,
          explanation: '$secondNumber → ${secondNumber - 1} + 1',
        );
      }
    }
  }
  
  static String _generateExplanation(int firstNumber, int secondNumber, int userPart1, int userPart2) {
    final onesDigit = firstNumber % 10;
    final correctBreakdown = generateCorrectBreakdown(firstNumber: firstNumber, secondNumber: secondNumber);
    
    return '''
Problem: $firstNumber - $secondNumber
Your answer: $secondNumber → $userPart1 + $userPart2
Correct answer: ${correctBreakdown.explanation}

Strategy: Break the second number so the first part equals the ones digit ($onesDigit) of the first number.
This takes us to the next lower ten: $firstNumber - $userPart1 = ${firstNumber - userPart1}
''';
  }
}

/// Result of number bond validation
class ValidationResult {
  final bool isValid;
  final bool mathematicallyCorrect;
  final bool strategyCorrect;
  final bool crossesTen;
  final int expectedFirstPart;
  final int expectedSecondPart;
  final String explanation;
  
  const ValidationResult({
    required this.isValid,
    required this.mathematicallyCorrect,
    required this.strategyCorrect,
    required this.crossesTen,
    required this.expectedFirstPart,
    required this.expectedSecondPart,
    required this.explanation,
  });
  
  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, math: $mathematicallyCorrect, strategy: $strategyCorrect, crosses: $crossesTen)';
  }
}

/// Breakdown of a number bond
class NumberBondBreakdown {
  final int firstPart;
  final int secondPart;
  final String explanation;
  
  const NumberBondBreakdown({
    required this.firstPart,
    required this.secondPart,
    required this.explanation,
  });
}
