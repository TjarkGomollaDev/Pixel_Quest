import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:pixel_adventure/game/level/player.dart';

class CharacterMetadata {
  final String name;
  final String origin;
  final String ability;

  const CharacterMetadata._({required this.name, required this.origin, required this.ability});

  factory CharacterMetadata._fromMap(Map<String, dynamic> map) {
    return CharacterMetadata._(name: map['name'] as String, origin: map['origin'] as String, ability: map['ability'] as String);
  }

  static Future<Map<PlayerCharacter, CharacterMetadata>> loadFromJson(String path) async {
    final jsonString = await rootBundle.loadString(path);
    final List<dynamic> data = jsonDecode(jsonString);
    final Map<PlayerCharacter, CharacterMetadata> result = {};
    for (var item in data) {
      final map = item as Map<String, dynamic>;
      final keyString = map['key'] as String;
      final playerCharacter = PlayerCharacter.fromName(keyString);
      result[playerCharacter] = CharacterMetadata._fromMap(map);
    }
    return result;
  }
}
