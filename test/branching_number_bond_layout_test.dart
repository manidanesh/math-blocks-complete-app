import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:number_bond_math/models/kid_profile.dart';
import 'package:number_bond_math/providers/profile_provider.dart';
import 'package:number_bond_math/screens/adaptive_challenge_screen.dart';
import 'package:number_bond_math/services/answer_validator.dart';
import 'package:number_bond_math/services/language_service.dart';
import 'package:number_bond_math/services/problem_generator.dart';
import 'package:number_bond_math/widgets/interactive_number_bond_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder _key(String name) => find.byKey(ValueKey(name));
Finder _part(int index) => _key('bond-part-$index');
Finder _number(int number) => _key('bond-number-$number');

const _safe = EdgeInsets.only(top: 47, bottom: 34);
const _viewports = [Size(320, 568), Size(390, 844), Size(568, 320)];

MathProblem _problem(int first, int second, {String operation = '+'}) =>
    MathProblem(
      operand1: first,
      operand2: second,
      operator: operation,
      correctAnswer: operation == '+' ? first + second : first - second,
      problemText: '$first $operation $second = ?',
      options: const [],
      strategy: ProblemStrategy.crossing,
      level: 4,
      explanation: '',
    );

Future<void> _pumpWorkspace(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  String language = 'en',
  double textScale = 1,
  MathProblem? problem,
  List<bool>? completions,
  NumberBondAttempt? restoredAttempt,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final currentProblem = problem ?? _problem(110, 999);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: _safe,
          viewPadding: _safe,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Scaffold(
        appBar: AppBar(
          toolbarHeight: 44,
          title: const Text('Challenge'),
          leading: const BackButton(),
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  currentProblem.problemText,
                  key: const ValueKey('challenge-question'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(height: 16),
                InteractiveNumberBondWidget(
                  key: ValueKey(currentProblem.problemText),
                  operand1: currentProblem.operand1,
                  operand2: currentProblem.operand2,
                  operation: currentProblem.operator == '+'
                      ? 'addition'
                      : 'subtraction',
                  strategy: currentProblem.strategy,
                  language: language,
                  onBondComplete: completions?.add,
                  restoredAttempt: restoredAttempt,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  key: const ValueKey('challenge-next'),
                  onPressed: () {},
                  child: const Text('Next challenge'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void _expectWithinViewport(
  WidgetTester tester,
  Finder finder,
  Size viewport, {
  bool interactive = false,
}) {
  expect(finder, findsOneWidget);
  final rect = tester.getRect(finder);
  expect(rect.top, greaterThanOrEqualTo(_safe.top - 0.01));
  expect(rect.bottom, lessThanOrEqualTo(viewport.height - _safe.bottom + 0.01));
  expect(rect.left, greaterThanOrEqualTo(-0.01));
  expect(rect.right, lessThanOrEqualTo(viewport.width + 0.01));
  if (interactive) {
    expect(finder.hitTestable(), findsOneWidget);
    expect(rect.width, greaterThanOrEqualTo(44 - 0.01));
    expect(rect.height, greaterThanOrEqualTo(44 - 0.01));
  }
}

Future<void> _expectBranchGeometry(
  WidgetTester tester,
  Size viewport, {
  int partCount = 2,
}) async {
  await tester.ensureVisible(_key('bond-whole'));
  await tester.pump();
  expect(tester.takeException(), isNull);
  for (final name in ['bond-whole', 'bond-branch-lines']) {
    _expectWithinViewport(tester, _key(name), viewport);
  }
  final whole = tester.getRect(_key('bond-whole'));
  final parts = [
    for (var index = 0; index < partCount; index++)
      tester.getRect(_part(index)),
  ];
  for (var index = 0; index < partCount; index++) {
    _expectWithinViewport(tester, _part(index), viewport, interactive: true);
    expect(parts[index].top, greaterThan(whole.bottom));
    expect(parts[index].center.dy, closeTo(parts.first.center.dy, 0.01));
    if (index > 0) {
      expect(parts[index].left, greaterThan(parts[index - 1].right));
    }
  }
  expect(
    whole.center.dx,
    closeTo((parts.first.center.dx + parts.last.center.dx) / 2, 0.01),
  );

  final paintFinder = find.descendant(
    of: _key('bond-branch-lines'),
    matching: find.byType(CustomPaint),
    matchRoot: true,
  );
  expect(paintFinder, findsOneWidget);
  final paint = tester.widget<CustomPaint>(paintFinder);
  expect(paint.painter, isA<NumberBondLinePainter>());
  final painter = paint.painter! as NumberBondLinePainter;
  expect(painter.partCount, partCount);
  final canvas = TestRecordingCanvas();
  painter.paint(canvas, tester.getSize(paintFinder));
  final lines = canvas.invocations
      .where((call) => call.invocation.memberName == #drawLine)
      .toList();
  expect(lines, hasLength(partCount));
  final paintRect = tester.getRect(paintFinder);
  for (var index = 0; index < partCount; index++) {
    final arguments = lines[index].invocation.positionalArguments;
    final start = paintRect.topLeft + (arguments[0] as Offset);
    final end = paintRect.topLeft + (arguments[1] as Offset);
    expect(start.dx, closeTo(whole.center.dx, 0.01));
    expect(start.dy, greaterThanOrEqualTo(whole.bottom - 0.01));
    expect(end.dx, closeTo(parts[index].center.dx, 0.01));
    expect(end.dy, lessThanOrEqualTo(parts[index].top + 0.01));
    expect(parts[index].top - end.dy, inInclusiveRange(-0.01, 10));
  }
}

Future<void> _expectScrollableControls(
  WidgetTester tester,
  Size viewport,
) async {
  _expectNoManualPartControls();
  final choices = find.byWidgetPredicate(
    (widget) =>
        widget is InkWell &&
        widget.key is ValueKey<String> &&
        (widget.key! as ValueKey<String>).value.startsWith('bond-number-'),
  );
  expect(choices, findsWidgets);
  for (final element in choices.evaluate()) {
    final choice = find.byWidget(element.widget);
    await tester.ensureVisible(choice);
    await tester.pump();
    _expectWithinViewport(tester, choice, viewport, interactive: true);
  }
  await tester.ensureVisible(_key('challenge-next'));
  await tester.pump();
  _expectWithinViewport(
    tester,
    _key('challenge-next'),
    viewport,
    interactive: true,
  );
  expect(tester.takeException(), isNull);
}

void _expectNoManualPartControls() {
  expect(_key('bond-add-part'), findsNothing);
  expect(_key('bond-remove-part'), findsNothing);
  for (final icon in [
    Icons.add,
    Icons.add_circle_outline,
    Icons.remove,
    Icons.remove_circle_outline,
  ]) {
    expect(find.byIcon(icon), findsNothing);
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _pick(WidgetTester tester, int index, int number) async {
  await _tap(tester, _part(index));
  await tester.pumpAndSettle();
  final choice = _key('bond-picker-number-$number');
  await tester.ensureVisible(choice);
  await tester.pump();
  await tester.tap(choice);
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump();
}

void main() {
  testWidgets('full landscape challenge celebrates success without overflow', (
    tester,
  ) async {
    const size = Size(568, 320);
    final profile = KidProfile(
      id: 'branching-child',
      name: 'Alexandria Long Child Name',
      birthYear: 2019,
      avatarId: 'default',
      language: 'fr',
      isCurrent: true,
      createdAt: DateTime(2026, 1, 1),
      lastPlayed: DateTime(2026, 10, 10),
    );
    SharedPreferences.setMockInitialValues({
      'current_profile': jsonEncode(profile.toJson()),
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(profileProvider.future);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: _safe,
              viewPadding: _safe,
              textScaler: TextScaler.linear(1.5),
            ),
            child: child!,
          ),
          home: AdaptiveChallengeScreen(initialProblem: _problem(4, 14)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(_key('challenge-question')).data, '4 + 14 = ?');
    expect(
      tester
          .widget<InteractiveNumberBondWidget>(
            find.byType(InteractiveNumberBondWidget),
          )
          .compact,
      isFalse,
    );
    await _expectBranchGeometry(tester, size);
    await _pick(tester, 0, 10);
    await _tap(tester, _number(4));
    await tester.pump(const Duration(milliseconds: 699));
    expect(tester.widget<Text>(_key('challenge-question')).data, '4 + 14 = ?');
    await tester.pump(const Duration(milliseconds: 1));
    expect(tester.widget<Text>(_key('challenge-question')).data, '4 + 14 = 18');
    await tester.pumpAndSettle();
    expect(_key('challenge-success-scroll'), findsOneWidget);
    expect(container.read(profileProvider).value!.totalStars, 1);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await _expectBranchGeometry(tester, size);
    await tester.ensureVisible(_key('challenge-question'));
    await tester.pump();
    _expectWithinViewport(tester, _key('challenge-question'), size);
    expect(tester.widget<Text>(_key('challenge-question')).data, '4 + 14 = 18');
    expect(find.text('14 + 4 = 18'), findsOneWidget);
    await tester.ensureVisible(_key('challenge-next'));
    await tester.pump();
    _expectWithinViewport(
      tester,
      _key('challenge-next'),
      size,
      interactive: true,
    );
    expect(tester.takeException(), isNull);
  });

  for (final language in ['en', 'es', 'fr']) {
    for (final size in _viewports) {
      for (final scale in [1.0, 1.5]) {
        testWidgets(
          '$language $size at $scale text keeps two vertical branches safe',
          (tester) async {
            for (final problem in [_problem(4, 14), _problem(110, 999)]) {
              await _pumpWorkspace(
                tester,
                size: size,
                language: language,
                textScale: scale,
                problem: problem,
              );
              await _expectBranchGeometry(tester, size);
              await _expectScrollableControls(tester, size);
            }
          },
        );
      }
    }
  }

  for (final size in _viewports) {
    testWidgets(
      '$size automatic and restored parts fit the lower branching row',
      (tester) async {
        final completions = <bool>[];
        await _pumpWorkspace(
          tester,
          size: size,
          language: 'fr',
          textScale: 1.5,
          problem: _problem(110, 235),
          completions: completions,
        );
        await _tap(tester, _number(200));
        await _tap(tester, _number(30));
        await tester.pump(const Duration(milliseconds: 700));
        expect(completions, isEmpty);
        await _expectBranchGeometry(tester, size, partCount: 3);
        await _tap(
          tester,
          find.byTooltip(LanguageService.translate('bond_clear', 'fr')),
        );
        await _expectBranchGeometry(tester, size);
        expect(_part(2), findsNothing);
        await _pumpWorkspace(
          tester,
          size: size,
          language: 'fr',
          textScale: 1.5,
          problem: _problem(2345, 1234, operation: '-'),
          restoredAttempt: const NumberBondAttempt(
            isCorrect: true,
            attemptNumber: 1,
            usedHint: false,
            method: 'placeValue',
            selectedParts: [1000, 200, 30, 4],
          ),
        );
        await _expectBranchGeometry(tester, size, partCount: 4);
      },
    );
  }

  for (final language in ['en', 'es', 'fr']) {
    testWidgets('$language branching circle picker and grid still auto-check', (
      tester,
    ) async {
      const size = Size(320, 568);
      final completions = <bool>[];
      await _pumpWorkspace(
        tester,
        size: size,
        language: language,
        problem: _problem(4, 14),
        completions: completions,
      );
      await _pick(tester, 0, 10);
      expect(
        find.descendant(of: _part(0), matching: find.text('10')),
        findsOneWidget,
      );
      await _tap(tester, _number(4));
      await tester.pump(const Duration(milliseconds: 699));
      expect(completions, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(completions, [true]);
      await _expectBranchGeometry(tester, size);
    });
  }

  testWidgets(
    'canonical third part adds a third vertical branch without failure',
    (tester) async {
      const size = Size(320, 568);
      final completions = <bool>[];
      await _pumpWorkspace(
        tester,
        size: size,
        problem: _problem(110, 235),
        completions: completions,
      );
      await _tap(tester, _number(200));
      await _tap(tester, _number(30));
      await tester.pump(const Duration(milliseconds: 700));
      expect(completions, isEmpty);
      await _expectBranchGeometry(tester, size, partCount: 3);
      await _tap(tester, _number(5));
      await tester.pump(const Duration(milliseconds: 700));
      expect(completions, [true]);
      await _expectBranchGeometry(tester, size, partCount: 3);
    },
  );

  testWidgets(
    'landscape scrolling reaches all999 choices and the next challenge',
    (tester) async {
      const size = Size(568, 320);
      await _pumpWorkspace(tester, size: size, language: 'fr', textScale: 1.5);
      final expected = {
        for (var number = 1; number <= 9; number++) number,
        ...AnswerValidator.suggestedBreakdowns(
          number1: 110,
          number2: 999,
          action: 'addition',
        ).expand((parts) => parts),
      };
      for (final number in expected) {
        expect(_number(number), findsOneWidget);
      }
      await _expectScrollableControls(tester, size);
      await _expectBranchGeometry(tester, size);
    },
  );
}
