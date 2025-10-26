import 'dart:convert';
import 'package:flutter/services.dart';

class WorldMetadata {
  final String uuid;
  final List<String> levelUuids;
  final int index;
  final String foreGroundFileName;
  final String titleFileName;

  const WorldMetadata._({
    required this.uuid,
    required this.levelUuids,
    required this.index,
    required this.foreGroundFileName,
    required this.titleFileName,
  });

  factory WorldMetadata._fromMap(Map<String, dynamic> map, int index) {
    return WorldMetadata._(
      uuid: map['uuid'] as String,
      levelUuids: List<String>.from(map['levelUuids']),
      index: index,
      foreGroundFileName: map['foreGroundFileName'] as String,
      titleFileName: map['titleFileName'] as String,
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
