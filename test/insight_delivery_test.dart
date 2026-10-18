import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:number_bond_math/services/adaptive_challenge_engine.dart';
import 'package:number_bond_math/services/adaptive_problem_service.dart';
import 'package:number_bond_math/services/insight_delivery_service.dart';
import 'package:number_bond_math/services/insights_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _channel = MethodChannel('plugins.flutter.io/shared_preferences');

Future<void> _complete(int index) => AdaptiveProblemService.recordAttempt(
  childId: 'child',
  problemId: 'event-$index',
  problemText: '18 + 7',
  level: 1,
  correct: true,
  timeTaken: 5,
  bondCorrect: true,
  operand1: 18,
  operand2: 7,
  operator: '+',
  correctAnswer: 25,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, Object> disk;
  late Set<String> rejected;
  setUp(() {
    SharedPreferences.resetStatic();
    disk = {};
    rejected = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          if (call.method == 'getAll') return Map<String, Object>.from(disk);
          final args = call.arguments as Map;
          final key = args['key'] as String;
          if (rejected.contains(key)) return false;
          if (call.method == 'remove') {
            disk.remove(key);
            return true;
          }
          final value = args['value']!;
          disk[key] = value is List ? value.cast<String>().toList() : value;
          return true;
        });
  });
  tearDown(() {
    SharedPreferences.resetStatic();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  test(
    'a failed analytics event survives completion and retries on the next challenge',
    () async {
      rejected.add('flutter.insights_problem_logs');
      await _complete(0);
      expect(await AdaptiveChallengeEngine.getChallengeCount('child'), 1);
      expect(disk['flutter.pending_insight_events_child'], isNotNull);
      rejected.clear();
      await AdaptiveProblemService.getNextChallenge('child', 'Maya');
      expect((await InsightsEngine.getProblemLogs('child')).length, 1);
      expect(disk['flutter.pending_insight_events_child'], isNull);
      for (var index = 1; index < 20; index++) {
        await _complete(index);
      }
      expect(await AdaptiveChallengeEngine.getChallengeCount('child'), 20);
      expect((await InsightsEngine.getProblemLogs('child')).length, 20);
      expect(
        (await InsightsEngine.getLatestAnalysis('child'))!.totalProblems,
        20,
      );
    },
  );

  test(
    'unconfirmed outbox retention fails completion and a retry remains idempotent',
    () async {
      rejected.add('flutter.pending_insight_events_child');
      await expectLater(_complete(0), throwsStateError);
      expect(await AdaptiveChallengeEngine.getChallengeCount('child'), 1);
      rejected.clear();
      await _complete(0);
      expect(await AdaptiveChallengeEngine.getChallengeCount('child'), 1);
      expect((await InsightsEngine.getProblemLogs('child')).length, 1);
      expect(disk['flutter.pending_insight_events_child'], isNull);
    },
  );

  test(
    'a queue-removal failure safely redelivers without duplicate analytics',
    () async {
      rejected.add('flutter.insights_problem_logs');
      await _complete(0);
      rejected.clear();
      final prefs = await SharedPreferences.getInstance();
      final event =
          (jsonDecode(prefs.getString('pending_insight_events_child')!) as List)
              .single;
      // Delivery succeeds, but confirming queue removal is rejected.
      rejected.add('flutter.pending_insight_events_child');
      await InsightDeliveryService.flush('child');
      expect((await InsightsEngine.getProblemLogs('child')).length, 1);
      expect(prefs.getString('pending_insight_events_child'), isNotNull);
      rejected.clear();
      await InsightDeliveryService.flush('child');
      final logs = await InsightsEngine.getProblemLogs('child');
      expect(logs.length, 1);
      expect(
        logs.single.timestamp,
        DateTime.parse(event['timestamp'] as String),
      );
      expect(prefs.getString('pending_insight_events_child'), isNull);
    },
  );

  test(
    'clearing a child outbox preserves another child and prevents replay',
    () async {
      rejected.add('flutter.insights_problem_logs');
      await _complete(0);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_insight_events_other', '[]');
      await InsightDeliveryService.clear('child');
      rejected.clear();
      await InsightDeliveryService.flush('child');
      expect(await InsightsEngine.getProblemLogs('child'), isEmpty);
      expect(prefs.getString('pending_insight_events_other'), '[]');
    },
  );
}
