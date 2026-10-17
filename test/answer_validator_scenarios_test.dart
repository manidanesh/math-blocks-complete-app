import 'package:flutter_test/flutter_test.dart';
import 'package:number_bond_math/services/answer_validator.dart';

ValidationResult _validate(
  int first,
  int second,
  List<int> parts,
  String action,
) => AnswerValidator.validateParts(
  number1: first,
  number2: second,
  action: action,
  userParts: parts,
);

Iterable<List<int>> _permutations(List<int> parts) sync* {
  if (parts.isEmpty) {
    yield <int>[];
    return;
  }
  for (var index = 0; index < parts.length; index++) {
    final remaining = List<int>.of(parts)..removeAt(index);
    for (final tail in _permutations(remaining)) {
      yield [parts[index], ...tail];
    }
  }
}

// Verify displayed arithmetic independently of the validator's strategy rules.
void _checkWorkedSolution(
  int first,
  int second,
  String action,
  ValidationResult result,
) {
  final context = '$first $action $second: ${result.solutionParts}';
  expect(result.solutionParts, isNotEmpty, reason: context);
  expect(result.solutionParts.every((part) => part >= 0), isTrue);
  expect(result.solutionParts.fold<int>(0, (a, b) => a + b), second);
  final lines = result.proposedSolution.split('\n');
  expect(lines.length, result.solutionParts.length + 1, reason: context);
  expect(lines.first, '$second → ${result.solutionParts.join(' + ')}');
  final stepPattern = RegExp(r'^(-?\d+) ([+-]) (\d+) = (-?\d+)$');
  var current = first;
  for (var index = 0; index < result.solutionParts.length; index++) {
    final match = stepPattern.firstMatch(lines[index + 1]);
    expect(match, isNotNull, reason: '$context: ${lines[index + 1]}');
    final start = int.parse(match!.group(1)!);
    final part = int.parse(match.group(3)!);
    final finish = int.parse(match.group(4)!);
    expect(start, current, reason: context);
    expect(part, result.solutionParts[index], reason: context);
    expect(match.group(2), action == 'addition' ? '+' : '-');
    expect(finish, action == 'addition' ? start + part : start - part);
    current = finish;
  }
  expect(current, action == 'addition' ? first + second : first - second);
}

void main() {
  group('systematic answer and arithmetic scenarios', () {
    test(
      'all round two-part splits from 11 through 999 work in either order',
      () {
        var checked = 0;
        for (var second = 11; second <= 999; second++) {
          final first = second + 107;
          for (var chunk = 10; chunk < second; chunk += 10) {
            for (final parts in [
              [chunk, second - chunk],
              [second - chunk, chunk],
            ]) {
              for (final action in ['addition', 'subtraction']) {
                final result = _validate(first, second, parts, action);
                if (!result.success ||
                    result.solutionParts.length != 2 ||
                    result.solutionParts[0] != parts[0] ||
                    result.solutionParts[1] != parts[1]) {
                  fail('$first $action $second must accept $parts unchanged');
                }
                final computed = result.solutionParts.fold<int>(
                  first,
                  (value, part) =>
                      action == 'addition' ? value + part : value - part,
                );
                if (computed !=
                    (action == 'addition' ? first + second : first - second)) {
                  fail('Wrong result for $first $action $second using $parts');
                }
                checked++;
              }
            }
          }
        }
        expect(checked, 197604);
      },
    );

    test(
      'every three-digit place expansion preserves every selected order',
      () {
        var checked = 0;
        for (var second = 11; second <= 999; second++) {
          final expanded = AnswerValidator.placeValueParts(second);
          if (expanded.length < 2) continue;
          for (final parts in _permutations(expanded)) {
            for (final action in ['addition', 'subtraction']) {
              final first = second + 110;
              final result = _validate(first, second, parts, action);
              expect(result.success, isTrue, reason: '$action $second: $parts');
              expect(result.solutionParts, parts);
              _checkWorkedSolution(first, second, action, result);
              checked++;
            }
          }
        }
        expect(checked, 9720);
      },
    );

    test('one-off totals and negative parts never pass a round strategy', () {
      for (var second = 11; second <= 999; second++) {
        for (final action in ['addition', 'subtraction']) {
          for (final parts in [
            [10, second - 11],
            [10, second - 9],
            [second - 11, 10],
            [second - 9, 10],
            [-1, 10, second - 9], // Correct total, invalid negative part.
          ]) {
            final result = _validate(second + 110, second, parts, action);
            expect(result.success, isFalse, reason: '$action $second: $parts');
            _checkWorkedSolution(second + 110, second, action, result);
          }
        }
      }
    });

    test(
      'corrected explanations themselves validate for supported targets',
      () {
        for (var second = 11; second <= 999; second++) {
          for (final action in ['addition', 'subtraction']) {
            for (final parts in [
              [10, second - 11],
              [second - 11, 10],
              [20, 3],
              [3, 20],
              [200, 30, 4],
              [1, 1],
              [999, -1],
              <int>[],
              [second],
            ]) {
              final first = second + 107;
              final result = _validate(first, second, parts, action);
              _checkWorkedSolution(first, second, action, result);
              expect(
                _validate(first, second, result.solutionParts, action).success,
                isTrue,
                reason:
                    '$first $action $second: $parts -> ${result.solutionParts}',
              );
            }
          }
        }
      },
    );

    test(
      'all suggested choices are usable, unique, and arithmetically sound',
      () {
        for (var second = 2; second <= 999; second++) {
          for (final action in ['addition', 'subtraction']) {
            final first = second + 110;
            final suggestions = AnswerValidator.suggestedBreakdowns(
              number1: first,
              number2: second,
              action: action,
            );
            // Small non-crossing subtractions intentionally keep legacy rules.
            if (suggestions.isEmpty) continue;
            expect(
              suggestions.map((parts) => parts.join(',')).toSet().length,
              suggestions.length,
            );
            for (final parts in suggestions) {
              final result = _validate(first, second, parts, action);
              expect(result.success, isTrue, reason: '$action $second: $parts');
              _checkWorkedSolution(first, second, action, result);
            }
          }
        }
      },
    );

    test('repeated round chunks and zero place values retain correct math', () {
      const scenarios = [
        (110, 235, [200, 30, 5]),
        (100, 24, [10, 10, 4]),
        (345, 235, [100, 100, 30, 5]),
        (400, 205, [200, 5]),
        (2000, 1000, [100, 900]),
        (5000, 2035, [2000, 30, 5]),
        (5000, 2035, [5, 30, 2000]),
        (6000, 2305, [2000, 300, 5]),
        (6000, 2305, [300, 5, 2000]),
        (6000, 2305, [10, 10, 2000, 280, 5]),
      ];
      for (final (first, second, parts) in scenarios) {
        for (final action in ['addition', 'subtraction']) {
          final result = _validate(first, second, parts, action);
          expect(result.success, isTrue, reason: '$action $second: $parts');
          expect(result.solutionParts, parts);
          _checkWorkedSolution(first, second, action, result);
        }
      }
      expect(AnswerValidator.placeValueParts(2000), [2000]);
      expect(AnswerValidator.placeValueParts(2005), [2000, 5]);
      expect(AnswerValidator.placeValueParts(2035), [2000, 30, 5]);
    });

    test('legacy single-digit crossing splits and corrections still work', () {
      for (var first = 11; first <= 99; first++) {
        final ones = first % 10;
        if (ones == 0) continue;
        for (var second = ones + 1; second <= 9; second++) {
          final valid = _validate(first, second, [
            ones,
            second - ones,
          ], 'subtraction');
          expect(valid.success, isTrue);
          _checkWorkedSolution(first, second, 'subtraction', valid);
          final corrected = _validate(first, second, [1, 1], 'subtraction');
          _checkWorkedSolution(first, second, 'subtraction', corrected);
          expect(
            _validate(
              first,
              second,
              corrected.solutionParts,
              'subtraction',
            ).success,
            isTrue,
          );
        }
      }
    });
  });
}
