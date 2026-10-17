import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:number_bond_math/models/kid_profile.dart';
import 'package:number_bond_math/models/rewards_model.dart';
import 'package:number_bond_math/providers/profile_provider.dart';
import 'package:number_bond_math/services/language_service.dart';
import 'package:number_bond_math/widgets/rewards_display.dart';

ChildRewards _rewards(ChildLevel level) => ChildRewards(
  childId: 'reward-layout-child',
  totalStars: level.minStars + 17,
  totalBadges: 12,
  totalStickers: 3,
  currentLevel: level,
  recentRewards: const [],
  badges: const [],
  stickers: const [],
  lastUpdated: DateTime(2026, 10, 10),
);

class _FrenchProfile extends ProfileNotifier {
  @override
  Future<KidProfile?> build() async => KidProfile(
    id: 'reward-layout-child',
    name: 'Maya',
    birthYear: 2020,
    avatarId: 'default',
    language: 'fr',
    isCurrent: true,
    createdAt: DateTime(2026, 1, 1),
    lastPlayed: DateTime(2026, 10, 10),
  );
}

Future<void> _pumpRewards(
  WidgetTester tester, {
  required ChildRewards rewards,
  String? language = 'en',
  double width = 288,
  double textScale = 1.5,
  bool showDetailed = false,
  bool profileScope = false,
}) async {
  Widget app = MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: width,
            child: RewardsDisplay(
              key: const ValueKey('full-rewards'),
              rewards: rewards,
              childName: 'Maya',
              language: language,
              showDetailed: showDetailed,
            ),
          ),
        ),
      ),
    ),
  );
  if (profileScope) {
    app = ProviderScope(
      overrides: [profileProvider.overrideWith(_FrenchProfile.new)],
      child: app,
    );
  }
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

String _levelKey(ChildLevel level) => switch (level) {
  ChildLevel.onesExplorer => 'ones_explorer',
  ChildLevel.tensBuilder => 'tens_builder',
  ChildLevel.hundredsHero => 'hundreds_hero',
  ChildLevel.thousandsChampion => 'thousands_champion',
};

void _expectRewardsFit(
  WidgetTester tester,
  ChildRewards rewards,
  String language,
) {
  expect(tester.takeException(), isNull);
  final card = tester.getRect(find.byKey(const ValueKey('full-rewards')));
  final labels = [
    '${rewards.currentLevel.emoji} ${LanguageService.translate(_levelKey(rewards.currentLevel), language)}',
    '${rewards.totalStars} ⭐',
    LanguageService.translate('progress_to_next_level', language),
    '${rewards.starsToNextLevel} ${LanguageService.translate('stars_to_go', language)}',
  ];
  for (final label in labels) {
    final finder = find.text(label);
    expect(finder, findsOneWidget);
    final textBounds = tester.getRect(finder);
    expect(textBounds.left, greaterThanOrEqualTo(card.left + 16));
    expect(textBounds.right, lessThanOrEqualTo(card.right - 16 + 0.01));
    expect(textBounds.top, greaterThanOrEqualTo(card.top));
    expect(textBounds.bottom, lessThanOrEqualTo(card.bottom));
  }
  final progress = tester.widget<LinearProgressIndicator>(
    find.byType(LinearProgressIndicator),
  );
  expect(progress.value, rewards.levelProgress);
}

void main() {
  for (final language in ['en', 'es', 'fr']) {
    for (final width in [240.0, 288.0]) {
      for (final level in [
        ChildLevel.hundredsHero,
        ChildLevel.thousandsChampion,
      ]) {
        testWidgets(
          '$language ${level.name} fits $width px at text scale 1.5 without a profile scope',
          (tester) async {
            final rewards = _rewards(level);
            await _pumpRewards(
              tester,
              rewards: rewards,
              language: language,
              width: width,
            );
            _expectRewardsFit(tester, rewards, language);
          },
        );
      }
    }
  }

  testWidgets('omitted language still follows the current profile', (
    tester,
  ) async {
    final rewards = _rewards(ChildLevel.thousandsChampion);
    await _pumpRewards(
      tester,
      rewards: rewards,
      language: null,
      profileScope: true,
    );
    _expectRewardsFit(tester, rewards, 'fr');
  });

  testWidgets('explicit language takes precedence over the profile', (
    tester,
  ) async {
    final rewards = _rewards(ChildLevel.hundredsHero);
    await _pumpRewards(
      tester,
      rewards: rewards,
      language: 'es',
      profileScope: true,
    );
    _expectRewardsFit(tester, rewards, 'es');
    expect(find.textContaining('Héros des Centaines'), findsNothing);
  });

  testWidgets('wide card retains its level and stars on the same row', (
    tester,
  ) async {
    final rewards = _rewards(ChildLevel.thousandsChampion);
    await _pumpRewards(
      tester,
      rewards: rewards,
      language: 'fr',
      width: 600,
      textScale: 1,
    );
    _expectRewardsFit(tester, rewards, 'fr');
    final level = tester.getRect(find.text('🏆 Champion des Milliers'));
    final stars = tester.getRect(find.text('${rewards.totalStars} ⭐'));
    expect(level.center.dy, closeTo(stars.center.dy, 0.01));
  });

  testWidgets('detailed reward totals remain visible on a narrow card', (
    tester,
  ) async {
    final rewards = _rewards(ChildLevel.hundredsHero);
    await _pumpRewards(
      tester,
      rewards: rewards,
      language: 'fr',
      width: 240,
      showDetailed: true,
    );
    _expectRewardsFit(tester, rewards, 'fr');
    expect(find.text('12'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Badges'), findsOneWidget);
    expect(find.text('Stickers'), findsOneWidget);
  });
}
