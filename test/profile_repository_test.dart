import 'package:flutter_test/flutter_test.dart';
import 'package:number_bond_math/models/kid_profile.dart';
import 'package:number_bond_math/repositories/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

KidProfile _profile(String id) => KidProfile(
  id: id,
  name: id,
  birthYear: 2019,
  avatarId: 'default',
  language: 'en',
  isCurrent: true,
  createdAt: DateTime(2026, 1, 1),
  lastPlayed: DateTime(2026, 1, 1),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'repository stores profiles and switches current without losing birth year',
    () async {
      final repository = ProfileRepository();
      await repository.createProfile(_profile('first'));
      await repository.createProfile(_profile('second'));
      expect((await ProfileRepository().getCurrentProfile())?.id, 'second');
      await repository.setCurrentProfile('first');
      expect((await repository.getCurrentProfile())?.birthYear, 2019);
      expect(
        (await repository.getAll())
            .where((profile) => profile.isCurrent)
            .length,
        1,
      );
      await repository.setCurrentProfile('missing');
      expect((await repository.getCurrentProfile())?.id, 'first');
    },
  );

  test('stats persist accuracy and reset only the target progress', () async {
    final repository = ProfileRepository();
    await repository.createProfile(_profile('first'));
    await repository.createProfile(_profile('second'));
    expect(
      await repository.updateProfileStats(
        profileId: 'first',
        additionalStars: 9,
        additionalProblems: 12,
        newAccuracy: 0.75,
      ),
      isTrue,
    );
    final saved = await ProfileRepository().findById('first');
    expect(saved?.totalStars, 9);
    expect(saved?.totalProblemsCompleted, 12);
    expect(saved?.overallAccuracy, 0.75);
    expect(await repository.resetProfileData('first'), isTrue);
    final reset = await repository.findById('first');
    expect(reset?.birthYear, 2019);
    expect(reset?.totalStars, 0);
    expect(reset?.overallAccuracy, 0);
    expect((await repository.getCurrentProfile())?.id, 'second');
    expect(await repository.updateProfileStats(profileId: 'missing'), isFalse);
  });

  test(
    'duplicate profile identities fail without changing the current profile',
    () async {
      final repository = ProfileRepository();
      await repository.createProfile(_profile('first'));
      await repository.createProfile(_profile('second'));
      await expectLater(
        repository.createProfile(_profile('first')),
        throwsArgumentError,
      );
      expect(await repository.count(), 2);
      expect((await repository.getCurrentProfile())?.id, 'second');
    },
  );
}
