import 'package:flutter_test/flutter_test.dart';
import 'package:number_bond_math/models/problem_attempt.dart';
import 'package:number_bond_math/services/adaptive_problem_service.dart';
import 'package:number_bond_math/services/adaptive_challenge_engine.dart';
import 'package:number_bond_math/services/problem_attempt_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProblemAttempt _attempt({
  String id = 'event',
  String child = 'child',
  bool correct = false,
  String operator = '+',
}) => ProblemAttempt(
  id: id,
  childId: child,
  problemText: '29 $operator 15 = ?',
  operand1: 29,
  operand2: 15,
  operator: operator,
  correctAnswer: operator == '+' ? 44 : 14,
  userAnswer: correct ? (operator == '+' ? 44 : 14) : null,
  isCorrect: correct,
  timestamp: DateTime(2026, 10, 10, 10),
  attemptNumber: correct ? 2 : 3,
  timeSpentSeconds: 7.5,
  strategy: 'placeValue',
  difficultyLevel: 2,
  skillArea: 'adaptive_level_2',
  usedHint: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'same equation completed again within a minute is a distinct event',
    () async {
      await ProblemAttemptService.recordAttempt(_attempt(id: 'first'));
      await ProblemAttemptService.recordAttempt(_attempt(id: 'second'));
      expect(
        (await ProblemAttemptService.getAttemptsForChild(
          'child',
        )).map((attempt) => attempt.id),
        ['second', 'first'],
      );
    },
  );

  test('a successful retry is retained after a terminal failure', () async {
    await ProblemAttemptService.recordAttempt(_attempt());
    await ProblemAttemptService.recordAttempt(_attempt(correct: true));
    expect(
      (await ProblemAttemptService.getAttemptsForChild(
        'child',
      )).map((attempt) => attempt.isCorrect),
      [true, false],
    );
  });

  test(
    'duplicate simultaneous delivery is counted once and child identities are isolated',
    () async {
      final attempt = _attempt();
      await Future.wait([
        ProblemAttemptService.recordAttempt(attempt),
        ProblemAttemptService.recordAttempt(attempt),
      ]);
      await ProblemAttemptService.recordAttempt(_attempt(child: 'other'));
      expect(
        (await ProblemAttemptService.getAttemptsForChild('child')).length,
        1,
      );
      expect(
        (await ProblemAttemptService.getAttemptsForChild('other')).length,
        1,
      );
    },
  );

  test(
    'failed addition and subtraction with the same operands stay separate',
    () async {
      await ProblemAttemptService.recordAttempt(_attempt(id: 'addition'));
      await ProblemAttemptService.recordAttempt(
        _attempt(id: 'subtraction', operator: '-'),
      );
      expect(
        (await ProblemAttemptService.getUniqueFailedAttempts(
          'child',
        )).map((attempt) => attempt.operator).toSet(),
        {'+', '-'},
      );
    },
  );

  test('per-child progress reset preserves other profiles', () async {
    await ProblemAttemptService.recordAttempt(_attempt());
    await ProblemAttemptService.recordAttempt(_attempt(child: 'other'));
    await ProblemAttemptService.clearAttemptsForChild('child');
    expect(await ProblemAttemptService.getAttemptsForChild('child'), isEmpty);
    expect(
      (await ProblemAttemptService.getAttemptsForChild('other')).length,
      1,
    );
  });

  test('recent history keeps one hundred outcomes per child', () async {
    await ProblemAttemptService.recordAttempt(_attempt(child: 'other'));
    for (var index = 0; index < 105; index++) {
      await ProblemAttemptService.recordAttempt(_attempt(id: 'event-$index'));
    }
    final attempts = await ProblemAttemptService.getAttemptsForChild('child');
    expect(attempts.length, 100);
    expect(attempts.first.id, 'event-104');
    expect(attempts.last.id, 'event-5');
    expect(
      (await ProblemAttemptService.getAttemptsForChild('other')).length,
      1,
    );
  });

  test(
    'live recording stores measured time, actual attempts, hint and chosen strategy',
    () async {
      await AdaptiveProblemService.recordAttempt(
        childId: 'child',
        problemId: 'terminal-event',
        problemText: '29 - 15 = ?',
        level: 2,
        correct: true,
        timeTaken: 12.75,
        bondCorrect: true,
        operand1: 29,
        operand2: 15,
        operator: '-',
        correctAnswer: 14,
        attemptNumber: 2,
        usedHint: true,
        strategy: 'roundChunks',
        hintType: 'roundChunks',
        explanation: '29 - 10 - 5 = 14',
        isReviewProblem: true,
      );
      final attempt = (await ProblemAttemptService.getAttemptsForChild(
        'child',
      )).single;
      expect(attempt.timeSpentSeconds, 12.75);
      expect(attempt.attemptNumber, 2);
      expect(attempt.usedHint, isTrue);
      expect(attempt.strategy, 'roundChunks');
      expect(attempt.hintType, 'roundChunks');
      expect(attempt.explanation, '29 - 10 - 5 = 14');
      final result = (await AdaptiveChallengeEngine.getAllProblemResults(
        'child',
      )).single;
      expect(result.timeTaken, 12.75);
      expect(result.isReviewProblem, isTrue);
    },
  );
}
