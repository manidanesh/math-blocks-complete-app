// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:number_bond_math/main.dart';

void main() {
    testWidgets('Number Bond Challenge app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MathBlocksCompleteApp()));

    // Wait for the app to load
    await tester.pumpAndSettle();

    // Verify that the app starts with profile creation screen
    expect(find.text('Create Profile'), findsOneWidget);
    
    // Verify that the name input field is present
    expect(find.byType(TextField), findsOneWidget);
    
    // Verify that the create button is present
    expect(find.text('Create Profile'), findsOneWidget);
  });
}
