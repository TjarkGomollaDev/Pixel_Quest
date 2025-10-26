import 'package:pixel_adventure/game/level/player.dart';

class SettingsEntity {
  final bool soundsEnabled;
  final PlayerCharacter character;
  final int worldSkin;

  const SettingsEntity({required this.soundsEnabled, required this.character, required this.worldSkin});

  SettingsEntity.defaultSettings() : this(soundsEnabled: true, character: PlayerCharacter.getDefault(), worldSkin: 1);

  Map<String, dynamic> toMap() => {'soundsEnabled': soundsEnabled, 'character': character.name, 'worldSkin': worldSkin};

  factory SettingsEntity.fromMap(Map<String, dynamic> map) {
    return SettingsEntity(
      soundsEnabled: map['soundsEnabled'] as bool,
      character: PlayerCharacter.fromName(map['character'] as String),
      worldSkin: map['worldSkin'] as int,
    );
  }

  SettingsEntity copyWith({bool? soundsEnabled, PlayerCharacter? character, int? worldSkin}) {
    return SettingsEntity(
      soundsEnabled: soundsEnabled ?? this.soundsEnabled,
      character: character ?? this.character,
      worldSkin: worldSkin ?? this.worldSkin,
    );
  }
}
