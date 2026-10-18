import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:number_bond_math/models/kid_profile.dart';
import 'package:number_bond_math/providers/profile_provider.dart';
import 'package:number_bond_math/screens/adaptive_challenge_screen.dart';
import 'package:number_bond_math/services/adaptive_challenge_engine.dart';
import 'package:number_bond_math/services/problem_attempt_service.dart';
import 'package:number_bond_math/services/problem_generator.dart';
import 'package:number_bond_math/services/rewards_service.dart';
import 'package:number_bond_math/widgets/challenge_workspace.dart';
import 'package:number_bond_math/widgets/interactive_number_bond_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _channel = MethodChannel('plugins.flutter.io/shared_preferences');

class _Preferences {
  final Map<String, Object> disk;
  String? failingKey;
  String? failingRemoveKey;
  bool throws = false;
  Completer<void>? profileGate;
  Completer<void>? journalGate;
  bool profileWriteStarted = false;
  bool journalWriteStarted = false;

  _Preferences(KidProfile profile)
    : disk = {'flutter.current_profile': jsonEncode(profile.toJson())};

  Future<Object?> handle(MethodCall call) async {
    if (call.method == 'getAll') return Map<String, Object>.from(disk);
    final args = call.arguments as Map<Object?, Object?>;
    final key = args['key']! as String;
    if (call.method == 'remove') {
      if (key == 'flutter.$failingRemoveKey') {
        if (throws) throw PlatformException(code: 'remove_failed');
        return false;
      }
      disk.remove(key);
      return true;
    }
    if (call.method.startsWith('set')) {
      if (key == 'flutter.pending_challenge_completion_child') {
        journalWriteStarted = true;
        await journalGate?.future;
      }
      if (key == 'flutter.current_profile') {
        profileWriteStarted = true;
        await profileGate?.future;
      }
      if (key == 'flutter.$failingKey') {
        if (throws) throw PlatformException(code: 'write_failed');
        return false;
      }
      final value = args['value']!;
      disk[key] = value is List ? value.cast<String>().toList() : value;
      return true;
    }
    throw StateError('Unexpected preference method: ${call.method}');
  }
}

Finder _key(String key) => find.byKey(ValueKey(key));

String _question(WidgetTester tester) =>
    tester.widget<Text>(_key('challenge-question')).data!;

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _choosePart(WidgetTester tester, int index, int number) async {
  await _tap(tester, _key('bond-part-$index'));
  await _tap(tester, _key('bond-picker-number-$number'));
}

Future<void> _solve(WidgetTester tester) async {
  await _choosePart(tester, 0, 10);
  await _choosePart(tester, 1, 4);
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pumpAndSettle();
}

void main() {
  late _Preferences store;
  late ProviderContainer container;

  setUp(() {
    final profile = KidProfile(
      id: 'child',
      name: 'Maya',
      age: 7,
      avatarId: 'default',
      language: 'en',
      isCurrent: true,
      createdAt: DateTime(2026),
      lastPlayed: DateTime(2026),
    );
    store = _Preferences(profile);
    SharedPreferences.resetStatic();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, store.handle);
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
    SharedPreferences.resetStatic();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  Future<void> pumpChallenge(WidgetTester tester, {bool preload = true}) async {
    if (preload) await container.read(profileProvider.future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: AdaptiveChallengeScreen(
            initialProblem: MathProblem(
              operand1: 4,
              operand2: 14,
              operator: '+',
              correctAnswer: 18,
              problemText: '4 + 14',
              options: const [],
              strategy: ProblemStrategy.crossing,
              level: 1,
              explanation: '',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> closeChallenge(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: Text('Challenge closed')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final key in [
    'pending_challenge_completion_child',
    'adaptive_challenge_results_child',
    'challenge_count_child',
    'problem_attempts',
    'pending_insight_events_child',
    'rewards_child',
    'current_profile',
  ]) {
    for (final throws in [false, true]) {
      testWidgets(
        '${throws ? 'throwing' : 'rejected'} $key retries the same completion once',
        (tester) async {
          await pumpChallenge(tester);
          expect(_question(tester), '4 + 14 = ?');
          store.failingKey = key;
          store.throws = throws;
          await _solve(tester);
          expect(_question(tester), '4 + 14 = 18');
          expect(find.text('4 + 10 = 14'), findsOneWidget);
          expect(find.text('14 + 4 = 18'), findsOneWidget);
          expect(find.text('Retry saving'), findsOneWidget);
          expect(
            tester.widget<ElevatedButton>(_key('challenge-next')).onPressed,
            isNull,
          );
          final bondKey = tester
              .widget<InteractiveNumberBondWidget>(
                find.byType(InteractiveNumberBondWidget),
              )
              .key;
          final before = await ProblemAttemptService.getAttemptsForChild(
            'child',
          );
          final savedEventId = before.isEmpty ? null : before.single.id;

          store.failingKey = null;
          await _tap(tester, _key('challenge-retry'));
          expect(_question(tester), '4 + 14 = 18');
          // The already entered answer stays intact; no second solve is needed.
          final bond = tester.widget<InteractiveNumberBondWidget>(
            find.byType(InteractiveNumberBondWidget),
          );
          expect(bond.key, bondKey);
          final attempts = await ProblemAttemptService.getAttemptsForChild(
            'child',
          );
          expect(attempts, hasLength(1));
          if (savedEventId != null) expect(attempts.single.id, savedEventId);
          expect(attempts.single.isCorrect, isTrue);
          expect(attempts.single.attemptNumber, 1);
          expect(await AdaptiveChallengeEngine.getChallengeCount('child'), 1);
          expect((await RewardsService.getRewards('child')).totalStars, 1);
          expect(
            container.read(profileProvider).value!.totalProblemsCompleted,
            1,
          );
          expect(container.read(profileProvider).value!.totalStars, 1);

          // Repeated delivery after recovery also cannot count or award again.
          await (bond.onBondComplete!(true) as Future<void>);
          expect(await AdaptiveChallengeEngine.getChallengeCount('child'), 1);
          expect((await RewardsService.getRewards('child')).totalStars, 1);
          expect(
            container.read(profileProvider).value!.totalProblemsCompleted,
            1,
          );
          await tester.pump(const Duration(seconds: 3));
          await tester.pumpAndSettle();
          expect(_question(tester), '4 + 14 = 18');
          expect(
            tester.widget<ElevatedButton>(_key('challenge-next')).onPressed,
            isNotNull,
          );
          expect(_key('challenge-retry'), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('saving a failed outcome preserves the later learning retry', (
    tester,
  ) async {
    await pumpChallenge(tester);
    store.failingKey = 'current_profile';
    for (var attempt = 0; attempt < 3; attempt++) {
      await _choosePart(tester, 0, 10);
      await _choosePart(tester, 1, 3);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(_question(tester), '4 + 14 = ?');
      if (attempt < 2) {
        await _tap(tester, find.byTooltip('Clear and try again'));
      }
    }
    expect(find.text('Retry saving'), findsOneWidget);
    final failed = (await ProblemAttemptService.getAttemptsForChild(
      'child',
    )).single;
    expect(failed.isCorrect, isFalse);
    expect(failed.attemptNumber, 3);

    await closeChallenge(tester);
    await pumpChallenge(tester);
    expect(_question(tester), '4 + 14 = ?');
    expect(find.text('Retry saving'), findsOneWidget);

    store.failingKey = null;
    await _tap(tester, _key('challenge-retry'));
    expect(find.text('Try Again'), findsOneWidget);
    expect(_question(tester), '4 + 14 = ?');
    expect(container.read(profileProvider).value!.totalProblemsCompleted, 1);
    expect((await RewardsService.getRewards('child')).totalStars, 0);

    await _tap(tester, _key('challenge-retry'));
    expect(_question(tester), '4 + 14 = ?');
    await _solve(tester);
    expect(_question(tester), '4 + 14 = 18');
    final attempts = await ProblemAttemptService.getAttemptsForChild('child');
    expect(attempts, hasLength(2));
    expect(
      attempts.where((entry) => entry.isCorrect).single.id,
      isNot(failed.id),
    );
    expect(
      attempts.singleWhere((entry) => entry.id == failed.id).attemptNumber,
      3,
    );
    final profile = container.read(profileProvider).value!;
    expect(profile.totalProblemsCompleted, 2);
    expect(profile.totalStars, 1);
    expect(profile.overallAccuracy, 0.5);
    expect(await AdaptiveChallengeEngine.getChallengeCount('child'), 2);
    expect((await RewardsService.getRewards('child')).totalStars, 1);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending save disables advancement and repeated retries', (
    tester,
  ) async {
    await pumpChallenge(tester);
    store.profileGate = Completer<void>();
    await _solve(tester);
    expect(store.profileWriteStarted, isTrue);
    expect(find.text('Saving result...'), findsOneWidget);
    expect(_question(tester), '4 + 14 = 18');
    expect(
      tester.widget<ElevatedButton>(_key('challenge-next')).onPressed,
      isNull,
    );
    expect(
      tester.widget<OutlinedButton>(_key('challenge-retry')).onPressed,
      isNull,
    );
    store.profileGate!.complete();
    await tester.pumpAndSettle();
    expect(container.read(profileProvider).value!.totalProblemsCompleted, 1);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ElevatedButton>(_key('challenge-next')).onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'correct bond reveals the answer before the first save and next resets it',
    (tester) async {
      await pumpChallenge(tester);
      expect(_question(tester), '4 + 14 = ?');
      store.journalGate = Completer<void>();
      await _solve(tester);
      expect(store.journalWriteStarted, isTrue);
      expect(_question(tester), '4 + 14 = 18');
      expect(find.text('4 + 10 = 14'), findsOneWidget);
      expect(find.text('14 + 4 = 18'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      expect(await ProblemAttemptService.getAttemptsForChild('child'), isEmpty);
      expect(container.read(profileProvider).value!.totalProblemsCompleted, 0);
      store.journalGate!.complete();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(_question(tester), '4 + 14 = 18');
      expect(find.text('4 + 10 = 14'), findsOneWidget);
      await _tap(tester, _key('challenge-next'));
      expect(_question(tester), endsWith(' = ?'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed next-challenge load never redisplays a completed round', (
    tester,
  ) async {
    await pumpChallenge(tester);
    await _solve(tester);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    final savedState = prefs.getString('adaptive_state_child')!;
    await prefs.setString('adaptive_state_child', '{unreadable');
    await _tap(tester, _key('challenge-next'));
    expect(find.byType(InteractiveNumberBondWidget), findsNothing);
    expect(find.text('Try Again'), findsOneWidget);

    await prefs.setString('adaptive_state_child', savedState);
    await _tap(tester, find.text('Try Again'));
    expect(find.byType(InteractiveNumberBondWidget), findsOneWidget);
    expect(_question(tester), endsWith(' = ?'));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'challenge opened before profile loading still displays rewards',
    (tester) async {
      await RewardsService.addStar('child');
      container.dispose();
      SharedPreferences.resetStatic();
      container = ProviderContainer();
      await pumpChallenge(tester, preload: false);
      final workspace = tester.widget<ChallengeWorkspace>(
        find.byType(ChallengeWorkspace),
      );
      expect(workspace.rewards?.totalStars, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reopening restores the original pending event and attempt metrics',
    (tester) async {
      await pumpChallenge(tester);
      store.failingKey = 'current_profile';
      await _choosePart(tester, 0, 10);
      await _choosePart(tester, 1, 3);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      await _choosePart(tester, 1, 4);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      final pending =
          jsonDecode(
                store.disk['flutter.pending_challenge_completion_child']!
                    as String,
              )
              as Map<String, dynamic>;
      expect((pending['attempt'] as Map)['attemptNumber'], 2);
      expect((pending['attempt'] as Map)['usedHint'], isTrue);
      expect((pending['attempt'] as Map)['selectedParts'], [10, 4]);
      await closeChallenge(tester);
      await pumpChallenge(tester);
      expect(find.text('Retry saving'), findsOneWidget);
      final recoveredBond = tester.widget<InteractiveNumberBondWidget>(
        find.byType(InteractiveNumberBondWidget),
      );
      expect(recoveredBond.showSolution, isTrue);
      expect(_question(tester), '4 + 14 = 18');
      expect(recoveredBond.enabled, isFalse);
      expect(recoveredBond.restoredAttempt?.selectedParts, [10, 4]);
      expect(find.text('Break 14 into 10 + 4'), findsOneWidget);
      expect(tester.widget<InkWell>(_key('bond-part-0')).onTap, isNull);

      store.failingKey = null;
      await _tap(tester, _key('challenge-retry'));
      final attempt = (await ProblemAttemptService.getAttemptsForChild(
        'child',
      )).single;
      expect(attempt.id, pending['eventId']);
      expect(attempt.attemptNumber, 2);
      expect(attempt.usedHint, isTrue);
      expect(attempt.strategy, (pending['attempt'] as Map)['method']);
      expect(attempt.timeSpentSeconds, pending['timeTaken']);
      expect(await AdaptiveChallengeEngine.getChallengeCount('child'), 1);
      expect((await RewardsService.getRewards('child')).totalStars, 1);
      expect(container.read(profileProvider).value!.totalProblemsCompleted, 1);
      expect(container.read(profileProvider).value!.totalStars, 1);
      expect(store.disk['flutter.pending_challenge_completion_child'], isNull);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reopening during a pending write resumes without another outcome',
    (tester) async {
      await pumpChallenge(tester);
      store.profileGate = Completer<void>();
      await _solve(tester);
      expect(store.profileWriteStarted, isTrue);
      await closeChallenge(tester);
      await pumpChallenge(tester);
      expect(find.text('Saving result...'), findsOneWidget);
      expect(_question(tester), '4 + 14 = 18');
      store.profileGate!.complete();
      await tester.pumpAndSettle();
      expect(await AdaptiveChallengeEngine.getChallengeCount('child'), 1);
      expect(
        (await ProblemAttemptService.getAttemptsForChild('child')).length,
        1,
      );
      expect((await RewardsService.getRewards('child')).totalStars, 1);
      expect(container.read(profileProvider).value!.totalProblemsCompleted, 1);
      expect(store.disk['flutter.pending_challenge_completion_child'], isNull);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'recovered success without attempt metadata still reveals its answer',
    (tester) async {
      await pumpChallenge(tester);
      store.failingKey = 'current_profile';
      final bond = tester.widget<InteractiveNumberBondWidget>(
        find.byType(InteractiveNumberBondWidget),
      );
      await (bond.onBondComplete!(true) as Future<void>);
      await tester.pumpAndSettle();
      final pending =
          jsonDecode(
                store.disk['flutter.pending_challenge_completion_child']!
                    as String,
              )
              as Map<String, dynamic>;
      expect(pending.containsKey('attempt'), isFalse);
      await closeChallenge(tester);
      await pumpChallenge(tester);
      expect(_question(tester), '4 + 14 = 18');
      expect(find.text('Retry saving'), findsOneWidget);
      expect(
        tester
            .widget<InteractiveNumberBondWidget>(
              find.byType(InteractiveNumberBondWidget),
            )
            .restoredAttempt,
        isNull,
      );
      store.failingKey = null;
      await _tap(tester, _key('challenge-retry'));
      expect(_question(tester), '4 + 14 = 18');
      expect(container.read(profileProvider).value!.totalProblemsCompleted, 1);
      expect((await RewardsService.getRewards('child')).totalStars, 1);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  for (final throws in [false, true]) {
    testWidgets(
      '${throws ? 'throwing' : 'rejected'} journal cleanup stays retryable',
      (tester) async {
        await pumpChallenge(tester);
        store.failingRemoveKey = 'pending_challenge_completion_child';
        store.throws = throws;
        await _solve(tester);
        expect(find.text('Retry saving'), findsOneWidget);
        expect(
          container.read(profileProvider).value!.totalProblemsCompleted,
          1,
        );
        expect(
          store.disk['flutter.pending_challenge_completion_child'],
          isNotNull,
        );
        store.failingRemoveKey = null;
        await _tap(tester, _key('challenge-retry'));
        expect(await AdaptiveChallengeEngine.getChallengeCount('child'), 1);
        expect((await RewardsService.getRewards('child')).totalStars, 1);
        expect(
          container.read(profileProvider).value!.totalProblemsCompleted,
          1,
        );
        expect(
          store.disk['flutter.pending_challenge_completion_child'],
          isNull,
        );
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('reset waits for an active save and cancels queued recovery', (
    tester,
  ) async {
    await pumpChallenge(tester);
    store.profileGate = Completer<void>();
    await _solve(tester);
    await closeChallenge(tester);
    await pumpChallenge(tester);
    expect(find.text('Saving result...'), findsOneWidget);
    final reset = container.read(profileProvider.notifier).resetProgress();
    store.profileGate!.complete();
    await reset;
    await tester.pumpAndSettle();
    expect(_question(tester), endsWith(' = ?'));
    expect(await AdaptiveChallengeEngine.getChallengeCount('child'), 0);
    expect(await ProblemAttemptService.getAttemptsForChild('child'), isEmpty);
    expect((await RewardsService.getRewards('child')).totalStars, 0);
    expect(container.read(profileProvider).value!.totalProblemsCompleted, 0);
    expect(container.read(profileProvider).value!.totalStars, 0);
    expect(store.disk['flutter.pending_challenge_completion_child'], isNull);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'an unreadable journal blocks new outcomes and retains its bytes',
    (tester) async {
      const raw = '{unreadable outcome';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_challenge_completion_child', raw);
      await pumpChallenge(tester);
      expect(find.byType(InteractiveNumberBondWidget), findsNothing);
      expect(find.text('Try Again'), findsOneWidget);
      await _tap(tester, find.text('Try Again'));
      expect(find.byType(InteractiveNumberBondWidget), findsNothing);
      expect(store.disk['flutter.pending_challenge_completion_child'], raw);
      expect(await AdaptiveChallengeEngine.getChallengeCount('child'), 0);
      expect(container.read(profileProvider).value!.totalProblemsCompleted, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
