import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:number_bond_math/models/adaptive_challenge.dart';
import 'package:number_bond_math/services/adaptive_challenge_engine.dart';
import 'package:number_bond_math/services/adaptive_problem_service.dart';
import 'package:number_bond_math/services/central_problem_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var sequence = 0;

  ProblemResult result({
    String child = 'child',
    int level = 1,
    bool correct = true,
    bool review = false,
    double seconds = 30,
    String text = '14 + 7 = ?',
    String? id,
  }) => ProblemResult(
    problemId: id ?? 'event-${sequence++}',
    level: level,
    correct: correct,
    timeTaken: seconds,
    bondCorrect: correct,
    timestamp: DateTime(2026, 10, 10).add(Duration(seconds: sequence)),
    problemText: text,
    childId: child,
    isReviewProblem: review,
  );

  Future<void> outcomes(
    int level,
    List<bool> correct, {
    String child = 'child',
  }) async {
    for (final value in correct) {
      await AdaptiveChallengeEngine.storeProblemResult(
        result(child: child, level: level, correct: value),
      );
    }
  }

  setUp(() {
    sequence = 0;
    SharedPreferences.setMockInitialValues({});
    CentralProblemGenerator.setRandomForTesting(Random(20261010));
  });
  tearDown(() => CentralProblemGenerator.setRandomForTesting(Random()));

  test(
    'live service reaches every level and saves the level across later opens',
    () async {
      var challenge = await AdaptiveProblemService.getNextChallenge(
        'child',
        'Jamie',
      );
      expect(challenge.level, 1);
      for (var level = 1; level < 4; level++) {
        for (var completion = 0; completion < 5; completion++) {
          expect(challenge.level, level);
          await AdaptiveChallengeEngine.storeProblemResult(
            result(level: challenge.level),
          );
          challenge = await AdaptiveProblemService.getNextChallenge(
            'child',
            'Jamie',
          );
        }
        expect(challenge.level, level + 1);
        expect(
          await AdaptiveChallengeEngine.getCurrentLevel('child'),
          level + 1,
        );
      }
      final reopened = await AdaptiveProblemService.getNextChallenge(
        'child',
        'Jamie',
      );
      expect(reopened.level, 4);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('adaptive_current_level_child'), 4);
    },
  );

  for (final entry in {
    '80% advances': ([true, true, false, true, true], 3),
    '60% stays': ([true, true, false, false, true], 2),
    '40% moves down': ([false, false, false, true, true], 1),
  }.entries) {
    test(entry.key, () async {
      await outcomes(2, entry.value.$1);
      expect(
        await AdaptiveChallengeEngine.determineNextLevel('child', 2),
        entry.value.$2,
      );
    });
  }

  test(
    'five current-level outcomes are needed; repeated reads cannot advance twice',
    () async {
      await outcomes(1, [true, true, true, true]);
      expect(await AdaptiveChallengeEngine.determineNextLevel('child', 1), 1);
      await outcomes(1, [true]);
      expect(await AdaptiveChallengeEngine.determineNextLevel('child', 1), 2);
      for (var read = 0; read < 4; read++) {
        expect(await AdaptiveChallengeEngine.determineNextLevel('child', 1), 2);
      }
      await outcomes(2, [true, true, true, true]);
      expect(await AdaptiveChallengeEngine.determineNextLevel('child', 2), 2);
      await outcomes(2, [true]);
      expect(await AdaptiveChallengeEngine.determineNextLevel('child', 2), 3);
    },
  );

  test('easier reviews do not advance or replace the normal level', () async {
    await outcomes(2, [true, true, true, true]);
    for (var index = 0; index < 5; index++) {
      await AdaptiveChallengeEngine.storeProblemResult(
        result(level: 1, review: true),
      );
    }
    expect(await AdaptiveChallengeEngine.determineNextLevel('child', 2), 2);
    await outcomes(2, [true]);
    expect(await AdaptiveChallengeEngine.determineNextLevel('child', 2), 3);
    await AdaptiveChallengeEngine.storeProblemResult(
      result(level: 1, correct: false, review: true),
    );
    expect(await AdaptiveChallengeEngine.determineNextLevel('child', 3), 3);
    expect(await AdaptiveChallengeEngine.getCurrentLevel('child'), 3);
  });

  test('metrics use the last five outcomes and real elapsed times', () async {
    await AdaptiveChallengeEngine.storeProblemResult(
      result(correct: false, seconds: 999),
    );
    for (var index = 1; index <= 5; index++) {
      await AdaptiveChallengeEngine.storeProblemResult(
        result(correct: index <= 3, seconds: index.toDouble()),
      );
    }
    final metrics = await AdaptiveChallengeEngine.calculatePerformanceMetrics(
      'child',
    );
    expect(metrics.accuracy, 0.6);
    expect(metrics.averageTime, 3);
    expect(metrics.consecutiveIncorrect, 2);
    expect(metrics.recentLevels, [1, 1, 1, 1, 1]);
  });

  test(
    'review starts after two failures or four completions, not an empty history',
    () async {
      expect(
        await AdaptiveChallengeEngine.shouldInjectReviewProblem('child'),
        isFalse,
      );
      await outcomes(2, [false]);
      expect(
        await AdaptiveChallengeEngine.shouldInjectReviewProblem('child'),
        isFalse,
      );
      await outcomes(2, [false]);
      expect(
        await AdaptiveChallengeEngine.shouldInjectReviewProblem('child'),
        isTrue,
      );
      await outcomes(2, [true]);
      expect(
        await AdaptiveChallengeEngine.shouldInjectReviewProblem('child'),
        isFalse,
      );
      await outcomes(2, [true]);
      expect(
        await AdaptiveChallengeEngine.shouldInjectReviewProblem('child'),
        isTrue,
      );
    },
  );

  test(
    'review preserves the mistaken operation and stays below the base level',
    () async {
      await AdaptiveChallengeEngine.storeProblemResult(
        result(level: 4, correct: false),
      );
      final review = await AdaptiveChallengeEngine.generateReviewProblem(
        'child',
        const [],
        currentLevel: 2,
      );
      expect(review!.isReviewProblem, isTrue);
      expect(review.operator, '+');
      expect(review.level, 1);
      expect(await AdaptiveChallengeEngine.getCurrentLevel('child'), 4);
    },
  );

  test('preferred operation applies to normal and review challenges', () async {
    for (final preference in ['addition', 'subtraction']) {
      for (var index = 0; index < 10; index++) {
        final challenge = await AdaptiveProblemService.getNextChallenge(
          preference,
          'Jamie',
          preferredOperation: preference,
        );
        expect(challenge.operator, preference == 'addition' ? '+' : '-');
      }
    }
    await outcomes(1, [false, false]); // Past mistakes are addition.
    final challenge = await AdaptiveProblemService.getNextChallenge(
      'child',
      'Jamie',
      preferredOperation: 'subtraction',
    );
    expect(challenge.operator, '-');
    expect(challenge.isReviewProblem, isFalse);
  });

  test(
    'normal and review generation excludes exact second operands at every level',
    () async {
      final prefs = await SharedPreferences.getInstance();
      for (var level = 1; level <= 4; level++) {
        for (final action in ['addition', 'subtraction']) {
          final child = '$action-level-$level';
          await prefs.setInt('adaptive_current_level_$child', level);
          for (var sample = 0; sample < 20; sample++) {
            final challenge = await AdaptiveProblemService.getNextChallenge(
              child,
              'Jamie',
              preferredOperation: action,
            );
            expect(challenge.level, level);
            expect(challenge.isReviewProblem, isFalse);
            expect(challenge.operator, action == 'addition' ? '+' : '-');
            expect(challenge.operand2, isNot(isIn([10, 100, 1000])));
          }
          for (var failure = 0; failure < 2; failure++) {
            await AdaptiveChallengeEngine.storeProblemResult(
              result(
                child: child,
                level: level,
                correct: false,
                text: action == 'addition' ? '4 + 14 = ?' : '29 - 15 = ?',
              ),
            );
          }
          for (var sample = 0; sample < 20; sample++) {
            final review = await AdaptiveProblemService.getNextChallenge(
              child,
              'Jamie',
              preferredOperation: action,
            );
            expect(review.isReviewProblem, isTrue);
            expect(review.level, level == 1 ? 1 : level - 1);
            expect(review.operator, action == 'addition' ? '+' : '-');
            expect(review.operand2, isNot(isIn([10, 100, 1000])));
            expect(await AdaptiveChallengeEngine.getCurrentLevel(child), level);
          }
        }
      }
    },
  );

  test(
    'duplicate callbacks are idempotent, but failure then success is recorded',
    () async {
      final failure = result(correct: false, id: 'same-event');
      await Future.wait([
        AdaptiveChallengeEngine.storeProblemResult(failure),
        AdaptiveChallengeEngine.storeProblemResult(failure),
      ]);
      expect(await AdaptiveChallengeEngine.getChallengeCount('child'), 1);
      await AdaptiveChallengeEngine.storeProblemResult(
        result(id: 'same-event'),
      );
      expect(await AdaptiveChallengeEngine.getChallengeCount('child'), 2);
      expect(
        (await AdaptiveChallengeEngine.getAllProblemResults(
          'child',
        )).map((result) => result.correct),
        [true, false],
      );
    },
  );

  test(
    'legacy results migrate without guessing that normal results were reviews',
    () async {
      final legacy = result(level: 3).toJson()..remove('isReviewProblem');
      SharedPreferences.setMockInitialValues({
        'adaptive_challenge_results_child': jsonEncode([legacy]),
        'challenge_count_child': 1,
      });
      expect(
        (await AdaptiveChallengeEngine.getAllProblemResults(
          'child',
        )).single.isReviewProblem,
        isFalse,
      );
      expect(await AdaptiveChallengeEngine.getCurrentLevel('child'), 3);
      expect(
        (await AdaptiveProblemService.getNextChallenge('child', 'Jamie')).level,
        3,
      );
    },
  );

  test('legacy review IDs do not replace the last normal level', () async {
    final normal = result(level: 3).toJson()..remove('isReviewProblem');
    final review = result(level: 1, id: 'review_123').toJson()
      ..remove('isReviewProblem');
    SharedPreferences.setMockInitialValues({
      'adaptive_challenge_results_child': jsonEncode([review, normal]),
      'challenge_count_child': 2,
    });
    expect(
      (await AdaptiveChallengeEngine.getAllProblemResults(
        'child',
      )).first.isReviewProblem,
      isTrue,
    );
    expect(await AdaptiveChallengeEngine.getCurrentLevel('child'), 3);
  });

  test(
    'an already interrupted legacy demotion repairs its stale baseline',
    () async {
      final failed = result(level: 2, correct: false);
      SharedPreferences.setMockInitialValues({
        'adaptive_challenge_results_child': jsonEncode([
          failed.toJson(),
          for (var i = 0; i < 4; i++) result(level: 2, correct: false).toJson(),
          for (var i = 0; i < 5; i++) result(level: 1).toJson(),
        ]),
        'challenge_count_child': 10,
        'adaptive_current_level_child': 1,
        'adaptive_level_decision_child':
            '${failed.problemId}:false:${failed.timestamp.toIso8601String()}',
        'adaptive_level_start_count_child': 0,
      });
      expect(await AdaptiveChallengeEngine.determineNextLevel('child', 1), 1);
      await outcomes(1, [true]);
      expect(await AdaptiveChallengeEngine.determineNextLevel('child', 1), 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('adaptive_level_start_count_child'), 10);
      await outcomes(1, [true, true, true, true]);
      expect(await AdaptiveChallengeEngine.determineNextLevel('child', 1), 2);
    },
  );

  test('reset removes level and history only for the chosen child', () async {
    await outcomes(2, [true, true, true, true, true]);
    await AdaptiveChallengeEngine.determineNextLevel('child', 2);
    await outcomes(3, [true], child: 'other');
    await AdaptiveChallengeEngine.determineNextLevel('other', 3);
    await AdaptiveChallengeEngine.clearChildData('child');
    expect(await AdaptiveChallengeEngine.getCurrentLevel('child'), 1);
    expect(await AdaptiveChallengeEngine.getChallengeCount('child'), 0);
    expect(
      await AdaptiveChallengeEngine.getAllProblemResults('child'),
      isEmpty,
    );
    expect(await AdaptiveChallengeEngine.getCurrentLevel('other'), 3);
    expect(await AdaptiveChallengeEngine.getChallengeCount('other'), 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('adaptive_state_child'), isNull);
    expect(prefs.getString('adaptive_state_other'), isNotNull);
  });
}
