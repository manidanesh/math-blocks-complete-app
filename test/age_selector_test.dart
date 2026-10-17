import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:number_bond_math/widgets/age_selector.dart';

void main() {
  for (final scale in [1.0, 2.4]) {
    testWidgets(
      'age choices four to nine wrap on a narrow screen at $scale text',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 640);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final chosen = <int>[];
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AgeSelector(
                    selectedAge: null,
                    onAgeSelected: chosen.add,
                  ),
                ),
              ),
            ),
          ),
        );
        for (var age = 4; age <= 9; age++) {
          final choice = find.text('$age');
          expect(choice, findsOneWidget);
          await tester.ensureVisible(choice);
          await tester.tap(choice);
        }
        expect(chosen, [4, 5, 6, 7, 8, 9]);
        expect(find.text('10'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
