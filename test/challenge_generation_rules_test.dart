import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:number_bond_math/services/challenge_generation_rules.dart';
import 'package:number_bond_math/services/problem_generator.dart';

class _IndexRandom implements Random {
  final int index;
  final List<int> bounds = [];

  _IndexRandom(this.index);

  @override
  int nextInt(int max) {
    bounds.add(max);
    if (bounds.length > 1) throw StateError('The chooser must not retry.');
    if (index < 0 || index >= max) throw RangeError.range(index, 0, max - 1);
    return index;
  }

  @override
  bool nextBool() => throw StateError('Unexpected nextBool call');

  @override
  double nextDouble() => throw StateError('Unexpected nextDouble call');
}

void main() {
  test('only exact second operands 10, 100 and 1000 are excluded', () {
    for (final number in [10, 100, 1000]) {
      expect(ChallengeGenerationRules.isAllowedSecondOperand(number), isFalse);
    }
    for (final number in [
      1,
      9,
      11,
      20,
      30,
      99,
      101,
      200,
      999,
      1001,
      2000,
      10000,
    ]) {
      expect(
        ChallengeGenerationRules.isAllowedSecondOperand(number),
        isTrue,
        reason: '$number is not an excluded exact value.',
      );
    }
  });

  for (final range in [(8, 12), (98, 102), (998, 1002), (1, 1002)]) {
    test(
      'each allowed value in ${range.$1}..${range.$2} has one uniform random index',
      () {
        final allowed = {
          for (var number = range.$1; number <= range.$2; number++)
            if (![10, 100, 1000].contains(number)) number,
        };
        final selected = <int>{};
        for (var index = 0; index < allowed.length; index++) {
          final random = _IndexRandom(index);
          final second = ChallengeGenerationRules.chooseSecondOperand(
            random,
            min: range.$1,
            max: range.$2,
          );
          expect(random.bounds, [allowed.length]);
          expect(
            selected.add(second),
            isTrue,
            reason: 'Index $index must select a distinct allowed value.',
          );
        }
        expect(selected, allowed);
      },
    );
  }

  for (final number in [11, 99, 101, 999, 1001, 20, 200, 2000]) {
    test('allowed singleton $number remains selectable', () {
      expect(
        ChallengeGenerationRules.chooseSecondOperand(
          _IndexRandom(0),
          min: number,
          max: number,
        ),
        number,
      );
    });
  }

  for (final number in [10, 100, 1000]) {
    test(
      'a range containing only excluded $number reports an invalid configuration',
      () {
        final random = _IndexRandom(0);
        expect(
          () => ChallengeGenerationRules.chooseSecondOperand(
            random,
            min: number,
            max: number,
          ),
          throwsArgumentError,
        );
        expect(random.bounds, isEmpty);
      },
    );
  }

  test('an inverted range is rejected before drawing randomness', () {
    final random = _IndexRandom(0);
    expect(
      () => ChallengeGenerationRules.chooseSecondOperand(
        random,
        min: 101,
        max: 99,
      ),
      throwsArgumentError,
    );
    expect(random.bounds, isEmpty);
  });

  test(
    'compatibility generator capped fallback preserves first ten and excludes second ten',
    () {
      // Level five's first operand is at least ten, so no allowed second operand
      // can satisfy makeTen's sum <= 20. This deterministically reaches fallback.
      final problem = ProblemGenerator.generateProblem(
        level: 5,
        strategy: ProblemStrategy.makeTen,
      );
      expect(problem.operand1, 10);
      expect(problem.operand2, inInclusiveRange(11, 25));
      expect(problem.operand2, isNot(isIn([10, 100, 1000])));
      expect(problem.correctAnswer, problem.operand1 + problem.operand2);
      expect(problem.operator, '+');
      expect(problem.level, 5);
    },
  );
}
