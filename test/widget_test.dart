// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:math_blocks_complete_app/main.dart';

void main() {
  testWidgets('Math Blocks app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MathBlocksCompleteApp()));

    // Wait for the app to load
    await tester.pumpAndSettle();

    // Verify that the app starts with profile creation
    expect(find.text('Welcome to Math Blocks!'), findsOneWidget);
  });
}
