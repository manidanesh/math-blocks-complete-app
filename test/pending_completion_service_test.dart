import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:number_bond_math/services/pending_completion_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'pending journals are isolated by child and older cleanup preserves newer events',
    () async {
      await PendingCompletionService.save('child', {
        'childId': 'child',
        'eventId': 'first',
        'timeTaken': 12.5,
      });
      await PendingCompletionService.save('other', {
        'childId': 'other',
        'eventId': 'other-first',
      });
      await PendingCompletionService.save('child', {
        'childId': 'child',
        'eventId': 'second',
        'timeTaken': 7.25,
      });
      await PendingCompletionService.clear('child', eventId: 'first');
      expect(
        (await PendingCompletionService.load('child'))!['eventId'],
        'second',
      );
      await PendingCompletionService.clear('child', eventId: 'second');
      expect(await PendingCompletionService.load('child'), isNull);
      expect(
        (await PendingCompletionService.load('other'))!['eventId'],
        'other-first',
      );
    },
  );

  test(
    'a mismatched saved identity remains intact until explicit progress reset',
    () async {
      final raw = jsonEncode({'childId': 'other', 'eventId': 'other-event'});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_challenge_completion_child', raw);
      await expectLater(
        PendingCompletionService.load('child'),
        throwsFormatException,
      );
      await expectLater(
        PendingCompletionService.clear('child', eventId: 'other-event'),
        throwsFormatException,
      );
      expect(prefs.getString('pending_challenge_completion_child'), raw);
      await PendingCompletionService.clear('child');
      expect(await PendingCompletionService.load('child'), isNull);
    },
  );

  test(
    'reset drains an active completion, cancels older queued work and permits new work',
    () async {
      final gate = Completer<void>();
      final started = Completer<void>();
      final order = <String>[];
      final active = PendingCompletionService.runCompletion('child', () async {
        order.add('active');
        started.complete();
        await gate.future;
        order.add('completed');
      });
      await started.future;
      final older = PendingCompletionService.runCompletion('child', () async {
        order.add('older');
      });
      final reset = PendingCompletionService.runReset('child', () async {
        order.add('reset');
      });
      final newer = PendingCompletionService.runCompletion('child', () async {
        order.add('newer');
      });
      expect(
        await PendingCompletionService.runCompletion('other', () async {}),
        isTrue,
      );
      expect(order, ['active']);
      gate.complete();
      expect(await active, isTrue);
      expect(await older, isFalse);
      await reset;
      expect(await newer, isTrue);
      expect(order, ['active', 'completed', 'reset', 'newer']);
    },
  );

  test(
    'recovery loaded while reset is queued cannot recreate its cleared journal',
    () async {
      await PendingCompletionService.save('child', {
        'childId': 'child',
        'eventId': 'old-event',
      });
      final gate = Completer<void>();
      final started = Completer<void>();
      final active = PendingCompletionService.runCompletion('child', () async {
        started.complete();
        await gate.future;
      });
      await started.future;
      final reset = PendingCompletionService.runReset(
        'child',
        () => PendingCompletionService.clear('child'),
      );
      final readDuringReset = await PendingCompletionService.load('child');
      expect(readDuringReset!['eventId'], 'old-event');
      var restored = false;
      final recovered = PendingCompletionService.runCompletion(
        'child',
        () async {
          restored = true;
          await PendingCompletionService.save('child', readDuringReset);
        },
        expectedEventId: 'old-event',
      );
      gate.complete();
      await active;
      await reset;
      expect(await recovered, isFalse);
      expect(restored, isFalse);
      expect(await PendingCompletionService.load('child'), isNull);
    },
  );
}
