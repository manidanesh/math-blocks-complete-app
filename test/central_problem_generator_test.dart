import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:number_bond_math/services/answer_validator.dart';
import 'package:number_bond_math/services/central_problem_generator.dart';

Map<String, dynamic> _generate({required int level, required String action}) {
  return runZoned(
    () => CentralProblemGenerator.generateProblem(level: level, action: action),
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, message) {},
    ),
  );
}

class _ScriptedRandom implements Random {
  final List<int> _values;

  _ScriptedRandom(List<int> values) : _values = List<int>.of(values);

  @override
  int nextInt(int max) {
    if (max <= 0) throw RangeError.value(max, 'max');
    final value = _values.removeAt(0);
    if (value < 0 || value >= max) throw RangeError.range(value, 0, max - 1);
    return value;
  }

  @override
  bool nextBool() => throw StateError('Unexpected nextBool call');

  @override
  double nextDouble() => throw StateError('Unexpected nextDouble call');
}

void main() {
  setUp(() => CentralProblemGenerator.setRandomForTesting(Random(20261010)));
  tearDown(() => CentralProblemGenerator.setRandomForTesting(Random()));

  test('level 2 addition skips first operands ending in zero or one', () {
    CentralProblemGenerator.setRandomForTesting(_ScriptedRandom([0, 1, 2, 0]));
    final problem = _generate(level: 2, action: 'addition');
    expect(problem['operand1'], 12);
    expect(problem['operand2'], 9);
    expect(problem['correctAnswer'], 21);
  });

  test(
    'level 3 addition retains a remainder for an exact-ten first operand',
    () {
      CentralProblemGenerator.setRandomForTesting(_ScriptedRandom([0, 0]));
      final problem = _generate(level: 3, action: 'addition');
      expect(problem['operand1'], 10);
      expect(problem['operand2'], 11);
      expect(problem['correctAnswer'], 21);
    },
  );

  test('level 4 addition still permits an exact-hundred first operand', () {
    CentralProblemGenerator.setRandomForTesting(_ScriptedRandom([0, 0]));
    final problem = _generate(level: 4, action: 'addition');
    expect(problem['operand1'], 100);
    expect(problem['operand2'], 11);
    expect(problem['correctAnswer'], 111);
  });

  test(
    'level 3 excludes ten as the second operand without excluding eleven',
    () {
      CentralProblemGenerator.setRandomForTesting(_ScriptedRandom([1, 0]));
      final problem = _generate(level: 3, action: 'addition');
      expect(problem['operand1'], 11);
      expect(problem['operand2'], 11);
      expect(problem['correctAnswer'], 22);
    },
  );

  test(
    'every level 1 stretch subtraction offers an accepted decomposition',
    () {
      for (var index = 0; index < 9; index++) {
        CentralProblemGenerator.setRandomForTesting(
          _ScriptedRandom([0, index]),
        );
        final problem = _generate(level: 1, action: 'subtraction');
        final first = problem['operand1'] as int;
        final second = problem['operand2'] as int;
        final suggestions = AnswerValidator.suggestedBreakdowns(
          number1: first,
          number2: second,
          action: 'subtraction',
        );
        expect(suggestions, isNotEmpty, reason: '$first - $second');
        for (final parts in suggestions) {
          expect(
            AnswerValidator.validateParts(
              number1: first,
              number2: second,
              action: 'subtraction',
              userParts: parts,
            ).success,
            isTrue,
            reason: '$first - $second with $parts',
          );
        }
      }
    },
  );

  test(
    'level 1 standard teaching uses the accepted boundary decomposition',
    () {
      CentralProblemGenerator.setRandomForTesting(_ScriptedRandom([4, 4, 2]));
      final problem = _generate(level: 1, action: 'subtraction');
      expect(problem['operand1'], 15);
      expect(problem['operand2'], 8);
      expect(
        problem['bondSteps'],
        'Crossing strategy: 15 - 8 = 15 - 5 - 3 = 10 - 3 = 7',
      );
    },
  );

  group('Level 4 three-digit second operands', () {
    test('addition crosses a ten with a positive remainder', () {
      var sawHundreds = false;
      for (var index = 0; index < 200; index++) {
        final problem = _generate(level: 4, action: 'addition');
        final first = problem['operand1'] as int;
        final second = problem['operand2'] as int;
        final answer = problem['correctAnswer'] as int;
        final need = 10 - first % 10;
        expect(first, inInclusiveRange(100, 999));
        expect(second, inInclusiveRange(need + 1, 999));
        expect(answer, first + second);
        expect(problem['operator'], '+');
        expect(second - need, greaterThan(0));
        expect(problem['bondSteps'], contains('= $answer'));
        sawHundreds = sawHundreds || second >= 100;
      }
      expect(sawHundreds, isTrue);
    });

    test('subtraction crosses a ten and retains a positive answer', () {
      var sawHundreds = false;
      for (var index = 0; index < 200; index++) {
        final problem = _generate(level: 4, action: 'subtraction');
        final first = problem['operand1'] as int;
        final second = problem['operand2'] as int;
        final answer = problem['correctAnswer'] as int;
        expect(first, inInclusiveRange(100, 999));
        expect(first % 10, isNot(0));
        expect(second, inInclusiveRange(6, first - 1));
        expect(second, greaterThan(first % 10));
        expect(answer, first - second);
        expect(answer, greaterThan(0));
        expect(answer, lessThan(first - first % 10));
        expect(problem['operator'], '-');
        sawHundreds = sawHundreds || second >= 100;
      }
      expect(sawHundreds, isTrue);
    });
  });

  test('earlier subtraction levels keep their original second-operand cap', () {
    for (final level in [2, 3]) {
      for (var index = 0; index < 100; index++) {
        final problem = _generate(level: level, action: 'subtraction');
        final first = problem['operand1'] as int;
        final second = problem['operand2'] as int;
        expect(first, inInclusiveRange(level == 2 ? 20 : 50, 99));
        expect(first % 10, isNot(0));
        expect(second, inInclusiveRange(6, 18));
        expect(second, greaterThan(first % 10));
        expect(problem['correctAnswer'], first - second);
      }
    }
  });

  test(
    '4,000 seeded problems have correct arithmetic and accepted corrections',
    () {
      for (var level = 1; level <= 4; level++) {
        for (final action in ['addition', 'subtraction']) {
          for (var index = 0; index < 500; index++) {
            final problem = _generate(level: level, action: action);
            final first = problem['operand1'] as int;
            final second = problem['operand2'] as int;
            final answer = problem['correctAnswer'] as int;
            expect(
              second,
              isNot(isIn([10, 100, 1000])),
              reason:
                  'Level $level $action must exclude exact powers of ten only as second operands.',
            );
            expect(
              answer,
              action == 'addition' ? first + second : first - second,
            );
            expect(answer, greaterThan(0));
            if (action == 'addition') {
              expect(second, greaterThan(10 - first % 10));
            }
            final suggestions = AnswerValidator.suggestedBreakdowns(
              number1: first,
              number2: second,
              action: action,
            );
            expect(suggestions, isNotEmpty, reason: '$first $action $second');
            for (final parts in suggestions) {
              expect(
                AnswerValidator.validateParts(
                  number1: first,
                  number2: second,
                  action: action,
                  userParts: parts,
                ).success,
                isTrue,
                reason: '$first $action $second with $parts',
              );
            }
            final incorrect = AnswerValidator.validateParts(
              number1: first,
              number2: second,
              action: action,
              userParts: [1, second],
            );
            expect(incorrect.success, isFalse);
            expect(
              AnswerValidator.validateParts(
                number1: first,
                number2: second,
                action: action,
                userParts: incorrect.solutionParts,
              ).success,
              isTrue,
              reason:
                  '$first $action $second corrects to ${incorrect.solutionParts}',
            );
            expect(incorrect.proposedSolution, endsWith('= $answer'));
          }
        }
      }
    },
  );
}
