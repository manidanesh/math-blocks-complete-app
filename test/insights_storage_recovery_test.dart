import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:number_bond_math/models/insights.dart';
import 'package:number_bond_math/services/insights_engine.dart';
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

Future<void> _log(int index, {String child = 'child', DateTime? timestamp}) =>
    InsightsEngine.logProblem(
      childId: child,
      eventId: 'event-$index',
      problemType: 'addition',
      numbersUsed: [14, 7],
      correct: true,
      timeTaken: 5.5,
      hintUsed: false,
      level: 'Level 1',
      strategy: 'makeTen',
      timestamp: timestamp,
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
    for (final key in [
      'insights_problem_logs',
      'insights_problem_count_child',
    ]) {
      test(
        'a ${throws ? 'throwing' : 'rejected'} $key write preserves the twentieth event for retry',
        () async {
          await _log(0, child: 'other');
          for (var index = 0; index < 19; index++) {
            await _log(index);
          }
          final before = Map<String, Object>.from(store.disk);
          (throws ? store.throwing : store.rejected).add('flutter.$key');
          await expectLater(
            _log(19),
            throws ? throwsA(isA<PlatformException>()) : throwsStateError,
          );

          expect(store.disk, before);
          expect((await InsightsEngine.getProblemLogs('child')).length, 19);
          expect((await InsightsEngine.getProblemLogs('other')).length, 1);
          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getInt('insights_problem_count_child'), 19);
          expect(await InsightsEngine.getLatestAnalysis('child'), isNull);

          store.throwing.clear();
          store.rejected.clear();
          await _log(19);
          expect((await InsightsEngine.getProblemLogs('child')).length, 20);
          expect((await InsightsEngine.getProblemLogs('other')).length, 1);
          expect(prefs.getInt('insights_problem_count_child'), 20);
          expect(prefs.getInt('insights_last_analysis_count_child'), 20);
          expect(
            (await InsightsEngine.getLatestAnalysis('child'))!.totalProblems,
            20,
          );
          final insights = await InsightsEngine.getInsights('child');
          await _log(19);
          expect((await InsightsEngine.getProblemLogs('child')).length, 20);
          expect(prefs.getInt('insights_problem_count_child'), 20);
          expect(
            (await InsightsEngine.getInsights(
              'child',
            )).map((value) => value.id),
            insights.map((value) => value.id),
          );
        },
      );
    }
  }

  test(
    'a failed first count write restores absent log and count keys',
    () async {
      store.rejected.add('flutter.insights_problem_count_child');
      await expectLater(_log(0), throwsStateError);
      expect(store.disk.keys, ['flutter.insights_state_child']);
      expect(
        (jsonDecode(store.disk['flutter.insights_state_child']! as String)
            as Map)['count'],
        0,
      );
      expect(await InsightsEngine.getProblemLogs('child'), isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('insights_problem_count_child'), isNull);
      store.rejected.clear();
      await _log(0);
      expect((await InsightsEngine.getProblemLogs('child')).length, 1);
      expect(prefs.getInt('insights_problem_count_child'), 1);
    },
  );

  test(
    'restart at every capped-log save prefix replays the twentieth batch once',
    () async {
      await _log(0, child: 'other');
      for (var i = 0; i < 119; i++) {
        await _log(i);
      }
      store.checkpoints.clear();
      await _log(119);
      final checkpoints = store.checkpoints.take(3).toList();
      expect(checkpoints.map((entry) => entry.key), [
        'flutter.insights_problem_logs',
        'flutter.insights_problem_count_child',
        'flutter.insights_state_child',
      ]);
      for (var prefix = 0; prefix < checkpoints.length; prefix++) {
        SharedPreferences.resetStatic();
        store.disk
          ..clear()
          ..addAll(checkpoints[prefix].disk);
        final committed = prefix == checkpoints.length - 1;
        final before = await InsightsEngine.getProblemLogs('child');
        expect(before.length, 100);
        expect(
          before.any((log) => log.id == 'event-119'),
          committed,
          reason: 'prefix $prefix',
        );
        // A different child may save first after restarting. Its compatibility
        // mirror must not publish this child's uncommitted log as committed.
        await _log(1, child: 'other');
        expect(
          (await InsightsEngine.getProblemLogs(
            'child',
          )).any((log) => log.id == 'event-119'),
          committed,
        );
        await _log(119);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('insights_problem_count_child'), 120);
        expect(prefs.getInt('insights_last_analysis_count_child'), 120);
        expect(
          (await InsightsEngine.getLatestAnalysis('child'))!.totalProblems,
          100,
        );
        expect(
          (await InsightsEngine.getProblemLogs(
            'child',
          )).where((log) => log.id == 'event-119').length,
          1,
        );
        expect((await InsightsEngine.getProblemLogs('other')).length, 2);
        final cards = (await InsightsEngine.getInsights(
          'child',
        )).map((card) => card.id).toList();
        await _log(119);
        expect(
          (await InsightsEngine.getInsights('child')).map((card) => card.id),
          cards,
        );
      }
    },
  );

  test(
    'legacy twentieth log saved before its counter repairs and analyzes on replay',
    () async {
      store.disk['flutter.insights_problem_logs'] = [
        for (var i = 0; i < 20; i++)
          jsonEncode(
            ProblemLog(
              id: 'event-$i',
              childId: 'child',
              problemType: 'addition',
              numbersUsed: [14, 7],
              correct: true,
              timeTaken: 5.5,
              hintUsed: false,
              timestamp: DateTime.now(),
              level: 'Level 1',
              strategy: 'makeTen',
            ).toJson(),
          ),
      ];
      store.disk['flutter.insights_problem_count_child'] = 19;
      await _log(19);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('insights_problem_count_child'), 20);
      expect(prefs.getInt('insights_last_analysis_count_child'), 20);
      expect(
        (await InsightsEngine.getLatestAnalysis('child'))!.totalProblems,
        20,
      );
      expect((await InsightsEngine.getProblemLogs('child')).length, 20);
    },
  );

  test(
    'replayed events preserve their original time and reset removes the snapshot',
    () async {
      final timestamp = DateTime.now().subtract(const Duration(days: 9));
      await _log(0, timestamp: timestamp);
      await _log(0, child: 'other');
      SharedPreferences.resetStatic();
      await _log(0);
      expect(
        (await InsightsEngine.getProblemLogs('child')).single.timestamp,
        timestamp,
      );
      await InsightsEngine.forceAnalysis('child');
      expect(await InsightsEngine.getLatestAnalysis('child'), isNull);
      await InsightsEngine.clearInsights('child');
      expect(store.disk.containsKey('flutter.insights_state_child'), isFalse);
      expect(await InsightsEngine.getProblemLogs('child'), isEmpty);
      expect((await InsightsEngine.getProblemLogs('other')).length, 1);
    },
  );

  for (final throws in [false, true]) {
    test(
      'a ${throws ? 'throwing' : 'rejected'} insights snapshot commit leaves the event retryable',
      () async {
        await _log(0);
        (throws ? store.throwing : store.rejected).add(
          'flutter.insights_state_child',
        );
        await expectLater(
          _log(1),
          throws ? throwsA(isA<PlatformException>()) : throwsStateError,
        );
        SharedPreferences.resetStatic();
        expect(
          (await InsightsEngine.getProblemLogs('child')).single.id,
          'event-0',
        );
        store.throwing.clear();
        store.rejected.clear();
        await _log(1);
        expect((await InsightsEngine.getProblemLogs('child')).length, 2);
        expect(store.disk['flutter.insights_problem_count_child'], 2);
      },
    );
  }

  test(
    'a failed capped-history count write restores retained logs before retry',
    () async {
      await _log(0, child: 'other');
      for (var index = 0; index < 119; index++) {
        await _log(index);
      }
      final before = Map<String, Object>.from(store.disk);
      final beforeIds = (await InsightsEngine.getProblemLogs(
        'child',
      )).map((log) => log.id).toList();
      store.rejected.add('flutter.insights_problem_count_child');
      await expectLater(_log(119), throwsStateError);
      expect(store.disk, before);
      expect(
        (await InsightsEngine.getProblemLogs('child')).map((log) => log.id),
        beforeIds,
      );
      store.rejected.clear();
      await _log(119);
      final logs = await InsightsEngine.getProblemLogs('child');
      expect(logs.length, 100);
      expect(logs.first.id, 'event-119');
      expect(logs.last.id, 'event-20');
      expect(
        (await InsightsEngine.getProblemLogs('other')).single.id,
        'event-0',
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('insights_problem_count_child'), 120);
      expect(prefs.getInt('insights_last_analysis_count_child'), 120);
      expect(
        (await InsightsEngine.getLatestAnalysis('child'))!.totalProblems,
        100,
      );
    },
  );
}
