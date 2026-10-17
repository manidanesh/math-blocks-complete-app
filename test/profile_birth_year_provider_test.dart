import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:number_bond_math/models/kid_profile.dart';
import 'package:number_bond_math/providers/profile_provider.dart';
import 'package:number_bond_math/widgets/profile_age_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';

KidProfile _profile({int? birthYear, int age = 7}) => KidProfile(
  id: 'child-1',
  name: 'Jamie',
  age: age,
  birthYear: birthYear,
  avatarId: 'default',
  language: 'en',
  isCurrent: true,
  createdAt: DateTime(2020, 6, 10),
  lastPlayed: DateTime(2026, 10, 10),
  totalStars: 10,
  totalProblemsCompleted: 20,
  overallAccuracy: 0.5,
  favoriteNumbers: const [3, 7],
  preferredOperation: 'subtraction',
);

Map<String, dynamic> _legacyJson() => {
  'id': 'child-1',
  'name': 'Jamie',
  'age': 4,
  'avatarId': 'default',
  'language': 'en',
  'isCurrent': true,
  'createdAt': '2020-06-10T00:00:00.000',
  'lastPlayed': '2026-10-10T00:00:00.000',
  'totalStars': 10,
  'totalProblemsCompleted': 20,
  'overallAccuracy': 0.5,
  'favoriteNumbers': [3, 7],
  'preferredOperation': 'subtraction',
};

Future<Map<String, dynamic>> _savedProfile() async {
  final prefs = await SharedPreferences.getInstance();
  return jsonDecode(prefs.getString('current_profile')!)
      as Map<String, dynamic>;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 10, 10);
    container = ProviderContainer(
      overrides: [profileNowProvider.overrideWithValue(() => now)],
    );
  });

  tearDown(() => container.dispose());

  test(
    'stores birth year and current derived age with profile statistics',
    () async {
      await container.read(profileProvider.future);
      await container
          .read(profileProvider.notifier)
          .createProfile(_profile(birthYear: 2019, age: 99));

      final profile = container.read(profileProvider).requireValue!;
      expect(profile.birthYear, 2019);
      expect(profile.age, 7);
      final saved = await _savedProfile();
      expect(saved['birthYear'], 2019);
      expect(saved['age'], 7);
      expect(saved['totalStars'], 10);
      expect(saved['totalProblemsCompleted'], 20);
      expect(saved['favoriteNumbers'], [3, 7]);
      expect(saved['name'], 'Jamie');
    },
  );

  test(
    'reopening years later recalculates age without a child age cap',
    () async {
      await container.read(profileProvider.future);
      await container
          .read(profileProvider.notifier)
          .createProfile(_profile(birthYear: 2019));
      final savedBefore = await _savedProfile();
      expect(savedBefore['age'], 7);

      // A new provider container represents reopening the app with the same data.
      final reopened = ProviderContainer(
        overrides: [
          profileNowProvider.overrideWithValue(() => DateTime(2040, 1, 2)),
        ],
      );
      addTearDown(reopened.dispose);
      final profile = (await reopened.read(profileProvider.future))!;
      expect(profile.birthYear, 2019);
      expect(profile.age, 21);
      expect(profile.totalStars, 10);
      expect(profile.totalProblemsCompleted, 20);
      expect(profile.favoriteNumbers, [3, 7]);
      expect(profile.id, 'child-1');
      expect((await _savedProfile())['age'], 21);
    },
  );

  test(
    'startup and age refresh preserve additional saved profile fields',
    () async {
      SharedPreferences.setMockInitialValues({
        'current_profile': jsonEncode({
          ..._legacyJson(),
          'age': 6,
          'birthYear': 2019,
          'customMetadata': {'note': 'preserve me'},
        }),
      });
      final loaded = (await container.read(profileProvider.future))!;
      expect(loaded.age, 7);
      expect((await _savedProfile())['customMetadata'], {
        'note': 'preserve me',
      });

      now = DateTime(2027, 1, 1);
      await container.read(profileProvider.notifier).refreshAge();
      final refreshed = await _savedProfile();
      expect(refreshed['age'], 8);
      expect(refreshed['customMetadata'], {'note': 'preserve me'});
      expect(refreshed['totalStars'], 10);
      expect(refreshed['totalProblemsCompleted'], 20);
    },
  );

  test('legacy saved age remains until the birth year is confirmed', () async {
    SharedPreferences.setMockInitialValues({
      'current_profile': jsonEncode(_legacyJson()),
    });
    final legacy = (await container.read(profileProvider.future))!;
    expect(legacy.age, 4);
    expect(legacy.birthYear, isNull);

    now = DateTime(2040, 1, 2);
    await container.read(profileProvider.notifier).refreshAge();
    final later = container.read(profileProvider).requireValue!;
    expect(later.age, 4);
    expect(later.birthYear, isNull);
    final untouched = await _savedProfile();
    expect(untouched['age'], 4);
    expect(untouched['birthYear'], isNull);
    expect(untouched['createdAt'], _legacyJson()['createdAt']);

    now = DateTime(2026, 10, 10);
    await container
        .read(profileProvider.notifier)
        .updateProfile(later.copyWith(birthYear: 2016));
    final migrated = container.read(profileProvider).requireValue!;
    expect(migrated.age, 10);
    expect(migrated.birthYear, 2016);
    expect(migrated.id, legacy.id);
    expect(migrated.totalStars, legacy.totalStars);
    expect(migrated.totalProblemsCompleted, legacy.totalProblemsCompleted);
    expect(migrated.overallAccuracy, legacy.overallAccuracy);
    expect(migrated.favoriteNumbers, legacy.favoriteNumbers);
    expect((await _savedProfile())['birthYear'], 2016);
  });

  test('profile edits and progress updates retain birth year', () async {
    await container.read(profileProvider.future);
    await container
        .read(profileProvider.notifier)
        .createProfile(_profile(birthYear: 2019));
    final notifier = container.read(profileProvider.notifier);
    final current = container.read(profileProvider).requireValue!;
    await notifier.updateProfile(
      current.copyWith(language: 'fr', favoriteNumbers: [4, 8]),
    );
    await notifier.updateProgress(2, 3, 0.75);

    final updated = container.read(profileProvider).requireValue!;
    expect(updated.birthYear, 2019);
    expect(updated.age, 7);
    expect(updated.language, 'fr');
    expect(updated.favoriteNumbers, [4, 8]);
    expect(updated.totalStars, 12);
    expect(updated.totalProblemsCompleted, 23);
    expect(updated.overallAccuracy, 0.75);
    final saved = await _savedProfile();
    expect(saved['birthYear'], 2019);
    expect(saved['totalStars'], 12);
    expect(saved['totalProblemsCompleted'], 23);
  });

  test(
    'resetting progress retains birth year and all profile preferences',
    () async {
      await container.read(profileProvider.future);
      await container
          .read(profileProvider.notifier)
          .createProfile(_profile(birthYear: 2019));
      await container.read(profileProvider.notifier).resetProgress();

      final reset = container.read(profileProvider).requireValue!;
      expect(reset.birthYear, 2019);
      expect(reset.age, 7);
      expect(reset.id, 'child-1');
      expect(reset.name, 'Jamie');
      expect(reset.language, 'en');
      expect(reset.favoriteNumbers, [3, 7]);
      expect(reset.preferredOperation, 'subtraction');
      expect(reset.totalStars, 0);
      expect(reset.totalProblemsCompleted, 0);
      expect(reset.overallAccuracy, 0.0);
      final saved = await _savedProfile();
      expect(saved['birthYear'], 2019);
      expect(saved['totalStars'], 0);
      expect(saved['totalProblemsCompleted'], 0);
    },
  );

  test(
    'year rollover refresh republishes age and caches it without changing birth year',
    () async {
      now = DateTime(2026, 12, 31, 23, 59);
      await container.read(profileProvider.future);
      await container
          .read(profileProvider.notifier)
          .createProfile(_profile(birthYear: 2019));
      expect(container.read(profileProvider).requireValue!.age, 7);
      var notifications = 0;
      final subscription = container.listen(
        profileProvider,
        (previous, next) => notifications++,
      );
      addTearDown(subscription.close);

      now = DateTime(2027, 1, 1);
      await container.read(profileProvider.notifier).refreshAge();
      final refreshed = container.read(profileProvider).requireValue!;
      expect(notifications, greaterThan(0));
      expect(refreshed.age, 8);
      expect(refreshed.birthYear, 2019);
      expect(refreshed.totalStars, 10);
      expect(refreshed.totalProblemsCompleted, 20);
      expect((await _savedProfile())['age'], 8);
      expect((await _savedProfile())['birthYear'], 2019);
    },
  );

  test('clearing a profile removes its saved birth year', () async {
    await container.read(profileProvider.future);
    final notifier = container.read(profileProvider.notifier);
    await notifier.createProfile(_profile(birthYear: 2019));
    await notifier.clearProfile();
    expect(container.read(profileProvider).requireValue, isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('current_profile'), isFalse);
  });

  Future<void> showAge(WidgetTester tester) => tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: ProfileAgeRefresh(
          child: Consumer(
            builder: (context, ref, child) =>
                Text('age:${ref.watch(profileProvider).value?.age}'),
          ),
        ),
      ),
    ),
  );

  testWidgets('foreground resume updates displayed and persisted age', (
    tester,
  ) async {
    await container.read(profileProvider.future);
    await container
        .read(profileProvider.notifier)
        .createProfile(_profile(birthYear: 2019));
    await showAge(tester);
    expect(find.text('age:7'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = DateTime(2028, 6, 10);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('age:9'), findsOneWidget);
    expect((await _savedProfile())['age'], 9);
    expect((await _savedProfile())['birthYear'], 2019);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('an open app updates displayed age at the new year', (
    tester,
  ) async {
    now = DateTime(2026, 12, 31, 23, 59, 58);
    await container.read(profileProvider.future);
    await container
        .read(profileProvider.notifier)
        .createProfile(_profile(birthYear: 2019));
    await showAge(tester);
    expect(find.text('age:7'), findsOneWidget);

    now = DateTime(2027, 1, 1);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('age:8'), findsOneWidget);
    expect((await _savedProfile())['age'], 8);
    expect((await _savedProfile())['birthYear'], 2019);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('an age observer mounted in the background waits for resume', (
    tester,
  ) async {
    now = DateTime(2026, 12, 31, 23, 59, 58);
    await container.read(profileProvider.future);
    await container
        .read(profileProvider.notifier)
        .createProfile(_profile(birthYear: 2019));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ProfileAgeRefresh(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) =>
                  Text('age:${ref.watch(profileProvider).value?.age}'),
            ),
          ),
        ),
      ),
    );
    tester.binding.scheduleForcedFrame();
    await tester.pump();
    expect(find.byType(ProfileAgeRefresh), findsOneWidget);
    await tester.pumpAndSettle();
    var notifications = 0;
    final subscription = container.listen(
      profileProvider,
      (previous, next) => notifications++,
    );
    addTearDown(subscription.close);
    now = DateTime(2027, 1, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(notifications, 0);
    expect((await _savedProfile())['age'], 7);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('age:8'), findsOneWidget);
    expect(notifications, greaterThan(0));
    expect((await _savedProfile())['age'], 8);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
