import 'package:pixel_adventure/game/level/player.dart';

class SettingsEntity {
  final bool soundsEnabled;
  final PlayerCharacter playerCharacter;
  final int worldSkin;

  const SettingsEntity({required this.soundsEnabled, required this.playerCharacter, required this.worldSkin});

  SettingsEntity.defaultSettings() : this(soundsEnabled: true, playerCharacter: PlayerCharacter.getDefault(), worldSkin: 1);

  Map<String, dynamic> toMap() => {'soundsEnabled': soundsEnabled, 'playerCharacter': playerCharacter.name, 'worldSkin': worldSkin};

  factory SettingsEntity.fromMap(Map<String, dynamic> map) {
    return SettingsEntity(
      soundsEnabled: map['soundsEnabled'] as bool,
      playerCharacter: PlayerCharacter.fromName(map['playerCharacter'] as String),
      worldSkin: map['worldSkin'] as int,
    );
  }

  SettingsEntity copyWith({bool? soundsEnabled, PlayerCharacter? playerCharacter, int? worldSkin}) {
    return SettingsEntity(
      soundsEnabled: soundsEnabled ?? this.soundsEnabled,
      playerCharacter: playerCharacter ?? this.playerCharacter,
      worldSkin: worldSkin ?? this.worldSkin,
    );
  }
}
