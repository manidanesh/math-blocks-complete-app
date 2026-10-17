import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:number_bond_math/models/kid_profile.dart';
import 'package:number_bond_math/models/rewards_model.dart';
import 'package:number_bond_math/providers/profile_provider.dart';
import 'package:number_bond_math/screens/adaptive_challenge_screen.dart';
import 'package:number_bond_math/services/answer_validator.dart';
import 'package:number_bond_math/services/language_service.dart';
import 'package:number_bond_math/services/problem_generator.dart';
import 'package:number_bond_math/services/problem_attempt_service.dart';
import 'package:number_bond_math/widgets/challenge_workspace.dart';
import 'package:number_bond_math/widgets/interactive_number_bond_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder _key(String value) => find.byKey(ValueKey(value));
Finder _number(int number) => _key('bond-number-$number');
Finder _part(int index) => _key('bond-part-$index');

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

ChildRewards get _rewards => ChildRewards(
  childId: 'test-child',
  totalStars: 83,
  totalBadges: 3,
  totalStickers: 1,
  currentLevel: ChildLevel.tensBuilder,
  recentRewards: const [],
  badges: const [],
  stickers: const [],
  lastUpdated: DateTime(2026, 10, 10),
);

Future<void> _pumpWorkspace(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  EdgeInsets safe = const EdgeInsets.only(top: 47, bottom: 34),
  MathProblem? problem,
  String language = 'en',
  double textScale = 1,
  bool showRetry = false,
  bool showSolution = false,
  bool showAnswer = false,
  List<bool>? completions,
  VoidCallback? next,
  VoidCallback? retry,
}) async {
  var answerVisible = showAnswer;
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: safe,
          viewPadding: safe,
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
        body: StatefulBuilder(
          builder: (context, setState) => ChallengeWorkspace(
            compact: true,
            childName: 'Alexandria Long Child Name',
            level: 4,
            problem: problem ?? _problem(110, 235),
            rewards: _rewards,
            language: language,
            showRetry: showRetry,
            showSolution: showSolution,
            showAnswer: answerVisible,
            onBondComplete: (correct) {
              completions?.add(correct);
              if (correct) setState(() => answerVisible = true);
            },
            onNextChallenge: next ?? () {},
            onRetryChallenge: retry ?? () {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void _expectCoreVisible(WidgetTester tester, Size size, EdgeInsets safe) {
  _expectNoManualPartControls();
  expect(tester.takeException(), isNull);
  expect(
    find.byWidgetPredicate(
      (widget) =>
          widget is ScrollView && widget.scrollDirection == Axis.vertical,
    ),
    findsNothing,
  );
  for (final name in [
    'challenge-question',
    'bond-part-0',
    'bond-part-1',
    'challenge-next',
  ]) {
    final finder = _key(name);
    expect(finder, findsOneWidget);
    final rect = tester.getRect(finder);
    expect(rect.top, greaterThanOrEqualTo(safe.top));
    expect(rect.bottom, lessThanOrEqualTo(size.height - safe.bottom));
    expect(rect.left, greaterThanOrEqualTo(safe.left));
    expect(rect.right, lessThanOrEqualTo(size.width - safe.right));
    expect(finder.hitTestable(), findsOneWidget);
  }
  final choices = find.byWidgetPredicate(
    (widget) =>
        widget is InkWell &&
        widget.key is ValueKey<String> &&
        (widget.key! as ValueKey<String>).value.startsWith('bond-number-'),
  );
  expect(choices, findsWidgets);
  for (final element in choices.evaluate()) {
    final finder = find.byWidget(element.widget);
    final rect = tester.getRect(finder);
    expect(rect.width, greaterThanOrEqualTo(44 - 0.000001));
    expect(rect.height, greaterThanOrEqualTo(44 - 0.000001));
    expect(rect.top, greaterThan(tester.getRect(_part(0)).bottom));
    expect(rect.bottom, lessThan(tester.getRect(_key('challenge-next')).top));
    expect(finder.hitTestable(), findsOneWidget);
  }
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
  await tester.pumpAndSettle();
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
  testWidgets(
    'real challenge screen uses the full workspace and records success',
    (tester) async {
      final profile = KidProfile(
        id: 'test-child',
        name: 'Maya',
        birthYear: 2019,
        avatarId: 'default',
        language: 'en',
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
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(top: 47, bottom: 34),
                viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
              ),
              child: child!,
            ),
            home: const AdaptiveChallengeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_key('challenge-page-scroll'), findsOneWidget);
      _expectNoManualPartControls();
      expect(_key('challenge-profile-summary'), findsOneWidget);
      final bond = tester.widget<InteractiveNumberBondWidget>(
        find.byType(InteractiveNumberBondWidget),
      );
      expect(bond.compact, isFalse);
      final problem = tester
          .widget<ChallengeWorkspace>(find.byType(ChallengeWorkspace))
          .problem;
      final equation =
          '${problem.operand1} ${problem.operator} ${problem.operand2} = ';
      expect(
        tester.widget<Text>(_key('challenge-question')).data,
        '$equation?',
      );
      final parts = AnswerValidator.suggestedBreakdowns(
        number1: bond.operand1,
        number2: bond.operand2,
        action: bond.operation!,
      ).first;
      for (var i = 0; i < parts.length - 1; i++) {
        await _pick(tester, i, parts[i]);
      }
      await _tap(tester, _number(parts.last));
      await tester.pump(const Duration(milliseconds: 699));
      expect(
        tester.widget<Text>(_key('challenge-question')).data,
        '$equation?',
      );
      await tester.pump(const Duration(milliseconds: 1));
      expect(
        tester.widget<Text>(_key('challenge-question')).data,
        '$equation${problem.correctAnswer}',
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      final rewards =
          jsonDecode(prefs.getString('rewards_test-child')!)
              as Map<String, dynamic>;
      expect(rewards['totalStars'], 1);
      final attempt = (await ProblemAttemptService.getAttemptsForChild(
        'test-child',
      )).single;
      expect(attempt.isCorrect, isTrue);
      expect(attempt.attemptNumber, 1);
      expect(attempt.usedHint, isFalse);
      expect(attempt.timeSpentSeconds, greaterThan(0));
      expect(attempt.timeSpentSeconds, isNot(30));
      expect(container.read(profileProvider).value?.totalProblemsCompleted, 1);
      expect(container.read(profileProvider).value?.overallAccuracy, 1);
      await _tap(tester, _key('challenge-next'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(_key('challenge-question')).data,
        endsWith('= ?'),
      );
      expect(_key('challenge-page-scroll'), findsOneWidget);
      await tester.ensureVisible(_part(0));
      await tester.pumpAndSettle();
      expect(_part(0).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'terminal failure, hint use and successful retry are recorded separately',
    (tester) async {
      final profile = KidProfile(
        id: 'test-child',
        name: 'Maya',
        birthYear: 2019,
        avatarId: 'default',
        language: 'en',
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
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: AdaptiveChallengeScreen(initialProblem: _problem(4, 14)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(_key('challenge-question')).data,
        '4 + 14 = ?',
      );
      for (var failure = 0; failure < 3; failure++) {
        if (failure > 0) {
          await _tap(
            tester,
            find.byTooltip(LanguageService.translate('bond_clear', 'en')),
          );
          await tester.pump();
        }
        await _pick(tester, 0, 1);
        await _pick(tester, 1, 1);
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();
        expect(
          tester.widget<Text>(_key('challenge-question')).data,
          '4 + 14 = ?',
        );
      }
      for (var pump = 0; pump < 10; pump++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(_key('challenge-retry'), findsOneWidget);
      final failed = (await ProblemAttemptService.getAttemptsForChild(
        'test-child',
      )).single;
      expect(failed.isCorrect, isFalse);
      expect(failed.attemptNumber, 3);
      expect(failed.usedHint, isTrue);
      await _tap(tester, _key('challenge-retry'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(_key('challenge-question')).data,
        '4 + 14 = ?',
      );
      await _pick(tester, 0, 10);
      await _pick(tester, 1, 4);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      final attempts = await ProblemAttemptService.getAttemptsForChild(
        'test-child',
      );
      expect(
        tester.widget<Text>(_key('challenge-question')).data,
        '4 + 14 = 18',
      );
      expect(attempts.length, 2);
      expect(attempts.first.isCorrect, isTrue);
      expect(attempts.first.id, isNot(failed.id));
      expect(attempts.first.attemptNumber, 1);
      expect(attempts.first.usedHint, isFalse);
      expect(attempts.first.strategy, 'placeValue');
      final updatedProfile = container.read(profileProvider).value!;
      expect(updatedProfile.totalProblemsCompleted, 2);
      expect(updatedProfile.totalStars, 1);
      expect(updatedProfile.overallAccuracy, 0.5);
      expect(tester.takeException(), isNull);
    },
  );

  for (final language in ['en', 'es', 'fr']) {
    for (final scenario in [
      (
        size: const Size(390, 844),
        safe: const EdgeInsets.only(top: 47, bottom: 34),
      ),
      (size: const Size(320, 568), safe: const EdgeInsets.only(top: 20)),
      (
        size: const Size(320, 568),
        safe: const EdgeInsets.only(top: 47, bottom: 34),
      ),
      (size: const Size(568, 320), safe: const EdgeInsets.only(top: 20)),
    ]) {
      testWidgets('$language ${scenario.size} keeps entry visible', (
        tester,
      ) async {
        await _pumpWorkspace(
          tester,
          size: scenario.size,
          safe: scenario.safe,
          language: language,
          problem: _problem(110, 999),
        );
        _expectCoreVisible(tester, scenario.size, scenario.safe);
      });
    }
  }

  testWidgets(
    'iPhone shows all235 number choices without paging or scrolling',
    (tester) async {
      await _pumpWorkspace(tester);
      final expected = {
        for (var n = 1; n <= 9; n++) n,
        ...AnswerValidator.suggestedBreakdowns(
          number1: 110,
          number2: 235,
          action: 'addition',
        ).expand((parts) => parts),
      };
      for (final number in expected) {
        expect(_number(number).hitTestable(), findsOneWidget);
      }
      expect(_key('bond-numbers-next'), findsNothing);
    },
  );

  testWidgets(
    'small phone pages retain every available number and selected part',
    (tester) async {
      const size = Size(320, 568);
      const safe = EdgeInsets.only(top: 47, bottom: 34);
      await _pumpWorkspace(
        tester,
        size: size,
        safe: safe,
        problem: _problem(110, 999),
      );
      await _tap(tester, _number(900));
      final expected = {
        for (var n = 1; n <= 9; n++) n,
        ...AnswerValidator.suggestedBreakdowns(
          number1: 110,
          number2: 999,
          action: 'addition',
        ).expand((parts) => parts),
      };
      final seen = <int>{};
      for (var page = 0; page < 30; page++) {
        _expectCoreVisible(tester, size, safe);
        for (final number in expected) {
          if (_number(number).evaluate().isNotEmpty) seen.add(number);
        }
        final next = tester.widget<IconButton>(_key('bond-numbers-next'));
        if (next.onPressed == null) break;
        await _tap(tester, _key('bond-numbers-next'));
      }
      expect(seen, expected);
      expect(
        find.descendant(of: _part(0), matching: find.text('900')),
        findsOneWidget,
      );
      expect(
        tester.widget<IconButton>(_key('bond-numbers-next')).onPressed,
        isNull,
      );
      await _tap(tester, _key('bond-numbers-previous'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('grid completes a canonical split without moving the question', (
    tester,
  ) async {
    final completions = <bool>[];
    await _pumpWorkspace(tester, completions: completions);
    final question = tester.getRect(_key('challenge-question'));
    expect(
      tester.widget<Text>(_key('challenge-question')).data,
      '110 + 235 = ?',
    );
    await _tap(tester, _number(200));
    await _tap(tester, _number(30));
    await tester.pump(const Duration(milliseconds: 700));
    expect(_part(2).hitTestable(), findsOneWidget);
    expect(
      tester.widget<Text>(_key('challenge-question')).data,
      '110 + 235 = ?',
    );
    await _tap(tester, _number(5));
    await tester.pump(const Duration(milliseconds: 699));
    expect(
      tester.widget<Text>(_key('challenge-question')).data,
      '110 + 235 = ?',
    );
    await tester.pump(const Duration(milliseconds: 1));
    expect(completions, [true]);
    expect(
      tester.widget<Text>(_key('challenge-question')).data,
      '110 + 235 = 345',
    );
    expect(tester.getRect(_key('challenge-question')).center, question.center);
    _expectCoreVisible(
      tester,
      const Size(390, 844),
      const EdgeInsets.only(top: 47, bottom: 34),
    );
    await _tap(tester, _key('bond-feedback-details'));
    await tester.pumpAndSettle();
    expect(_key('bond-feedback-sheet'), findsOneWidget);
    expect(find.text('110 + 200 = 310'), findsOneWidget);
    expect(find.text('340 + 5 = 345'), findsOneWidget);
    await _tap(tester, _key('bond-feedback-close'));
    await tester.pumpAndSettle();
    expect(completions, [true]);
  });

  testWidgets('circle picker and compact retry help keep entry usable', (
    tester,
  ) async {
    final completions = <bool>[];
    await _pumpWorkspace(
      tester,
      size: const Size(320, 568),
      safe: const EdgeInsets.only(top: 47, bottom: 34),
      problem: _problem(29, 15, operation: '-'),
      completions: completions,
    );
    await _pick(tester, 0, 10);
    await _pick(tester, 1, 4);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('2 tries left. Tap info for help.'), findsOneWidget);
    expect(tester.widget<Text>(_key('challenge-question')).data, '29 - 15 = ?');
    _expectCoreVisible(
      tester,
      const Size(320, 568),
      const EdgeInsets.only(top: 47, bottom: 34),
    );
    await _tap(tester, _key('bond-feedback-details'));
    await tester.pumpAndSettle();
    expect(find.text('Try splitting 15 into 10 + 5.'), findsOneWidget);
    await _tap(tester, find.text('Clear & Try Again!'));
    await tester.pumpAndSettle();
    expect(_key('bond-feedback-sheet'), findsNothing);
    await _pick(tester, 0, 10);
    await _pick(tester, 1, 5);
    await tester.pump(const Duration(milliseconds: 700));
    expect(completions, [true]);
    expect(
      tester.widget<Text>(_key('challenge-question')).data,
      '29 - 15 = 14',
    );
  });

  testWidgets(
    'automatic four part answers fit beside whole number on small phone',
    (tester) async {
      final completions = <bool>[];
      await _pumpWorkspace(
        tester,
        size: const Size(320, 568),
        safe: const EdgeInsets.only(top: 20),
        problem: _problem(2345, 1234, operation: '-'),
        completions: completions,
      );
      _expectNoManualPartControls();
      await _pick(tester, 0, 1000);
      await _pick(tester, 1, 200);
      await tester.pump(const Duration(milliseconds: 700));
      expect(completions, isEmpty);
      expect(
        tester.widget<Text>(_key('challenge-question')).data,
        '2345 - 1234 = ?',
      );
      for (var i = 0; i < 4; i++) {
        expect(_part(i).hitTestable(), findsOneWidget);
      }
      await _pick(tester, 2, 30);
      await _pick(tester, 3, 4);
      await tester.pump(const Duration(milliseconds: 700));
      expect(completions, [true]);
      expect(
        tester.widget<Text>(_key('challenge-question')).data,
        '2345 - 1234 = 1111',
      );
      _expectNoManualPartControls();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('larger text and review actions preserve the entry viewport', (
    tester,
  ) async {
    var nextCount = 0;
    var retryCount = 0;
    await _pumpWorkspace(
      tester,
      size: const Size(320, 568),
      safe: const EdgeInsets.only(top: 20),
      language: 'fr',
      textScale: 1.5,
      showRetry: true,
      showSolution: true,
      next: () => nextCount++,
      retry: () => retryCount++,
    );
    _expectCoreVisible(
      tester,
      const Size(320, 568),
      const EdgeInsets.only(top: 20),
    );
    expect(
      tester.widget<Text>(_key('challenge-question')).data,
      '110 + 235 = ?',
    );
    await _tap(tester, _key('challenge-retry'));
    await _tap(tester, _key('challenge-next'));
    expect(nextCount, 1);
    expect(retryCount, 1);
    await _tap(tester, _key('bond-feedback-details'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: _key('bond-feedback-sheet'),
        matching: find.text(
          LanguageService.translate('step_by_step_solution', 'fr'),
        ),
      ),
      findsOneWidget,
    );
  });
}
