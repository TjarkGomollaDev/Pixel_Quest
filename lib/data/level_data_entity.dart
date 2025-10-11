class LevelDataEntity {
  final int index;
  final int stars;
  final int totalFruits;
  final int earnedFruits;
  final int deaths;

  const LevelDataEntity({
    required this.index,
    required this.stars,
    required this.totalFruits,
    required this.earnedFruits,
    required this.deaths,
  });

  LevelDataEntity.newLevelData({required int index}) : this(index: index, stars: 0, totalFruits: 0, earnedFruits: 0, deaths: 0);

  Map<String, dynamic> toMap() => {'stars': stars, 'totalFruits': totalFruits, 'earnedFruits': earnedFruits, 'deaths': deaths};

  factory LevelDataEntity.fromMap(Map<String, dynamic> map, int index) {
    return LevelDataEntity(
      index: index,
      stars: map['stars'] as int,
      totalFruits: map['totalFruits'] as int,
      earnedFruits: map['earnedFruits'] as int,
      deaths: map['deaths'] as int,
    );
  }

  bool shouldReplace({required LevelDataEntity storedData}) {
    if (stars != storedData.stars) return stars > storedData.stars;
    if (earnedFruits != storedData.earnedFruits) return earnedFruits > storedData.earnedFruits;
    if (deaths != storedData.deaths) return deaths < storedData.deaths;
    return false;
  }
}
