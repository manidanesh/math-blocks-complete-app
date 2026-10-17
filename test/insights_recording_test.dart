import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:number_bond_math/models/insights.dart';
import 'package:number_bond_math/services/adaptive_challenge_engine.dart';
import 'package:number_bond_math/services/adaptive_problem_service.dart';
import 'package:number_bond_math/services/insights_engine.dart';
import 'package:number_bond_math/services/problem_attempt_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _complete(
  int index, {
  String child = 'child',
  bool correct = true,
  bool hint = false,
  String operator = '+',
}) => AdaptiveProblemService.recordAttempt(
  childId: child,
  problemId: 'event-$index',
  problemText: '29 $operator 15 = ?',
  level: 2,
  correct: correct,
  timeTaken: 7.25,
  bondCorrect: correct,
  operand1: 29,
  operand2: 15,
  operator: operator,
  correctAnswer: operator == '+' ? 44 : 14,
  usedHint: hint,
  strategy: 'roundChunks',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'the live recording path analyzes the twentieth unique terminal event',
    () async {
      for (var index = 0; index < 19; index++) {
        await _complete(
          index,
          correct: index >= 10,
          hint: index < 10,
          operator: index < 10 ? '+' : '-',
        );
      }
      expect(await InsightsEngine.getLatestAnalysis('child'), isNull);
      await _complete(18); // Same event/outcome, despite another callback.
      expect((await InsightsEngine.getProblemLogs('child')).length, 19);
      expect(await InsightsEngine.getLatestAnalysis('child'), isNull);
      await _complete(19, operator: '-');
      final analysis = (await InsightsEngine.getLatestAnalysis('child'))!;
      expect(analysis.totalProblems, 20);
      expect(analysis.overallAccuracy, 0.5);
      expect(analysis.averageTime, 7.25);
      expect(analysis.problemTypeAccuracy, {
        'addition': 0.0,
        'subtraction': 1.0,
      });
      expect(analysis.strategyAccuracy, {'roundChunks': 0.5});
      final additionWeakness = analysis.patterns.singleWhere(
        (pattern) =>
            pattern.category == 'problem_type' &&
            pattern.metadata['problemType'] == 'addition',
      );
      expect(additionWeakness.metadata['hintUsage'], 1.0);
      expect(analysis.insights, isNotEmpty);
      final insights = await InsightsEngine.getInsights('child');
      expect(
        insights.map((insight) => insight.id).toSet().length,
        insights.length,
      );
      expect(
        analysis.insights.map((insight) => insight.id).toSet(),
        insights.map((insight) => insight.id).toSet(),
      );
      await _complete(19, operator: '-');
      expect((await InsightsEngine.getProblemLogs('child')).length, 20);
      expect(
        (await InsightsEngine.getInsights('child')).length,
        insights.length,
      );
    },
  );

  test(
    'cadence remains every twenty completions after recent history is capped',
    () async {
      for (var index = 0; index < 100; index++) {
        await _complete(index);
      }
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('insights_last_analysis_count_child'), 100);
      for (var index = 100; index < 119; index++) {
        await _complete(index);
      }
      expect((await InsightsEngine.getProblemLogs('child')).length, 100);
      expect(prefs.getInt('insights_problem_count_child'), 119);
      expect(prefs.getInt('insights_last_analysis_count_child'), 100);
      await _complete(119);
      expect(prefs.getInt('insights_last_analysis_count_child'), 120);
      expect(
        (await InsightsEngine.getLatestAnalysis('child'))!.totalProblems,
        100,
      );
      expect(
        (await InsightsEngine.getInsights(
          'child',
        )).any((insight) => insight.id.contains(':batch-6:')),
        isTrue,
      );
    },
  );

  test(
    'concurrent duplicates do not inflate insight or primary histories',
    () async {
      await Future.wait([_complete(0), _complete(0)]);
      expect((await InsightsEngine.getProblemLogs('child')).length, 1);
      expect(await AdaptiveChallengeEngine.getChallengeCount('child'), 1);
      expect(
        (await ProblemAttemptService.getAttemptsForChild('child')).length,
        1,
      );
    },
  );

  test(
    'a successful retry is logged separately from the failed outcome',
    () async {
      await _complete(0, correct: false, hint: true);
      await _complete(0);
      expect(
        (await InsightsEngine.getProblemLogs(
          'child',
        )).map((log) => log.correct),
        [true, false],
      );
    },
  );

  test(
    'secondary insight errors preserve the persisted terminal event identity',
    () async {
      SharedPreferences.setMockInitialValues({
        'insights_problem_logs': ['invalid json'],
      });
      await _complete(0);
      expect(await AdaptiveChallengeEngine.getChallengeCount('child'), 1);
      expect(
        (await ProblemAttemptService.getAttemptsForChild('child')).length,
        1,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('insights_problem_logs');
      await _complete(0);
      expect(await AdaptiveChallengeEngine.getChallengeCount('child'), 1);
      expect(
        (await ProblemAttemptService.getAttemptsForChild('child')).length,
        1,
      );
      expect((await InsightsEngine.getProblemLogs('child')).length, 1);
    },
  );

  test(
    'legacy integer times read correctly and each child keeps an independent cadence',
    () async {
      final legacy = ProblemLog(
        id: 'old-event',
        childId: 'child',
        problemType: 'addition',
        numbersUsed: [14, 7],
        correct: true,
        timeTaken: 5,
        hintUsed: false,
        timestamp: DateTime.now(),
        level: 'Level 1',
        strategy: 'makeTen',
      ).toJson()..['timeTaken'] = 5;
      SharedPreferences.setMockInitialValues({
        'insights_problem_logs': [jsonEncode(legacy)],
      });
      expect(
        (await InsightsEngine.getProblemLogs('child')).single.timeTaken,
        5.0,
      );
      for (var index = 0; index < 19; index++) {
        await _complete(index);
        await _complete(index, child: 'other');
      }
      expect(
        (await InsightsEngine.getLatestAnalysis('child'))!.totalProblems,
        20,
      );
      expect(await InsightsEngine.getLatestAnalysis('other'), isNull);
      await _complete(19, child: 'other');
      expect(
        (await InsightsEngine.getLatestAnalysis('other'))!.totalProblems,
        20,
      );
    },
  );
}
