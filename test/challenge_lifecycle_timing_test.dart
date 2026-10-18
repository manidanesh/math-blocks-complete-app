import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:number_bond_math/models/kid_profile.dart';
import 'package:number_bond_math/providers/profile_provider.dart';
import 'package:number_bond_math/screens/adaptive_challenge_screen.dart';
import 'package:number_bond_math/services/problem_attempt_service.dart';
import 'package:number_bond_math/services/problem_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _channel = MethodChannel('plugins.flutter.io/shared_preferences');

class _Preferences {
  final Map<String, Object> disk;
  final readStarted = Completer<void>();
  Completer<void>? readGate;
  Stopwatch? foreground;
  double? foregroundAtJournalWrite;

  _Preferences(KidProfile profile)
    : disk = {'flutter.current_profile': jsonEncode(profile.toJson())};

  Future<Object?> handle(MethodCall call) async {
    if (call.method == 'getAll') {
      if (!readStarted.isCompleted) readStarted.complete();
      await readGate?.future;
      return Map<String, Object>.from(disk);
    }
    final args = call.arguments as Map<Object?, Object?>;
    final key = args['key'] as String;
    if (call.method == 'remove') {
      disk.remove(key);
      return true;
    }
    if (call.method.startsWith('set')) {
      if (key == 'flutter.pending_challenge_completion_child') {
        foregroundAtJournalWrite =
            foreground!.elapsedMicroseconds / Duration.microsecondsPerSecond;
      }
      final value = args['value']!;
      disk[key] = value is List ? value.cast<String>().toList() : value;
      return true;
    }
    throw StateError('Unexpected preference method: ${call.method}');
  }
}

Future<void> _tapNumber(WidgetTester tester, int number) async {
  final choice = find.byKey(ValueKey('bond-number-$number'));
  await tester.ensureVisible(choice);
  await tester.pumpAndSettle();
  await tester.tap(choice);
  await tester.pump();
}

void main() {
  for (final initiallyPaused in [false, true]) {
    testWidgets(
      initiallyPaused
          ? 'a challenge mounted while paused waits for resume before timing'
          : 'challenge loading completed while paused excludes background time',
      (tester) async {
        final profile = KidProfile(
          id: 'child',
          name: 'Maya',
          age: 7,
          avatarId: 'default',
          language: 'en',
          isCurrent: true,
          createdAt: DateTime(2026),
          lastPlayed: DateTime(2026),
        );
        final store = _Preferences(profile);
        SharedPreferences.resetStatic();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_channel, store.handle);
        final container = ProviderContainer();
        addTearDown(() {
          container.dispose();
          SharedPreferences.resetStatic();
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(_channel, null);
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
        });
        if (initiallyPaused) {
          await container.read(profileProvider.future);
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
        } else {
          store.readGate = Completer<void>();
        }
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: AdaptiveChallengeScreen(
                initialProblem: MathProblem(
                  operand1: 4,
                  operand2: 14,
                  operator: '+',
                  correctAnswer: 18,
                  problemText: '4 + 14',
                  options: const [],
                  strategy: ProblemStrategy.crossing,
                  level: 1,
                  explanation: '',
                ),
              ),
            ),
          ),
        );
        if (initiallyPaused) {
          // Paused apps do not schedule ordinary rendering frames.
          tester.binding.scheduleForcedFrame();
          await tester.pump();
        } else {
          await store.readStarted.future;
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
          store.readGate!.complete();
          await container.read(profileProvider.future);
        }
        await tester.pump();
        await tester.pump();
        // Stopwatch uses wall time rather than Flutter's fake frame clock.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 450)),
        );
        store.foreground = Stopwatch()..start();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        final activeWait = Stopwatch()..start();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        activeWait.stop();
        await _tapNumber(tester, 10);
        await _tapNumber(tester, 4);
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();
        final attempt = (await ProblemAttemptService.getAttemptsForChild(
          'child',
        )).single;
        // Compare nested clock intervals, avoiding a machine-speed threshold:
        // timing must include the active wait and fit within the foreground.
        expect(
          attempt.timeSpentSeconds,
          greaterThanOrEqualTo(
            activeWait.elapsedMicroseconds / Duration.microsecondsPerSecond,
          ),
        );
        expect(store.foregroundAtJournalWrite, isNotNull);
        expect(
          attempt.timeSpentSeconds,
          lessThanOrEqualTo(store.foregroundAtJournalWrite!),
        );
        expect(attempt.isCorrect, isTrue);
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
