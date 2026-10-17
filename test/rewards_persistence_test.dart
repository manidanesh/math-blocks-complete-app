import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:number_bond_math/models/rewards_model.dart';
import 'package:number_bond_math/services/rewards_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

ChildRewards _summary({
  String child = 'child',
  int stars = 0,
  ChildLevel level = ChildLevel.onesExplorer,
  int badges = 0,
  int stickers = 0,
}) => ChildRewards(
  childId: child,
  totalStars: stars,
  totalBadges: badges,
  totalStickers: stickers,
  currentLevel: level,
  recentRewards: const [],
  badges: const [],
  stickers: const [],
  lastUpdated: DateTime(2026, 10, 10),
);

Future<RewardResult> _award(String id, {String child = 'child'}) =>
    RewardsService.addStar(child, metadata: {'eventId': id});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'earned badges and level stickers survive reopening the stored summary',
    () async {
      for (var index = 0; index < 50; index++) {
        expect((await _award('event-$index')).success, isTrue);
      }
      final reopened = await RewardsService.getRewards('child');
      expect(reopened.totalStars, 50);
      expect(reopened.totalBadges, 5);
      expect(reopened.badges.length, 5);
      expect(reopened.totalStickers, 1);
      expect(reopened.stickers.single.level, ChildLevel.tensBuilder);
      expect(reopened.currentLevel, ChildLevel.tensBuilder);
      expect((await RewardsService.getBadges('child')).length, 5);
      expect((await RewardsService.getStickers('child')).length, 1);
      final prefs = await SharedPreferences.getInstance();
      final document =
          jsonDecode(prefs.getString('rewards_child')!) as Map<String, dynamic>;
      expect((document['badges'] as List).length, 5);
      expect((document['stickers'] as List).length, 1);
    },
  );

  test(
    'event receipts prevent duplicate stars after the recent reward list expires',
    () async {
      for (var index = 0; index < 25; index++) {
        await _award('event-$index');
      }
      final before = await RewardsService.getRewards('child');
      expect(before.recentRewards.length, 20);
      expect(
        before.recentRewards.any(
          (reward) => reward.metadata?['eventId'] == 'event-0',
        ),
        isFalse,
      );
      final duplicate = await _award('event-0');
      expect(duplicate.success, isTrue);
      expect(duplicate.levelUp, isFalse);
      final after = await RewardsService.getRewards('child');
      expect(after.totalStars, 25);
      expect(after.totalBadges, 2);
      expect(after.badges.length, 2);
    },
  );

  test(
    'simultaneous distinct awards are retained and repeated event callbacks count once',
    () async {
      final results = await Future.wait([
        for (var index = 0; index < 30; index++) _award('event-$index'),
        _award('event-0'),
        _award('event-0'),
      ]);
      expect(results.every((result) => result.success), isTrue);
      final rewards = await RewardsService.getRewards('child');
      expect(rewards.totalStars, 30);
      expect(rewards.totalBadges, 3);
      expect(rewards.badges.length, 3);
    },
  );

  for (final entry in {
    49: ChildLevel.tensBuilder,
    99: ChildLevel.hundredsHero,
    199: ChildLevel.thousandsChampion,
  }.entries) {
    test(
      'the star at threshold ${entry.key + 1} awards the expected level sticker',
      () async {
        SharedPreferences.setMockInitialValues({
          'rewards_child': jsonEncode(_summary(stars: entry.key).toJson()),
        });
        final result = await _award('threshold');
        expect(result.success, isTrue);
        expect(result.levelUp, isTrue);
        expect(result.rewards!.currentLevel, entry.value);
        expect(result.newSticker!.level, entry.value);
        expect(
          (await RewardsService.getRewards('child')).stickers.single.level,
          entry.value,
        );
        final duplicate = await _award('threshold');
        expect(duplicate.levelUp, isFalse);
        expect(
          (await RewardsService.getRewards('child')).totalStars,
          entry.key + 1,
        );
      },
    );
  }

  test(
    'migrated high star totals choose the highest eligible level in one award',
    () async {
      SharedPreferences.setMockInitialValues({
        'rewards_child': jsonEncode(_summary(stars: 250).toJson()),
      });
      final result = await _award('migrated');
      expect(result.rewards!.currentLevel, ChildLevel.thousandsChampion);
      expect(result.newSticker!.level, ChildLevel.thousandsChampion);
      expect(result.rewards!.nextLevel, isNull);
      expect(result.rewards!.starsToNextLevel, 0);
      expect(result.rewards!.levelProgress, 1.0);
      expect(
        (await RewardsService.getRewards('child')).currentLevel,
        ChildLevel.thousandsChampion,
      );
    },
  );

  test(
    'legacy separate badge and sticker data are recovered and saved in the summary',
    () async {
      final badge = Badge(
        id: 'legacy-badge',
        name: 'Collector',
        emoji: '🏅',
        description: 'Ten stars',
        requiredStars: 10,
        earnedAt: DateTime(2025),
      );
      final sticker = Sticker(
        id: 'legacy-sticker',
        name: 'Tens',
        emoji: '🏗️',
        description: 'Tens Builder',
        level: ChildLevel.tensBuilder,
        earnedAt: DateTime(2025),
      );
      SharedPreferences.setMockInitialValues({
        'rewards_child': jsonEncode(
          _summary(
            stars: 50,
            level: ChildLevel.tensBuilder,
            badges: 1,
            stickers: 1,
          ).toJson(),
        ),
        'badges_child': jsonEncode([badge.toJson()]),
        'stickers_child': jsonEncode([sticker.toJson()]),
      });
      final recovered = await RewardsService.getRewards('child');
      expect(recovered.badges.single.id, badge.id);
      expect(recovered.stickers.single.id, sticker.id);
      await _award('after-migration');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('badges_child');
      await prefs.remove('stickers_child');
      final reopened = await RewardsService.getRewards('child');
      expect(reopened.badges.single.id, badge.id);
      expect(reopened.stickers.single.id, sticker.id);
    },
  );

  test(
    'reset clears only the chosen child and allows its event ids to be reused',
    () async {
      await _award('same-event');
      await _award('same-event', child: 'other');
      await RewardsService.resetRewards('child');
      expect((await RewardsService.getRewards('child')).totalStars, 0);
      expect((await RewardsService.getRewards('other')).totalStars, 1);
      await _award('same-event');
      expect((await RewardsService.getRewards('child')).totalStars, 1);
    },
  );

  test(
    'reset queued after an award leaves that child with reset rewards',
    () async {
      final award = _award('concurrent-event');
      final reset = RewardsService.resetRewards('child');
      await award;
      await reset;
      expect((await RewardsService.getRewards('child')).totalStars, 0);
    },
  );
}
