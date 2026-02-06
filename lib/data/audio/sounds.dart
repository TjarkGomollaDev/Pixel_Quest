part of 'package:pixel_quest/data/audio/audio_center.dart';

/// One-shot sound effects.
enum Sfx {
  appearing('appearing'),
  disappearing('disappearing'),
  enemieHit('enemie-hit'),
  enemieWallHit('enemie-wall-hit'),
  plantShot('plant-shot'),
  trunkShot('trunk-shot'),
  chicken('chicken'),
  playerHit('player-hit'),
  playerDeath('player-death'),
  jetFlame('jet-flame'),
  collected('collected'),
  fanSwitch('fan-switch'),
  star('star'),
  popIn('pop-in'),
  popOut('pop-out'),
  jumpBoost('jump-boost'),
  checkpoint('checkpoint'),
  finish('finish'),
  pressurePlate('pressure-plate'),
  jump('jump'),
  doubleJump('double-jump'),
  stompRock('stomp-rock'),
  changeCharacter('change-character'),
  tap('tap');

  // path
  static const String _basePath = 'effects/';
  static const String _pathEnd = '.wav';
  String get path => _basePath + fileName + _pathEnd;

  final String fileName;
  const Sfx(this.fileName);
}

/// Loopable sound effects.
enum LoopSfx {
  saw('saw'),
  bird('bird'),
  ghost('ghost'),
  slime('slime'),
  mushroom('mushroom'),
  fire('fire');

  // path
  static const String _basePath = 'loop-effects/';
  static const String _pathEnd = '.wav';
  String get path => _basePath + fileName + _pathEnd;

  final String fileName;
  const LoopSfx(this.fileName);
}

/// Background music tracks.
enum BackgroundMusic {
  menu('menu'),
  win('win'),
  game('game');

  // path
  static const String _basePath = 'music/';
  static const String _pathEnd = '.mp3';
  String get path => _basePath + fileName + _pathEnd;

  final String fileName;
  const BackgroundMusic(this.fileName);
}

/// Logical channel a sound effect belongs to.
enum SfxType { ui, game, level, player }

/// Global sound toggle state used across the game.
enum SoundState {
  on,
  off;

  bool get enabled => this == on;
  static const SoundState defaultState = on;
  static SoundState fromName(String name) => values.firstWhere((s) => s.name == name, orElse: () => defaultState);
}
