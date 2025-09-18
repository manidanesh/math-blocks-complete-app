/// Represents a single attempt at solving a math problem
class ProblemAttempt {
  final String id;
  final String childId;
  final String problemText;
  final int operand1;
  final int operand2;
  final String operator;
  final int correctAnswer;
  final int? userAnswer;
  final bool isCorrect;
  final DateTime timestamp;
  final int attemptNumber; // 1st, 2nd, 3rd attempt
  final double timeSpentSeconds;
  final String strategy; // 'make_ten', 'counting', etc.
  final int difficultyLevel;
  final String skillArea; // 'addition_level1', 'addition_level2'
  final bool usedHint;
  final String? hintType;
  final String? explanation; // Explanation shown after failure

  const ProblemAttempt({
    required this.id,
    required this.childId,
    required this.problemText,
    required this.operand1,
    required this.operand2,
    required this.operator,
    required this.correctAnswer,
    this.userAnswer,
    required this.isCorrect,
    required this.timestamp,
    required this.attemptNumber,
    required this.timeSpentSeconds,
    required this.strategy,
    required this.difficultyLevel,
    required this.skillArea,
    required this.usedHint,
    this.hintType,
    this.explanation,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'problemText': problemText,
      'operand1': operand1,
      'operand2': operand2,
      'operator': operator,
      'correctAnswer': correctAnswer,
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
      'timestamp': timestamp.toIso8601String(),
      'attemptNumber': attemptNumber,
      'timeSpentSeconds': timeSpentSeconds,
      'strategy': strategy,
      'difficultyLevel': difficultyLevel,
      'skillArea': skillArea,
      'usedHint': usedHint,
      'hintType': hintType,
      'explanation': explanation,
    };
  }

  factory ProblemAttempt.fromJson(Map<String, dynamic> json) {
    return ProblemAttempt(
      id: json['id'] as String,
      childId: json['childId'] as String,
      problemText: json['problemText'] as String,
      operand1: json['operand1'] as int,
      operand2: json['operand2'] as int,
      operator: json['operator'] as String,
      correctAnswer: json['correctAnswer'] as int,
      userAnswer: json['userAnswer'] as int?,
      isCorrect: json['isCorrect'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      attemptNumber: json['attemptNumber'] as int,
      timeSpentSeconds: json['timeSpentSeconds'] as double,
      strategy: json['strategy'] as String,
      difficultyLevel: json['difficultyLevel'] as int,
      skillArea: json['skillArea'] as String,
      usedHint: json['usedHint'] as bool,
      hintType: json['hintType'] as String?,
      explanation: json['explanation'] as String?,
    );
  }

  @override
  String toString() {
    return 'ProblemAttempt(problem: $problemText, correct: $isCorrect, attempt: $attemptNumber, time: ${timeSpentSeconds}s)';
  }
}

/// Represents a complete problem session with multiple attempts
class ProblemSession {
  final String id;
  final String childId;
  final String problemText;
  final List<ProblemAttempt> attempts;
  final bool wasCompleted;
  final bool needsReview;
  final DateTime startTime;
  final DateTime? endTime;
  final String skillArea;
  final int difficultyLevel;
  final String? finalExplanation; // Explanation given after 3 failures

  const ProblemSession({
    required this.id,
    required this.childId,
    required this.problemText,
    required this.attempts,
    required this.wasCompleted,
    required this.needsReview,
    required this.startTime,
    this.endTime,
    required this.skillArea,
    required this.difficultyLevel,
    this.finalExplanation,
  });

  /// Get the total number of attempts made
  int get totalAttempts => attempts.length;

  /// Check if the problem was solved correctly
  bool get wasSolved => attempts.any((attempt) => attempt.isCorrect);

  /// Get the final attempt (successful or last failed attempt)
  ProblemAttempt? get finalAttempt => attempts.isNotEmpty ? attempts.last : null;

  /// Calculate total time spent on this problem
  double get totalTimeSpent {
    return attempts.fold(0.0, (sum, attempt) => sum + attempt.timeSpentSeconds);
  }

  /// Check if hints were used during this session
  bool get usedHints => attempts.any((attempt) => attempt.usedHint);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'problemText': problemText,
      'attempts': attempts.map((attempt) => attempt.toJson()).toList(),
      'wasCompleted': wasCompleted,
      'needsReview': needsReview,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'skillArea': skillArea,
      'difficultyLevel': difficultyLevel,
      'finalExplanation': finalExplanation,
    };
  }

  factory ProblemSession.fromJson(Map<String, dynamic> json) {
    return ProblemSession(
      id: json['id'] as String,
      childId: json['childId'] as String,
      problemText: json['problemText'] as String,
      attempts: (json['attempts'] as List<dynamic>)
          .map((attemptJson) => ProblemAttempt.fromJson(attemptJson as Map<String, dynamic>))
          .toList(),
      wasCompleted: json['wasCompleted'] as bool,
      needsReview: json['needsReview'] as bool,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      skillArea: json['skillArea'] as String,
      difficultyLevel: json['difficultyLevel'] as int,
      finalExplanation: json['finalExplanation'] as String?,
    );
  }
}
