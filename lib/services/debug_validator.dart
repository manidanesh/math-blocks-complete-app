import 'math_logic_validator.dart';

/// Debug utility to validate math logic from within the app
class DebugValidator {
  /// Run validation and return results as a string
  static String runValidation() {
    final buffer = StringBuffer();
    
    // Run validation and capture output
    MathLogicValidator.validateAllLogic();
    
    return buffer.toString();
  }
  
  /// Quick validation of a specific problem
  static String validateProblem(int operand1, int operand2, String operator) {
    final buffer = StringBuffer();
    
    buffer.writeln('🔍 Validating: $operand1 $operator $operand2');
    
    if (operator == '-') {
      final isValidCrossing = _isValidCrossingSubtraction(operand1, operand2);
      buffer.writeln('   Crossing subtraction valid: $isValidCrossing');
      
      if (isValidCrossing) {
        final half = operand2 ~/ 2;
        final otherHalf = operand2 - half;
        final intermediate = operand1 - half;
        final finalResult = intermediate - otherHalf;
        buffer.writeln('   Breakdown: $operand2 = $half + $otherHalf');
        buffer.writeln('   Steps: $operand1 - $half = $intermediate');
        buffer.writeln('   Final: $intermediate - $otherHalf = $finalResult');
        buffer.writeln('   Expected: ${operand1 - operand2}');
        buffer.writeln('   Correct: ${finalResult == operand1 - operand2}');
      }
    } else {
      final isValidCrossing = _isValidCrossingAddition(operand1, operand2);
      buffer.writeln('   Crossing addition valid: $isValidCrossing');
      
      if (isValidCrossing) {
        final half = operand2 ~/ 2;
        final otherHalf = operand2 - half;
        final intermediate = operand1 + half;
        final finalResult = intermediate + otherHalf;
        buffer.writeln('   Breakdown: $operand2 = $half + $otherHalf');
        buffer.writeln('   Steps: $operand1 + $half = $intermediate');
        buffer.writeln('   Final: $intermediate + $otherHalf = $finalResult');
        buffer.writeln('   Expected: ${operand1 + operand2}');
        buffer.writeln('   Correct: ${finalResult == operand1 + operand2}');
      }
    }
    
    return buffer.toString();
  }
  
  // Helper methods (copied from MathLogicValidator for standalone use)
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
}
