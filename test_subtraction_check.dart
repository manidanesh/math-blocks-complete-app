import 'dart:io';
import 'dart:math';

import 'lib/services/answer_validator.dart';
import 'lib/services/central_problem_generator.dart';

/// A deterministic CLI check of the app's actual subtraction generator.
void main() {
  CentralProblemGenerator.setRandomForTesting(Random(20261012));
  var checked = 0;
  for (var level = 1; level <= 4; level++) {
    for (var sample = 0; sample < 100; sample++) {
      final problem = CentralProblemGenerator.generateProblem(
        action: 'subtraction',
        level: level,
      );
      final first = problem['operand1'] as int;
      final second = problem['operand2'] as int;
      final answer = problem['correctAnswer'] as int;
      final crossesTen = answer < first - first % 10;
      final supportedStretch =
          level == 1 && first == 20 && (second == 8 || second == 9);
      if (answer != first - second ||
          answer <= 0 ||
          (first % 10 == 0 ? !supportedStretch : !crossesTen)) {
        throw StateError('Invalid Level $level subtraction: $problem');
      }
      final splits = AnswerValidator.suggestedBreakdowns(
        number1: first,
        number2: second,
        action: 'subtraction',
      );
      if (splits.isEmpty ||
          splits.any(
            (parts) => !AnswerValidator.validateParts(
              number1: first,
              number2: second,
              action: 'subtraction',
              userParts: parts,
            ).success,
          )) {
        throw StateError('Rejected subtraction split: $problem; $splits');
      }
      checked++;
    }
  }
  stdout.writeln(
    'Validated $checked generated subtraction problems across all four levels.',
  );
}
