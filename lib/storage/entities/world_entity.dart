class WorldEntity {
  final String uuid;
  final int stars;
  final bool locked;

  const WorldEntity({required this.uuid, required this.stars, required this.locked});

  WorldEntity.defaultWorld({required String uuid, bool locked = true}) : this(uuid: uuid, stars: 0, locked: locked);

  Map<String, dynamic> toMap() => {'stars': stars, 'locked': locked};

  factory WorldEntity.fromMap(Map<String, dynamic> map, String uuid) {
    return WorldEntity(uuid: uuid, stars: map['stars'] as int, locked: map['locked'] as bool);
  }

  WorldEntity copyWith({int? stars, bool? locked}) {
    return WorldEntity(uuid: uuid, stars: stars ?? this.stars, locked: locked ?? this.locked);
  }

  WorldEntity copyWithIncreasedStars(int newStars) {
    return WorldEntity(uuid: uuid, stars: stars + newStars, locked: locked);
  }
}
