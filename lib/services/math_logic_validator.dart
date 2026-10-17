import 'answer_validator.dart';
import 'central_problem_generator.dart';

/// Diagnostic checks against the same generator and validator used by the app.
class MathLogicValidator {
  /// Returns checked problem count; throws with the actual failing equation.
  static int validateAllLogic({int samplesPerLevel = 100}) {
    if (samplesPerLevel < 1) {
      throw ArgumentError.value(samplesPerLevel, 'samplesPerLevel');
    }
    var checked = 0;
    for (var level = 1; level <= 4; level++) {
      for (final action in ['addition', 'subtraction']) {
        for (var sample = 0; sample < samplesPerLevel; sample++) {
          final problem = CentralProblemGenerator.generateProblem(
            level: level,
            action: action,
          );
          final first = problem['operand1'] as int;
          final second = problem['operand2'] as int;
          final answer = action == 'addition' ? first + second : first - second;
          if (problem['correctAnswer'] != answer || answer <= 0) {
            throw StateError('Incorrect generated answer: $problem');
          }
          final splits = AnswerValidator.suggestedBreakdowns(
            number1: first,
            number2: second,
            action: action,
          );
          if (splits.isEmpty ||
              splits.any(
                (parts) => !AnswerValidator.validateParts(
                  number1: first,
                  number2: second,
                  action: action,
                  userParts: parts,
                ).success,
              )) {
            throw StateError(
              'Unsolvable number bond: $problem; splits=$splits',
            );
          }
          checked++;
        }
      }
    }
    return checked;
  }
}
