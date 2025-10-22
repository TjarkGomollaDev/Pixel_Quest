class LevelEntity {
  final String uuid;
  final int stars;
  final int totalFruits;
  final int earnedFruits;
  final int deaths;

  const LevelEntity({required this.uuid, required this.stars, required this.totalFruits, required this.earnedFruits, required this.deaths});

  LevelEntity.defaultLevel({required String uuid}) : this(uuid: uuid, stars: 0, totalFruits: 0, earnedFruits: 0, deaths: 0);

  Map<String, dynamic> toMap() => {'stars': stars, 'totalFruits': totalFruits, 'earnedFruits': earnedFruits, 'deaths': deaths};

  factory LevelEntity.fromMap(Map<String, dynamic> map, String uuid) {
    return LevelEntity(
      uuid: uuid,
      stars: map['stars'] as int,
      totalFruits: map['totalFruits'] as int,
      earnedFruits: map['earnedFruits'] as int,
      deaths: map['deaths'] as int,
    );
  }

  LevelEntity copyWith({int? stars, int? totalFruits, int? earnedFruits, int? deaths}) {
    return LevelEntity(
      uuid: uuid,
      stars: stars ?? this.stars,
      totalFruits: totalFruits ?? this.totalFruits,
      earnedFruits: earnedFruits ?? this.earnedFruits,
      deaths: deaths ?? this.deaths,
    );
  }

  bool shouldReplace(LevelEntity storedData) {
    if (stars != storedData.stars) return stars > storedData.stars;
    if (earnedFruits != storedData.earnedFruits) return earnedFruits > storedData.earnedFruits;
    if (deaths != storedData.deaths) return deaths < storedData.deaths;
    return false;
  }

  int starDifference(LevelEntity storedData) => stars > storedData.stars ? stars - storedData.stars : 0;
}
