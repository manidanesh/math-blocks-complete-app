import 'answer_validator.dart';
import 'math_logic_validator.dart';

/// Debug diagnostics share the production generator and answer rules.
class DebugValidator {
  static String runValidation() =>
      'Validated ${MathLogicValidator.validateAllLogic()} generated problems.';

  static String validateProblem(int operand1, int operand2, String operator) {
    if (operator != '+' && operator != '-') {
      return 'Unsupported operator: $operator';
    }
    final action = operator == '+' ? 'addition' : 'subtraction';
    final splits = AnswerValidator.suggestedBreakdowns(
      number1: operand1,
      number2: operand2,
      action: action,
    );
    if (splits.isEmpty) {
      return 'No supported number-bond split for $operand1 $operator $operand2.';
    }
    return splits
        .map((parts) {
          final result = AnswerValidator.validateParts(
            number1: operand1,
            number2: operand2,
            action: action,
            userParts: parts,
          );
          if (!result.success) {
            throw StateError('Rejected suggested split: $parts');
          }
          return result.proposedSolution;
        })
        .join('\n');
  }
}
