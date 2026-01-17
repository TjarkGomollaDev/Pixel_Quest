part of 'package:pixel_adventure/data/audio/audio_center.dart';

enum Sfx {
  appearing('appearing'),
  disappearing('disappearing'),
  enemieHit('enemie-hit'),
  enemieWallHit('enemie-wall-hit'),
  enemieShot('enemie-shot'),
  playerHit('player-hit'),
  playerDeath('player-death'),
  jetFlame('jet-flame'),
  collected('collected'),
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

enum LoopSfx {
  saw('saw'),
  fire('fire');

  // path
  static const String _basePath = 'loop-effects/';
  static const String _pathEnd = '.m4a';
  String get path => _basePath + fileName + _pathEnd;

  final String fileName;
  const LoopSfx(this.fileName);
}

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

enum SoundState {
  on,
  off;

  bool get enabled => this == SoundState.on;
  static const SoundState defaultState = SoundState.off;
  static SoundState fromName(String name) => SoundState.values.firstWhere((s) => s.name == name, orElse: () => defaultState);
}

enum SfxType { ui, game, level, player }
