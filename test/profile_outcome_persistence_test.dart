import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:number_bond_math/models/kid_profile.dart';
import 'package:number_bond_math/providers/profile_provider.dart';
import 'package:number_bond_math/services/pending_completion_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _channel = MethodChannel('plugins.flutter.io/shared_preferences');

class _Preferences {
  final Map<String, Object> disk;
  final firstProfileWrite = Completer<void>();
  Completer<void>? profileWriteGate;
  int profileWrites = 0;
  bool rejectNextProfileWrite = false;
  bool throwNextProfileWrite = false;
  final Set<String> rejectedRemoves = {};

  _Preferences(KidProfile profile)
    : disk = {'flutter.current_profile': jsonEncode(profile.toJson())};

  Future<Object?> handle(MethodCall call) async {
    if (call.method == 'getAll') return Map<String, Object>.from(disk);
    final args = call.arguments as Map<Object?, Object?>;
    final key = args['key'] as String;
    if (call.method == 'remove') {
      if (rejectedRemoves.contains(key)) return false;
      disk.remove(key);
      return true;
    }
    if (call.method.startsWith('set')) {
      if (key == 'flutter.current_profile') {
        profileWrites++;
        if (!firstProfileWrite.isCompleted) firstProfileWrite.complete();
        await profileWriteGate?.future;
        if (throwNextProfileWrite) {
          throwNextProfileWrite = false;
          throw PlatformException(code: 'write_failed');
        }
        if (rejectNextProfileWrite) {
          rejectNextProfileWrite = false;
          return false;
        }
      }
      final value = args['value']!;
      disk[key] = value is List ? value.cast<String>().toList() : value;
      return true;
    }
    throw StateError('Unexpected preference method: ${call.method}');
  }

  Map<String, dynamic> get savedProfile =>
      jsonDecode(disk['flutter.current_profile']! as String)
          as Map<String, dynamic>;
}

KidProfile _profile({String id = 'child'}) => KidProfile(
  id: id,
  name: 'Maya',
  birthYear: 2019,
  now: () => DateTime(2026, 10, 10),
  avatarId: 'default',
  language: 'en',
  isCurrent: true,
  createdAt: DateTime(2026),
  lastPlayed: DateTime(2026),
);

ProviderContainer _container({DateTime Function()? clock}) {
  final container = ProviderContainer(
    overrides: [
      profileNowProvider.overrideWithValue(
        clock ?? () => DateTime(2026, 10, 10),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Preferences store;
  late ProviderContainer container;
  late ProfileNotifier notifier;

  setUp(() async {
    SharedPreferences.resetStatic();
    store = _Preferences(_profile());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, store.handle);
    container = _container();
    await container.read(profileProvider.future);
    notifier = container.read(profileProvider.notifier);
  });

  tearDown(() {
    SharedPreferences.resetStatic();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  test(
    'overlapping outcomes retain both completions and their accuracy',
    () async {
      store.profileWriteGate = Completer<void>();
      final first = notifier.recordChallengeOutcome(
        childId: 'child',
        correct: true,
        stars: 1,
        eventId: 'first',
      );
      await store.firstProfileWrite.future;
      final second = notifier.recordChallengeOutcome(
        childId: 'child',
        correct: false,
        eventId: 'second',
      );
      await Future<void>.delayed(Duration.zero);
      expect(store.profileWrites, 1);
      store.profileWriteGate!.complete();
      await Future.wait([first, second]);
      final profile = container.read(profileProvider).requireValue!;
      expect(profile.totalProblemsCompleted, 2);
      expect(profile.totalStars, 1);
      expect(profile.overallAccuracy, 0.5);
      expect(store.savedProfile['totalProblemsCompleted'], 2);
      expect(store.savedProfile['challengeOutcomeReceipts'], [
        'first',
        'second',
      ]);
    },
  );

  test(
    'an edit queued during an outcome save retains its committed totals',
    () async {
      final original = container.read(profileProvider).requireValue!;
      store.profileWriteGate = Completer<void>();
      final outcome = notifier.recordChallengeOutcome(
        childId: 'child',
        correct: true,
        stars: 1,
        eventId: 'first',
      );
      await store.firstProfileWrite.future;
      final edit = notifier.updateProfile(original.copyWith(language: 'fr'));
      store.profileWriteGate!.complete();
      await Future.wait([outcome, edit]);
      final profile = container.read(profileProvider).requireValue!;
      expect(profile.language, 'fr');
      expect(profile.totalProblemsCompleted, 1);
      expect(profile.totalStars, 1);
      expect(profile.overallAccuracy, 1);
      expect(store.savedProfile['challengeOutcomeReceipts'], ['first']);
    },
  );

  test(
    'queued edits preserve unrelated preferences from an earlier save',
    () async {
      final original = container.read(profileProvider).requireValue!;
      store.profileWriteGate = Completer<void>();
      final first = notifier.updateProfile(
        original.copyWith(
          birthYear: 2018,
          language: 'fr',
          favoriteNumbers: [3],
        ),
      );
      await store.firstProfileWrite.future;
      final second = notifier.updateProfile(
        original.copyWith(
          favoriteNumbers: [],
          preferredOperation: 'subtraction',
        ),
      );
      store.profileWriteGate!.complete();
      await Future.wait([first, second]);
      final profile = container.read(profileProvider).requireValue!;
      expect(profile.birthYear, 2018);
      expect(profile.language, 'fr');
      expect(profile.favoriteNumbers, [3]);
      expect(profile.preferredOperation, 'subtraction');
    },
  );

  for (final replace in [false, true]) {
    test(
      'a queued edit cannot restore a ${replace ? 'replaced' : 'cleared'} child',
      () async {
        final original = container.read(profileProvider).requireValue!;
        store.profileWriteGate = Completer<void>();
        final outcome = notifier.recordChallengeOutcome(
          childId: 'child',
          correct: true,
          stars: 1,
          eventId: 'first',
        );
        await store.firstProfileWrite.future;
        final changed = replace
            ? notifier.createProfile(_profile(id: 'other-child'))
            : notifier.clearProfile();
        final staleEdit = expectLater(
          notifier.updateProfile(original.copyWith(language: 'fr')),
          throwsStateError,
        );
        store.profileWriteGate!.complete();
        await Future.wait([outcome, changed, staleEdit]);
        if (replace) {
          expect(
            container.read(profileProvider).requireValue!.id,
            'other-child',
          );
          expect(store.savedProfile['id'], 'other-child');
          expect(store.savedProfile['language'], 'en');
        } else {
          expect(container.read(profileProvider).requireValue, isNull);
          expect(store.disk.containsKey('flutter.current_profile'), isFalse);
        }
      },
    );
  }

  test(
    'a queued age refresh safely stops after the provider is disposed',
    () async {
      store.profileWriteGate = Completer<void>();
      final outcome = notifier.recordChallengeOutcome(
        childId: 'child',
        correct: true,
        stars: 1,
        eventId: 'first',
      );
      await store.firstProfileWrite.future;
      final refresh = notifier.refreshAge();
      container.dispose();
      store.profileWriteGate!.complete();
      await Future.wait([outcome, refresh]);
      expect(store.savedProfile['totalProblemsCompleted'], 1);
      expect(store.savedProfile['lastPlayed'], '2026-10-10T00:00:00.000');
    },
  );

  for (final throwing in [false, true]) {
    test(
      'a ${throwing ? 'throwing' : 'rejected'} age snapshot reloads the cache and remains retryable',
      () async {
        var now = DateTime(2026, 10, 10);
        final active = _container(clock: () => now);
        await active.read(profileProvider.future);
        final activeNotifier = active.read(profileProvider.notifier);
        await activeNotifier.recordChallengeOutcome(
          childId: 'child',
          correct: true,
          stars: 1,
          eventId: 'first',
        );
        now = DateTime(2027, 1, 1);
        store.rejectNextProfileWrite = !throwing;
        store.throwNextProfileWrite = throwing;
        await activeNotifier.refreshAge();
        expect(active.read(profileProvider).requireValue!.age, 8);
        expect(store.savedProfile['age'], 7);
        final prefs = await SharedPreferences.getInstance();
        expect(
          (jsonDecode(prefs.getString('current_profile')!) as Map)['age'],
          7,
        );
        await activeNotifier.refreshAge();
        expect(store.savedProfile['age'], 8);
        expect(store.savedProfile['totalProblemsCompleted'], 1);
        expect(store.savedProfile['challengeOutcomeReceipts'], ['first']);
      },
    );
  }

  test('progress updates and resets use the injected profile clock', () async {
    await notifier.updateProgress(1, 1, 1);
    expect(
      container.read(profileProvider).requireValue!.lastPlayed,
      DateTime(2026, 10, 10),
    );
    await notifier.resetProgress();
    expect(store.savedProfile['lastPlayed'], '2026-10-10T00:00:00.000');
  });

  test(
    'receipts deduplicate concurrent calls and persist through edits and reopening',
    () async {
      Future<void> record(ProfileNotifier active) =>
          active.recordChallengeOutcome(
            childId: 'child',
            correct: true,
            stars: 1,
            eventId: 'first',
          );
      await Future.wait([record(notifier), record(notifier)]);
      await notifier.updateProfile(
        container.read(profileProvider).requireValue!.copyWith(language: 'es'),
      );
      await notifier.refreshAge();
      final reopened = _container();
      await reopened.read(profileProvider.future);
      await record(reopened.read(profileProvider.notifier));
      final profile = reopened.read(profileProvider).requireValue!;
      expect(profile.totalProblemsCompleted, 1);
      expect(profile.totalStars, 1);
      expect(profile.language, 'es');
      expect(store.savedProfile['challengeOutcomeReceipts'], ['first']);
    },
  );

  for (final throwing in [false, true]) {
    test(
      'a ${throwing ? 'throwing' : 'rejected'} outcome does not block queued saves or its retry',
      () async {
        store.profileWriteGate = Completer<void>();
        store.rejectNextProfileWrite = !throwing;
        store.throwNextProfileWrite = throwing;
        final first = notifier.recordChallengeOutcome(
          childId: 'child',
          correct: false,
          eventId: 'first',
        );
        final failure = expectLater(
          first,
          throwing ? throwsA(isA<PlatformException>()) : throwsStateError,
        );
        await store.firstProfileWrite.future;
        final second = notifier.recordChallengeOutcome(
          childId: 'child',
          correct: true,
          stars: 1,
          eventId: 'second',
        );
        store.profileWriteGate!.complete();
        await failure;
        await second;
        expect(
          container.read(profileProvider).requireValue!.totalProblemsCompleted,
          1,
        );
        expect(store.savedProfile['challengeOutcomeReceipts'], ['second']);
        await notifier.recordChallengeOutcome(
          childId: 'child',
          correct: false,
          eventId: 'first',
        );
        final profile = container.read(profileProvider).requireValue!;
        expect(profile.totalProblemsCompleted, 2);
        expect(profile.totalStars, 1);
        expect(profile.overallAccuracy, 0.5);
        expect(store.savedProfile['challengeOutcomeReceipts'], [
          'second',
          'first',
        ]);
      },
    );
  }

  test(
    'reset clears receipts together with totals and permits a fresh outcome',
    () async {
      await notifier.recordChallengeOutcome(
        childId: 'child',
        correct: true,
        stars: 1,
        eventId: 'first',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'pending_challenge_completion_child',
        '{pending result}',
      );
      await notifier.resetProgress();
      expect(prefs.containsKey('pending_challenge_completion_child'), isFalse);
      expect(
        store.disk.containsKey('flutter.pending_challenge_completion_child'),
        isFalse,
      );
      expect(
        store.savedProfile.containsKey('challengeOutcomeReceipts'),
        isFalse,
      );
      expect(
        container.read(profileProvider).requireValue!.totalProblemsCompleted,
        0,
      );
      await notifier.recordChallengeOutcome(
        childId: 'child',
        correct: true,
        stars: 1,
        eventId: 'first',
      );
      expect(
        container.read(profileProvider).requireValue!.totalProblemsCompleted,
        1,
      );
    },
  );

  test(
    'a rejected pending-result removal rolls back profile totals and journal bytes',
    () async {
      await notifier.recordChallengeOutcome(
        childId: 'child',
        correct: true,
        stars: 1,
        eventId: 'first',
      );
      final prefs = await SharedPreferences.getInstance();
      const rawPending = '{pending result bytes}';
      await prefs.setString('pending_challenge_completion_child', rawPending);
      final before = prefs.getString('current_profile');
      store.rejectedRemoves.add('flutter.pending_challenge_completion_child');
      await expectLater(notifier.resetProgress(), throwsStateError);
      expect(prefs.getString('current_profile'), before);
      expect(prefs.getString('pending_challenge_completion_child'), rawPending);
      expect(
        store.disk['flutter.pending_challenge_completion_child'],
        rawPending,
      );
      final profile = container.read(profileProvider).requireValue!;
      expect(profile.totalProblemsCompleted, 1);
      expect(profile.totalStars, 1);
      expect(store.savedProfile['challengeOutcomeReceipts'], ['first']);
    },
  );

  test(
    'a reset waiting for completion cannot reset a replacement child',
    () async {
      final started = Completer<void>();
      final finish = Completer<void>();
      final completion = PendingCompletionService.runCompletion(
        'child',
        () async {
          started.complete();
          await finish.future;
        },
      );
      await started.future;
      final reset = expectLater(notifier.resetProgress(), throwsStateError);
      await notifier.createProfile(
        _profile(id: 'other-child').copyWith(
          totalStars: 5,
          totalProblemsCompleted: 7,
          overallAccuracy: 0.5,
        ),
      );
      finish.complete();
      await completion;
      await reset;
      final profile = container.read(profileProvider).requireValue!;
      expect(profile.id, 'other-child');
      expect(profile.totalStars, 5);
      expect(profile.totalProblemsCompleted, 7);
      expect(profile.overallAccuracy, 0.5);
      expect(store.savedProfile['id'], 'other-child');
    },
  );

  test(
    'queued outcomes ignore another child and receipts do not cross profiles',
    () async {
      store.profileWriteGate = Completer<void>();
      final outcome = notifier.recordChallengeOutcome(
        childId: 'child',
        correct: true,
        stars: 1,
        eventId: 'first',
      );
      await store.firstProfileWrite.future;
      final replacement = notifier.createProfile(_profile(id: 'other-child'));
      final staleOutcome = notifier.recordChallengeOutcome(
        childId: 'child',
        correct: true,
        stars: 1,
        eventId: 'stale',
      );
      final otherOutcome = notifier.recordChallengeOutcome(
        childId: 'other-child',
        correct: true,
        stars: 1,
        eventId: 'first',
      );
      store.profileWriteGate!.complete();
      await Future.wait([outcome, replacement, staleOutcome, otherOutcome]);
      final profile = container.read(profileProvider).requireValue!;
      expect(profile.id, 'other-child');
      expect(profile.totalProblemsCompleted, 1);
      expect(profile.totalStars, 1);
      expect(store.savedProfile['challengeOutcomeReceipts'], ['first']);
    },
  );
}
