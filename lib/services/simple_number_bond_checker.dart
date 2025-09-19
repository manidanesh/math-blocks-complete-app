/// SIMPLE, CLEAN NUMBER BOND CHECKER
/// Single responsibility: Check if user's breakdown is mathematically correct
class SimpleNumberBondChecker {
  
  /// Checks if the user's breakdown is correct
  /// For subtraction: user breaks secondNumber into two parts that add up
  /// Example: 12 - 5, user says 5 = 2 + 3, we check if 2 + 3 = 5
  static bool isCorrectBreakdown({
    required int secondNumber,
    required int userPart1,
    required int userPart2,
  }) {
    return userPart1 + userPart2 == secondNumber;
  }
  
  /// Gets the correct answer for the problem
  static int getCorrectAnswer({
    required int firstNumber,
    required int secondNumber,
  }) {
    return firstNumber - secondNumber;
  }
  
  /// Simple explanation for the user
  static String getExplanation({
    required int firstNumber,
    required int secondNumber,
    required int userPart1,
    required int userPart2,
  }) {
    final isCorrect = isCorrectBreakdown(
      secondNumber: secondNumber,
      userPart1: userPart1,
      userPart2: userPart2,
    );
    
    if (isCorrect) {
      final answer = getCorrectAnswer(firstNumber: firstNumber, secondNumber: secondNumber);
      return '''
✅ Correct! 
$secondNumber = $userPart1 + $userPart2
$firstNumber - $userPart1 - $userPart2 = ${firstNumber - userPart1} - $userPart2 = $answer
''';
    } else {
      return '''
❌ Not quite right.
You said $secondNumber = $userPart1 + $userPart2 = ${userPart1 + userPart2}
But $userPart1 + $userPart2 should equal $secondNumber
''';
    }
  }
}


