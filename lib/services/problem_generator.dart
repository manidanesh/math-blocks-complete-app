import 'dart:math';

/// Strategy for problem generation
enum ProblemStrategy {
  makeTen,      // Focus on making 10 first
  crossing,     // Problems that cross 10 or 20
  basic,        // Basic addition without crossing
  review,       // Mixed review problems
}

/// Difficulty levels for math problems
class DifficultyLevel {
  final int level;
  final String name;
  final String description;
  final int minOperand1;
  final int maxOperand1;
  final int minOperand2;
  final int maxOperand2;
  final bool mustCrossTen;
  final bool mustCrossTwenty;
  final ProblemStrategy preferredStrategy;

  const DifficultyLevel({
    required this.level,
    required this.name,
    required this.description,
    required this.minOperand1,
    required this.maxOperand1,
    required this.minOperand2,
    required this.maxOperand2,
    this.mustCrossTen = false,
    this.mustCrossTwenty = false,
    this.preferredStrategy = ProblemStrategy.basic,
  });
}

/// Generated math problem
class MathProblem {
  final int operand1;
  final int operand2;
  final String operator;
  final int correctAnswer;
  final String problemText;
  final List<int> options;
  final ProblemStrategy strategy;
  final int level;
  final String explanation;

  const MathProblem({
    required this.operand1,
    required this.operand2,
    required this.operator,
    required this.correctAnswer,
    required this.problemText,
    required this.options,
    required this.strategy,
    required this.level,
    required this.explanation,
  });

  @override
  String toString() {
    return '$problemText (Level $level, Strategy: $strategy)';
  }
}

/// Service for generating adaptive math problems
class ProblemGenerator {
  static final Random _random = Random();

  /// Difficulty levels configuration
  static const List<DifficultyLevel> _levels = [
    DifficultyLevel(
      level: 1,
      name: "Beginner",
      description: "Single digit + single digit (no crossing 10)",
      minOperand1: 1,
      maxOperand1: 9,
      minOperand2: 1,
      maxOperand2: 9,
      preferredStrategy: ProblemStrategy.basic,
    ),
    DifficultyLevel(
      level: 2,
      name: "Make Ten",
      description: "Problems that make 10 (crossing 10 strategy)",
      minOperand1: 4,
      maxOperand1: 9,
      minOperand2: 1,
      maxOperand2: 9,
      mustCrossTen: true,
      preferredStrategy: ProblemStrategy.makeTen,
    ),
    DifficultyLevel(
      level: 3,
      name: "Teen Numbers",
      description: "Two digit + single digit (crossing 20)",
      minOperand1: 10,
      maxOperand1: 19,
      minOperand2: 1,
      maxOperand2: 9,
      mustCrossTwenty: true,
      preferredStrategy: ProblemStrategy.crossing,
    ),
    DifficultyLevel(
      level: 4,
      name: "Advanced",
      description: "Two digit + single digit (advanced crossing)",
      minOperand1: 15,
      maxOperand1: 25,
      minOperand2: 5,
      maxOperand2: 15,
      preferredStrategy: ProblemStrategy.crossing,
    ),
    DifficultyLevel(
      level: 5,
      name: "Expert",
      description: "Mixed problems with various strategies",
      minOperand1: 10,
      maxOperand1: 50,
      minOperand2: 10,
      maxOperand2: 25,
      preferredStrategy: ProblemStrategy.review,
    ),
  ];

  /// Generate a problem for the specified level and strategy
  static MathProblem generateProblem({
    required int level,
    ProblemStrategy? strategy,
  }) {
    try {
      // Clamp level to valid range
      final clampedLevel = level.clamp(1, _levels.length);
      final difficultyLevel = _levels[clampedLevel - 1];
      
      // Use provided strategy or level's preferred strategy
      final problemStrategy = strategy ?? difficultyLevel.preferredStrategy;
      
      // Generate operands based on level and strategy
      final operands = _generateOperands(difficultyLevel, problemStrategy);
      final operand1 = operands['operand1']!;
      final operand2 = operands['operand2']!;
      
      // Calculate answer
      const operator = '+';
      final correctAnswer = operand1 + operand2;
      
      // Create problem text
      final problemText = '$operand1 $operator $operand2 = ?';
      
      // Generate multiple choice options
      final options = _generateOptions(correctAnswer);
      
      // Create explanation based on strategy
      final explanation = _generateExplanation(
        operand1, 
        operand2, 
        correctAnswer, 
        problemStrategy,
      );
      
      final problem = MathProblem(
        operand1: operand1,
        operand2: operand2,
        operator: operator,
        correctAnswer: correctAnswer,
        problemText: problemText,
        options: options,
        strategy: problemStrategy,
        level: clampedLevel,
        explanation: explanation,
      );
      
      print('🧮 Generated problem: $problem');
      return problem;
    } catch (e) {
      print('❌ Error generating problem: $e');
      // Return safe fallback problem
      return const MathProblem(
        operand1: 3,
        operand2: 4,
        operator: '+',
        correctAnswer: 7,
        problemText: '3 + 4 = ?',
        options: [5, 6, 7, 8],
        strategy: ProblemStrategy.basic,
        level: 1,
        explanation: 'Count up: 3, 4, 5, 6, 7',
      );
    }
  }

  /// Generate operands based on difficulty level and strategy
  static Map<String, int> _generateOperands(
    DifficultyLevel level, 
    ProblemStrategy strategy,
  ) {
    int operand1, operand2;
    int attempts = 0;
    const maxAttempts = 50;
    
    do {
      operand1 = _random.nextInt(level.maxOperand1 - level.minOperand1 + 1) + level.minOperand1;
      operand2 = _random.nextInt(level.maxOperand2 - level.minOperand2 + 1) + level.minOperand2;
      attempts++;
      
      if (attempts > maxAttempts) {
        // Fallback to prevent infinite loop
        operand1 = level.minOperand1;
        operand2 = level.minOperand2;
        break;
      }
    } while (!_meetsStrategyRequirements(operand1, operand2, level, strategy));
    
    return {'operand1': operand1, 'operand2': operand2};
  }

  /// Check if operands meet the strategy requirements
  static bool _meetsStrategyRequirements(
    int operand1, 
    int operand2, 
    DifficultyLevel level,
    ProblemStrategy strategy,
  ) {
    final sum = operand1 + operand2;
    
    switch (strategy) {
      case ProblemStrategy.makeTen:
        // Must cross 10, and one operand should work well with make-ten strategy
        return sum > 10 && sum <= 20 && (operand1 <= 10 || operand2 <= 10);
        
      case ProblemStrategy.crossing:
        if (level.mustCrossTwenty) {
          return sum > 20; // Must cross 20
        } else if (level.mustCrossTen) {
          return sum > 10 && sum <= 20; // Must cross 10 but not 20
        }
        return sum > 10;
        
      case ProblemStrategy.basic:
        // Should not cross major boundaries unless required by level
        if (level.mustCrossTen || level.mustCrossTwenty) {
          return true; // Level requirements take precedence
        }
        return sum <= 10; // Stay within 10 for basic strategy
        
      case ProblemStrategy.review:
        // Mixed problems, any valid combination
        return true;
    }
  }

  /// Generate multiple choice options including the correct answer
  static List<int> _generateOptions(int correctAnswer) {
    final options = <int>{correctAnswer}; // Use Set to avoid duplicates
    
    // Generate plausible wrong answers
    final variations = [
      correctAnswer - 1,  // Off by one (common error)
      correctAnswer + 1,  // Off by one (common error)
      correctAnswer - 2,  // Calculation error
      correctAnswer + 2,  // Calculation error
      correctAnswer - 10, // Place value error
      correctAnswer + 10, // Place value error
    ];
    
    // Add variations that make sense (positive numbers)
    for (final variation in variations) {
      if (variation > 0 && variation != correctAnswer && options.length < 4) {
        options.add(variation);
      }
    }
    
    // Fill remaining slots with random plausible answers
    while (options.length < 4) {
      final randomOption = correctAnswer + _random.nextInt(10) - 5;
      if (randomOption > 0) {
        options.add(randomOption);
      }
    }
    
    // Convert to list and shuffle
    final optionsList = options.toList();
    optionsList.shuffle(_random);
    
    return optionsList;
  }

  /// Generate explanation based on strategy
  static String _generateExplanation(
    int operand1, 
    int operand2, 
    int answer, 
    ProblemStrategy strategy,
  ) {
    switch (strategy) {
      case ProblemStrategy.makeTen:
        // Find how to make 10 first
        if (operand1 <= 10 && operand2 <= 10) {
          final needed = 10 - operand1;
          if (needed <= operand2) {
            final remaining = operand2 - needed;
            return "Make 10 first: $operand1 + $needed = 10, then 10 + $remaining = $answer";
          }
        }
        return "Think: What makes 10? Then add the rest.";
        
      case ProblemStrategy.crossing:
        if (answer > 20) {
          return "Cross 20: Break down the problem step by step";
        } else if (answer > 10) {
          return "Cross 10: $operand1 + $operand2. First make 10, then add the rest";
        }
        return "Add step by step: $operand1 + $operand2 = $answer";
        
      case ProblemStrategy.basic:
        if (answer <= 10) {
          return "Count up: Start with $operand1 and count $operand2 more";
        }
        return "Add: $operand1 + $operand2 = $answer";
        
      case ProblemStrategy.review:
        return "Use your preferred strategy: counting, making 10, or breaking numbers apart";
    }
  }

  /// Get available difficulty levels
  static List<DifficultyLevel> get levels => _levels;

  /// Get level info by number
  static DifficultyLevel? getLevelInfo(int level) {
    if (level < 1 || level > _levels.length) return null;
    return _levels[level - 1];
  }

  /// Generate a set of problems for practice session
  static List<MathProblem> generatePracticeSet({
    required int level,
    int count = 5,
    ProblemStrategy? strategy,
  }) {
    final problems = <MathProblem>[];
    
    for (int i = 0; i < count; i++) {
      problems.add(generateProblem(level: level, strategy: strategy));
    }
    
    return problems;
  }

  /// Generate review problems based on struggling concepts
  static List<MathProblem> generateReviewProblems({
    required List<String> strugglingConcepts,
    int count = 3,
  }) {
    final problems = <MathProblem>[];
    
    for (final concept in strugglingConcepts) {
      final strategy = _getStrategyForConcept(concept);
      final level = _getLevelForConcept(concept);
      
      problems.add(generateProblem(level: level, strategy: strategy));
      
      if (problems.length >= count) break;
    }
    
    // Fill remaining with basic problems if needed
    while (problems.length < count) {
      problems.add(generateProblem(level: 1, strategy: ProblemStrategy.basic));
    }
    
    return problems;
  }

  /// Map concept to strategy
  static ProblemStrategy _getStrategyForConcept(String concept) {
    switch (concept) {
      case 'single_digit_addition':
        return ProblemStrategy.basic;
      case 'crossing_ten':
        return ProblemStrategy.makeTen;
      case 'crossing_twenty':
        return ProblemStrategy.crossing;
      default:
        return ProblemStrategy.review;
    }
  }

  /// Map concept to appropriate level
  static int _getLevelForConcept(String concept) {
    switch (concept) {
      case 'single_digit_addition':
        return 1;
      case 'crossing_ten':
        return 2;
      case 'crossing_twenty':
        return 3;
      default:
        return 2;
    }
  }
}
