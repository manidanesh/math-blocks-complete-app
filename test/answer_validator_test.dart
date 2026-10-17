import 'package:flutter_test/flutter_test.dart';
import 'package:number_bond_math/services/answer_validator.dart';

void main() {
  ValidationResult validate(
    int first,
    int second,
    List<int> parts, {
    String action = 'subtraction',
  }) => AnswerValidator.validateParts(
    number1: first,
    number2: second,
    action: action,
    userParts: parts,
  );

  group('existing two-part answers', () {
    test('does not label arbitrary correct splits as making ten', () {
      final addition = validate(4, 14, [7, 7], action: 'addition');
      expect(addition.success, isTrue);
      expect(addition.method, BondMethod.basic);
      expect(addition.solutionParts, [7, 7]);
      final subtraction = validate(40, 15, [7, 8]);
      expect(subtraction.success, isTrue);
      expect(subtraction.method, BondMethod.basic);
    });
    test('keeps the two-circle API and addition acceptance', () {
      final makeTen = AnswerValidator.validateAnswer(
        number1: 4,
        number2: 14,
        action: 'addition',
        userPart1: 6,
        userPart2: 8,
      );
      expect(makeTen.success, isTrue);
      expect(makeTen.method, BondMethod.makeTen);
      expect(validate(4, 14, [7, 7], action: 'addition').success, isTrue);
      expect(validate(4, 14, [8, 6], action: 'addition').success, isTrue);
    });

    test('preserves subtraction boundary and zero-ending special cases', () {
      expect(validate(29, 15, [9, 6]).success, isTrue);
      expect(validate(40, 15, [7, 8]).success, isTrue);
      expect(validate(40, 15, [10, 5]).success, isTrue);
      expect(validate(40, 10, [5, 5]).success, isTrue);
      expect(validate(29, 15, [7, 8]).success, isFalse);
      // Only the new round-number methods are order independent.
      expect(validate(29, 15, [6, 9]).success, isFalse);
    });

    test('retains zero remainders accepted by the legacy boundary rule', () {
      final result = validate(29, 9, [9, 0]);
      expect(result.success, isTrue);
      expect(result.solutionParts, [9, 0]);
    });

    test('corrects a boundary-equal target to an accepted legacy split', () {
      final result = validate(129, 9, [4, 4]);
      expect(result.success, isFalse);
      expect(result.solutionParts, [9, 0]);
      expect(result.solutionParts.every((part) => part >= 0), isTrue);
      expect(validate(129, 9, result.solutionParts).success, isTrue);
    });
  });

  group('additional round-number methods', () {
    test('accepts tens splits in either order for both operations', () {
      for (final action in ['addition', 'subtraction']) {
        for (final parts in [
          [10, 14],
          [14, 10],
          [20, 4],
          [4, 20],
        ]) {
          final result = validate(34, 24, parts, action: action);
          expect(result.success, isTrue, reason: '$action $parts');
          expect(result.solutionParts, parts);
        }
        expect(validate(29, 15, [5, 10], action: action).success, isTrue);
        expect(validate(29, 15, [10, 5], action: action).success, isTrue);
        expect(validate(29, 20, [10, 10], action: action).success, isTrue);
      }
    });

    test('accepts hundreds without an upper eligibility limit', () {
      for (final action in ['addition', 'subtraction']) {
        expect(validate(250, 120, [100, 20], action: action).success, isTrue);
        expect(validate(250, 120, [20, 100], action: action).success, isTrue);
        expect(
          validate(1100, 1000, [900, 100], action: action).success,
          isTrue,
        );
        expect(validate(150, 100, [10, 90], action: action).success, isTrue);
      }
    });

    test('accepts all permutations of the three-place-value expansion', () {
      const permutations = [
        [200, 30, 5],
        [200, 5, 30],
        [30, 200, 5],
        [30, 5, 200],
        [5, 200, 30],
        [5, 30, 200],
      ];
      for (final action in ['addition', 'subtraction']) {
        for (final parts in permutations) {
          final result = validate(345, 235, parts, action: action);
          expect(result.success, isTrue, reason: '$action $parts');
          expect(result.method, BondMethod.placeValue);
          expect(result.solutionParts, parts);
        }
      }
    });

    test('does not accept arbitrary ones partitions for subtraction', () {
      expect(validate(29, 15, [7, 8]).success, isFalse);
      expect(validate(345, 235, [200, 30, 3, 2]).success, isFalse);
      expect(validate(345, 235, [200, 20, 15]).success, isTrue);
      expect(validate(345, 235, [110, 125]).success, isTrue);
    });

    test('never lets the strategy bypass the total or input checks', () {
      for (final action in ['addition', 'subtraction']) {
        for (final parts in [
          <int>[],
          [24],
          [-1, 25],
          [10, 13],
          [200, 30, 4],
        ]) {
          final second = parts.length == 3 ? 235 : 24;
          expect(validate(345, second, parts, action: action).success, isFalse);
        }
      }
      expect(validate(29, 15, [10, 4]).success, isFalse);
      expect(validate(29, 15, [5, 10], action: 'multiply').success, isFalse);
    });
  });

  group('strategy and worked solutions', () {
    test('keeps boundary-first attempts despite a round remainder', () {
      final correct = validate(29, 19, [9, 10]);
      final incorrect = validate(29, 20, [9, 10]);
      expect(correct.success, isTrue);
      expect(correct.method, BondMethod.makeTen);
      expect(correct.solutionParts, [9, 10]);
      expect(incorrect.success, isFalse);
      expect(incorrect.method, BondMethod.makeTen);
      expect(incorrect.solutionParts, [9, 11]);
    });

    test('corrects tens attempts while preserving the selected chunk', () {
      final tenFirst = validate(29, 15, [10, 4]);
      expect(tenFirst.method, BondMethod.placeValue);
      expect(tenFirst.solutionParts, [10, 5]);
      expect(
        tenFirst.proposedSolution,
        '15 → 10 + 5\n29 - 10 = 19\n19 - 5 = 14',
      );
      expect(validate(34, 24, [20, 3]).solutionParts, [20, 4]);
      expect(validate(34, 24, [3, 20]).solutionParts, [4, 20]);
      final addition = validate(4, 14, [10, 3], action: 'addition');
      expect(addition.solutionParts, [10, 4]);
      expect(
        addition.proposedSolution,
        '14 → 10 + 4\n4 + 10 = 14\n14 + 4 = 18',
      );
    });

    test(
      'corrects incomplete three-place attempts using actual place values',
      () {
        for (final parts in [
          [200, 30, 4],
          [200, 20, 4],
        ]) {
          final result = validate(110, 235, parts, action: 'addition');
          expect(result.success, isFalse);
          expect(result.method, BondMethod.placeValue);
          expect(result.solutionParts, [200, 30, 5]);
          expect(
            result.proposedSolution,
            '235 → 200 + 30 + 5\n110 + 200 = 310\n310 + 30 = 340\n340 + 5 = 345',
          );
        }
      },
    );

    test('uses the actual accepted order and preserves the first operand', () {
      final result = validate(110, 235, [200, 30, 5], action: 'addition');
      expect(result.success, isTrue);
      expect(result.proposedSolution, contains('110 + 200 = 310'));
      expect(result.proposedSolution, endsWith('340 + 5 = 345'));
      final reversed = validate(29, 15, [5, 10]);
      expect(
        reversed.proposedSolution,
        '15 → 5 + 10\n29 - 5 = 24\n24 - 10 = 14',
      );
    });

    test('solutions never introduce negative or empty-place parts', () {
      for (final second in [1, 10, 24, 100, 120, 235, 1000]) {
        final result = validate(345, second, [999, -1]);
        expect(result.solutionParts.every((part) => part > 0), isTrue);
        expect(
          result.solutionParts.fold<int>(0, (sum, part) => sum + part),
          second,
        );
      }
    });

    test('result parts are detached and immutable', () {
      final parts = [200, 30, 5];
      final result = validate(345, 235, parts);
      parts[0] = 100;
      expect(result.solutionParts, [200, 30, 5]);
      expect(() => result.solutionParts.add(1), throwsUnsupportedError);
    });
  });

  group('suggested decompositions', () {
    test('offers the required tens and hundreds choices', () {
      final tens = AnswerValidator.suggestedBreakdowns(
        number1: 34,
        number2: 24,
        action: 'subtraction',
      );
      expect(tens, contains(equals([4, 20])));
      expect(tens, contains(equals([10, 14])));
      expect(tens, contains(equals([20, 4])));
      expect(AnswerValidator.placeValueParts(120), [100, 20]);
      expect(AnswerValidator.placeValueParts(235), [200, 30, 5]);
      expect(AnswerValidator.placeValueParts(205), [200, 5]);
      final hundreds = AnswerValidator.suggestedBreakdowns(
        number1: 110,
        number2: 235,
        action: 'addition',
      );
      expect(hundreds, contains(equals([200, 30, 5])));
      expect(hundreds, contains(equals([200, 35])));
    });

    test('all offered decompositions validate for both operations', () {
      for (final action in ['addition', 'subtraction']) {
        for (final second in [14, 24, 99, 100, 120, 235, 1000]) {
          final first = second + 107;
          final suggestions = AnswerValidator.suggestedBreakdowns(
            number1: first,
            number2: second,
            action: action,
          );
          expect(suggestions, isNotEmpty);
          for (final parts in suggestions) {
            expect(
              validate(first, second, parts, action: action).success,
              isTrue,
              reason: '$first $action $second with $parts',
            );
          }
        }
      }
    });
  });
}
