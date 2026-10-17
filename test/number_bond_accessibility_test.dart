import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:number_bond_math/services/problem_generator.dart';
import 'package:number_bond_math/widgets/interactive_number_bond_widget.dart';

Finder _key(String value) => find.byKey(ValueKey(value));

Future<void> _withSemantics(
  WidgetTester tester,
  Future<void> Function() action,
) async {
  final semantics = tester.ensureSemantics();
  try {
    await action();
  } finally {
    semantics.dispose();
  }
}

Future<void> _pumpBond(
  WidgetTester tester, {
  String language = 'en',
  List<bool>? completions,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            height: 400,
            child: InteractiveNumberBondWidget(
              operand1: 4,
              operand2: 14,
              strategy: ProblemStrategy.crossing,
              compact: true,
              language: language,
              onBondComplete: completions?.add,
            ),
          ),
        ),
      ),
    ),
  );
}

SemanticsData _partData(WidgetTester tester, int index) =>
    tester.getSemantics(_key('bond-part-semantics-$index')).getSemanticsData();

SemanticsData _optionData(WidgetTester tester, String key, int number) => tester
    .getSemantics(
      find.ancestor(
        of: _key(key),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.label == '$number',
        ),
      ),
    )
    .getSemanticsData();

void main() {
  for (final translation in [
    (language: 'en', first: 'Part 1', second: 'Part 2', empty: 'Not chosen'),
    (language: 'es', first: 'Parte 1', second: 'Parte 2', empty: 'Sin elegir'),
    (
      language: 'fr',
      first: 'Partie 1',
      second: 'Partie 2',
      empty: 'Non choisi',
    ),
  ]) {
    testWidgets(
      '${translation.language} identifies each part and selected value',
      (tester) => _withSemantics(tester, () async {
        await _pumpBond(tester, language: translation.language);
        var first = _partData(tester, 0);
        var second = _partData(tester, 1);
        expect(first.label, translation.first);
        expect(first.value, translation.empty);
        expect(first.flagsCollection.isButton, isTrue);
        expect(first.flagsCollection.isSelected, isTrue);
        expect(first.flagsCollection.isEnabled, isTrue);
        expect(first.hasAction(ui.SemanticsAction.tap), isTrue);
        expect(second.label, translation.second);
        expect(second.flagsCollection.isSelected, isFalse);
        expect(second.value, translation.empty);
        await tester.tap(_key('bond-number-10'));
        await tester.pump();
        first = _partData(tester, 0);
        second = _partData(tester, 1);
        expect(first.value, '10');
        expect(first.flagsCollection.isSelected, isFalse);
        expect(second.flagsCollection.isSelected, isTrue);
        expect(
          _optionData(tester, 'bond-number-10', 10).flagsCollection.isSelected,
          isTrue,
        );
        expect(
          _optionData(tester, 'bond-number-1', 1).flagsCollection.isSelected,
          isFalse,
        );
        expect(tester.takeException(), isNull);
      }),
    );
  }

  testWidgets(
    'picker choices expose current selection and a working tap action',
    (tester) => _withSemantics(tester, () async {
      await _pumpBond(tester);
      await tester.tap(_key('bond-number-10'));
      await tester.pump();
      await tester.tap(_key('bond-part-0'));
      await tester.pumpAndSettle();
      final selected = _optionData(tester, 'bond-picker-number-10', 10);
      expect(selected.label, '10');
      expect(selected.flagsCollection.isSelected, isTrue);
      expect(selected.flagsCollection.isButton, isTrue);
      expect(selected.flagsCollection.isEnabled, isTrue);
      expect(selected.hasAction(ui.SemanticsAction.tap), isTrue);
      final choice = _optionData(tester, 'bond-picker-number-4', 4);
      expect(choice.flagsCollection.isSelected, isFalse);
      await tester.tap(_key('bond-picker-number-4'));
      await tester.pumpAndSettle();
      expect(_partData(tester, 0).value, '4');
      expect(tester.takeException(), isNull);
    }),
  );

  testWidgets(
    'completed answer announces disabled parts and number options',
    (tester) => _withSemantics(tester, () async {
      final completions = <bool>[];
      await _pumpBond(tester, completions: completions);
      await tester.tap(_key('bond-number-10'));
      await tester.pump();
      await tester.tap(_key('bond-number-4'));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();
      expect(completions, [true]);
      final part = _partData(tester, 0);
      expect(part.flagsCollection.isEnabled, isFalse);
      expect(part.hasAction(ui.SemanticsAction.tap), isFalse);
      final option = _optionData(tester, 'bond-number-10', 10);
      expect(option.flagsCollection.isSelected, isTrue);
      expect(option.flagsCollection.isEnabled, isFalse);
      expect(option.hasAction(ui.SemanticsAction.tap), isFalse);
      expect(tester.takeException(), isNull);
    }),
  );
}
