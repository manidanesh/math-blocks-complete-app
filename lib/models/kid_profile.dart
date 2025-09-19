class KidProfile {
  final String id;
  final String name;
  final int age;
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
    required this.age,
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
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
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

  factory KidProfile.fromJson(Map<String, dynamic> json) {
    return KidProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      avatarId: json['avatarId'] as String,
      language: json['language'] as String? ?? 'en',
      isCurrent: json['isCurrent'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastPlayed: DateTime.parse(json['lastPlayed'] as String),
      totalStars: json['totalStars'] as int? ?? 0,
      totalProblemsCompleted: json['totalProblemsCompleted'] as int? ?? 0,
      overallAccuracy: json['overallAccuracy'] as double? ?? 0.0,
      favoriteNumbers: (json['favoriteNumbers'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      preferredOperation: json['preferredOperation'] as String? ?? 'both',
    );
  }

  KidProfile copyWith({
    String? id,
    String? name,
    int? age,
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
      age: age ?? this.age,
      avatarId: avatarId ?? this.avatarId,
      language: language ?? this.language,
      isCurrent: isCurrent ?? this.isCurrent,
      createdAt: createdAt ?? this.createdAt,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      totalStars: totalStars ?? this.totalStars,
      totalProblemsCompleted: totalProblemsCompleted ?? this.totalProblemsCompleted,
      overallAccuracy: overallAccuracy ?? this.overallAccuracy,
      favoriteNumbers: favoriteNumbers ?? this.favoriteNumbers,
      preferredOperation: preferredOperation ?? this.preferredOperation,
    );
  }

  @override
  String toString() {
    return 'KidProfile(id: $id, name: $name, age: $age, language: $language, stars: $totalStars)';
  }
}

