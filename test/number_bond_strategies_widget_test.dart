import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:number_bond_math/services/answer_validator.dart';
import 'package:number_bond_math/services/problem_generator.dart';
import 'package:number_bond_math/services/language_service.dart';
import 'package:number_bond_math/widgets/interactive_number_bond_widget.dart';

Finder _number(int value) => find.byKey(ValueKey('bond-number-$value'));
Finder _part(int index) => find.byKey(ValueKey('bond-part-$index'));
Finder _pickerNumber(int value) =>
    find.byKey(ValueKey('bond-picker-number-$value'));

Future<void> _tap(WidgetTester tester, Finder target) async {
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await tester.pump();
}

Future<void> _waitForAutoCheck(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pump();
}

Future<void> _choosePart(WidgetTester tester, int index, int value) async {
  await _tap(tester, _part(index));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('bond-number-picker')), findsOneWidget);
  await _tap(tester, _pickerNumber(value));
  // Let the sheet finish closing while remaining inside the checking delay.
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump();
}

Future<void> _pumpBond(
  WidgetTester tester, {
  required int first,
  required int second,
  required List<bool> completions,
  String operation = 'addition',
  String language = 'en',
}) async {
  var showSolution = false;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: StatefulBuilder(
              builder: (context, setState) => InteractiveNumberBondWidget(
                operand1: first,
                operand2: second,
                operation: operation,
                strategy: ProblemStrategy.crossing,
                language: language,
                showSolution: showSolution,
                onBondComplete: (isCorrect) {
                  completions.add(isCorrect);
                  setState(() => showSolution = !isCorrect);
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _enterParts(WidgetTester tester, List<int> parts) async {
  var currentPartCount = 2;
  while (_part(currentPartCount).evaluate().isNotEmpty) {
    currentPartCount++;
  }
  while (currentPartCount < parts.length) {
    final bond = tester.widget<InteractiveNumberBondWidget>(
      find.byType(InteractiveNumberBondWidget),
    );
    final canonical = AnswerValidator.placeValueParts(bond.operand2);
    expect(
      canonical.length,
      parts.length,
      reason: 'Extra fields require a canonical place-value split.',
    );
    final remaining = canonical.toList();
    final prefixIsCanonical = parts.take(2).every(remaining.remove);
    final prefix = prefixIsCanonical
        ? parts.take(2).toList()
        : canonical.take(2).toList();
    await _choosePart(tester, 0, prefix[0]);
    await _choosePart(tester, 1, prefix[1]);
    await _waitForAutoCheck(tester);
    expect(_part(parts.length - 1), findsOneWidget);
    currentPartCount = canonical.length;
  }
  expect(currentPartCount, parts.length);
  for (var index = 0; index < parts.length; index++) {
    await _choosePart(tester, index, parts[index]);
  }
}

Future<void> _clear(WidgetTester tester) =>
    _tap(tester, find.byTooltip('Clear and try again'));

void main() {
  group('Accepted number bond strategies', () {
    final examples =
        <({int first, int second, String operation, List<int> parts})>[
          (first: 4, second: 14, operation: 'addition', parts: [6, 8]),
          (first: 4, second: 14, operation: 'addition', parts: [10, 4]),
          (first: 4, second: 14, operation: 'addition', parts: [4, 10]),
          (first: 29, second: 15, operation: 'subtraction', parts: [9, 6]),
          (first: 29, second: 15, operation: 'subtraction', parts: [10, 5]),
          (first: 29, second: 15, operation: 'subtraction', parts: [5, 10]),
          (first: 100, second: 14, operation: 'addition', parts: [10, 4]),
          (first: 100, second: 14, operation: 'addition', parts: [4, 10]),
          (first: 100, second: 24, operation: 'addition', parts: [10, 14]),
          (first: 100, second: 24, operation: 'addition', parts: [14, 10]),
          (first: 100, second: 24, operation: 'addition', parts: [20, 4]),
          (first: 100, second: 24, operation: 'addition', parts: [4, 20]),
          (first: 100, second: 120, operation: 'addition', parts: [100, 20]),
          (first: 100, second: 120, operation: 'addition', parts: [20, 100]),
          (first: 110, second: 235, operation: 'addition', parts: [200, 30, 5]),
          (first: 110, second: 235, operation: 'addition', parts: [5, 200, 30]),
        ];

    for (final example in examples) {
      testWidgets(
        '${example.first} ${example.operation} ${example.second} accepts '
        '${example.parts.join(' + ')} automatically',
        (tester) async {
          final completions = <bool>[];
          await _pumpBond(
            tester,
            first: example.first,
            second: example.second,
            operation: example.operation,
            completions: completions,
          );
          await _enterParts(tester, example.parts);

          expect(completions, isEmpty, reason: 'Wait for the checking delay.');
          await _waitForAutoCheck(tester);

          expect(completions, [true]);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'a place-value prefix offers its missing circle automatically',
      (tester) async {
        final completions = <bool>[];
        await _pumpBond(
          tester,
          first: 110,
          second: 235,
          completions: completions,
        );
        await _tap(tester, _number(200));
        await _tap(tester, _number(30));
        expect(completions, isEmpty);

        await _waitForAutoCheck(tester);
        expect(_part(2), findsOneWidget);
        expect(
          completions,
          isEmpty,
          reason: 'A place-value prefix must not consume an attempt.',
        );
        expect(find.text('Try splitting 235 into 200 + 30 + 5.'), findsNothing);
        expect(
          find.descendant(of: _part(2), matching: find.text('?')),
          findsOneWidget,
        );

        await _tap(tester, _number(5));
        expect(completions, isEmpty);
        await _waitForAutoCheck(tester);
        expect(completions, [true]);
      },
    );

    testWidgets('the same grid number can fill more than one circle', (
      tester,
    ) async {
      final completions = <bool>[];
      await _pumpBond(tester, first: 100, second: 20, completions: completions);
      await _enterParts(tester, [10, 10]);

      expect(
        find.descendant(of: _part(0), matching: find.text('10')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: _part(1), matching: find.text('10')),
        findsOneWidget,
      );
      await _waitForAutoCheck(tester);
      expect(completions, [true]);
    });

    testWidgets('a selected circle can be edited during the checking delay', (
      tester,
    ) async {
      final completions = <bool>[];
      await _pumpBond(tester, first: 4, second: 14, completions: completions);
      await _enterParts(tester, [10, 5]);
      await _choosePart(tester, 1, 4);
      await _waitForAutoCheck(tester);

      expect(completions, [true]);
    });

    testWidgets('ordinary two-part answers have no part-count controls', (
      tester,
    ) async {
      final completions = <bool>[];
      await _pumpBond(tester, first: 100, second: 24, completions: completions);
      expect(find.byKey(const ValueKey('bond-add-part')), findsNothing);
      expect(find.byKey(const ValueKey('bond-remove-part')), findsNothing);
      expect(_part(2), findsNothing);

      await _enterParts(tester, [20, 4]);
      await _waitForAutoCheck(tester);
      expect(completions, [true]);
    });
  });

  group('Arithmetic across operand sizes and part orders', () {
    final scenarios =
        <
          ({
            int first,
            int second,
            String operation,
            List<int> parts,
            List<String> steps,
          })
        >[
          (
            first: 3,
            second: 2,
            operation: 'addition',
            parts: [1, 1],
            steps: ['3 + 1 = 4', '4 + 1 = 5'],
          ),
          (
            first: 8,
            second: 9,
            operation: 'addition',
            parts: [2, 7],
            steps: ['8 + 2 = 10', '10 + 7 = 17'],
          ),
          (
            first: 47,
            second: 6,
            operation: 'addition',
            parts: [3, 3],
            steps: ['47 + 3 = 50', '50 + 3 = 53'],
          ),
          (
            first: 80,
            second: 12,
            operation: 'subtraction',
            parts: [2, 10],
            steps: ['80 - 2 = 78', '78 - 10 = 68'],
          ),
          (
            first: 25,
            second: 5,
            operation: 'subtraction',
            parts: [5, 0],
            steps: ['25 - 5 = 20', '20 - 0 = 20'],
          ),
          (
            first: 52,
            second: 20,
            operation: 'subtraction',
            parts: [10, 10],
            steps: ['52 - 10 = 42', '42 - 10 = 32'],
          ),
          (
            first: 129,
            second: 9,
            operation: 'subtraction',
            parts: [9, 0],
            steps: ['129 - 9 = 120', '120 - 0 = 120'],
          ),
          (
            first: 110,
            second: 205,
            operation: 'addition',
            parts: [200, 5],
            steps: ['110 + 200 = 310', '310 + 5 = 315'],
          ),
          (
            first: 345,
            second: 205,
            operation: 'subtraction',
            parts: [5, 200],
            steps: ['345 - 5 = 340', '340 - 200 = 140'],
          ),
          (
            first: 300,
            second: 120,
            operation: 'subtraction',
            parts: [20, 100],
            steps: ['300 - 20 = 280', '280 - 100 = 180'],
          ),
          (
            first: 345,
            second: 235,
            operation: 'subtraction',
            parts: [5, 30, 200],
            steps: ['345 - 5 = 340', '340 - 30 = 310', '310 - 200 = 110'],
          ),
          (
            first: 345,
            second: 235,
            operation: 'subtraction',
            parts: [30, 200, 5],
            steps: ['345 - 30 = 315', '315 - 200 = 115', '115 - 5 = 110'],
          ),
          (
            first: 345,
            second: 235,
            operation: 'subtraction',
            parts: [30, 5, 200],
            steps: ['345 - 30 = 315', '315 - 5 = 310', '310 - 200 = 110'],
          ),
          (
            first: 500,
            second: 300,
            operation: 'subtraction',
            parts: [100, 100, 100],
            steps: ['500 - 100 = 400', '400 - 100 = 300', '300 - 100 = 200'],
          ),
          (
            first: 300,
            second: 300,
            operation: 'subtraction',
            parts: [100, 100, 100],
            steps: ['300 - 100 = 200', '200 - 100 = 100', '100 - 100 = 0'],
          ),
          (
            first: 300,
            second: 120,
            operation: 'subtraction',
            parts: [100, 10, 10],
            steps: ['300 - 100 = 200', '200 - 10 = 190', '190 - 10 = 180'],
          ),
          (
            first: 100,
            second: 120,
            operation: 'addition',
            parts: [10, 10, 100],
            steps: ['100 + 10 = 110', '110 + 10 = 120', '120 + 100 = 220'],
          ),
          (
            first: 2000,
            second: 1234,
            operation: 'addition',
            parts: [1000, 200, 30, 4],
            steps: [
              '2000 + 1000 = 3000',
              '3000 + 200 = 3200',
              '3200 + 30 = 3230',
              '3230 + 4 = 3234',
            ],
          ),
          (
            first: 2345,
            second: 1234,
            operation: 'subtraction',
            parts: [4, 30, 200, 1000],
            steps: [
              '2345 - 4 = 2341',
              '2341 - 30 = 2311',
              '2311 - 200 = 2111',
              '2111 - 1000 = 1111',
            ],
          ),
          (
            first: 2345,
            second: 1234,
            operation: 'subtraction',
            parts: [1000, 4, 200, 30],
            steps: [
              '2345 - 1000 = 1345',
              '1345 - 4 = 1341',
              '1341 - 200 = 1141',
              '1141 - 30 = 1111',
            ],
          ),
          (
            first: 1234,
            second: 1000,
            operation: 'addition',
            parts: [900, 100],
            steps: ['1234 + 900 = 2134', '2134 + 100 = 2234'],
          ),
          (
            first: 2000,
            second: 1000,
            operation: 'subtraction',
            parts: [900, 100],
            steps: ['2000 - 900 = 1100', '1100 - 100 = 1000'],
          ),
        ];

    for (final scenario in scenarios) {
      if (scenario.parts.length > 2 &&
          scenario.parts.length !=
              AnswerValidator.placeValueParts(scenario.second).length) {
        test(
          '${scenario.first} ${scenario.operation} ${scenario.second} validates ${scenario.parts.join(' + ')} without manual UI fields',
          () {
            final result = AnswerValidator.validateParts(
              number1: scenario.first,
              number2: scenario.second,
              action: scenario.operation,
              userParts: scenario.parts,
            );
            expect(result.success, isTrue);
            expect(result.solutionParts, scenario.parts);
          },
        );
        continue;
      }
      testWidgets(
        '${scenario.first} ${scenario.operation} ${scenario.second} shows '
        'correct steps for ${scenario.parts.join(' + ')}',
        (tester) async {
          final completions = <bool>[];
          await _pumpBond(
            tester,
            first: scenario.first,
            second: scenario.second,
            operation: scenario.operation,
            completions: completions,
          );
          await _enterParts(tester, scenario.parts);
          expect(completions, isEmpty);
          for (var index = 0; index < scenario.parts.length; index++) {
            expect(
              find.descendant(
                of: _part(index),
                matching: find.text('${scenario.parts[index]}'),
              ),
              findsOneWidget,
            );
          }
          await _waitForAutoCheck(tester);

          expect(completions, [true]);
          expect(
            find.text(
              'Break ${scenario.second} into ${scenario.parts.join(' + ')}',
            ),
            findsOneWidget,
          );
          for (final step in scenario.steps) {
            expect(find.text(step), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('an arbitrary correct addition retains the basic strategy', (
      tester,
    ) async {
      final completions = <bool>[];
      await _pumpBond(tester, first: 100, second: 14, completions: completions);
      await _enterParts(tester, [7, 7]);
      await _waitForAutoCheck(tester);

      expect(completions, [true]);
      expect(find.text('Basic Strategy'), findsOneWidget);
      expect(find.text('Make Ten Strategy'), findsNothing);
      expect(find.text('100 + 7 = 107'), findsOneWidget);
      expect(find.text('107 + 7 = 114'), findsOneWidget);
    });

    testWidgets('changing the operation resets the same operands', (
      tester,
    ) async {
      final completions = <bool>[];
      await _pumpBond(tester, first: 29, second: 15, completions: completions);
      await _enterParts(tester, [10, 5]);
      await _waitForAutoCheck(tester);
      expect(find.text('39 + 5 = 44'), findsOneWidget);

      await _pumpBond(
        tester,
        first: 29,
        second: 15,
        operation: 'subtraction',
        completions: completions,
      );
      expect(find.text('39 + 5 = 44'), findsNothing);
      await _enterParts(tester, [5, 10]);
      await _waitForAutoCheck(tester);

      expect(completions, [true, true]);
      expect(find.text('29 - 5 = 24'), findsOneWidget);
      expect(find.text('24 - 10 = 14'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Failed attempts across operand sizes', () {
    final scenarios =
        <
          ({
            int first,
            int second,
            String operation,
            List<int> attempted,
            List<int> corrected,
            List<String> steps,
          })
        >[
          (
            first: 3,
            second: 2,
            operation: 'addition',
            attempted: [1, 2],
            corrected: [1, 1],
            steps: ['3 + 1 = 4', '4 + 1 = 5'],
          ),
          (
            first: 4,
            second: 14,
            operation: 'addition',
            attempted: [6, 9],
            corrected: [6, 8],
            steps: ['4 + 6 = 10', '10 + 8 = 18'],
          ),
          (
            first: 47,
            second: 16,
            operation: 'addition',
            attempted: [3, 9],
            corrected: [3, 13],
            steps: ['47 + 3 = 50', '50 + 13 = 63'],
          ),
          (
            first: 25,
            second: 5,
            operation: 'subtraction',
            attempted: [1, 4],
            corrected: [5, 0],
            steps: ['25 - 5 = 20', '20 - 0 = 20'],
          ),
          (
            first: 29,
            second: 15,
            operation: 'subtraction',
            attempted: [6, 9],
            corrected: [9, 6],
            steps: ['29 - 9 = 20', '20 - 6 = 14'],
          ),
          (
            first: 100,
            second: 24,
            operation: 'addition',
            attempted: [4, 10],
            corrected: [14, 10],
            steps: ['100 + 14 = 114', '114 + 10 = 124'],
          ),
          (
            first: 300,
            second: 120,
            operation: 'subtraction',
            attempted: [5, 100],
            corrected: [20, 100],
            steps: ['300 - 20 = 280', '280 - 100 = 180'],
          ),
          (
            first: 345,
            second: 235,
            operation: 'subtraction',
            attempted: [4, 30, 200],
            corrected: [200, 30, 5],
            steps: ['345 - 200 = 145', '145 - 30 = 115', '115 - 5 = 110'],
          ),
          (
            first: 4000,
            second: 1234,
            operation: 'subtraction',
            attempted: [1000, 200, 30, 3],
            corrected: [1000, 200, 30, 4],
            steps: [
              '4000 - 1000 = 3000',
              '3000 - 200 = 2800',
              '2800 - 30 = 2770',
              '2770 - 4 = 2766',
            ],
          ),
          (
            first: 110,
            second: 235,
            operation: 'addition',
            attempted: [100, 200, 30, 5],
            corrected: [200, 30, 5],
            steps: ['110 + 200 = 310', '310 + 30 = 340', '340 + 5 = 345'],
          ),
        ];

    for (final scenario in scenarios) {
      if (scenario.attempted.length > 2 &&
          scenario.attempted.length !=
              AnswerValidator.placeValueParts(scenario.second).length) {
        test(
          '${scenario.first} ${scenario.operation} ${scenario.second} corrects ${scenario.attempted.join(' + ')} without manual UI fields',
          () {
            final result = AnswerValidator.validateParts(
              number1: scenario.first,
              number2: scenario.second,
              action: scenario.operation,
              userParts: scenario.attempted,
            );
            expect(result.success, isFalse);
            expect(result.solutionParts, scenario.corrected);
          },
        );
        continue;
      }
      testWidgets(
        '${scenario.first} ${scenario.operation} ${scenario.second} explains '
        'a failed ${scenario.attempted.join(' + ')} attempt',
        (tester) async {
          final completions = <bool>[];
          await _pumpBond(
            tester,
            first: scenario.first,
            second: scenario.second,
            operation: scenario.operation,
            completions: completions,
          );
          for (var attempt = 0; attempt < 3; attempt++) {
            await _enterParts(tester, scenario.attempted);
            await _waitForAutoCheck(tester);
            if (attempt < 2) {
              expect(completions, isEmpty);
              expect(
                find.text(
                  'Try splitting ${scenario.second} into ${scenario.corrected.join(' + ')}.',
                ),
                findsOneWidget,
              );
              await _clear(tester);
            }
          }

          expect(completions, [false]);
          final breakdown = find.text(
            'Break ${scenario.second} into ${scenario.corrected.join(' + ')}',
          );
          expect(breakdown, findsOneWidget);
          for (final step in scenario.steps) {
            expect(find.text(step), findsOneWidget);
          }
          await _clear(tester);
          expect(breakdown, findsOneWidget);
          for (final step in scenario.steps) {
            expect(find.text(step), findsOneWidget);
          }
          expect(completions, [false]);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('Number choices', () {
    testWidgets('all crossing, ten, and place-value choices remain available', (
      tester,
    ) async {
      await _pumpBond(tester, first: 34, second: 24, completions: []);
      for (final value in [6, 18, 10, 14, 20, 4]) {
        expect(_number(value), findsOneWidget, reason: 'Missing choice $value');
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('large remainder choices are not removed by a grid limit', (
      tester,
    ) async {
      await _pumpBond(tester, first: 100, second: 99, completions: []);
      expect(_number(10), findsOneWidget);
      expect(_number(89), findsOneWidget);
      await _enterParts(tester, [10, 89]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('hundreds and each place-value component are selectable', (
      tester,
    ) async {
      await _pumpBond(tester, first: 110, second: 235, completions: []);
      for (final value in [200, 30, 5]) {
        expect(_number(value), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('Strategy-aware explanations and completion', () {
    testWidgets('an incorrect ten split gets the matching retry hint', (
      tester,
    ) async {
      final completions = <bool>[];
      await _pumpBond(
        tester,
        first: 29,
        second: 15,
        operation: 'subtraction',
        completions: completions,
      );
      await _enterParts(tester, [10, 4]);
      await _waitForAutoCheck(tester);

      expect(find.text('Try splitting 15 into 10 + 5.'), findsOneWidget);
      expect(completions, isEmpty);
    });

    testWidgets('an incorrect crossing split keeps the crossing retry hint', (
      tester,
    ) async {
      final completions = <bool>[];
      await _pumpBond(
        tester,
        first: 29,
        second: 15,
        operation: 'subtraction',
        completions: completions,
      );
      await _enterParts(tester, [9, 5]);
      await _waitForAutoCheck(tester);

      expect(find.text('Try splitting 15 into 9 + 6.'), findsOneWidget);
      expect(completions, isEmpty);
    });

    testWidgets('retry hints distinguish both accepted ways to split 24', (
      tester,
    ) async {
      final completions = <bool>[];
      await _pumpBond(tester, first: 100, second: 24, completions: completions);
      await _enterParts(tester, [10, 5]);
      await _waitForAutoCheck(tester);
      expect(find.text('Try splitting 24 into 10 + 14.'), findsOneWidget);

      await _clear(tester);
      await _enterParts(tester, [20, 5]);
      await _waitForAutoCheck(tester);
      expect(find.text('Try splitting 24 into 20 + 4.'), findsOneWidget);
      expect(completions, isEmpty);
    });

    testWidgets('an incorrect three-part split gets a place-value hint', (
      tester,
    ) async {
      final completions = <bool>[];
      await _pumpBond(
        tester,
        first: 110,
        second: 235,
        completions: completions,
      );
      await _enterParts(tester, [200, 30, 4]);
      await _waitForAutoCheck(tester);

      expect(find.text('Try splitting 235 into 200 + 30 + 5.'), findsOneWidget);
      expect(completions, isEmpty);
    });

    testWidgets('the final method follows the most recent submitted attempt', (
      tester,
    ) async {
      final completions = <bool>[];
      await _pumpBond(
        tester,
        first: 29,
        second: 15,
        operation: 'subtraction',
        completions: completions,
      );
      for (final parts in [
        <int>[10, 4],
        <int>[10, 4],
        <int>[9, 5],
      ]) {
        await _enterParts(tester, parts);
        await _waitForAutoCheck(tester);
        if (completions.isEmpty) await _clear(tester);
      }

      expect(completions, [false]);
      expect(find.text('Break 15 into 9 + 6'), findsOneWidget);
      expect(find.text('29 - 9 = 20'), findsOneWidget);
      expect(find.text('20 - 6 = 14'), findsOneWidget);
    });

    testWidgets('clearing after three failures preserves the final method', (
      tester,
    ) async {
      final completions = <bool>[];
      await _pumpBond(
        tester,
        first: 29,
        second: 15,
        operation: 'subtraction',
        completions: completions,
      );
      for (var attempt = 0; attempt < 3; attempt++) {
        await _enterParts(tester, [10, 4]);
        await _waitForAutoCheck(tester);
        if (attempt < 2) await _clear(tester);
      }

      expect(completions, [false]);
      expect(find.text('Break 15 into 10 + 5'), findsOneWidget);
      expect(find.text('29 - 10 = 19'), findsOneWidget);
      expect(find.text('19 - 5 = 14'), findsOneWidget);

      await _clear(tester);
      expect(find.text('Break 15 into 10 + 5'), findsOneWidget);
      expect(find.text('29 - 10 = 19'), findsOneWidget);
      expect(find.text('19 - 5 = 14'), findsOneWidget);
      expect(completions, [false]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('three-part explanations use correct sequential arithmetic', (
      tester,
    ) async {
      final completions = <bool>[];
      await _pumpBond(
        tester,
        first: 110,
        second: 235,
        completions: completions,
      );
      await _enterParts(tester, [200, 30, 5]);
      await _waitForAutoCheck(tester);

      expect(completions, [true]);
      expect(find.text('Break 235 into 200 + 30 + 5'), findsOneWidget);
      expect(find.text('110 + 200 = 310'), findsOneWidget);
      expect(find.text('310 + 30 = 340'), findsOneWidget);
      expect(find.text('340 + 5 = 345'), findsOneWidget);
    });

    testWidgets('a completed problem cannot award another completion', (
      tester,
    ) async {
      final completions = <bool>[];
      await _pumpBond(tester, first: 4, second: 14, completions: completions);
      await _enterParts(tester, [10, 4]);
      await _waitForAutoCheck(tester);
      expect(completions, [true]);

      await _waitForAutoCheck(tester);
      await _clear(tester);
      for (final value in [10, 4]) {
        if (_number(value).evaluate().isNotEmpty) {
          await _tap(tester, _number(value));
        }
      }
      await _waitForAutoCheck(tester);

      expect(completions, [true]);
      expect(find.text('Break 14 into 10 + 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a new problem resets the previous completion lock', (
      tester,
    ) async {
      final completions = <bool>[];
      await _pumpBond(tester, first: 4, second: 14, completions: completions);
      await _enterParts(tester, [10, 4]);
      await _waitForAutoCheck(tester);

      await _pumpBond(tester, first: 100, second: 24, completions: completions);
      expect(find.text('Break 14 into 10 + 4'), findsNothing);
      await _enterParts(tester, [20, 4]);
      await _waitForAutoCheck(tester);

      expect(completions, [true, true]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the parent retry action starts a new attempt after failure', (
      tester,
    ) async {
      final completions = <bool>[];
      var showSolution = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) => Column(
                  children: [
                    InteractiveNumberBondWidget(
                      operand1: 29,
                      operand2: 15,
                      operation: 'subtraction',
                      strategy: ProblemStrategy.crossing,
                      showSolution: showSolution,
                      onBondComplete: (isCorrect) {
                        completions.add(isCorrect);
                        setState(() => showSolution = !isCorrect);
                      },
                    ),
                    ElevatedButton(
                      key: const ValueKey('parent-retry'),
                      onPressed: () => setState(() => showSolution = false),
                      child: const Text('Retry Challenge'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var attempt = 0; attempt < 3; attempt++) {
        await _enterParts(tester, [10, 4]);
        await _waitForAutoCheck(tester);
        if (attempt < 2) await _clear(tester);
      }
      expect(completions, [false]);

      await _tap(tester, find.byKey(const ValueKey('parent-retry')));
      expect(find.text('Break 15 into 10 + 5'), findsNothing);
      await _enterParts(tester, [10, 5]);
      await _waitForAutoCheck(tester);

      expect(completions, [false, true]);
      expect(tester.takeException(), isNull);
    });
  });

  group('Circle number picker', () {
    testWidgets(
      'picker selection fills its tapped circle and the grid fills the other',
      (tester) async {
        final completions = <bool>[];
        await _pumpBond(tester, first: 4, second: 14, completions: completions);
        await _choosePart(tester, 1, 4);
        expect(
          find.descendant(of: _part(0), matching: find.text('?')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: _part(1), matching: find.text('4')),
          findsOneWidget,
        );
        await _waitForAutoCheck(tester);
        expect(completions, isEmpty);

        await _tap(tester, _number(10));
        await _waitForAutoCheck(tester);
        expect(completions, [true]);
        expect(find.text('Break 14 into 10 + 4'), findsOneWidget);
        expect(find.byKey(const ValueKey('bond-submit')), findsNothing);
      },
    );

    testWidgets(
      'a filled circle can be corrected through its picker after a failed check',
      (tester) async {
        final completions = <bool>[];
        await _pumpBond(tester, first: 4, second: 14, completions: completions);
        await _tap(tester, _number(6));
        await _tap(tester, _number(5));
        await _waitForAutoCheck(tester);
        expect(find.text('Try splitting 14 into 6 + 8.'), findsOneWidget);
        expect(completions, isEmpty);

        await _choosePart(tester, 1, 8);
        await _waitForAutoCheck(tester);
        expect(completions, [true]);
        expect(find.text('4 + 6 = 10'), findsOneWidget);
        expect(find.text('10 + 8 = 18'), findsOneWidget);
      },
    );

    testWidgets('completed circles stay locked when tapped', (tester) async {
      final completions = <bool>[];
      await _pumpBond(tester, first: 4, second: 14, completions: completions);
      await _enterParts(tester, [10, 4]);
      await _waitForAutoCheck(tester);
      await _tap(tester, _part(0));
      await _waitForAutoCheck(tester);

      expect(find.byKey(const ValueKey('bond-number-picker')), findsNothing);
      expect(completions, [true]);
    });

    for (final translation in [
      (language: 'en', title: 'Choose a number for Part 2', close: 'Close'),
      (
        language: 'es',
        title: 'Elige un número para la parte 2',
        close: 'Cerrar',
      ),
      (
        language: 'fr',
        title: 'Choisis un nombre pour la partie 2',
        close: 'Fermer',
      ),
    ]) {
      testWidgets('${translation.language} localizes the circle picker', (
        tester,
      ) async {
        final completions = <bool>[];
        await _pumpBond(
          tester,
          first: 100,
          second: 24,
          language: translation.language,
          completions: completions,
        );
        await _tap(tester, _part(1));
        await tester.pumpAndSettle();

        expect(find.text(translation.title), findsOneWidget);
        expect(find.byKey(const ValueKey('bond-picker-close')), findsOneWidget);
        expect(
          find.text(translation.close).evaluate().isNotEmpty ||
              find.byTooltip(translation.close).evaluate().isNotEmpty,
          isTrue,
          reason: 'The picker close control must be localized.',
        );
        for (final value in [10, 14, 20, 4]) {
          expect(_pickerNumber(value), findsOneWidget);
        }
        await _tap(tester, find.byKey(const ValueKey('bond-picker-close')));
        await tester.pump(const Duration(milliseconds: 350));
        await _waitForAutoCheck(tester);

        expect(find.byKey(const ValueKey('bond-number-picker')), findsNothing);
        expect(completions, isEmpty);
        expect(tester.takeException(), isNull);
      });
    }
  });

  for (final translation in [
    (
      language: 'es',
      hint: 'Intenta dividir 15 en 10 + 5.',
      solution: 'Divide 15 en 10 + 5',
    ),
    (
      language: 'fr',
      hint: 'Essaie de décomposer 15 en 10 + 5.',
      solution: 'Décompose 15 en 10 + 5',
    ),
  ]) {
    testWidgets('${translation.language} translates automatic-check guidance', (
      tester,
    ) async {
      final completions = <bool>[];
      await _pumpBond(
        tester,
        first: 29,
        second: 15,
        operation: 'subtraction',
        language: translation.language,
        completions: completions,
      );
      expect(find.byKey(const ValueKey('bond-add-part')), findsNothing);
      expect(find.byKey(const ValueKey('bond-remove-part')), findsNothing);
      expect(
        find.text(
          LanguageService.translate(
            'bond_auto_check_instruction',
            translation.language,
          ),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('bond-submit')), findsNothing);

      for (var attempt = 0; attempt < 3; attempt++) {
        await _enterParts(tester, [10, 4]);
        await _waitForAutoCheck(tester);
        if (attempt < 2) {
          expect(find.text(translation.hint), findsOneWidget);
          expect(find.text('Try splitting 15 into 10 + 5.'), findsNothing);
          await _tap(tester, find.byIcon(Icons.refresh));
        }
      }

      expect(find.text(translation.solution), findsOneWidget);
      expect(find.text('Break 15 into 10 + 5'), findsNothing);
      expect(completions, [false]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'automatically extended parts and solutions fit a narrow screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final completions = <bool>[];
      await _pumpBond(
        tester,
        first: 110,
        second: 235,
        completions: completions,
      );
      await _enterParts(tester, [200, 30, 5]);
      await _waitForAutoCheck(tester);

      expect(completions, [true]);
      expect(find.text('340 + 5 = 345'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
