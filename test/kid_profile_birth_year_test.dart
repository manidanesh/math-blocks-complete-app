import 'package:flutter_test/flutter_test.dart';
import 'package:number_bond_math/models/kid_profile.dart';

KidProfile _profile({
  int? birthYear = 2020,
  int? age,
  DateTime Function()? now,
}) => KidProfile(
  id: 'child-1',
  name: 'Ari',
  birthYear: birthYear,
  age: age,
  avatarId: 'fox',
  language: 'fr',
  isCurrent: true,
  createdAt: DateTime(2024, 5, 12),
  lastPlayed: DateTime(2026, 9, 20),
  totalStars: 42,
  totalProblemsCompleted: 73,
  overallAccuracy: 0.85,
  favoriteNumbers: const [3, 8],
  preferredOperation: 'subtraction',
  now: now,
);

Map<String, dynamic> _storedProfile({
  Object? birthYear = 2020,
  Object? age = 99,
  Object? overallAccuracy = 0.85,
}) => {
  'id': 'child-1',
  'name': 'Ari',
  'birthYear': birthYear,
  'age': age,
  'avatarId': 'fox',
  'language': 'fr',
  'isCurrent': true,
  'createdAt': '2024-05-12T00:00:00.000',
  'lastPlayed': '2026-09-20T00:00:00.000',
  'totalStars': 42,
  'totalProblemsCompleted': 73,
  'overallAccuracy': overallAccuracy,
  'favoriteNumbers': [3, 8],
  'preferredOperation': 'subtraction',
};

void _expectIdentityAndPreferences(KidProfile profile) {
  expect(profile.id, 'child-1');
  expect(profile.name, 'Ari');
  expect(profile.avatarId, 'fox');
  expect(profile.language, 'fr');
  expect(profile.isCurrent, isTrue);
  expect(profile.createdAt, DateTime(2024, 5, 12));
  expect(profile.lastPlayed, DateTime(2026, 9, 20));
  expect(profile.favoriteNumbers, [3, 8]);
  expect(profile.preferredOperation, 'subtraction');
}

void _expectProgress(KidProfile profile) {
  expect(profile.totalStars, 42);
  expect(profile.totalProblemsCompleted, 73);
  expect(profile.overallAccuracy, 0.85);
}

void main() {
  group('age derived from birth year', () {
    test('a 2020 birth year gives six in 2026 and seven in 2027', () {
      final profile = _profile();
      expect(profile.hasBirthYear, isTrue);
      expect(profile.ageOn(DateTime(2026, 1, 1)), 6);
      expect(profile.ageOn(DateTime(2026, 12, 31, 23, 59)), 6);
      expect(profile.ageOn(DateTime(2027, 1, 1)), 7);
    });

    test('age changes with the calendar year rather than month or day', () {
      final profile = _profile();
      for (var month = 1; month <= 12; month++) {
        expect(profile.ageOn(DateTime(2026, month, 15)), 6);
      }
      expect(profile.ageOn(DateTime(2027, 1, 1)), 7);
    });

    test('many elapsed years do not freeze or cap age at the child range', () {
      final profile = _profile();
      expect(profile.ageOn(DateTime(2040)), 20);
      expect(profile.ageOn(DateTime(2060)), 40);
    });

    test('dates before the birth year never produce a negative age', () {
      final profile = _profile();
      expect(profile.ageOn(DateTime(2019, 12, 31)), 0);
      expect(profile.ageOn(DateTime(2020, 1, 1)), 0);
    });

    test('the getter recalculates when the injected clock crosses a year', () {
      var current = DateTime(2026, 12, 31, 23, 59);
      final profile = _profile(now: () => current);
      expect(profile.age, 6);
      current = DateTime(2027, 1, 1);
      expect(profile.age, 7);
      current = DateTime(2030, 1, 1);
      expect(profile.age, 10);
    });
  });

  group('stored profile compatibility', () {
    test('a valid birth year overrides an outdated stored age', () {
      final profile = KidProfile.fromJson(
        _storedProfile(age: 99),
        now: () => DateTime(2026, 10, 10),
      );
      expect(profile.birthYear, 2020);
      expect(profile.age, 6);
      expect(profile.toJson()['age'], 6);
      _expectIdentityAndPreferences(profile);
      _expectProgress(profile);
    });

    test('legacy age stays stable until a birth year is supplied', () {
      final json = _storedProfile(age: 6)..remove('birthYear');
      final profile = KidProfile.fromJson(
        json,
        now: () => DateTime(2026, 10, 10),
      );
      expect(profile.hasBirthYear, isFalse);
      expect(profile.birthYear, isNull);
      expect(profile.ageOn(DateTime(2026)), 6);
      expect(profile.ageOn(DateTime(2050)), 6);
      expect(profile.toJson()['birthYear'], isNull);
      _expectIdentityAndPreferences(profile);
      _expectProgress(profile);
    });

    test('a null stored birth year behaves like an absent year', () {
      final profile = KidProfile.fromJson(
        _storedProfile(birthYear: null, age: 7),
        now: () => DateTime(2026),
      );
      expect(profile.hasBirthYear, isFalse);
      expect(profile.age, 7);
      expect(profile.ageOn(DateTime(2030)), 7);
    });

    test('malformed, nonpositive, and future years retain the legacy age', () {
      for (final invalid in ['2020', 2020.5, true, 0, -1, 2027]) {
        final profile = KidProfile.fromJson(
          _storedProfile(birthYear: invalid, age: 6),
          now: () => DateTime(2026, 10, 10),
        );
        expect(profile.hasBirthYear, isFalse, reason: '$invalid');
        expect(profile.birthYear, isNull, reason: '$invalid');
        expect(profile.ageOn(DateTime(2027)), 6, reason: '$invalid');
        _expectProgress(profile);
      }
    });

    test('a profile with a birth year does not require a stored age', () {
      final json = _storedProfile()..remove('age');
      final profile = KidProfile.fromJson(json, now: () => DateTime(2026));
      expect(profile.age, 6);
      expect(profile.hasBirthYear, isTrue);
    });

    test('a valid birth year can replace a malformed saved age', () {
      final profile = KidProfile.fromJson(
        _storedProfile(age: 'six'),
        now: () => DateTime(2026),
      );
      expect(profile.age, 6);
      expect(profile.birthYear, 2020);
    });

    test(
      'invalid years without a usable legacy age are rejected explicitly',
      () {
        for (final invalid in [null, '2020', 2020.5, 0, -1, 2027]) {
          expect(
            () => KidProfile.fromJson(
              _storedProfile(birthYear: invalid, age: null),
              now: () => DateTime(2026),
            ),
            throwsFormatException,
            reason: '$invalid',
          );
        }
      },
    );

    test('integer and double JSON accuracy values remain compatible', () {
      for (final accuracy in [0, 1, 0.85]) {
        final profile = KidProfile.fromJson(
          _storedProfile(overallAccuracy: accuracy),
          now: () => DateTime(2026),
        );
        expect(profile.overallAccuracy, accuracy.toDouble());
      }
      final missing = _storedProfile()..remove('overallAccuracy');
      expect(KidProfile.fromJson(missing).overallAccuracy, 0.0);
    });

    test(
      'round-tripping into another year retains birth year and progress',
      () {
        final first = _profile(now: () => DateTime(2026));
        final stored = first.toJson();
        final later = KidProfile.fromJson(stored, now: () => DateTime(2027));
        expect(stored['birthYear'], 2020);
        expect(stored['age'], 6);
        expect(later.birthYear, 2020);
        expect(later.age, 7);
        _expectIdentityAndPreferences(later);
        _expectProgress(later);
      },
    );
  });

  group('profile changes preserve the year', () {
    test('confirming a legacy birth year retains all saved learning data', () {
      final legacy = _profile(
        birthYear: null,
        age: 6,
        now: () => DateTime(2026),
      );
      final updated = legacy.copyWith(birthYear: 2020);
      expect(updated.hasBirthYear, isTrue);
      expect(updated.ageOn(DateTime(2027)), 7);
      _expectIdentityAndPreferences(updated);
      _expectProgress(updated);
    });

    test('changing another field preserves the birth year and age rule', () {
      final profile = _profile(now: () => DateTime(2026));
      final updated = profile.copyWith(name: 'Mira', language: 'es');
      expect(updated.birthYear, 2020);
      expect(updated.ageOn(DateTime(2027)), 7);
      expect(updated.name, 'Mira');
      expect(updated.language, 'es');
      _expectProgress(updated);
    });

    test('an age copy cannot override an existing confirmed birth year', () {
      final profile = _profile(now: () => DateTime(2026));
      final updated = profile.copyWith(age: 99);
      expect(updated.birthYear, 2020);
      expect(updated.age, 6);
      expect(updated.ageOn(DateTime(2027)), 7);
    });

    test('legacy age can still be changed without guessing a birth year', () {
      final legacy = _profile(birthYear: null, age: 6);
      final updated = legacy.copyWith(age: 7);
      expect(updated.birthYear, isNull);
      expect(updated.hasBirthYear, isFalse);
      expect(updated.ageOn(DateTime(2050)), 7);
    });

    test(
      'resetting progress preserves identity, preferences, and birth year',
      () {
        final profile = _profile(now: () => DateTime(2026));
        final reset = profile.copyWith(
          totalStars: 0,
          totalProblemsCompleted: 0,
          overallAccuracy: 0.0,
        );
        expect(reset.birthYear, 2020);
        expect(reset.ageOn(DateTime(2027)), 7);
        expect(reset.totalStars, 0);
        expect(reset.totalProblemsCompleted, 0);
        expect(reset.overallAccuracy, 0.0);
        _expectIdentityAndPreferences(reset);
      },
    );

    test('copying preserves the dynamic clock without serializing it', () {
      var current = DateTime(2026);
      final original = _profile(now: () => current);
      final copied = original.copyWith(totalStars: 43);
      expect(copied.age, 6);
      current = DateTime(2027);
      expect(copied.age, 7);
      expect(copied.toJson().containsKey('now'), isFalse);
      expect(copied.toJson().containsKey('_now'), isFalse);
    });
  });
}
