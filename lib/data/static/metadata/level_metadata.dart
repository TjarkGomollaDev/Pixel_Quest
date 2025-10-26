import 'dart:convert';
import 'package:flutter/services.dart';

class LevelMetadata {
  final String uuid;
  final String worldUuid;
  final int number;
  final String tmxFileName;
  final String btnFileName;

  const LevelMetadata._({
    required this.uuid,
    required this.worldUuid,
    required this.number,
    required this.tmxFileName,
    required this.btnFileName,
  });

  factory LevelMetadata._fromMap(Map<String, dynamic> map, String worldUuid, int number) {
    return LevelMetadata._(
      uuid: map['uuid'] as String,
      worldUuid: worldUuid,
      number: number,
      tmxFileName: map['tmxFileName'] as String,
      btnFileName: map['btnFileName'] as String,
    );
  }

  static Future<Map<String, List<LevelMetadata>>> loadFromJson(String path) async {
    final jsonString = await rootBundle.loadString(path);
    final List<dynamic> data = jsonDecode(jsonString);
    final Map<String, List<LevelMetadata>> allLevels = {};

    for (final world in data) {
      final worldUuid = world['worldUuid'] as String;
      final levels = world['levels'] as List<dynamic>;
      int number = 1;
      allLevels[worldUuid] = levels
          .map((levelMap) => LevelMetadata._fromMap(levelMap as Map<String, dynamic>, worldUuid, number++))
          .toList();
    }

    return allLevels;
  }
}

extension LevelMetadataListLookup on List<LevelMetadata> {
  LevelMetadata getLevelByNumber(int number) =>
      firstWhere((level) => level.number == number, orElse: () => firstWhere((level) => level.number == 1));

  LevelMetadata getLevelByUUID(String uuid) =>
      firstWhere((level) => level.uuid == uuid, orElse: () => firstWhere((level) => level.number == 1));
}

extension LevelMetadataMapLookup on Map<String, List<LevelMetadata>> {
  Iterable<LevelMetadata> flat() sync* {
    for (var levels in values) {
      yield* levels;
    }
  }
}
