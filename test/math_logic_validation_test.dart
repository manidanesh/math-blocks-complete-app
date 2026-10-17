import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:number_bond_math/services/central_problem_generator.dart';
import 'package:number_bond_math/services/math_logic_validator.dart';
import 'package:number_bond_math/services/debug_validator.dart';

void main() {
  test(
    'live generator answers and all offered decompositions work at every level',
    () {
      CentralProblemGenerator.setRandomForTesting(Random(20261010));
      addTearDown(() => CentralProblemGenerator.setRandomForTesting(Random()));
      expect(MathLogicValidator.validateAllLogic(samplesPerLevel: 200), 1600);
    },
  );

  test('diagnostic rejects a vacuous sample count', () {
    expect(
      () => MathLogicValidator.validateAllLogic(samplesPerLevel: 0),
      throwsArgumentError,
    );
  });
  test('debug explanations use accepted boundary and place-value splits', () {
    final explanations = DebugValidator.validateProblem(29, 15, '-');
    expect(explanations, contains('29 - 9 = 20\n20 - 6 = 14'));
    expect(explanations, contains('29 - 10 = 19\n19 - 5 = 14'));
    expect(explanations, isNot(contains('7 + 8')));
    expect(
      DebugValidator.validateProblem(29, 3, '-'),
      contains('No supported'),
    );
    expect(DebugValidator.validateProblem(4, 14, '*'), contains('Unsupported'));
  });
}
