import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:pixel_quest/game/background/background.dart';
import 'package:pixel_quest/game/hud/mini%20map/mini_map_helper.dart';

class WorldMetadata {
  final String uuid;
  final List<String> levelUuids;
  final int index;
  final String titleFileName;
  final String foregroundFileName;
  final String miniMapFrameFileName;
  final BackgroundScene backgroundScene;
  final LevelBaseBlock baseBlock;

  const WorldMetadata._({
    required this.uuid,
    required this.levelUuids,
    required this.index,
    required this.titleFileName,
    required this.foregroundFileName,
    required this.miniMapFrameFileName,
    required this.backgroundScene,
    required this.baseBlock,
  });

  factory WorldMetadata._fromMap(Map<String, dynamic> map, int index) {
    return WorldMetadata._(
      uuid: map['uuid'] as String,
      levelUuids: List<String>.from(map['levelUuids']),
      index: index,
      titleFileName: map['titleFileName'] as String,
      foregroundFileName: map['foregroundFileName'] as String,
      miniMapFrameFileName: map['miniMapFrameFileName'] as String,
      backgroundScene: BackgroundScene.fromName(map['backgroundScene'] as String)!,
      baseBlock: LevelBaseBlock.fromName(map['baseBlock'] as String),
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
  WorldMetadata worldById(String worldUuid) => (firstWhere((level) => level.uuid == worldUuid, orElse: () => this[0]));

  int indexById(String worldUuid) {
    final index = indexWhere((world) => world.uuid == worldUuid);
    return index == -1 ? 0 : index;
  }
}
