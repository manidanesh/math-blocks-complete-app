import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:number_bond_math/main.dart';
import 'package:number_bond_math/models/kid_profile.dart';
import 'package:number_bond_math/models/problem_attempt.dart';
import 'package:number_bond_math/navigation/app_router.dart';
import 'package:number_bond_math/providers/profile_provider.dart';
import 'package:number_bond_math/screens/adaptive_challenge_screen.dart';
import 'package:number_bond_math/screens/mode_select_screen.dart';
import 'package:number_bond_math/screens/profile_creation_screen.dart';
import 'package:number_bond_math/screens/profile_screen.dart';
import 'package:number_bond_math/widgets/interactive_number_bond_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

class _UnavailableProfile extends ProfileNotifier {
  @override
  Future<KidProfile?> build() async => throw StateError('Storage unavailable');
}

KidProfile _profile({String language = 'en', String name = 'Maya'}) =>
    KidProfile(
      id: 'navigation-child',
      name: name,
      birthYear: 2019,
      avatarId: 'default',
      language: language,
      isCurrent: true,
      createdAt: DateTime(2026, 1, 1),
      lastPlayed: DateTime(2026, 10, 10),
      favoriteNumbers: const [3, 8],
    );

ProblemAttempt _failedAttempt({int level = 3}) => ProblemAttempt(
  id: 'failed-history-problem',
  childId: 'navigation-child',
  problemText: '129 - 89 = ?',
  operand1: 129,
  operand2: 89,
  operator: '-',
  correctAnswer: 40,
  userAnswer: null,
  isCorrect: false,
  timestamp: DateTime(2026, 10, 10),
  attemptNumber: 3,
  timeSpentSeconds: 25,
  strategy: 'crossing',
  difficultyLevel: level,
  skillArea: 'subtraction',
  usedHint: true,
);

void _setViewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<ProviderContainer> _container({
  KidProfile? profile,
  List<ProblemAttempt> attempts = const [],
  bool preload = true,
}) async {
  SharedPreferences.setMockInitialValues({
    if (profile != null) 'current_profile': jsonEncode(profile.toJson()),
    if (attempts.isNotEmpty)
      'problem_attempts': jsonEncode(attempts.map((a) => a.toJson()).toList()),
  });
  final container = ProviderContainer(
    overrides: [
      profileNowProvider.overrideWithValue(() => DateTime(2026, 10, 10)),
    ],
  );
  addTearDown(container.dispose);
  if (preload) await container.read(profileProvider.future);
  return container;
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required ProviderContainer container,
  Size size = const Size(320, 568),
  double textScale = 1,
}) async {
  _setViewport(tester, size);
  final router = GoRouter(
    initialLocation: '/mode-select',
    routes: [
      GoRoute(
        path: '/mode-select',
        builder: (_, _) => const ModeSelectScreen(),
      ),
      GoRoute(
        path: '/profile-creation',
        builder: (_, _) => const Scaffold(body: Text('Create destination')),
      ),
      GoRoute(
        path: '/challenge',
        builder: (_, _) => const Scaffold(body: Text('Challenge destination')),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, _) => const Scaffold(body: Text('Profile destination')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 47, bottom: 34),
            viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<ProviderContainer> _pumpRealApp(
  WidgetTester tester, {
  KidProfile? profile,
  List<ProblemAttempt> attempts = const [],
  bool preload = true,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  _setViewport(tester, size);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
  tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
  final container = await _container(
    profile: profile,
    attempts: attempts,
    preload: preload,
  );
  container.read(routerProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MathBlocksCompleteApp(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  for (final language in ['en', 'es', 'fr']) {
    for (final layout in [
      (size: const Size(320, 568), scale: 1.0),
      (size: const Size(320, 568), scale: 2.4),
      (size: const Size(568, 320), scale: 2.0),
    ]) {
      testWidgets(
        '$language themed app home fits ${layout.size} with ${layout.scale} text',
        (tester) async {
          await _pumpRealApp(
            tester,
            profile: _profile(
              language: language,
              name: 'Alexandria Long Child Name',
            ),
            size: layout.size,
            textScale: layout.scale,
          );
          expect(find.byType(ModeSelectScreen), findsOneWidget);
          for (final key in ['home-challenge', 'home-profile']) {
            final button = _key(key);
            await tester.ensureVisible(button);
            await tester.pumpAndSettle();
            final buttonContext = tester.element(button);
            expect(Theme.of(buttonContext).useMaterial3, isTrue);
            expect(
              MediaQuery.textScalerOf(buttonContext).scale(10),
              closeTo(10 * layout.scale, 0.001),
            );
            expect(button.hitTestable(), findsOneWidget);
            final buttonRect = tester.getRect(button);
            expect(buttonRect.height, greaterThanOrEqualTo(48));
            expect(buttonRect.left, greaterThanOrEqualTo(0));
            expect(buttonRect.right, lessThanOrEqualTo(layout.size.width));
            for (final element
                in find
                    .descendant(of: button, matching: find.byType(Text))
                    .evaluate()) {
              final textRect = tester.getRect(find.byWidget(element.widget));
              expect(textRect.top, greaterThanOrEqualTo(buttonRect.top));
              expect(textRect.bottom, lessThanOrEqualTo(buttonRect.bottom));
              expect(textRect.left, greaterThanOrEqualTo(buttonRect.left));
              expect(textRect.right, lessThanOrEqualTo(buttonRect.right));
            }
            expect(tester.takeException(), isNull);
          }
          await _tapVisible(tester, _key('home-profile'));
          expect(find.byType(ProfileScreen), findsOneWidget);
          final edit = _key('profile-favorites-edit');
          await tester.ensureVisible(edit);
          await tester.pumpAndSettle();
          expect(edit.hitTestable(), findsOneWidget);
          final editRect = tester.getRect(edit);
          final editText = find.descendant(
            of: edit,
            matching: find.byType(Text),
          );
          expect(
            tester.getRect(editText).right,
            lessThanOrEqualTo(editRect.right),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final language in ['en', 'es', 'fr']) {
    for (final layout in [
      (size: const Size(320, 568), scale: 1.0),
      (size: const Size(568, 320), scale: 2.0),
    ]) {
      testWidgets(
        '$language home remains usable at ${layout.size} with ${layout.scale} text',
        (tester) async {
          final container = await _container(
            profile: _profile(
              language: language,
              name: 'Alexandria Long Child Name',
            ),
          );
          await _pumpHome(
            tester,
            container: container,
            size: layout.size,
            textScale: layout.scale,
          );
          expect(tester.takeException(), isNull);
          for (final key in ['home-challenge', 'home-profile']) {
            final button = _key(key);
            await tester.ensureVisible(button);
            await tester.pumpAndSettle();
            expect(button.hitTestable(), findsOneWidget);
            final rect = tester.getRect(button);
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(layout.size.width));
            expect(rect.height, greaterThanOrEqualTo(48));
            expect(tester.takeException(), isNull);
          }
          await _tapVisible(tester, _key('home-challenge'));
          expect(find.text('Challenge destination'), findsOneWidget);
        },
      );
    }
  }

  for (final translation in [
    (language: 'en', label: 'Create a profile to start learning.'),
    (language: 'es', label: 'Crea un perfil para empezar a aprender.'),
    (language: 'fr', label: 'Crée un profil pour commencer à apprendre.'),
  ]) {
    testWidgets('${translation.language} missing profile offers recovery', (
      tester,
    ) async {
      tester.platformDispatcher.localeTestValue = Locale(translation.language);
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);
      final container = await _container();
      await _pumpHome(tester, container: container);
      expect(find.text(translation.label), findsOneWidget);
      await _tapVisible(tester, _key('home-create-profile'));
      expect(find.text('Create destination'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('saved profile opens home after cold asynchronous loading', (
    tester,
  ) async {
    await _pumpRealApp(tester, profile: _profile(), preload: false);
    expect(find.byType(ModeSelectScreen), findsOneWidget);
    expect(find.byType(ProfileCreationScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile loading errors provide a usable recovery action', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [profileProvider.overrideWith(_UnavailableProfile.new)],
    );
    addTearDown(container.dispose);
    await _pumpHome(tester, container: container);
    expect(find.text('Unable to load your profile.'), findsOneWidget);
    expect(find.textContaining('Storage unavailable'), findsNothing);
    expect(_key('home-create-profile'), findsNothing);
    await _tapVisible(tester, _key('home-retry-profile'));
    expect(find.text('Unable to load your profile.'), findsOneWidget);
    expect(_key('home-retry-profile').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'corrupt saved profile opens recovery and preserves stored data',
    (tester) async {
      const storedProfile = '{profile that cannot be decoded';
      SharedPreferences.setMockInitialValues({
        'current_profile': storedProfile,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MathBlocksCompleteApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ModeSelectScreen), findsOneWidget);
      expect(find.byType(ProfileCreationScreen), findsNothing);
      expect(_key('home-create-profile'), findsNothing);
      expect(find.text('Unable to load your profile.'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('current_profile'), storedProfile);
      await _tapVisible(tester, _key('home-retry-profile'));
      expect(prefs.getString('current_profile'), storedProfile);
      expect(find.byType(ProfileCreationScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('new profile creation reaches the localized live home', (
    tester,
  ) async {
    final container = await _pumpRealApp(tester);
    expect(find.byType(ProfileCreationScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Maya');
    await _tapVisible(tester, _key('birth-year-dropdown'));
    await _tapVisible(tester, find.text('7').last);
    await _tapVisible(tester, find.text('Français').first);
    await _tapVisible(tester, find.text('Créer le Profil'));
    expect(find.byType(ModeSelectScreen), findsOneWidget);
    expect(find.text('Bienvenue Maya!'), findsOneWidget);
    final profile = container.read(profileProvider).value!;
    expect(profile.birthYear, 2019);
    expect(profile.language, 'fr');
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString('current_profile')!)['birthYear'], 2019);
    await _tapVisible(tester, _key('home-challenge'));
    expect(find.byType(AdaptiveChallengeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final route in ['/challenge', '/profile']) {
    testWidgets('$route without a profile returns to creation', (tester) async {
      final container = await _pumpRealApp(tester);
      container.read(routerProvider).go(route);
      await tester.pumpAndSettle();
      expect(find.byType(ProfileCreationScreen), findsOneWidget);
      expect(find.byType(AdaptiveChallengeScreen), findsNothing);
      expect(find.byType(ProfileScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'already loaded profile opens home without another provider update',
    (tester) async {
      await _pumpRealApp(tester, profile: _profile());
      expect(find.byType(ModeSelectScreen), findsOneWidget);
      expect(find.byType(ProfileCreationScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'home challenge and profile navigation return to the saved home',
    (tester) async {
      await _pumpRealApp(tester, profile: _profile(language: 'fr'));
      await _tapVisible(tester, _key('home-challenge'));
      expect(find.byType(AdaptiveChallengeScreen), findsOneWidget);
      await _tapVisible(tester, find.byIcon(Icons.arrow_back));
      expect(find.byType(ModeSelectScreen), findsOneWidget);
      await _tapVisible(tester, _key('home-profile'));
      expect(find.byType(ProfileScreen), findsOneWidget);
      await _tapVisible(tester, find.byIcon(Icons.arrow_back));
      expect(find.byType(ModeSelectScreen), findsOneWidget);
      expect(find.text('Bienvenue Maya!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final level in [3, 4]) {
    testWidgets(
      'level $level history retains difficulty when opened and retried',
      (tester) async {
        final history = _failedAttempt(level: level);
        final container = await _pumpRealApp(
          tester,
          profile: _profile(),
          attempts: [history],
        );
        await _tapVisible(tester, _key('home-profile'));
        await _tapVisible(tester, find.text('129 - 89 = ?'));
        expect(find.byType(AdaptiveChallengeScreen), findsOneWidget);
        expect(
          tester
              .widget<AdaptiveChallengeScreen>(
                find.byType(AdaptiveChallengeScreen),
              )
              .initialProblem!
              .level,
          level,
        );
        expect(
          tester.widget<Text>(_key('challenge-question')).data,
          '129 - 89 = ?',
        );
        final bond = tester.widget<InteractiveNumberBondWidget>(
          find.byType(InteractiveNumberBondWidget),
        );
        expect(bond.operand1, 129);
        expect(bond.operand2, 89);
        expect(bond.operation, 'subtraction');
        expect(bond.showSolution, isTrue);
        expect(bond.compact, isFalse);
        for (final step in ['129 - 9 = 120', '120 - 80 = 40']) {
          final explanation = find.text(step);
          expect(explanation, findsOneWidget);
          expect(
            find.ancestor(
              of: explanation,
              matching: _key('challenge-page-scroll'),
            ),
            findsOneWidget,
          );
          await tester.ensureVisible(explanation);
          await tester.pumpAndSettle();
          expect(explanation.hitTestable(), findsOneWidget);
        }
        final prefs = await SharedPreferences.getInstance();
        expect(jsonDecode(prefs.getString('problem_attempts')!), hasLength(1));
        expect(container.read(profileProvider).value!.id, 'navigation-child');

        await _tapVisible(tester, _key('challenge-retry'));
        expect(
          tester.widget<Text>(_key('challenge-question')).data,
          '129 - 89 = ?',
        );
        final retryBond = tester.widget<InteractiveNumberBondWidget>(
          find.byType(InteractiveNumberBondWidget),
        );
        expect(retryBond.operand1, 129);
        expect(retryBond.operand2, 89);
        expect(retryBond.operation, 'subtraction');
        expect(retryBond.showSolution, isFalse);
        expect(find.text('129 - 9 = 120'), findsNothing);
        expect(find.text('120 - 80 = 40'), findsNothing);
        for (var index = 0; index < 2; index++) {
          expect(
            find.descendant(
              of: _key('bond-part-$index'),
              matching: find.text('?'),
            ),
            findsOneWidget,
          );
        }
        expect(jsonDecode(prefs.getString('problem_attempts')!), hasLength(1));
        await _tapVisible(tester, _key('bond-number-9'));
        await _tapVisible(tester, _key('bond-number-80'));
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();
        expect(
          tester.widget<Text>(_key('challenge-question')).data,
          '129 - 89 = 40',
        );
        expect(find.text('129 - 9 = 120'), findsOneWidget);
        expect(find.text('120 - 80 = 40'), findsOneWidget);
        final savedAttempts =
            (jsonDecode(prefs.getString('problem_attempts')!) as List)
                .map(
                  (entry) =>
                      ProblemAttempt.fromJson(entry as Map<String, dynamic>),
                )
                .toList();
        expect(savedAttempts, hasLength(2));
        expect(
          savedAttempts.singleWhere((entry) => entry.id == history.id).toJson(),
          history.toJson(),
        );
        final retryAttempt = savedAttempts.singleWhere(
          (entry) => entry.id != history.id,
        );
        expect(retryAttempt.problemText, '129 - 89');
        expect(retryAttempt.operand1, 129);
        expect(retryAttempt.operand2, 89);
        expect(retryAttempt.operator, '-');
        expect(retryAttempt.correctAnswer, 40);
        expect(retryAttempt.isCorrect, isTrue);
        expect(retryAttempt.attemptNumber, 1);
        expect(retryAttempt.difficultyLevel, level);
        final adaptiveResults =
            jsonDecode(
                  prefs.getString(
                    'adaptive_challenge_results_navigation-child',
                  )!,
                )
                as List<dynamic>;
        expect(adaptiveResults, hasLength(1));
        expect(adaptiveResults.single['level'], level);
        expect(adaptiveResults.single['isReviewProblem'], isTrue);
        expect(container.read(profileProvider).value!.totalStars, 1);
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        expect(
          tester.widget<Text>(_key('challenge-question')).data,
          '129 - 89 = 40',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
