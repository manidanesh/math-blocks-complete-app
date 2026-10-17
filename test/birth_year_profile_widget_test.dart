import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:number_bond_math/models/kid_profile.dart';
import 'package:number_bond_math/models/problem_attempt.dart';
import 'package:number_bond_math/providers/profile_provider.dart';
import 'package:number_bond_math/screens/profile_creation_screen.dart';
import 'package:number_bond_math/screens/profile_screen.dart';
import 'package:number_bond_math/widgets/birth_year_selector.dart';

final _birthYearDropdown = find.byKey(const ValueKey('birth-year-dropdown'));
final _currentDate = DateTime(2026, 10, 10);

Future<void> _selectYear(WidgetTester tester, int year) async {
  final selector = tester.widget<BirthYearSelector>(
    find.byType(BirthYearSelector),
  );
  final label = selector.showAgeOptions
      ? '${_currentDate.year - year}'
      : '$year';
  await tester.ensureVisible(_birthYearDropdown);
  await tester.pumpAndSettle();
  await tester.tap(_birthYearDropdown);
  await tester.pumpAndSettle();
  final item = find.text(label).last;
  expect(item, findsOneWidget);
  await tester.ensureVisible(item);
  await tester.pumpAndSettle();
  await tester.tap(item);
  await tester.pumpAndSettle();
}

Future<void> _pumpCreation(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: '/profile-creation',
    routes: [
      GoRoute(
        path: '/profile-creation',
        builder: (context, state) => const ProfileCreationScreen(),
      ),
      GoRoute(
        path: '/mode-select',
        builder: (context, state) =>
            const Scaffold(body: Text('Profile saved')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [profileNowProvider.overrideWithValue(() => _currentDate)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

KidProfile _profile({int? birthYear, String language = 'en'}) => KidProfile(
  id: 'birth-year-child',
  name: 'Maya',
  age: birthYear == null ? 7 : null,
  birthYear: birthYear,
  avatarId: 'default',
  language: language,
  isCurrent: true,
  createdAt: DateTime(2024, 9, 1),
  lastPlayed: DateTime(2026, 9, 1),
  totalStars: 1,
  totalProblemsCompleted: 2,
  overallAccuracy: 0.5,
  favoriteNumbers: const [3, 8],
  preferredOperation: 'subtraction',
);

List<ProblemAttempt> _attemptsFor(KidProfile profile) => [
  for (var index = 0; index < 2; index++)
    ProblemAttempt(
      id: 'attempt-$index',
      childId: profile.id,
      problemText: '${4 + index} + 7',
      operand1: 4 + index,
      operand2: 7,
      operator: '+',
      correctAnswer: 11 + index,
      userAnswer: index == 0 ? 11 : 10,
      isCorrect: index == 0,
      timestamp: DateTime(2026, 9, 1, index),
      attemptNumber: 1,
      timeSpentSeconds: 12.0,
      strategy: 'makeTen',
      difficultyLevel: 1,
      skillArea: 'addition',
      usedHint: false,
    ),
];

Future<ProviderContainer> _pumpProfile(
  WidgetTester tester,
  KidProfile profile,
) async {
  SharedPreferences.setMockInitialValues({
    'current_profile': jsonEncode(profile.toJson()),
    'problem_attempts': jsonEncode(
      _attemptsFor(profile).map((attempt) => attempt.toJson()).toList(),
    ),
  });
  final container = ProviderContainer(
    overrides: [profileNowProvider.overrideWithValue(() => _currentDate)],
  );
  addTearDown(container.dispose);
  await container.read(profileProvider.future);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ProfileScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('BirthYearSelector', () {
    testWidgets('shows birth years for ages four through nine', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BirthYearSelector(
              selectedBirthYear: null,
              currentDate: DateTime(2026, 10, 10),
              onBirthYearSelected: (_) {},
            ),
          ),
        ),
      );
      final dropdown = tester.widget<DropdownButton<int>>(_birthYearDropdown);
      expect(dropdown.items!.map((item) => item.value), [
        2022,
        2021,
        2020,
        2019,
        2018,
        2017,
      ]);
      expect(find.text('Select birth year'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('birth-year-age-preview')),
        findsNothing,
      );
    });

    testWidgets('the age preview advances when the calendar year changes', (
      tester,
    ) async {
      var selections = 0;
      Future<void> showAt(DateTime date) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BirthYearSelector(
                selectedBirthYear: 2020,
                currentDate: date,
                onBirthYearSelected: (_) => selections++,
              ),
            ),
          ),
        );
      }

      await showAt(DateTime(2026, 12, 31));
      expect(find.text('Age this year: 6'), findsOneWidget);
      await showAt(DateTime(2027, 1, 1));
      expect(find.text('Age this year: 7'), findsOneWidget);
      expect(selections, 0);
    });

    testWidgets('retains a saved year when a child grows beyond twelve', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BirthYearSelector(
              selectedBirthYear: 2010,
              currentDate: DateTime(2026),
              onBirthYearSelected: (_) {},
            ),
          ),
        ),
      );
      expect(
        tester.widget<DropdownButton<int>>(_birthYearDropdown).value,
        2010,
      );
      expect(find.text('Age this year: 16'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('future birth years are unavailable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BirthYearSelector(
              selectedBirthYear: null,
              currentDate: DateTime(2026),
              minAge: 0,
              maxAge: 100,
              onBirthYearSelected: (_) {},
            ),
          ),
        ),
      );
      final dropdown = tester.widget<DropdownButton<int>>(_birthYearDropdown);
      expect(dropdown.items!.first.value, 2026);
      expect(dropdown.items!.last.value, 1926);
      expect(dropdown.items!.every((item) => item.value! <= 2026), isTrue);
    });

    testWidgets('invalid supplied years do not produce a selected value', (
      tester,
    ) async {
      for (final birthYear in [-1, 0, 2027]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BirthYearSelector(
                selectedBirthYear: birthYear,
                currentDate: DateTime(2026),
                onBirthYearSelected: (_) {},
              ),
            ),
          ),
        );
        final dropdown = tester.widget<DropdownButton<int>>(_birthYearDropdown);
        expect(dropdown.value, isNull);
        expect(dropdown.items!.every((item) => item.value! > 0), isTrue);
        expect(
          find.byKey(const ValueKey('birth-year-age-preview')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      }
    });

    for (final translation in [
      (
        language: 'en',
        label: 'Birth year',
        hint: 'Select birth year',
        preview: 'Age this year: 6',
      ),
      (
        language: 'es',
        label: 'Año de nacimiento',
        hint: 'Selecciona tu año de nacimiento',
        preview: 'Edad este año: 6',
      ),
      (
        language: 'fr',
        label: 'Année de naissance',
        hint: 'Choisissez votre année de naissance',
        preview: 'Âge cette année : 6',
      ),
    ]) {
      testWidgets('${translation.language} localizes birth-year selection', (
        tester,
      ) async {
        int? selectedYear;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => BirthYearSelector(
                  selectedBirthYear: selectedYear,
                  language: translation.language,
                  currentDate: DateTime(2026, 10, 10),
                  onBirthYearSelected: (year) =>
                      setState(() => selectedYear = year),
                ),
              ),
            ),
          ),
        );
        expect(find.text(translation.label), findsOneWidget);
        expect(find.text(translation.hint), findsOneWidget);
        await _selectYear(tester, 2020);
        expect(selectedYear, 2020);
        expect(find.text(translation.preview), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Profile creation', () {
    for (final age in [4, 9]) {
      testWidgets('offers ages four through nine and saves selected age $age', (
        tester,
      ) async {
        await _pumpCreation(tester);
        final dropdown = tester.widget<DropdownButton<int>>(_birthYearDropdown);
        expect(dropdown.items!.map((item) => item.value), [
          for (var age = 4; age <= 9; age++) _currentDate.year - age,
        ]);
        expect(dropdown.items!.map((item) => (item.child as Text).data), [
          '4',
          '5',
          '6',
          '7',
          '8',
          '9',
        ]);
        expect(find.text('How old are you?'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'Maya');
        await _selectYear(tester, _currentDate.year - age);
        final button = find.widgetWithText(ElevatedButton, 'Create Profile');
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.tap(button);
        await tester.pumpAndSettle();
        final stored =
            jsonDecode(
                  (await SharedPreferences.getInstance()).getString(
                    'current_profile',
                  )!,
                )
                as Map<String, dynamic>;
        expect(stored['birthYear'], _currentDate.year - age);
        expect(KidProfile.fromJson(stored, now: () => _currentDate).age, age);
        expect(find.text('Profile saved'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('requires both a name and a selected birth year', (
      tester,
    ) async {
      await _pumpCreation(tester);
      final button = find.widgetWithText(ElevatedButton, 'Create Profile');
      expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
      await tester.enterText(find.byType(TextField), 'Maya');
      await tester.pumpAndSettle();
      expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
      await _selectYear(tester, _currentDate.year - 6);
      expect(tester.widget<ElevatedButton>(button).onPressed, isNotNull);
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pumpAndSettle();
      expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
    });

    testWidgets('saves the selected birth year in a newly created profile', (
      tester,
    ) async {
      await _pumpCreation(tester);
      await tester.enterText(find.byType(TextField), 'Maya');
      await tester.pumpAndSettle();
      final birthYear = _currentDate.year - 6;
      await _selectYear(tester, birthYear);
      final button = find.widgetWithText(ElevatedButton, 'Create Profile');
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('Profile saved'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      final stored =
          jsonDecode(prefs.getString('current_profile')!)
              as Map<String, dynamic>;
      expect(stored['name'], 'Maya');
      expect(stored['birthYear'], birthYear);
      expect(KidProfile.fromJson(stored, now: () => _currentDate).age, 6);
    });

    testWidgets('changing language retains the selected birth year', (
      tester,
    ) async {
      await _pumpCreation(tester);
      final birthYear = _currentDate.year - 6;
      await _selectYear(tester, birthYear);
      final spanish = find.text('Español').first;
      await tester.ensureVisible(spanish);
      await tester.pumpAndSettle();
      await tester.tap(spanish);
      await tester.pumpAndSettle();

      expect(
        tester.widget<DropdownButton<int>>(_birthYearDropdown).value,
        birthYear,
      );
      expect(find.text('Edad este año: 6'), findsOneWidget);
      expect(find.text('Edad seleccionada'), findsOneWidget);
    });
  });

  group('Profile birth-year settings', () {
    testWidgets(
      'a legacy profile keeps its age until a birth year is supplied',
      (tester) async {
        final profile = _profile();
        final container = await _pumpProfile(tester, profile);
        expect(find.text('Age: 7'), findsOneWidget);
        expect(
          find.text('Add a birth year to keep age up to date.'),
          findsOneWidget,
        );
        expect(
          tester.widget<DropdownButton<int>>(_birthYearDropdown).value,
          isNull,
        );
        expect(container.read(profileProvider).value!.birthYear, isNull);

        final birthYear = _currentDate.year - 8;
        await _selectYear(tester, birthYear);
        final updated = container.read(profileProvider).value!;
        expect(updated.birthYear, birthYear);
        expect(updated.age, 8);
        expect(updated.totalStars, profile.totalStars);
        expect(updated.totalProblemsCompleted, profile.totalProblemsCompleted);
        expect(updated.overallAccuracy, profile.overallAccuracy);
        expect(updated.favoriteNumbers, profile.favoriteNumbers);
        expect(updated.language, profile.language);
        expect(updated.preferredOperation, profile.preferredOperation);
        expect(updated.createdAt, profile.createdAt);
        expect(updated.lastPlayed, profile.lastPlayed);
        expect(
          find.text('Add a birth year to keep age up to date.'),
          findsNothing,
        );
        expect(find.text('Age: 8'), findsOneWidget);

        final prefs = await SharedPreferences.getInstance();
        final saved = KidProfile.fromJson(
          jsonDecode(prefs.getString('current_profile')!)
              as Map<String, dynamic>,
        );
        expect(saved.birthYear, birthYear);
        expect(saved.totalStars, 1);
        expect(saved.totalProblemsCompleted, 2);
        expect(jsonDecode(prefs.getString('problem_attempts')!), hasLength(2));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'a saved birth year remains editable past the original age limit',
      (tester) async {
        final year = _currentDate.year;
        final container = await _pumpProfile(
          tester,
          _profile(birthYear: year - 15),
        );
        expect(
          tester.widget<DropdownButton<int>>(_birthYearDropdown).value,
          year - 15,
        );
        expect(find.text('Age: 15'), findsOneWidget);
        await _selectYear(tester, year - 16);
        expect(container.read(profileProvider).value!.birthYear, year - 16);
        expect(find.text('Age: 16'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  testWidgets('birth-year controls fit a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    int? selectedYear;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: StatefulBuilder(
              builder: (context, setState) => BirthYearSelector(
                selectedBirthYear: selectedYear,
                language: 'fr',
                currentDate: DateTime(2026),
                onBirthYearSelected: (year) =>
                    setState(() => selectedYear = year),
              ),
            ),
          ),
        ),
      ),
    );
    await _selectYear(tester, 2020);
    expect(find.text('Âge cette année : 6'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
