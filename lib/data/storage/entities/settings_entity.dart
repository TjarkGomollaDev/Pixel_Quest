import 'package:pixel_adventure/data/audio/audio_center.dart';
import 'package:pixel_adventure/game/level/mobile%20controls/mobile_controls.dart';

double _clamp01(double value) => value.toDouble().clamp(0, 1);

class SettingsEntity {
  // constructor parameters
  final SoundState soundState;
  final double sfxVolume;
  final double musicVolume;
  final JoystickSetup joystickSetup;
  final bool showMiniMapAtStart;

  const SettingsEntity({
    required this.soundState,
    required this.sfxVolume,
    required this.musicVolume,
    required this.joystickSetup,
    required this.showMiniMapAtStart,
  });

  SettingsEntity.defaultSettings()
    : this(
        soundState: SoundState.defaultState,
        sfxVolume: 0.9,
        musicVolume: 0.2,
        joystickSetup: JoystickSetup.defaultSetup,
        showMiniMapAtStart: true,
      );

  Map<String, dynamic> toMap() => {
    'soundState': soundState.name,
    'sfxVolume': sfxVolume,
    'musicVolume': musicVolume,
    'joystickSetup': joystickSetup.name,
    'showMiniMapAtStart': showMiniMapAtStart,
  };

  factory SettingsEntity.fromMap(Map<String, dynamic> map) {
    return SettingsEntity(
      soundState: SoundState.fromName(map['soundState'] as String),
      sfxVolume: map['sfxVolume'] as double,
      musicVolume: map['musicVolume'] as double,
      joystickSetup: JoystickSetup.fromName(map['joystickSetup'] as String),
      showMiniMapAtStart: map['showMiniMapAtStart'] as bool,
    );
  }

  SettingsEntity copyWith({
    SoundState? soundState,
    double? sfxVolume,
    double? musicVolume,
    JoystickSetup? joystickSetup,
    bool? showMiniMapAtStart,
  }) {
    return SettingsEntity(
      soundState: soundState ?? this.soundState,
      sfxVolume: sfxVolume != null ? _clamp01(sfxVolume) : this.sfxVolume,
      musicVolume: musicVolume != null ? _clamp01(musicVolume) : this.musicVolume,
      joystickSetup: joystickSetup ?? this.joystickSetup,
      showMiniMapAtStart: showMiniMapAtStart ?? this.showMiniMapAtStart,
    );
  }
}
