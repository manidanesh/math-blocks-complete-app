import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/adaptive_challenge.dart';
import 'central_problem_generator.dart';

/// Selects challenges using each child's recent performance and saved level.
class AdaptiveChallengeEngine {
  static const String _resultsKey = 'adaptive_challenge_results';
  static const String _challengeCountKey = 'challenge_count';
  static const String _levelKey = 'adaptive_current_level';
  static const String _levelStartCountKey = 'adaptive_level_start_count';
  static const String _levelDecisionKey = 'adaptive_level_decision';
  static const String _stateKey = 'adaptive_state';
  static const int _recentProblemsCount = 5;
  static const int _reviewProblemInterval = 4;
  static Future<void>? _pendingWrite;

  // Serialize read/modify/write operations, including simultaneous callbacks.
  static Future<void> _write(Future<void> Function() operation) {
    Future<void> run() async {
      try {
        await operation();
      } catch (_) {
        // SharedPreferences updates its cache before the platform confirms a
        // write. Restore disk-backed state before allowing a retry.
        await (await SharedPreferences.getInstance()).reload();
        rethrow;
      }
    }

    final previous = _pendingWrite;
    final next = previous == null
        ? Future<void>.sync(run)
        : previous.then(
            (_) => run(),
            onError: (Object _, StackTrace _) => run(),
          );
    late final Future<void> queued;
    queued = next.whenComplete(() {
      if (identical(_pendingWrite, queued)) _pendingWrite = null;
    });
    _pendingWrite = queued;
    return queued;
  }

  static void _requireSaved(bool saved) {
    if (!saved) throw StateError('Could not save adaptive challenge data.');
  }

  static String _decisionFor(ProblemResult result) =>
      '${result.problemId}:${result.correct}:${result.timestamp.toIso8601String()}';

  static _AdaptiveState _readState(SharedPreferences prefs, String childId) {
    final snapshot = prefs.getString('${_stateKey}_$childId');
    if (snapshot != null) {
      return _AdaptiveState.fromJson(jsonDecode(snapshot), childId);
    }
    final savedResults = prefs.getString('${_resultsKey}_$childId');
    final results = savedResults == null
        ? <ProblemResult>[]
        : (jsonDecode(savedResults) as List)
              .map(
                (json) => ProblemResult.fromJson(json as Map<String, dynamic>),
              )
              .toList();
    final count = max(
      prefs.getInt('${_challengeCountKey}_$childId') ?? 0,
      results.length,
    );
    final level = prefs.getInt('${_levelKey}_$childId');
    final decision = prefs.getString('${_levelDecisionKey}_$childId');
    var baseline = prefs.getInt('${_levelStartCountKey}_$childId') ?? 0;
    final normal = results.where((result) => !result.isReviewProblem);
    if (level != null &&
        normal.isNotEmpty &&
        normal.first.level != level &&
        decision == _decisionFor(normal.first)) {
      // Older releases could save a changed level and its decision before the
      // new baseline. No normal outcome at that new level has occurred yet.
      baseline = max(baseline, count);
    }
    return _AdaptiveState(
      results: results,
      count: count,
      level: level,
      levelStartCount: baseline,
      decision: decision,
    );
  }

  static int _inferredLevel(_AdaptiveState state, int fallback) {
    if (state.level != null) return state.level!.clamp(1, 4);
    final normal = state.results.where((result) => !result.isReviewProblem);
    return normal.isEmpty
        ? fallback.clamp(1, 4)
        : normal.first.level.clamp(1, 4);
  }

  static Future<void> _saveState(
    SharedPreferences prefs,
    String childId,
    _AdaptiveState before,
    _AdaptiveState after,
    Map<String, Object> mirrors,
  ) async {
    final key = '${_stateKey}_$childId';
    if (prefs.getString(key) == null) {
      // Publish a coherent before-image before touching compatibility keys.
      // A process exit during any subsequent prefix cannot expose half a save.
      _requireSaved(
        await prefs.setString(key, jsonEncode(before.toJson(childId))),
      );
    }
    final savedMirrors = {for (final key in mirrors.keys) key: prefs.get(key)};
    try {
      for (final entry in mirrors.entries) {
        _requireSaved(await _writePreference(prefs, entry.key, entry.value));
      }
      // This single document is the commit point for history, count and level.
      _requireSaved(
        await prefs.setString(key, jsonEncode(after.toJson(childId))),
      );
    } catch (_) {
      for (final entry in savedMirrors.entries) {
        try {
          _requireSaved(await _writePreference(prefs, entry.key, entry.value));
        } catch (_) {
          // Readers retain the committed snapshot even if a mirror cannot roll back.
        }
      }
      rethrow;
    }
  }

  static Future<bool> _writePreference(
    SharedPreferences prefs,
    String key,
    Object? value,
  ) => switch (value) {
    null => prefs.remove(key),
    String value => prefs.setString(key, value),
    int value => prefs.setInt(key, value),
    _ => throw StateError('Unsupported adaptive preference: $key'),
  };

  /// Repeated delivery of the same terminal event does not add another result.
  /// A failed event followed by a successful retry is a different outcome.
  static Future<void> storeProblemResult(ProblemResult result) =>
      _write(() async {
        final prefs = await SharedPreferences.getInstance();
        final before = _readState(prefs, result.childId);
        final results = List<ProblemResult>.of(before.results);
        if (results.any(
          (existing) =>
              existing.problemId == result.problemId &&
              existing.correct == result.correct,
        )) {
          if (prefs.getString('${_stateKey}_${result.childId}') == null) {
            await _saveState(prefs, result.childId, before, before, {
              '${_resultsKey}_${result.childId}': jsonEncode(
                results.map((result) => result.toJson()).toList(),
              ),
              '${_challengeCountKey}_${result.childId}': before.count,
            });
          }
          return;
        }
        results.insert(0, result);
        final resultKey = '${_resultsKey}_${result.childId}';
        final countKey = '${_challengeCountKey}_${result.childId}';
        final retained = results.take(100).toList();
        await _saveState(
          prefs,
          result.childId,
          before,
          before.copyWith(results: retained, count: before.count + 1),
          {
            resultKey: jsonEncode(
              retained.map((result) => result.toJson()).toList(),
            ),
            countKey: before.count + 1,
          },
        );
      });

  static Future<List<ProblemResult>> getAllProblemResults(
    String childId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    return _readState(prefs, childId).results;
  }

  static Future<int> getChallengeCount(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      return _readState(prefs, childId).count;
    } on FormatException {
      if (prefs.getString('${_stateKey}_$childId') != null) rethrow;
      // A legacy counter is still readable when its separate history is damaged.
      // Mutations continue to reject the unreadable history without overwriting it.
      return prefs.getInt('${_challengeCountKey}_$childId') ?? 0;
    }
  }

  /// Older installations did not save a level. Preserve their latest normal
  /// challenge level, or start at level one when no history exists.
  static Future<int> getCurrentLevel(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    return _inferredLevel(_readState(prefs, childId), 1);
  }

  static Future<PerformanceMetrics> calculatePerformanceMetrics(
    String childId,
  ) async {
    final results = await getAllProblemResults(childId);
    final recent = results.take(_recentProblemsCount).toList();
    var consecutiveIncorrect = 0;
    for (final result in recent) {
      if (result.correct) break;
      consecutiveIncorrect++;
    }
    final levels = <int, List<ProblemResult>>{};
    for (final result in results) {
      (levels[result.level] ??= []).add(result);
    }
    return PerformanceMetrics(
      accuracy: recent.isEmpty
          ? 0
          : recent.where((result) => result.correct).length / recent.length,
      averageTime: recent.isEmpty
          ? 0
          : recent.fold<double>(0, (sum, result) => sum + result.timeTaken) /
                recent.length,
      consecutiveIncorrect: consecutiveIncorrect,
      recentLevels: recent.map((result) => result.level).toList(),
      levelAccuracy: {
        for (final entry in levels.entries)
          entry.key:
              entry.value.where((result) => result.correct).length /
              entry.value.length,
      },
    );
  }

  /// Evaluate at most once per newly completed normal challenge. Each new
  /// level needs five outcomes of its own; previous-level successes and easier
  /// reviews cannot immediately promote the child again.
  static Future<int> determineNextLevel(
    String childId,
    int currentLevel,
  ) async {
    var nextLevel = currentLevel.clamp(1, 4);
    await _write(() async {
      final prefs = await SharedPreferences.getInstance();
      final before = _readState(prefs, childId);
      final level = _inferredLevel(before, currentLevel);
      nextLevel = level;
      final results = before.results;
      final normalResults = results
          .where((result) => !result.isReviewProblem)
          .toList();
      if (normalResults.isEmpty) {
        await _saveState(
          prefs,
          childId,
          before,
          before.copyWith(level: level),
          {'${_levelKey}_$childId': level},
        );
        return;
      }
      final latest = normalResults.first;
      final decision = _decisionFor(latest);
      if (before.decision == decision) return;

      final count = before.count;
      final levelStartCount = before.levelStartCount;
      final sinceLevelChange = (count - levelStartCount).clamp(
        0,
        results.length,
      );
      final recent = results
          .take(sinceLevelChange)
          .where((result) => !result.isReviewProblem && result.level == level)
          .take(_recentProblemsCount)
          .toList();
      if (recent.length == _recentProblemsCount) {
        final accuracy =
            recent.where((result) => result.correct).length / recent.length;
        if (accuracy >= 0.8) {
          nextLevel = (level + 1).clamp(1, 4);
        } else if (accuracy < 0.6) {
          nextLevel = (level - 1).clamp(1, 4);
        }
      }
      final baseline = nextLevel != level ? count : levelStartCount;
      await _saveState(
        prefs,
        childId,
        before,
        before.copyWith(
          level: nextLevel,
          decision: decision,
          levelStartCount: baseline,
        ),
        {
          '${_levelKey}_$childId': nextLevel,
          '${_levelDecisionKey}_$childId': decision,
          '${_levelStartCountKey}_$childId': baseline,
        },
      );
    });
    return nextLevel;
  }

  static Future<bool> shouldInjectReviewProblem(String childId) async {
    final metrics = await calculatePerformanceMetrics(childId);
    final count = await getChallengeCount(childId);
    return metrics.consecutiveIncorrect >= 2 ||
        (count > 0 && count % _reviewProblemInterval == 0);
  }

  static Future<List<ProblemResult>> getPastMistakes(String childId) async =>
      (await getAllProblemResults(
        childId,
      )).where((result) => !result.correct).toList();

  static String? _actionForPreference(String preferredOperation) =>
      preferredOperation == 'addition' || preferredOperation == 'subtraction'
      ? preferredOperation
      : null;

  /// Review the same operation as a past mistake at an easier level. Reviews
  /// never replace the persisted normal level or exceed that level.
  static Future<AdaptiveChallenge?> generateReviewProblem(
    String childId,
    List<int> favoriteNumbers, {
    int? currentLevel,
    String preferredOperation = 'both',
  }) async {
    final action = _actionForPreference(preferredOperation);
    final mistakes = (await getPastMistakes(childId)).where((result) {
      final isSubtraction =
          result.problemText.contains('-') || result.problemText.contains('−');
      return action == null || (action == 'subtraction') == isSubtraction;
    }).toList();
    if (mistakes.isEmpty) return null;
    final mistake = mistakes[Random().nextInt(mistakes.length)];
    final baseLevel = currentLevel ?? await getCurrentLevel(childId);
    final reviewLevel = min(mistake.level - 1, baseLevel - 1).clamp(1, 4);
    final isSubtraction =
        mistake.problemText.contains('-') || mistake.problemText.contains('−');
    final problem = CentralProblemGenerator.generateProblem(
      action: isSubtraction ? 'subtraction' : 'addition',
      level: reviewLevel,
    );
    return _challenge(problem, reviewLevel, isReviewProblem: true);
  }

  static Future<String?> getMotivationalFeedback(
    String childId,
    String childName,
  ) async {
    final results = await getAllProblemResults(childId);
    if (results.length < 10) return null;
    final recent = results.take(5).toList();
    final older = results.skip(5).take(5).toList();
    final recentAccuracy =
        recent.where((result) => result.correct).length / recent.length;
    final olderAccuracy =
        older.where((result) => result.correct).length / older.length;
    return recentAccuracy - olderAccuracy >= 0.2
        ? "Great job, $childName! You're ready for a tougher challenge! 🚀"
        : null;
  }

  static AdaptiveChallenge _challenge(
    Map<String, dynamic> problem,
    int level, {
    bool isReviewProblem = false,
    String? motivationalMessage,
  }) => AdaptiveChallenge(
    problemId:
        '${isReviewProblem ? 'review' : 'challenge'}_${DateTime.now().microsecondsSinceEpoch}',
    problemText: problem['problemText'] as String,
    level: level,
    bondSteps: problem['bondSteps'] as String,
    operand1: problem['operand1'] as int,
    operand2: problem['operand2'] as int,
    operator: problem['operator'] as String,
    correctAnswer: problem['correctAnswer'] as int,
    isReviewProblem: isReviewProblem,
    motivationalMessage: motivationalMessage,
  );

  static Future<AdaptiveChallenge> getNextProblem(
    String childId,
    String childName, {
    int? currentLevel,
    List<int> favoriteNumbers = const [],
    String preferredOperation = 'both',
  }) async {
    final level = await determineNextLevel(
      childId,
      currentLevel ?? await getCurrentLevel(childId),
    );
    if (await shouldInjectReviewProblem(childId)) {
      final review = await generateReviewProblem(
        childId,
        favoriteNumbers,
        currentLevel: level,
        preferredOperation: preferredOperation,
      );
      if (review != null) return review;
    }
    final problem = CentralProblemGenerator.generateProblem(
      action: _actionForPreference(preferredOperation),
      level: level,
    );
    return _challenge(
      problem,
      level,
      motivationalMessage: await getMotivationalFeedback(childId, childName),
    );
  }

  static Future<void> clearChildData(String childId) => _write(() async {
    final prefs = await SharedPreferences.getInstance();
    for (final prefix in [
      _resultsKey,
      _challengeCountKey,
      _levelKey,
      _levelStartCountKey,
      _levelDecisionKey,
      _stateKey,
    ]) {
      _requireSaved(await prefs.remove('${prefix}_$childId'));
    }
  });
}

class _AdaptiveState {
  final List<ProblemResult> results;
  final int count;
  final int? level;
  final int levelStartCount;
  final String? decision;

  const _AdaptiveState({
    this.results = const [],
    this.count = 0,
    this.level,
    this.levelStartCount = 0,
    this.decision,
  });

  factory _AdaptiveState.fromJson(Map<String, dynamic> json, String childId) {
    if (json['version'] != 1 || json['childId'] != childId) {
      throw const FormatException('Invalid adaptive state snapshot.');
    }
    return _AdaptiveState(
      results: (json['results'] as List)
          .map((value) => ProblemResult.fromJson(value as Map<String, dynamic>))
          .toList(),
      count: json['count'] as int,
      level: json['level'] as int?,
      levelStartCount: json['levelStartCount'] as int,
      decision: json['decision'] as String?,
    );
  }

  Map<String, dynamic> toJson(String childId) => {
    'version': 1,
    'childId': childId,
    'results': results.map((result) => result.toJson()).toList(),
    'count': count,
    'level': level,
    'levelStartCount': levelStartCount,
    'decision': decision,
  };

  _AdaptiveState copyWith({
    List<ProblemResult>? results,
    int? count,
    int? level,
    int? levelStartCount,
    String? decision,
  }) => _AdaptiveState(
    results: results ?? this.results,
    count: count ?? this.count,
    level: level ?? this.level,
    levelStartCount: levelStartCount ?? this.levelStartCount,
    decision: decision ?? this.decision,
  );
}
