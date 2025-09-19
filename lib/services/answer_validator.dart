/// ANSWER VALIDATOR
/// Validates user's number bond breakdown answers
class AnswerValidator {
  
  /// Main validation function
  /// Input: number1 (first operand), number2 (second operand), action ('addition' or 'subtraction')
  /// userPart1 and userPart2 are what the user put in the circles
  /// Output: ValidationResult with success/failed and proposed solution
  static ValidationResult validateAnswer({
    required int number1,
    required int number2,
    required String action,
    required int userPart1,
    required int userPart2,
  }) {
    
    if (action == 'subtraction') {
      return _validateSubtraction(number1, number2, userPart1, userPart2);
    } else if (action == 'addition') {
      return _validateAddition(number1, number2, userPart1, userPart2);
    } else {
      return ValidationResult(
        success: false,
        message: 'Invalid action: $action',
        proposedSolution: '',
      );
    }
  }
  
  /// Validate subtraction answer (from first release logic)
  static ValidationResult _validateSubtraction(int number1, int number2, int userPart1, int userPart2) {
    // Rule 1: Math must be correct - parts must add up to second number
    final mathCorrect = userPart1 + userPart2 == number2;
    
    // Rule 2: Order must be correct - enhanced for crossing strategy
    final onesDigit = number1 % 10;
    bool orderCorrect = false;
    
    if (onesDigit == 0) {
      // Special case for numbers ending in 0 (like 80, 90, etc.)
      // For crossing strategy, we want to subtract to cross the ten boundary
      // 80 - 12: break 12 into 10 + 2, so 80 - 10 = 70, then 70 - 2 = 68
      orderCorrect = userPart1 == 10 || userPart1 == (number2 ~/ 2); // Accept 10 or even split
    } else {
      // Standard rule: first part must be ones digit of first number
      orderCorrect = userPart1 == onesDigit;
    }
    
    final success = mathCorrect && orderCorrect;
    
    // Generate proposed solution
    final correctBreakdown = _generateCorrectSubtractionBreakdown(number1, number2);
    
    String message;
    if (success) {
      message = 'Correct! $number2 = $userPart1 + $userPart2';
    } else if (!mathCorrect) {
      message = 'Math error: $userPart1 + $userPart2 = ${userPart1 + userPart2}, but should equal $number2';
    } else if (!orderCorrect) {
      if (onesDigit == 0) {
        message = 'For numbers ending in 0, try breaking into 10 + remaining or use even split';
      } else {
        message = 'Order error: First number should be $onesDigit (ones digit of $number1)';
      }
    } else {
      message = 'Try again!';
    }
    
    return ValidationResult(
      success: success,
      message: message,
      proposedSolution: correctBreakdown,
    );
  }
  
  /// Validate addition answer
  static ValidationResult _validateAddition(int number1, int number2, int userPart1, int userPart2) {
    // For addition, just check if the breakdown is mathematically correct
    final mathCorrect = userPart1 + userPart2 == number2;
    
    final correctBreakdown = _generateCorrectAdditionBreakdown(number1, number2);
    
    String message;
    if (mathCorrect) {
      message = 'Correct! $number2 = $userPart1 + $userPart2';
    } else {
      message = 'Math error: $userPart1 + $userPart2 = ${userPart1 + userPart2}, but should equal $number2';
    }
    
    return ValidationResult(
      success: mathCorrect,
      message: message,
      proposedSolution: correctBreakdown,
    );
  }
  
  /// Generate correct subtraction breakdown (enhanced for crossing strategy)
  static String _generateCorrectSubtractionBreakdown(int number1, int number2) {
    final onesDigit = number1 % 10;
    
    if (onesDigit == 0 && number2 > 10) {
      // Special case for numbers ending in 0: use crossing strategy
      // 80 - 12: break 12 into 10 + 2, so 80 - 10 = 70, then 70 - 2 = 68
      final firstPart = 10;
      final secondPart = number2 - 10;
      return '$number2 → $firstPart + $secondPart\nThen: $number1 - $firstPart - $secondPart = ${number1 - firstPart} - $secondPart = ${number1 - number2}';
    } else if (onesDigit > 0 && onesDigit <= number2) {
      // Standard strategy: first part = ones digit, second part = remainder
      final firstPart = onesDigit;
      final secondPart = number2 - onesDigit;
      return '$number2 → $firstPart + $secondPart\nThen: $number1 - $firstPart - $secondPart = ${number1 - firstPart} - $secondPart = ${number1 - number2}';
    } else {
      // Fallback: even split
      final half1 = number2 ~/ 2;
      final half2 = number2 - half1;
      return '$number2 → $half1 + $half2\nThen: $number1 - $half1 - $half2 = ${number1 - half1} - $half2 = ${number1 - number2}';
    }
  }
  
  /// Generate correct addition breakdown
  static String _generateCorrectAdditionBreakdown(int number1, int number2) {
    final onesDigit = number1 % 10;
    final neededToMakeTen = 10 - onesDigit;
    
    if (neededToMakeTen > 0 && neededToMakeTen <= number2) {
      // Make ten strategy
      final firstPart = neededToMakeTen;
      final secondPart = number2 - neededToMakeTen;
      return '$number2 → $firstPart + $secondPart\nThen: $number1 + $firstPart + $secondPart = ${number1 + firstPart} + $secondPart = ${number1 + number2}';
    } else {
      // Simple breakdown
      final half1 = number2 ~/ 2;
      final half2 = number2 - half1;
      return '$number2 → $half1 + $half2\nThen: $number1 + $half1 + $half2 = ${number1 + half1} + $half2 = ${number1 + number2}';
    }
  }
}

/// Result of answer validation
class ValidationResult {
  final bool success;
  final String message;
  final String proposedSolution;
  
  const ValidationResult({
    required this.success,
    required this.message,
    required this.proposedSolution,
  });
  
  @override
  String toString() {
    return 'ValidationResult(success: $success, message: $message)';
  }
}


