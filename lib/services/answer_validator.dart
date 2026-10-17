enum BondMethod { makeTen, placeValue, basic }

/// Validates a decomposition of the second operand and describes its strategy.
class AnswerValidator {
  /// Compatibility entry point for the original two-circle number bond.
  static ValidationResult validateAnswer({
    required int number1,
    required int number2,
    required String action,
    required int userPart1,
    required int userPart2,
  }) => validateParts(
    number1: number1,
    number2: number2,
    action: action,
    userParts: [userPart1, userPart2],
  );

  static ValidationResult validateParts({
    required int number1,
    required int number2,
    required String action,
    required List<int> userParts,
  }) {
    if (action != 'addition' && action != 'subtraction') {
      return ValidationResult(
        success: false,
        message: 'Invalid action: $action',
        proposedSolution: '',
      );
    }

    final parts = List<int>.of(userParts);
    final boundary = _boundaryParts(number1, number2, action);
    final validParts = parts.length >= 2 && parts.every((part) => part >= 0);
    final total = parts.fold<int>(0, (sum, part) => sum + part);
    final mathCorrect = validParts && total == number2;
    final orderCorrect =
        action == 'addition' ||
        _isLegacySubtraction(number1, parts) ||
        _isRoundDecomposition(parts);
    final success = mathCorrect && orderCorrect;
    final method = _inferMethod(parts, boundary, success: success);
    final solutionParts = success
        ? parts
        : _correctedParts(number2, parts, boundary, method);

    final String message;
    if (!validParts) {
      message = 'Choose at least two nonnegative parts.';
    } else if (!mathCorrect) {
      message =
          'Math error: ${parts.join(' + ')} = $total, '
          'but should equal $number2';
    } else if (!orderCorrect) {
      message =
          'Use the reach-ten split, or round-number parts '
          'with at most one remainder.';
    } else {
      message = 'Correct! $number2 = ${parts.join(' + ')}';
    }

    return ValidationResult(
      success: success,
      message: message,
      proposedSolution: _solutionText(number1, number2, action, solutionParts),
      solutionParts: solutionParts,
      method: method,
    );
  }

  /// Expanded place values, omitting empty places: 235 -> [200, 30, 5].
  static List<int> placeValueParts(int number) {
    if (number <= 0) return const [];
    final parts = <int>[];
    var remaining = number;
    var place = 1;
    while (remaining > 0) {
      final digit = remaining % 10;
      if (digit != 0) parts.insert(0, digit * place);
      remaining ~/= 10;
      place *= 10;
    }
    return List<int>.unmodifiable(parts);
  }

  /// Correct choices for the existing method and round-number decompositions.
  static List<List<int>> suggestedBreakdowns({
    required int number1,
    required int number2,
    required String action,
  }) {
    if (action != 'addition' && action != 'subtraction') return const [];
    final suggestions = <List<int>>[];
    final seen = <String>{};
    void add(List<int> parts) {
      if (parts.length < 2 ||
          parts.any((part) => part < 0) ||
          parts.fold<int>(0, (sum, part) => sum + part) != number2) {
        return;
      }
      if (seen.add(parts.join(','))) {
        suggestions.add(List<int>.unmodifiable(parts));
      }
    }

    final boundary = _boundaryParts(number1, number2, action);
    if (boundary != null) add(boundary);
    if (action == 'subtraction' && number1 % 10 == 0 && number2 >= 2) {
      add([number2 ~/ 2, number2 - number2 ~/ 2]);
    }
    add(placeValueParts(number2));
    for (var place = 10; place < number2; place *= 10) {
      for (var digit = 1; digit <= 9; digit++) {
        final chunk = digit * place;
        if (chunk < number2) add([chunk, number2 - chunk]);
      }
    }
    if (suggestions.isEmpty && number2 >= 2 && action == 'addition') {
      add([number2 ~/ 2, number2 - number2 ~/ 2]);
    }
    return List<List<int>>.unmodifiable(suggestions);
  }

  static bool _isRound(int part) => part > 0 && part % 10 == 0;

  static bool _isRoundDecomposition(List<int> parts) {
    final positive = parts.where((part) => part > 0);
    return positive.any(_isRound) &&
        positive.where((part) => !_isRound(part)).length <= 1;
  }

  static bool _isLegacySubtraction(int number1, List<int> parts) {
    if (parts.length != 2) return false;
    final ones = number1 % 10;
    if (ones != 0) return parts.first == ones;
    final target = parts[0] + parts[1];
    return parts.first == 10 || parts.first == target ~/ 2;
  }

  static List<int>? _boundaryParts(int number1, int number2, String action) {
    final ones = number1 % 10;
    final first = action == 'addition' ? 10 - ones : (ones == 0 ? 10 : ones);
    if (first <= 0 || first > number2) return null;
    return [first, number2 - first];
  }

  static BondMethod _inferMethod(
    List<int> parts,
    List<int>? boundary, {
    required bool success,
  }) {
    // A round remainder in an existing two-part approach does not change it.
    if (parts.length == 2 &&
        boundary != null &&
        parts.first == boundary.first) {
      return BondMethod.makeTen;
    }
    if (parts.any(_isRound)) return BondMethod.placeValue;
    // Correct arbitrary addition splits and legacy even splits do not become
    // make-ten examples just because that method was available for the problem.
    return !success && boundary != null ? BondMethod.makeTen : BondMethod.basic;
  }

  static List<int> _correctedParts(
    int number2,
    List<int> attempted,
    List<int>? boundary,
    BondMethod method,
  ) {
    if (number2 <= 0) return const [];
    if (method == BondMethod.placeValue) {
      if (attempted.length == 2) {
        for (var index = 0; index < attempted.length; index++) {
          final chunk = attempted[index];
          if (_isRound(chunk) && chunk < number2) {
            return index == 0
                ? [chunk, number2 - chunk]
                : [number2 - chunk, chunk];
          }
        }
      }
      final expanded = placeValueParts(number2);
      if (expanded.length >= 2) return expanded;
      if (number2 > 10) return [number2 - 10, 10];
    }
    // Preserve a zero remainder when it is part of the accepted legacy rule.
    if (boundary != null && boundary.every((part) => part >= 0)) {
      return boundary;
    }
    if (number2 >= 2) return [number2 ~/ 2, number2 - number2 ~/ 2];
    return [number2];
  }

  static String _solutionText(
    int number1,
    int number2,
    String action,
    List<int> parts,
  ) {
    if (parts.isEmpty) return '';
    final operation = action == 'addition' ? '+' : '-';
    final steps = <String>['$number2 → ${parts.join(' + ')}'];
    var current = number1;
    for (final part in parts) {
      final next = action == 'addition' ? current + part : current - part;
      steps.add('$current $operation $part = $next');
      current = next;
    }
    return steps.join('\n');
  }
}

class ValidationResult {
  final bool success;
  final String message;
  final String proposedSolution;
  final List<int> solutionParts;
  final BondMethod method;

  ValidationResult({
    required this.success,
    required this.message,
    required this.proposedSolution,
    List<int> solutionParts = const [],
    this.method = BondMethod.basic,
  }) : solutionParts = List<int>.unmodifiable(solutionParts);

  @override
  String toString() => 'ValidationResult(success: $success, message: $message)';
}
