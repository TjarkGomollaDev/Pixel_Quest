import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:pixel_adventure/game/level/background_szene.dart';

class WorldMetadata {
  final String uuid;
  final List<String> levelUuids;
  final int index;
  final String titleFileName;
  final String foregroundFileName;
  final Szene backgroundSzene;

  const WorldMetadata._({
    required this.uuid,
    required this.levelUuids,
    required this.index,
    required this.titleFileName,
    required this.foregroundFileName,
    required this.backgroundSzene,
  });

  factory WorldMetadata._fromMap(Map<String, dynamic> map, int index) {
    return WorldMetadata._(
      uuid: map['uuid'] as String,
      levelUuids: List<String>.from(map['levelUuids']),
      index: index,
      titleFileName: map['titleFileName'] as String,
      foregroundFileName: map['foregroundFileName'] as String,
      backgroundSzene: Szene.fromName(map['backgroundSzene'] as String),
    );
  }

  static Future<List<WorldMetadata>> loadFromJson(String path) async {
    final jsonString = await rootBundle.loadString(path);
    final List<dynamic> data = jsonDecode(jsonString);
    int index = 0;
    return data.map((e) => WorldMetadata._fromMap(e, index++)).toList();
  }
}

extension WorldMetadataLookup on List<WorldMetadata> {
  WorldMetadata getWorldByUUID(String uuid) => (firstWhere((level) => level.uuid == uuid, orElse: () => this[0]));

  int getIndexByUUID(String uuid) {
    final index = indexWhere((world) => world.uuid == uuid);
    return index == -1 ? 0 : index;
  }
}
