import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:number_bond_math/models/adaptive_challenge.dart';
import 'package:number_bond_math/models/problem_attempt.dart';
import 'package:number_bond_math/services/adaptive_challenge_engine.dart';
import 'package:number_bond_math/services/adaptive_problem_service.dart';
import 'package:number_bond_math/services/insights_engine.dart';
import 'package:number_bond_math/services/problem_attempt_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _channel = MethodChannel('plugins.flutter.io/shared_preferences');

class _Preferences {
  final Map<String, Object> disk = {};
  final Set<String> rejected = {};
  final Set<String> throwing = {};
  final List<({String key, Map<String, Object> disk})> checkpoints = [];

  Future<Object?> handle(MethodCall call) async {
    if (call.method == 'getAll') return Map<String, Object>.from(disk);
    final args = call.arguments as Map<Object?, Object?>;
    final key = args['key']! as String;
    if (call.method == 'remove') {
      disk.remove(key);
      return true;
    }
    if (call.method.startsWith('set')) {
      if (throwing.contains(key)) throw PlatformException(code: 'write_failed');
      if (rejected.contains(key)) return false;
      final value = args['value']!;
      disk[key] = value is List ? value.cast<String>().toList() : value;
      checkpoints.add((key: key, disk: Map<String, Object>.from(disk)));
      return true;
    }
    throw StateError('Unexpected preference method: ${call.method}');
  }
}

ProblemAttempt _attempt() => ProblemAttempt(
  id: 'event',
  childId: 'child',
  problemText: '29 - 15 = ?',
  operand1: 29,
  operand2: 15,
  operator: '-',
  correctAnswer: 14,
  userAnswer: 14,
  isCorrect: true,
  timestamp: DateTime(2026),
  attemptNumber: 1,
  timeSpentSeconds: 7.5,
  strategy: 'roundChunks',
  difficultyLevel: 2,
  skillArea: 'adaptive_level_2',
  usedHint: false,
);

ProblemResult _result({
  String id = 'event',
  int level = 2,
  bool correct = true,
}) => ProblemResult(
  problemId: id,
  childId: 'child',
  problemText: '29 - 15 = ?',
  level: level,
  correct: correct,
  timeTaken: 7.5,
  bondCorrect: true,
  timestamp: DateTime(2026),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Preferences store;
  setUp(() {
    SharedPreferences.resetStatic();
    store = _Preferences();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, store.handle);
  });
  tearDown(() {
    SharedPreferences.resetStatic();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  for (final throws in [false, true]) {
    test(
      'attempt write ${throws ? 'exception' : 'rejection'} reloads cache and permits retry',
      () async {
        (throws ? store.throwing : store.rejected).add(
          'flutter.problem_attempts',
        );
        await expectLater(
          ProblemAttemptService.recordAttempt(_attempt()),
          throws ? throwsA(isA<PlatformException>()) : throwsStateError,
        );
        expect(store.disk.containsKey('flutter.problem_attempts'), isFalse);
        expect(await ProblemAttemptService.getAllAttempts(), isEmpty);
        store.throwing.clear();
        store.rejected.clear();
        await ProblemAttemptService.recordAttempt(_attempt());
        expect((await ProblemAttemptService.getAllAttempts()).length, 1);
        expect(store.disk.containsKey('flutter.problem_attempts'), isTrue);
      },
    );

    test(
      'adaptive result write ${throws ? 'exception' : 'rejection'} remains retryable',
      () async {
        (throws ? store.throwing : store.rejected).add(
          'flutter.adaptive_challenge_results_child',
        );
        await expectLater(
          AdaptiveChallengeEngine.storeProblemResult(_result()),
          throws ? throwsA(isA<PlatformException>()) : throwsStateError,
        );
        expect(
          await AdaptiveChallengeEngine.getAllProblemResults('child'),
          isEmpty,
        );
        expect(await AdaptiveChallengeEngine.getChallengeCount('child'), 0);
        store.throwing.clear();
        store.rejected.clear();
        await AdaptiveChallengeEngine.storeProblemResult(_result());
        expect(
          (await AdaptiveChallengeEngine.getAllProblemResults('child')).length,
          1,
        );
        expect(await AdaptiveChallengeEngine.getChallengeCount('child'), 1);
      },
    );
  }

  test(
    'rejected adaptive count rolls back the partial history before a retry',
    () async {
      await AdaptiveChallengeEngine.storeProblemResult(_result(id: 'previous'));
      store.rejected.add('flutter.challenge_count_child');
      await expectLater(
        AdaptiveChallengeEngine.storeProblemResult(_result()),
        throwsStateError,
      );
      expect(
        (await AdaptiveChallengeEngine.getAllProblemResults(
          'child',
        )).single.problemId,
        'previous',
      );
      expect(await AdaptiveChallengeEngine.getChallengeCount('child'), 1);
      store.rejected.clear();
      await AdaptiveChallengeEngine.storeProblemResult(_result());
      expect(
        (await AdaptiveChallengeEngine.getAllProblemResults('child')).length,
        2,
      );
      expect(await AdaptiveChallengeEngine.getChallengeCount('child'), 2);
    },
  );

  test(
    'restart at every capped-history save prefix preserves a coherent count',
    () async {
      final oldResults = [for (var i = 0; i < 100; i++) _result(id: 'old-$i')];
      store.disk.addAll({
        'flutter.adaptive_challenge_results_child': jsonEncode(
          oldResults.map((r) => r.toJson()).toList(),
        ),
        'flutter.challenge_count_child': 119,
      });
      await AdaptiveChallengeEngine.storeProblemResult(_result());
      final checkpoints = List.of(store.checkpoints);
      expect(checkpoints.map((entry) => entry.key), [
        'flutter.adaptive_state_child',
        'flutter.adaptive_challenge_results_child',
        'flutter.challenge_count_child',
        'flutter.adaptive_state_child',
      ]);
      for (var prefix = 0; prefix < checkpoints.length; prefix++) {
        SharedPreferences.resetStatic();
        store.disk
          ..clear()
          ..addAll(checkpoints[prefix].disk);
        final committed = prefix == checkpoints.length - 1;
        expect(
          await AdaptiveChallengeEngine.getChallengeCount('child'),
          committed ? 120 : 119,
          reason: 'prefix $prefix',
        );
        final results = await AdaptiveChallengeEngine.getAllProblemResults(
          'child',
        );
        expect(results.length, 100);
        expect(
          results.any((r) => r.problemId == 'event'),
          committed,
          reason: 'prefix $prefix',
        );
        await AdaptiveChallengeEngine.storeProblemResult(_result());
        expect(
          await AdaptiveChallengeEngine.getChallengeCount('child'),
          120,
          reason: 'retry prefix $prefix',
        );
        expect(
          (await AdaptiveChallengeEngine.getAllProblemResults(
            'child',
          )).where((r) => r.problemId == 'event').length,
          1,
        );
      }
    },
  );

  test(
    'legacy result saved before its count is repaired on same-event replay',
    () async {
      store.disk.addAll({
        'flutter.adaptive_challenge_results_child': jsonEncode([
          _result().toJson(),
        ]),
        'flutter.challenge_count_child': 0,
      });
      await AdaptiveChallengeEngine.storeProblemResult(_result());
      expect(await AdaptiveChallengeEngine.getChallengeCount('child'), 1);
      expect(store.disk['flutter.challenge_count_child'], 1);
      expect(
        (await AdaptiveChallengeEngine.getAllProblemResults('child')).length,
        1,
      );
    },
  );

  test(
    'restart at every level decision prefix preserves the fresh-outcome baseline',
    () async {
      for (var i = 0; i < 5; i++) {
        await AdaptiveChallengeEngine.storeProblemResult(
          _result(id: 'level1-$i', level: 1),
        );
      }
      store.checkpoints.clear();
      expect(await AdaptiveChallengeEngine.determineNextLevel('child', 1), 2);
      final checkpoints = List.of(store.checkpoints);
      expect(checkpoints.map((entry) => entry.key), [
        'flutter.adaptive_current_level_child',
        'flutter.adaptive_level_decision_child',
        'flutter.adaptive_level_start_count_child',
        'flutter.adaptive_state_child',
      ]);
      for (var prefix = 0; prefix < checkpoints.length; prefix++) {
        SharedPreferences.resetStatic();
        store.disk
          ..clear()
          ..addAll(checkpoints[prefix].disk);
        final level = await AdaptiveChallengeEngine.getCurrentLevel('child');
        expect(
          level,
          prefix == checkpoints.length - 1 ? 2 : 1,
          reason: 'prefix $prefix',
        );
        expect(
          await AdaptiveChallengeEngine.determineNextLevel('child', level),
          2,
        );
        expect(store.disk['flutter.adaptive_level_start_count_child'], 5);
        await AdaptiveChallengeEngine.storeProblemResult(
          _result(id: 'fresh-level2', level: 2),
        );
        expect(await AdaptiveChallengeEngine.determineNextLevel('child', 2), 2);
      }
    },
  );

  test(
    'migrated demotion retries a rejected baseline without reusing old successes',
    () async {
      store.disk.addAll({
        'flutter.adaptive_challenge_results_child': jsonEncode([
          for (var i = 0; i < 5; i++)
            _result(id: 'failed-level2-$i', correct: false).toJson(),
          for (var i = 0; i < 5; i++)
            _result(id: 'old-level1-$i', level: 1).toJson(),
        ]),
        'flutter.challenge_count_child': 10,
      });
      store.rejected.add('flutter.adaptive_level_start_count_child');
      await expectLater(
        AdaptiveChallengeEngine.determineNextLevel('child', 2),
        throwsStateError,
      );
      SharedPreferences.resetStatic();
      expect(await AdaptiveChallengeEngine.getCurrentLevel('child'), 2);
      store.rejected.clear();
      expect(await AdaptiveChallengeEngine.determineNextLevel('child', 2), 1);
      await AdaptiveChallengeEngine.storeProblemResult(
        _result(id: 'fresh-level1', level: 1),
      );
      expect(await AdaptiveChallengeEngine.determineNextLevel('child', 1), 1);
      expect(store.disk['flutter.adaptive_level_start_count_child'], 10);
    },
  );

  for (final throws in [false, true]) {
    test(
      'a ${throws ? 'throwing' : 'rejected'} adaptive snapshot commit retains the previous result',
      () async {
        await AdaptiveChallengeEngine.storeProblemResult(
          _result(id: 'previous'),
        );
        (throws ? store.throwing : store.rejected).add(
          'flutter.adaptive_state_child',
        );
        await expectLater(
          AdaptiveChallengeEngine.storeProblemResult(_result()),
          throws ? throwsA(isA<PlatformException>()) : throwsStateError,
        );
        SharedPreferences.resetStatic();
        expect(await AdaptiveChallengeEngine.getChallengeCount('child'), 1);
        expect(
          (await AdaptiveChallengeEngine.getAllProblemResults(
            'child',
          )).single.problemId,
          'previous',
        );
        store.throwing.clear();
        store.rejected.clear();
        await AdaptiveChallengeEngine.storeProblemResult(_result());
        expect(await AdaptiveChallengeEngine.getChallengeCount('child'), 2);
      },
    );
  }

  test(
    'normal progression retains the demotion baseline through a failed save',
    () async {
      for (var i = 0; i < 5; i++) {
        await AdaptiveChallengeEngine.storeProblemResult(
          _result(id: 'normal-level1-$i', level: 1),
        );
        await AdaptiveChallengeEngine.determineNextLevel('child', 1);
      }
      expect(await AdaptiveChallengeEngine.getCurrentLevel('child'), 2);
      for (var i = 0; i < 5; i++) {
        await AdaptiveChallengeEngine.storeProblemResult(
          _result(id: 'normal-level2-$i', correct: false),
        );
        if (i < 4) await AdaptiveChallengeEngine.determineNextLevel('child', 2);
      }
      store.rejected.add('flutter.adaptive_level_start_count_child');
      await expectLater(
        AdaptiveChallengeEngine.determineNextLevel('child', 2),
        throwsStateError,
      );
      SharedPreferences.resetStatic();
      expect(await AdaptiveChallengeEngine.getCurrentLevel('child'), 2);
      store.rejected.clear();
      expect(await AdaptiveChallengeEngine.determineNextLevel('child', 2), 1);
      expect(store.disk['flutter.adaptive_level_start_count_child'], 10);
      await AdaptiveChallengeEngine.storeProblemResult(
        _result(id: 'normal-fresh-level1', level: 1),
      );
      expect(await AdaptiveChallengeEngine.determineNextLevel('child', 1), 1);
    },
  );

  test('unreadable attempt history cannot be silently overwritten', () async {
    const raw = '{unreadable history';
    store.disk['flutter.problem_attempts'] = raw;
    await expectLater(
      ProblemAttemptService.getAllAttempts(),
      throwsFormatException,
    );
    await expectLater(
      ProblemAttemptService.recordAttempt(_attempt()),
      throwsFormatException,
    );
    expect(store.disk['flutter.problem_attempts'], raw);
  });

  test('unreadable adaptive history retains its saved bytes', () async {
    const raw = '{unreadable history';
    store.disk['flutter.adaptive_challenge_results_child'] = raw;
    await expectLater(
      AdaptiveChallengeEngine.storeProblemResult(_result()),
      throwsFormatException,
    );
    expect(store.disk['flutter.adaptive_challenge_results_child'], raw);
    expect(await AdaptiveChallengeEngine.getChallengeCount('child'), 0);
  });

  test(
    'rejected insight storage leaves primary records unique and analytics retryable',
    () async {
      Future<void> complete() => AdaptiveProblemService.recordAttempt(
        childId: 'child',
        problemId: 'event',
        problemText: '29 - 15 = ?',
        level: 2,
        correct: true,
        timeTaken: 7.5,
        bondCorrect: true,
        operand1: 29,
        operand2: 15,
        operator: '-',
        correctAnswer: 14,
        strategy: 'roundChunks',
      );
      store.rejected.add('flutter.insights_problem_logs');
      await complete();
      expect(await AdaptiveChallengeEngine.getChallengeCount('child'), 1);
      expect((await ProblemAttemptService.getAllAttempts()).length, 1);
      expect(await InsightsEngine.getProblemLogs('child'), isEmpty);
      store.rejected.clear();
      await complete();
      expect(await AdaptiveChallengeEngine.getChallengeCount('child'), 1);
      expect((await ProblemAttemptService.getAllAttempts()).length, 1);
      expect((await InsightsEngine.getProblemLogs('child')).length, 1);
    },
  );
}
