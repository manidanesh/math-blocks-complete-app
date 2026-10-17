import 'dart:math';

/// Operand choices for generated number-bond challenges.
class ChallengeGenerationRules {
  static const _excludedSecondOperands = [10, 100, 1000];

  static bool isAllowedSecondOperand(int number) =>
      !_excludedSecondOperands.contains(number);

  /// Choose from the allowed values without repeatedly drawing excluded ones.
  static int chooseSecondOperand(
    Random random, {
    required int min,
    required int max,
  }) {
    final excluded = _excludedSecondOperands
        .where((number) => number >= min && number <= max)
        .toList();
    final allowedCount = max - min + 1 - excluded.length;
    if (allowedCount <= 0) {
      throw ArgumentError('No allowed second operand between $min and $max.');
    }
    var number = min + random.nextInt(allowedCount);
    for (final excludedNumber in excluded) {
      if (number >= excludedNumber) number++;
    }
    return number;
  }
}
