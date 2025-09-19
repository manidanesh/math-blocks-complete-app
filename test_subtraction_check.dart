import 'dart:math';

// Test if subtraction problems cross the next 10
bool subtractionCrossesNextTen(int firstNumber, int secondNumber) {
  final firstNumberOnes = firstNumber % 10;
  final result = firstNumber - secondNumber;
  final currentTen = firstNumber - firstNumberOnes;
  return result < currentTen;
}

// Test the new generation logic
void testNewSubtractionLogic() {
  final random = Random();
  
  print('Testing new subtraction generation logic:');
  for (int i = 0; i < 10; i++) {
    int firstNumber = random.nextInt(90) + 10; // 10-99
    final firstNumberOnes = firstNumber % 10;
    
    int secondNumber;
    do {
      if (firstNumberOnes == 0) {
        secondNumber = random.nextInt(9) + 1; // 1-9
      } else {
        final minSecond = firstNumberOnes + 1;
        if (minSecond <= 9) {
          secondNumber = random.nextInt(9 - minSecond + 1) + minSecond;
        } else {
          secondNumber = 9;
        }
      }
      
      // Double-check that this actually crosses the next 10
      final result = firstNumber - secondNumber;
      final currentTen = firstNumber - firstNumberOnes;
      final crossesTen = result < currentTen;
      
      if (!crossesTen) {
        secondNumber = min(9, firstNumberOnes + random.nextInt(3) + 2);
      }
    } while (secondNumber == firstNumberOnes);
    
    final result = firstNumber - secondNumber;
    final crosses = subtractionCrossesNextTen(firstNumber, secondNumber);
    print('$firstNumber - $secondNumber = $result (crosses: $crosses)');
  }
}

void main() {
  print('Testing problematic cases that should be avoided:');
  print('18 - 6 = ${18 - 6}, crosses below 10: ${subtractionCrossesNextTen(18, 6)} ❌');
  print('89 - 7 = ${89 - 7}, crosses below 80: ${subtractionCrossesNextTen(89, 7)} ❌');
  print('');
  print('Testing correct cases:');
  print('18 - 9 = ${18 - 9}, crosses below 10: ${subtractionCrossesNextTen(18, 9)} ✅');
  print('67 - 8 = ${67 - 8}, crosses below 60: ${subtractionCrossesNextTen(67, 8)} ✅');
  print('');
  
  testNewSubtractionLogic();
}
