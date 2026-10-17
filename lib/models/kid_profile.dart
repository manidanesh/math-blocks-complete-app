import 'entity.dart';

class KidProfile implements Entity {
  @override
  final String id;
  final String name;

  /// Birth year is the source of age for new and updated profiles.
  final int? birthYear;
  final int? _legacyAge;
  final DateTime Function()? _now;
  final String avatarId;
  final String language; // 'en', 'es', 'fr'
  final bool isCurrent;
  final DateTime createdAt;
  final DateTime lastPlayed;
  final int totalStars;
  final int totalProblemsCompleted;
  final double overallAccuracy;
  final List<int> favoriteNumbers;
  final String preferredOperation; // 'addition', 'subtraction', 'both'

  const KidProfile({
    required this.id,
    required this.name,
    int? age,
    this.birthYear,
    DateTime Function()? now,
    required this.avatarId,
    required this.language,
    required this.isCurrent,
    required this.createdAt,
    required this.lastPlayed,
    this.totalStars = 0,
    this.totalProblemsCompleted = 0,
    this.overallAccuracy = 0.0,
    this.favoriteNumbers = const [],
    this.preferredOperation = 'both',
  }) : assert(age != null || birthYear != null),
       assert(age == null || age >= 0),
       assert(birthYear == null || birthYear > 0),
       _legacyAge = age,
       _now = now;

  bool get hasBirthYear => birthYear != null;

  /// A year-only age changes on January 1; no birthday is inferred.
  int ageOn(DateTime date) {
    final year = birthYear;
    if (year == null) return _legacyAge!;
    final years = date.year - year;
    return years < 0 ? 0 : years;
  }

  int get age => ageOn(_now?.call() ?? DateTime.now());

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      if (birthYear != null) 'birthYear': birthYear,
      'avatarId': avatarId,
      'language': language,
      'isCurrent': isCurrent,
      'createdAt': createdAt.toIso8601String(),
      'lastPlayed': lastPlayed.toIso8601String(),
      'totalStars': totalStars,
      'totalProblemsCompleted': totalProblemsCompleted,
      'overallAccuracy': overallAccuracy,
      'favoriteNumbers': favoriteNumbers,
      'preferredOperation': preferredOperation,
    };
  }

  factory KidProfile.fromJson(
    Map<String, dynamic> json, {
    DateTime Function()? now,
  }) {
    final currentYear = (now?.call() ?? DateTime.now()).year;
    final storedYear = json['birthYear'];
    final birthYear =
        storedYear is int && storedYear > 0 && storedYear <= currentYear
        ? storedYear
        : null;
    final storedAge = json['age'];
    final legacyAge = storedAge is int && storedAge >= 0 ? storedAge : null;
    if (birthYear == null && legacyAge == null) {
      throw const FormatException('Profile needs a birth year or saved age.');
    }
    return KidProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      age: legacyAge,
      birthYear: birthYear,
      now: now,
      avatarId: json['avatarId'] as String,
      language: json['language'] as String? ?? 'en',
      isCurrent: json['isCurrent'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastPlayed: DateTime.parse(json['lastPlayed'] as String),
      totalStars: json['totalStars'] as int? ?? 0,
      totalProblemsCompleted: json['totalProblemsCompleted'] as int? ?? 0,
      overallAccuracy: (json['overallAccuracy'] as num?)?.toDouble() ?? 0.0,
      favoriteNumbers:
          (json['favoriteNumbers'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      preferredOperation: json['preferredOperation'] as String? ?? 'both',
    );
  }

  KidProfile copyWith({
    String? id,
    String? name,
    int? age,
    int? birthYear,
    DateTime Function()? now,
    String? avatarId,
    String? language,
    bool? isCurrent,
    DateTime? createdAt,
    DateTime? lastPlayed,
    int? totalStars,
    int? totalProblemsCompleted,
    double? overallAccuracy,
    List<int>? favoriteNumbers,
    String? preferredOperation,
  }) {
    return KidProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? _legacyAge,
      birthYear: birthYear ?? this.birthYear,
      now: now ?? _now,
      avatarId: avatarId ?? this.avatarId,
      language: language ?? this.language,
      isCurrent: isCurrent ?? this.isCurrent,
      createdAt: createdAt ?? this.createdAt,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      totalStars: totalStars ?? this.totalStars,
      totalProblemsCompleted:
          totalProblemsCompleted ?? this.totalProblemsCompleted,
      overallAccuracy: overallAccuracy ?? this.overallAccuracy,
      favoriteNumbers: favoriteNumbers ?? this.favoriteNumbers,
      preferredOperation: preferredOperation ?? this.preferredOperation,
    );
  }

  @override
  String toString() {
    return 'KidProfile(id: $id, name: $name, birthYear: $birthYear, age: $age, language: $language, stars: $totalStars)';
  }
}
