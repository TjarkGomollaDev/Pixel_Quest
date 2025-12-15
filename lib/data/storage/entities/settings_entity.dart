import 'package:pixel_adventure/data/audio/audio_center.dart';
import 'package:pixel_adventure/game/hud/entity_on_mini_map.dart';
import 'package:pixel_adventure/game/level/player.dart';

double _clamp01(double value) => value.toDouble().clamp(0.0, 1.0);

class SettingsEntity {
  final SoundState soundState;
  final double sfxVolume;
  final double musicVolume;
  final PlayerCharacter character;
  final PlayerMiniMapMarkerType playerMarker;
  final int worldSkin;

  const SettingsEntity({
    required this.soundState,
    required this.sfxVolume,
    required this.musicVolume,
    required this.character,
    required this.playerMarker,
    required this.worldSkin,
  });

  SettingsEntity.defaultSettings()
    : this(
        soundState: SoundState.defaultState,
        sfxVolume: 1,
        musicVolume: 0.2,
        character: PlayerCharacter.defaultCharacter,
        playerMarker: PlayerMiniMapMarkerType.defaultMarker,
        worldSkin: 1,
      );

  Map<String, dynamic> toMap() => {
    'soundState': soundState.name,
    'sfxVolume': sfxVolume,
    'musicVolume': musicVolume,
    'character': character.name,
    'playerMarker': playerMarker.name,
    'worldSkin': worldSkin,
  };

  factory SettingsEntity.fromMap(Map<String, dynamic> map) {
    return SettingsEntity(
      soundState: SoundState.fromName(map['soundState'] as String),
      sfxVolume: map['sfxVolume'] as double,
      musicVolume: map['musicVolume'] as double,
      character: PlayerCharacter.fromName(map['character'] as String),
      playerMarker: PlayerMiniMapMarkerType.fromName(map['playerMarker'] as String),
      worldSkin: map['worldSkin'] as int,
    );
  }

  SettingsEntity copyWith({
    SoundState? soundState,
    double? sfxVolume,
    double? musicVolume,
    PlayerCharacter? character,
    PlayerMiniMapMarkerType? playerMarker,
    int? worldSkin,
  }) {
    return SettingsEntity(
      soundState: soundState ?? this.soundState,
      sfxVolume: sfxVolume != null ? _clamp01(sfxVolume) : this.sfxVolume,
      musicVolume: musicVolume != null ? _clamp01(musicVolume) : this.musicVolume,
      character: character ?? this.character,
      playerMarker: playerMarker ?? this.playerMarker,
      worldSkin: worldSkin ?? this.worldSkin,
    );
  }
}
