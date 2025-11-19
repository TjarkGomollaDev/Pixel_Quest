import 'package:pixel_adventure/game/hud/entity_on_mini_map.dart';
import 'package:pixel_adventure/game/level/player.dart';

class SettingsEntity {
  final bool soundsEnabled;
  final PlayerCharacter character;
  final PlayerMiniMapMarkerType playerMarker;
  final int worldSkin;

  const SettingsEntity({required this.soundsEnabled, required this.character, required this.playerMarker, required this.worldSkin});

  SettingsEntity.defaultSettings()
    : this(
        soundsEnabled: true,
        character: PlayerCharacter.defaultCharacter,
        playerMarker: PlayerMiniMapMarkerType.defaultMarker,
        worldSkin: 1,
      );

  Map<String, dynamic> toMap() => {
    'soundsEnabled': soundsEnabled,
    'character': character.name,
    'playerMarker': playerMarker.name,
    'worldSkin': worldSkin,
  };

  factory SettingsEntity.fromMap(Map<String, dynamic> map) {
    return SettingsEntity(
      soundsEnabled: map['soundsEnabled'] as bool,
      character: PlayerCharacter.fromName(map['character'] as String),
      playerMarker: PlayerMiniMapMarkerType.fromName(map['playerMarker'] as String),
      worldSkin: map['worldSkin'] as int,
    );
  }

  SettingsEntity copyWith({bool? soundsEnabled, PlayerCharacter? character, PlayerMiniMapMarkerType? playerMarker, int? worldSkin}) {
    return SettingsEntity(
      soundsEnabled: soundsEnabled ?? this.soundsEnabled,
      character: character ?? this.character,
      playerMarker: playerMarker ?? this.playerMarker,
      worldSkin: worldSkin ?? this.worldSkin,
    );
  }
}
