import 'package:flutter/material.dart';

/// Represents a single problem attempt for insights analysis
class ProblemLog {
  final String id;
  final String childId;
  final String problemType; // 'addition', 'subtraction', 'make_ten', 'crossing', etc.
  final List<int> numbersUsed; // [operand1, operand2] or [operand1, operand2, operand3]
  final bool correct;
  final int timeTaken; // in seconds
  final bool hintUsed;
  final DateTime timestamp;
  final String level; // 'Level 1', 'Level 2', etc.
  final String strategy; // 'make_ten', 'crossing', 'basic', etc.

  ProblemLog({
    required this.id,
    required this.childId,
    required this.problemType,
    required this.numbersUsed,
    required this.correct,
    required this.timeTaken,
    required this.hintUsed,
    required this.timestamp,
    required this.level,
    required this.strategy,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'problemType': problemType,
      'numbersUsed': numbersUsed,
      'correct': correct,
      'timeTaken': timeTaken,
      'hintUsed': hintUsed,
      'timestamp': timestamp.toIso8601String(),
      'level': level,
      'strategy': strategy,
    };
  }

  static ProblemLog fromJson(Map<String, dynamic> json) {
    return ProblemLog(
      id: json['id'],
      childId: json['childId'],
      problemType: json['problemType'],
      numbersUsed: List<int>.from(json['numbersUsed']),
      correct: json['correct'],
      timeTaken: json['timeTaken'],
      hintUsed: json['hintUsed'],
      timestamp: DateTime.parse(json['timestamp']),
      level: json['level'],
      strategy: json['strategy'],
    );
  }
}

/// Represents a learning pattern detected from analysis
class LearningPattern {
  final String patternType; // 'strength', 'weakness', 'trend'
  final String category; // 'problem_type', 'number_range', 'strategy', 'speed'
  final String description;
  final double confidence; // 0.0 to 1.0
  final Map<String, dynamic> metadata; // Additional context data

  LearningPattern({
    required this.patternType,
    required this.category,
    required this.description,
    required this.confidence,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'patternType': patternType,
      'category': category,
      'description': description,
      'confidence': confidence,
      'metadata': metadata,
    };
  }

  static LearningPattern fromJson(Map<String, dynamic> json) {
    return LearningPattern(
      patternType: json['patternType'],
      category: json['category'],
      description: json['description'],
      confidence: json['confidence'],
      metadata: Map<String, dynamic>.from(json['metadata']),
    );
  }
}

/// Represents an actionable insight generated from learning patterns
class Insight {
  final String id;
  final String childId;
  final String type; // 'strength', 'weakness', 'recommendation'
  final String title;
  final String message;
  final List<String> actionableSteps;
  final String priority; // 'high', 'medium', 'low'
  final DateTime generatedAt;
  final List<LearningPattern> relatedPatterns;
  final Map<String, dynamic> correctiveActions; // Links to specific actions

  Insight({
    required this.id,
    required this.childId,
    required this.type,
    required this.title,
    required this.message,
    required this.actionableSteps,
    required this.priority,
    required this.generatedAt,
    required this.relatedPatterns,
    required this.correctiveActions,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'type': type,
      'title': title,
      'message': message,
      'actionableSteps': actionableSteps,
      'priority': priority,
      'generatedAt': generatedAt.toIso8601String(),
      'relatedPatterns': relatedPatterns.map((p) => p.toJson()).toList(),
      'correctiveActions': correctiveActions,
    };
  }

  static Insight fromJson(Map<String, dynamic> json) {
    return Insight(
      id: json['id'],
      childId: json['childId'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      actionableSteps: List<String>.from(json['actionableSteps']),
      priority: json['priority'],
      generatedAt: DateTime.parse(json['generatedAt']),
      relatedPatterns: (json['relatedPatterns'] as List)
          .map((p) => LearningPattern.fromJson(p))
          .toList(),
      correctiveActions: Map<String, dynamic>.from(json['correctiveActions']),
    );
  }

  /// Get appropriate icon for the insight type
  IconData get icon {
    switch (type) {
      case 'strength':
        return Icons.star;
      case 'weakness':
        return Icons.warning;
      case 'recommendation':
        return Icons.lightbulb;
      default:
        return Icons.info;
    }
  }

  /// Get appropriate color for the insight type
  Color get color {
    switch (type) {
      case 'strength':
        return Colors.green;
      case 'weakness':
        return Colors.orange;
      case 'recommendation':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// Get priority color
  Color get priorityColor {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

/// Represents analysis results for a child's learning progress
class InsightsAnalysis {
  final String childId;
  final DateTime analyzedAt;
  final int totalProblems;
  final double overallAccuracy;
  final double averageTime;
  final List<LearningPattern> patterns;
  final List<Insight> insights;
  final Map<String, double> problemTypeAccuracy; // 'addition': 0.85, 'subtraction': 0.70
  final Map<String, double> strategyAccuracy; // 'make_ten': 0.90, 'crossing': 0.75
  final Map<String, double> numberRangeAccuracy; // 'single_digit': 0.88, 'two_digit': 0.72

  InsightsAnalysis({
    required this.childId,
    required this.analyzedAt,
    required this.totalProblems,
    required this.overallAccuracy,
    required this.averageTime,
    required this.patterns,
    required this.insights,
    required this.problemTypeAccuracy,
    required this.strategyAccuracy,
    required this.numberRangeAccuracy,
  });

  Map<String, dynamic> toJson() {
    return {
      'childId': childId,
      'analyzedAt': analyzedAt.toIso8601String(),
      'totalProblems': totalProblems,
      'overallAccuracy': overallAccuracy,
      'averageTime': averageTime,
      'patterns': patterns.map((p) => p.toJson()).toList(),
      'insights': insights.map((i) => i.toJson()).toList(),
      'problemTypeAccuracy': problemTypeAccuracy,
      'strategyAccuracy': strategyAccuracy,
      'numberRangeAccuracy': numberRangeAccuracy,
    };
  }

  static InsightsAnalysis fromJson(Map<String, dynamic> json) {
    return InsightsAnalysis(
      childId: json['childId'],
      analyzedAt: DateTime.parse(json['analyzedAt']),
      totalProblems: json['totalProblems'],
      overallAccuracy: json['overallAccuracy'],
      averageTime: json['averageTime'],
      patterns: (json['patterns'] as List)
          .map((p) => LearningPattern.fromJson(p))
          .toList(),
      insights: (json['insights'] as List)
          .map((i) => Insight.fromJson(i))
          .toList(),
      problemTypeAccuracy: Map<String, double>.from(json['problemTypeAccuracy']),
      strategyAccuracy: Map<String, double>.from(json['strategyAccuracy']),
      numberRangeAccuracy: Map<String, double>.from(json['numberRangeAccuracy']),
    );
  }
}
