import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:number_bond_math/services/problem_generator.dart';
import 'package:number_bond_math/widgets/interactive_number_bond_widget.dart';

Finder _number(int value) => find.byKey(ValueKey('bond-number-$value'));
Finder _part(int index) => find.byKey(ValueKey('bond-part-$index'));

Future<void> _pumpBond(
  WidgetTester tester,
  List<bool> completions, {
  int first = 29,
  int second = 15,
  String operation = 'subtraction',
  bool showSolution = false,
  bool showBond = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: showBond
            ? SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: InteractiveNumberBondWidget(
                    key: const ValueKey('auto-check-test-bond'),
                    operand1: first,
                    operand2: second,
                    operation: operation,
                    strategy: ProblemStrategy.crossing,
                    showSolution: showSolution,
                    onBondComplete: completions.add,
                  ),
                ),
              )
            : const Text('Bond removed'),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await tester.pump();
}

Future<void> _fill(WidgetTester tester, List<int> numbers) async {
  for (final number in numbers) {
    await _tap(tester, _number(number));
  }
}

Future<void> _openPicker(WidgetTester tester, int index) async {
  await _tap(tester, _part(index));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('bond-number-picker')), findsOneWidget);
}

Future<void> _closePicker(WidgetTester tester, {int? number}) async {
  await _tap(
    tester,
    find.byKey(
      ValueKey(
        number == null ? 'bond-picker-close' : 'bond-picker-number-$number',
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('bond-number-picker')), findsNothing);
}

void main() {
  testWidgets('automatic checking waits 700ms and completes only once', (
    tester,
  ) async {
    final completions = <bool>[];
    await _pumpBond(tester, completions);
    await _fill(tester, [10, 5]);
    await tester.pump(const Duration(milliseconds: 699));
    expect(completions, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(completions, [true]);
    await tester.pump(const Duration(seconds: 5));
    expect(completions, [true]);
  });

  testWidgets('clearing parts cancels their pending automatic check', (
    tester,
  ) async {
    final completions = <bool>[];
    await _pumpBond(tester, completions);
    await _fill(tester, [10, 4]);
    await tester.pump(const Duration(milliseconds: 350));
    await _tap(tester, find.byTooltip('Clear and try again'));
    await tester.pump(const Duration(seconds: 1));
    expect(completions, isEmpty);
    expect(find.text('2 more chances to be a Math Hero!'), findsNothing);
    await _fill(tester, [10, 5]);
    await tester.pump(const Duration(milliseconds: 700));
    expect(completions, [true]);
  });

  testWidgets('two-part answers have no manual part-count controls', (
    tester,
  ) async {
    final completions = <bool>[];
    await _pumpBond(tester, completions);
    expect(find.byKey(const ValueKey('bond-add-part')), findsNothing);
    expect(find.byKey(const ValueKey('bond-remove-part')), findsNothing);
    await _fill(tester, [10, 5]);
    await tester.pump(const Duration(milliseconds: 700));
    expect(completions, [true]);
    expect(_part(2), findsNothing);
  });

  testWidgets(
    'clearing an automatically extended entry cancels its pending check',
    (tester) async {
      final completions = <bool>[];
      await _pumpBond(
        tester,
        completions,
        first: 110,
        second: 235,
        operation: 'addition',
      );
      await _fill(tester, [200, 30]);
      await tester.pump(const Duration(milliseconds: 700));
      expect(_part(2), findsOneWidget);
      await _fill(tester, [4]);
      await tester.pump(const Duration(milliseconds: 350));
      await _tap(tester, find.byTooltip('Clear and try again'));
      expect(_part(2), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      expect(completions, isEmpty);
      expect(find.text('2 more chances to be a Math Hero!'), findsNothing);
      await _fill(tester, [200, 30]);
      await tester.pump(const Duration(milliseconds: 700));
      await _fill(tester, [5]);
      await tester.pump(const Duration(milliseconds: 699));
      expect(completions, isEmpty);
      expect(find.text('2 more chances to be a Math Hero!'), findsNothing);
      await tester.pump(const Duration(milliseconds: 1));
      expect(completions, [true]);
    },
  );

  testWidgets('changing the operands cancels the previous problem check', (
    tester,
  ) async {
    final completions = <bool>[];
    await _pumpBond(tester, completions);
    await _fill(tester, [10, 5]);
    await tester.pump(const Duration(milliseconds: 350));
    await _pumpBond(tester, completions, second: 14);
    await tester.pump(const Duration(seconds: 1));
    expect(completions, isEmpty);
    await _fill(tester, [10, 4]);
    await tester.pump(const Duration(milliseconds: 700));
    expect(completions, [true]);
  });

  testWidgets('changing the operation cancels the previous pending check', (
    tester,
  ) async {
    final completions = <bool>[];
    await _pumpBond(tester, completions);
    await _fill(tester, [10, 5]);
    await tester.pump(const Duration(milliseconds: 350));
    await _pumpBond(tester, completions, operation: 'addition');
    await tester.pump(const Duration(seconds: 1));
    expect(completions, isEmpty);
    await _fill(tester, [10, 5]);
    await tester.pump(const Duration(milliseconds: 700));
    expect(completions, [true]);
  });

  testWidgets('disposing the bond cancels its timer and callback', (
    tester,
  ) async {
    final completions = <bool>[];
    await _pumpBond(tester, completions);
    await _fill(tester, [10, 5]);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(completions, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an open picker suspends checking and close resumes the entry', (
    tester,
  ) async {
    final completions = <bool>[];
    await _pumpBond(tester, completions);
    await _fill(tester, [10, 5]);
    await tester.pump(const Duration(milliseconds: 350));
    await _openPicker(tester, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(completions, isEmpty);
    await _closePicker(tester);
    expect(completions, isEmpty);
    await tester.pump(const Duration(milliseconds: 700));
    expect(completions, [true]);
  });

  testWidgets('editing in the picker cancels the old correct answer', (
    tester,
  ) async {
    final completions = <bool>[];
    await _pumpBond(tester, completions);
    await _fill(tester, [10, 5]);
    await tester.pump(const Duration(milliseconds: 350));
    await _openPicker(tester, 1);
    await _closePicker(tester, number: 4);
    expect(completions, isEmpty);
    expect(find.text('2 more chances to be a Math Hero!'), findsNothing);
    await tester.pump(const Duration(milliseconds: 700));
    expect(completions, isEmpty);
    expect(find.text('2 more chances to be a Math Hero!'), findsOneWidget);
  });

  testWidgets('canceling a picker never repeats a validated wrong attempt', (
    tester,
  ) async {
    final completions = <bool>[];
    await _pumpBond(tester, completions);
    await _fill(tester, [10, 4]);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('2 more chances to be a Math Hero!'), findsOneWidget);
    await _openPicker(tester, 1);
    await _closePicker(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(completions, isEmpty);
    await _openPicker(tester, 1);
    await _closePicker(tester, number: 3);
    await tester.pump(const Duration(milliseconds: 700));
    expect(completions, isEmpty);
    expect(find.text('1 more chances to be a Math Hero!'), findsOneWidget);
  });

  testWidgets('choosing the same value never repeats a validated attempt', (
    tester,
  ) async {
    final completions = <bool>[];
    await _pumpBond(tester, completions);
    await _fill(tester, [10, 4]);
    await tester.pump(const Duration(milliseconds: 700));
    await _openPicker(tester, 1);
    await _closePicker(tester, number: 4);
    await tester.pump(const Duration(seconds: 2));
    expect(completions, isEmpty);
    await _openPicker(tester, 1);
    await _closePicker(tester, number: 3);
    await tester.pump(const Duration(milliseconds: 700));
    expect(completions, isEmpty);
    expect(find.text('1 more chances to be a Math Hero!'), findsOneWidget);
  });

  testWidgets(
    'clear and reentering the same wrong tuple counts a new attempt',
    (tester) async {
      final completions = <bool>[];
      await _pumpBond(tester, completions);
      for (var attempt = 1; attempt <= 3; attempt++) {
        if (attempt > 1) {
          await _tap(tester, find.byTooltip('Clear and try again'));
        }
        await _fill(tester, [10, 4]);
        await tester.pump(const Duration(milliseconds: 700));
        if (attempt < 3) {
          expect(completions, isEmpty);
          expect(
            find.text('${3 - attempt} more chances to be a Math Hero!'),
            findsOneWidget,
          );
        }
      }
      expect(completions, [false]);
      await tester.pump(const Duration(seconds: 2));
      expect(completions, [false]);
    },
  );

  testWidgets('a pending picker from the previous problem cannot change it', (
    tester,
  ) async {
    final completions = <bool>[];
    await _pumpBond(tester, completions);
    await _fill(tester, [10, 5]);
    await tester.pump(const Duration(milliseconds: 350));
    await _openPicker(tester, 1);
    await _pumpBond(tester, completions, second: 14);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bond-number-picker')), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    expect(completions, isEmpty);
    await _fill(tester, [10, 4]);
    await tester.pump(const Duration(milliseconds: 700));
    expect(completions, [true]);
  });

  testWidgets('canonical partial entry adds a circle after the grace period', (
    tester,
  ) async {
    final completions = <bool>[];
    await _pumpBond(
      tester,
      completions,
      first: 110,
      second: 235,
      operation: 'addition',
    );
    await _fill(tester, [200, 30]);
    await tester.pump(const Duration(milliseconds: 699));
    expect(_part(2), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(_part(2), findsOneWidget);
    expect(completions, isEmpty);
    expect(find.text('2 more chances to be a Math Hero!'), findsNothing);
    expect(
      find.descendant(of: _part(0), matching: find.text('200')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _part(1), matching: find.text('30')),
      findsOneWidget,
    );
    await _fill(tester, [5]);
    await tester.pump(const Duration(milliseconds: 700));
    expect(completions, [true]);
  });

  testWidgets('showing a solution cancels checking and retry starts fresh', (
    tester,
  ) async {
    final completions = <bool>[];
    await _pumpBond(tester, completions);
    await _fill(tester, [10, 4]);
    await tester.pump(const Duration(milliseconds: 350));
    await _pumpBond(tester, completions, showSolution: true);
    await tester.pump(const Duration(seconds: 2));
    expect(completions, isEmpty);
    await _pumpBond(tester, completions);
    await tester.pump(const Duration(seconds: 1));
    expect(completions, isEmpty);
    expect(find.text('2 more chances to be a Math Hero!'), findsNothing);
    await _fill(tester, [10, 4]);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('2 more chances to be a Math Hero!'), findsOneWidget);
    await _openPicker(tester, 1);
    await _closePicker(tester, number: 5);
    await tester.pump(const Duration(milliseconds: 700));
    expect(completions, [true]);
  });

  testWidgets('clearing an automatic extension permits a two-part method', (
    tester,
  ) async {
    final completions = <bool>[];
    await _pumpBond(
      tester,
      completions,
      first: 110,
      second: 235,
      operation: 'addition',
    );
    await _fill(tester, [200, 30]);
    await tester.pump(const Duration(milliseconds: 700));
    expect(_part(2), findsOneWidget);
    await _tap(tester, find.byTooltip('Clear and try again'));
    expect(_part(2), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    expect(completions, isEmpty);
    expect(find.text('2 more chances to be a Math Hero!'), findsNothing);
    await _fill(tester, [10, 225]);
    await tester.pump(const Duration(milliseconds: 700));
    expect(completions, [true]);
    expect(_part(2), findsNothing);
    expect(find.text('Break 235 into 10 + 225'), findsOneWidget);
  });

  testWidgets('removing the bond closes its picker on the retained navigator', (
    tester,
  ) async {
    final completions = <bool>[];
    await _pumpBond(tester, completions);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await _fill(tester, [10, 5]);
    await tester.pump(const Duration(milliseconds: 350));
    await _openPicker(tester, 1);
    await _pumpBond(tester, completions, showBond: false);
    await tester.pumpAndSettle();
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)),
      same(navigator),
    );
    expect(find.byKey(const ValueKey('bond-number-picker')), findsNothing);
    expect(find.text('Bond removed'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(completions, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reset before the picker first builds closes its stale route', (
    tester,
  ) async {
    final completions = <bool>[];
    await _pumpBond(tester, completions);
    await _fill(tester, [10, 5]);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.ensureVisible(_part(1));
    await tester.pump();
    // Do not pump the picker builder before changing the problem.
    await tester.tap(_part(1));
    await _pumpBond(tester, completions, second: 14);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bond-number-picker')), findsNothing);
    for (var index = 0; index < 2; index++) {
      expect(
        find.descendant(of: _part(index), matching: find.text('?')),
        findsOneWidget,
      );
    }
    await tester.pump(const Duration(seconds: 1));
    expect(completions, isEmpty);
    expect(tester.takeException(), isNull);
    await _fill(tester, [10, 4]);
    await tester.pump(const Duration(milliseconds: 700));
    expect(completions, [true]);
  });
}
