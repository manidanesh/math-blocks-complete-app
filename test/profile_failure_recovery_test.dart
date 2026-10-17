import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:number_bond_math/models/kid_profile.dart';
import 'package:number_bond_math/models/problem_attempt.dart';
import 'package:number_bond_math/providers/profile_provider.dart';
import 'package:number_bond_math/screens/profile_screen.dart';
import 'package:number_bond_math/widgets/favorite_numbers_selector.dart';
import 'package:number_bond_math/widgets/language_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _channel = MethodChannel('plugins.flutter.io/shared_preferences');

/// A real plugin-channel store that can reject writes without mutating disk.
class _Preferences {
  final Map<String, Object> data;
  final Set<String> failWrites = {};
  final Set<String> failRemoves = {};
  bool throwWrites = false;
  Completer<void>? writeGate;
  Completer<void>? readGate;

  _Preferences(Map<String, Object> initial)
    : data = {
        for (final entry in initial.entries)
          'flutter.${entry.key}': entry.value,
      };

  Future<Object?> handle(MethodCall call) async {
    if (call.method == 'getAll') {
      await readGate?.future;
      return Map<String, Object>.from(data);
    }
    final arguments = call.arguments as Map<Object?, Object?>;
    final key = arguments['key']! as String;
    if (call.method == 'remove') {
      if (failRemoves.contains(key.substring(8))) return false;
      data.remove(key);
      return true;
    }
    if (call.method.startsWith('set')) {
      await writeGate?.future;
      if (throwWrites) throw PlatformException(code: 'save_failed');
      if (failWrites.contains(key.substring(8))) return false;
      final value = arguments['value']!;
      data[key] = value is List ? value.cast<String>().toList() : value;
      return true;
    }
    throw StateError('Unexpected preference method: ${call.method}');
  }

  Map<String, Object> get saved => {
    for (final entry in data.entries) entry.key.substring(8): entry.value,
  };
}

KidProfile _profile({String language = 'en', int total = 2}) => KidProfile(
  id: 'child-1',
  name: 'Maya',
  birthYear: 2019,
  avatarId: 'default',
  language: language,
  isCurrent: true,
  createdAt: DateTime(2024, 9, 1),
  lastPlayed: DateTime(2026, 9, 1),
  totalStars: total == 2 ? 1 : 200,
  totalProblemsCompleted: total,
  overallAccuracy: total == 2 ? 0.5 : 0.8,
  favoriteNumbers: const [3, 8],
  preferredOperation: 'subtraction',
);

ProblemAttempt _attempt(String childId, int index) => ProblemAttempt(
  id: '$childId-attempt-$index',
  childId: childId,
  problemText: '29 - 15 = ?',
  operand1: 29,
  operand2: 15,
  operator: '-',
  correctAnswer: 14,
  isCorrect: index.isEven,
  timestamp: DateTime(2026, 9, 1, index % 24),
  attemptNumber: 1,
  timeSpentSeconds: 12,
  strategy: 'crossing',
  difficultyLevel: 2,
  skillArea: 'subtraction',
  usedHint: false,
);

Map<String, Object> _initial(KidProfile profile) => {
  'current_profile': jsonEncode(profile.toJson()),
  'problem_attempts': jsonEncode([
    _attempt(profile.id, 0).toJson(),
    _attempt('other-child', 1).toJson(),
  ]),
  'insights_problem_logs': [
    jsonEncode({'childId': profile.id, 'id': 'own-log'}),
    jsonEncode({'childId': 'other-child', 'id': 'other-log'}),
  ],
  'adaptive_challenge_results_${profile.id}': '[]',
  'challenge_count_${profile.id}': 8,
  'insights_generated_${profile.id}': <String>[],
  'insights_analysis_${profile.id}': '{}',
  'insights_problem_count_${profile.id}': 20,
  'insights_last_analysis_count_${profile.id}': 20,
  'rewards_${profile.id}': jsonEncode({
    'childId': profile.id,
    'totalStars': profile.totalStars,
    'totalBadges': 0,
    'totalStickers': 0,
    'currentLevel': 'Ones Explorer',
    'recentRewards': [],
    'badges': [],
    'stickers': [],
    'lastUpdated': '2026-10-10T00:00:00.000',
  }),
  'badges_${profile.id}': '[]',
  'stickers_${profile.id}': '[]',
  'challenge_count_other-child': 17,
  'rewards_other-child': 'preserve-other-rewards',
  'custom_setting': 'keep me',
};

Future<({_Preferences store, ProviderContainer container})> _load({
  KidProfile? profile,
  Map<String, Object>? initial,
}) async {
  final store = _Preferences(initial ?? _initial(profile ?? _profile()));
  SharedPreferences.resetStatic();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, store.handle);
  final container = ProviderContainer(
    overrides: [
      profileNowProvider.overrideWithValue(() => DateTime(2026, 10, 10)),
    ],
  );
  addTearDown(container.dispose);
  await container.read(profileProvider.future);
  return (store: store, container: container);
}

Future<void> _showProfile(
  WidgetTester tester,
  ProviderContainer container, {
  bool show = true,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: show
            ? const ProfileScreen()
            : const Scaffold(body: Text('Profile closed')),
      ),
    ),
  );
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pump();
}

Future<void> _editFavorites(WidgetTester tester) async {
  await _tap(tester, find.text('Edit'));
  final selector = find.byType(FavoriteNumbersSelector);
  await tester.ensureVisible(selector);
  await tester.pumpAndSettle();
  expect(tester.widget<FavoriteNumbersSelector>(selector).initialFavorites, [
    3,
    8,
  ]);
  await _tap(
    tester,
    find
        .ancestor(
          of: find.descendant(of: selector, matching: find.text('3')),
          matching: find.byType(GestureDetector),
        )
        .first,
  );
  expect(tester.widget<FavoriteNumbersSelector>(selector).initialFavorites, [
    8,
  ]);
}

Future<void> _confirmReset(WidgetTester tester) async {
  await _tap(tester, find.text('Reset Progress'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('profile-reset-confirm')));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
    SharedPreferences.resetStatic();
  });

  for (final language in ['en', 'fr']) {
    testWidgets(
      'unreadable rewards preserve $language profile preferences and editing',
      (tester) async {
        final profile = _profile(language: language);
        const unreadableRewards = '{invalid rewards';
        final initial = _initial(profile)
          ..['rewards_child-1'] = unreadableRewards;
        final env = await _load(initial: initial);
        await _showProfile(tester, env.container);
        await tester.pumpAndSettle();

        expect(
          tester
              .widget<LanguageSelector>(find.byType(LanguageSelector))
              .selectedLanguageCode,
          language,
        );
        await _tap(tester, find.text(language == 'fr' ? 'Modifier' : 'Edit'));
        final selector = tester.widget<FavoriteNumbersSelector>(
          find.byType(FavoriteNumbersSelector),
        );
        expect(selector.initialFavorites, [3, 8]);
        expect(selector.language, language);

        // Saving without changing any selection must preserve the saved values.
        await _tap(
          tester,
          find.byKey(const ValueKey('profile-favorites-save')),
        );
        await tester.pumpAndSettle();
        final saved = KidProfile.fromJson(
          jsonDecode(env.store.saved['current_profile']! as String)
              as Map<String, dynamic>,
        );
        expect(saved.favoriteNumbers, [3, 8]);
        expect(saved.language, language);
        expect(saved.preferredOperation, 'subtraction');
        expect(env.store.saved['rewards_child-1'], unreadableRewards);
        expect(find.byType(FavoriteNumbersSelector), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  test(
    'unreadable saved profile reports an error and preserves its bytes',
    () async {
      final raw = '{unreadable profile';
      final store = _Preferences({'current_profile': raw});
      SharedPreferences.resetStatic();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, store.handle);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await expectLater(
        container.read(profileProvider.future),
        throwsFormatException,
      );
      expect(container.read(profileProvider).hasError, isTrue);
      expect(store.saved['current_profile'], raw);
      store.data['flutter.current_profile'] = jsonEncode(_profile().toJson());
      await (await SharedPreferences.getInstance()).reload();
      container.invalidate(profileProvider);
      final recovered = (await container.read(profileProvider.future))!;
      expect(recovered.id, 'child-1');
      expect(recovered.birthYear, 2019);
    },
  );

  for (final throws in [false, true]) {
    test(
      'a ${throws ? 'throwing' : 'rejected'} edit keeps the usable profile',
      () async {
        final env = await _load();
        final before = env.container.read(profileProvider).requireValue!;
        final savedBefore = Map<String, Object>.from(env.store.saved);
        env.store.failWrites.add('current_profile');
        env.store.throwWrites = throws;
        await expectLater(
          env.container
              .read(profileProvider.notifier)
              .updateProfile(
                before.copyWith(language: 'fr', favoriteNumbers: [1]),
              ),
          throwsA(anyOf(isA<StateError>(), isA<PlatformException>())),
        );
        expect(env.container.read(profileProvider).hasError, isFalse);
        expect(env.container.read(profileProvider).requireValue, same(before));
        expect(env.store.saved, savedBefore);
        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString('current_profile'),
          savedBefore['current_profile'],
        );
      },
    );
  }

  test(
    'invalid birth year leaves the saved and active profile intact',
    () async {
      final env = await _load();
      final before = env.container.read(profileProvider).requireValue!;
      await expectLater(
        env.container
            .read(profileProvider.notifier)
            .updateProfile(before.copyWith(birthYear: 2030)),
        throwsArgumentError,
      );
      expect(env.container.read(profileProvider).requireValue, same(before));
      expect(env.container.read(profileProvider).hasError, isFalse);
    },
  );

  test('rejected profile clearing preserves its data and cache', () async {
    final env = await _load();
    final before = env.container.read(profileProvider).requireValue!;
    env.store.failRemoves.add('current_profile');
    await expectLater(
      env.container.read(profileProvider.notifier).clearProfile(),
      throwsStateError,
    );
    expect(env.container.read(profileProvider).requireValue, same(before));
    expect(
      (await SharedPreferences.getInstance()).getString('current_profile'),
      env.store.saved['current_profile'],
    );
  });

  test('a reset profile-write failure deletes no history', () async {
    final env = await _load();
    final before = Map<String, Object>.from(env.store.saved);
    env.store.failWrites.add('current_profile');
    await expectLater(
      env.container.read(profileProvider.notifier).resetProgress(),
      throwsStateError,
    );
    expect(env.store.saved, before);
    expect(env.container.read(profileProvider).requireValue!.totalStars, 1);
    expect(env.container.read(profileProvider).hasError, isFalse);
  });

  test('a later reset failure restores removed child data', () async {
    final env = await _load();
    final before = Map<String, Object>.from(env.store.saved);
    env.store.failRemoves.add('rewards_child-1');
    await expectLater(
      env.container.read(profileProvider.notifier).resetProgress(),
      throwsStateError,
    );
    expect(env.store.saved, before);
    expect(env.container.read(profileProvider).requireValue!.totalStars, 1);
    expect(env.container.read(profileProvider).hasError, isFalse);
  });

  test(
    'successful reset clears only this child and keeps profile preferences',
    () async {
      final env = await _load();
      await env.container.read(profileProvider.notifier).resetProgress();
      final profile = env.container.read(profileProvider).requireValue!;
      expect(profile.birthYear, 2019);
      expect(profile.language, 'en');
      expect(profile.favoriteNumbers, [3, 8]);
      expect(profile.preferredOperation, 'subtraction');
      expect(profile.totalProblemsCompleted, 0);
      expect(profile.totalStars, 0);
      final attempts =
          jsonDecode(env.store.saved['problem_attempts']! as String)
              as List<dynamic>;
      expect(attempts.map((entry) => entry['childId']), ['other-child']);
      final logs = env.store.saved['insights_problem_logs']! as List<String>;
      expect(logs.map((entry) => jsonDecode(entry)['childId']), [
        'other-child',
      ]);
      expect(env.store.saved['challenge_count_child-1'], isNull);
      expect(env.store.saved['insights_problem_count_child-1'], isNull);
      expect(env.store.saved['insights_last_analysis_count_child-1'], isNull);
      expect(env.store.saved['rewards_child-1'], isNull);
      expect(env.store.saved['challenge_count_other-child'], 17);
      expect(env.store.saved['rewards_other-child'], 'preserve-other-rewards');
      expect(env.store.saved['custom_setting'], 'keep me');
    },
  );

  test(
    'lifetime outcomes beyond 100 use prior totals and ignore another child',
    () async {
      final env = await _load(profile: _profile(total: 250));
      final notifier = env.container.read(profileProvider.notifier);
      await notifier.recordChallengeOutcome(
        childId: 'child-1',
        correct: true,
        stars: 1,
      );
      await notifier.recordChallengeOutcome(childId: 'child-1', correct: false);
      await notifier.recordChallengeOutcome(
        childId: 'other-child',
        correct: true,
        stars: 5,
      );
      final profile = env.container.read(profileProvider).requireValue!;
      expect(profile.totalProblemsCompleted, 252);
      expect(profile.totalStars, 201);
      expect(profile.overallAccuracy, closeTo(201 / 252, 0.000001));
      expect(profile.birthYear, 2019);
      expect(profile.favoriteNumbers, [3, 8]);
    },
  );

  testWidgets(
    'opening profile never reduces lifetime totals to recent history',
    (tester) async {
      final profile = _profile(total: 250);
      final env = await _load(profile: profile);
      final before = env.store.saved['current_profile'];
      await _showProfile(tester, env.container);
      await tester.pumpAndSettle();
      expect(env.store.saved['current_profile'], before);
      expect(
        env.container
            .read(profileProvider)
            .requireValue!
            .totalProblemsCompleted,
        250,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed favorite save keeps editor and permits a successful retry',
    (tester) async {
      final env = await _load();
      await _showProfile(tester, env.container);
      await tester.pumpAndSettle();
      await _editFavorites(tester);
      env.store.failWrites.add('current_profile');
      await _tap(tester, find.byKey(const ValueKey('profile-favorites-save')));
      await tester.pumpAndSettle();
      expect(
        find.text('Could not update favorite numbers. Please try again.'),
        findsOneWidget,
      );
      expect(find.byType(FavoriteNumbersSelector), findsOneWidget);
      expect(
        env.container.read(profileProvider).requireValue!.favoriteNumbers,
        [3, 8],
      );
      env.store.failWrites.clear();
      await _tap(tester, find.byKey(const ValueKey('profile-favorites-save')));
      await tester.pumpAndSettle();
      expect(find.text('Favorite numbers updated.'), findsOneWidget);
      expect(
        env.container.read(profileProvider).requireValue!.favoriteNumbers,
        [8],
      );
      expect(env.container.read(profileProvider).requireValue!.birthYear, 2019);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed language save keeps original language and is retryable', (
    tester,
  ) async {
    final env = await _load();
    await _showProfile(tester, env.container);
    await tester.pumpAndSettle();
    final spanish = find.descendant(
      of: find.byType(LanguageSelector),
      matching: find.text('Español'),
    );
    env.store.failWrites.add('current_profile');
    await _tap(tester, spanish);
    await tester.pumpAndSettle();
    expect(
      find.text('Could not update language. Please try again.'),
      findsOneWidget,
    );
    expect(env.container.read(profileProvider).requireValue!.language, 'en');
    env.store.failWrites.clear();
    await _tap(tester, spanish);
    await tester.pumpAndSettle();
    expect(find.text('Idioma actualizado.'), findsOneWidget);
    final profile = env.container.read(profileProvider).requireValue!;
    expect(profile.language, 'es');
    expect(profile.birthYear, 2019);
    expect(profile.favoriteNumbers, [3, 8]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failed birth-year save retains the selected year and can retry',
    (tester) async {
      final env = await _load();
      await _showProfile(tester, env.container);
      await tester.pumpAndSettle();
      final dropdown = find.byKey(const ValueKey('birth-year-dropdown'));
      Future<void> selectYear() async {
        await _tap(tester, dropdown);
        await tester.pumpAndSettle();
        await _tap(tester, find.text('2018').last);
        await tester.pumpAndSettle();
      }

      env.store.failWrites.add('current_profile');
      await selectYear();
      expect(
        find.text('Could not update birth year. Please try again.'),
        findsOneWidget,
      );
      expect(tester.widget<DropdownButton<int>>(dropdown).value, 2019);
      expect(env.container.read(profileProvider).requireValue!.birthYear, 2019);
      env.store.failWrites.clear();
      await selectYear();
      expect(find.text('Birth year updated.'), findsOneWidget);
      expect(env.container.read(profileProvider).requireValue!.birthYear, 2018);
      expect(
        env.container.read(profileProvider).requireValue!.favoriteNumbers,
        [3, 8],
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('favorite editor and reset dialog fit a narrow French page', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final env = await _load(profile: _profile(language: 'fr'));
    await _showProfile(tester, env.container, textScale: 1.5);
    await tester.pumpAndSettle();
    expect(find.text('Modifier'), findsOneWidget);
    await _tap(tester, find.text('Modifier'));
    expect(
      tester
          .widget<FavoriteNumbersSelector>(find.byType(FavoriteNumbersSelector))
          .language,
      'fr',
    );
    await _tap(tester, find.byKey(const ValueKey('profile-favorites-cancel')));
    await _tap(tester, find.text('Réinitialiser le Progrès'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('profile-reset-confirmation')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.widgetWithText(TextButton, 'Annuler'));
    await tester.pumpAndSettle();
    expect(env.container.read(profileProvider).requireValue!.totalStars, 1);
  });

  testWidgets('failed reset reports failure and leaves profile usable', (
    tester,
  ) async {
    final env = await _load();
    await _showProfile(tester, env.container);
    await tester.pumpAndSettle();
    env.store.failWrites.add('current_profile');
    await _confirmReset(tester);
    await tester.pumpAndSettle();
    expect(
      find.text('Could not reset progress. Please try again.'),
      findsOneWidget,
    );
    expect(
      find.text('✅ Progress reset successfully! Starting fresh!'),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('profile-reset-progress')), findsNothing);
    expect(env.container.read(profileProvider).requireValue!.totalStars, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving during profile loading never updates disposed state', (
    tester,
  ) async {
    final env = await _load();
    env.store.readGate = Completer<void>();
    SharedPreferences.resetStatic();
    await _showProfile(tester, env.container);
    await _showProfile(tester, env.container, show: false);
    env.store.readGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Profile closed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'leaving during favorite save allows persistence without UI work',
    (tester) async {
      final env = await _load();
      await _showProfile(tester, env.container);
      await tester.pumpAndSettle();
      await _editFavorites(tester);
      env.store.writeGate = Completer<void>();
      await _tap(tester, find.byKey(const ValueKey('profile-favorites-save')));
      await _showProfile(tester, env.container, show: false);
      env.store.writeGate!.complete();
      await tester.pumpAndSettle();
      expect(
        env.container.read(profileProvider).requireValue!.favoriteNumbers,
        [8],
      );
      expect(find.text('Profile closed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('leaving during reset safely closes only its progress dialog', (
    tester,
  ) async {
    final env = await _load();
    await _showProfile(tester, env.container);
    await tester.pumpAndSettle();
    env.store.writeGate = Completer<void>();
    await _confirmReset(tester);
    await _showProfile(tester, env.container, show: false);
    env.store.writeGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Profile closed'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-reset-progress')), findsNothing);
    expect(env.container.read(profileProvider).requireValue!.totalStars, 0);
    expect(tester.takeException(), isNull);
  });
}
