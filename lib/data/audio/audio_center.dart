import 'package:flame_audio/flame_audio.dart';
import 'package:pixel_adventure/data/storage/storage_center.dart';
import 'package:pixel_adventure/game/utils/settings_notifier.dart';

enum SoundEffect {
  appearing('appearing'),
  disappearing('disappearing'),
  enemieHit('enemie-hit'),
  playerHit('player-hit'),
  playerDeath('player-death'),
  collected('collected'),
  star('star'),
  jumpBoost('jump-boost'),
  checkpoint('checkpoint'),
  finish('finish'),
  pressurePlate('pressure-plate'),
  jump('jump'),
  doubleJump('double-jump'),
  changeCharacter('change-character'),
  tap('tap');

  // path
  static const String _basePath = 'effects/';
  static const String _pathEnd = '.wav';
  String get path => _basePath + fileName + _pathEnd;

  final String fileName;
  const SoundEffect(this.fileName);
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
  static const SoundState defaultState = SoundState.on;
  static SoundState fromName(String name) => SoundState.values.firstWhere((s) => s.name == name, orElse: () => defaultState);
}

class AudioCenter {
  // constructor parameters
  final StorageCenter _storageCenter;

  AudioCenter._(this._storageCenter);

  // data
  late SoundState _soundState;
  late double _sfxVolume;
  late double _musicVolume;

  // getter
  SoundState get soundState => _soundState;
  double get sfxVolume => _sfxVolume;
  double get musicVolume => _musicVolume;
  double get _effectiveSfxVolume => _soundState.enabled ? _sfxVolume : 0;
  double get _effectiveMusicVolume => _soundState.enabled ? _musicVolume : 0;

  // audio pools for extremely quick firing, repetitive or simultaneous sounds
  final Map<SoundEffect, AudioPool> _pools = {};

  static Future<AudioCenter> init({required StorageCenter storageCenter}) async {
    final audioCenter = AudioCenter._(storageCenter);
    await audioCenter._loadData();
    await audioCenter._createPools();
    FlameAudio.bgm.initialize();
    return audioCenter;
  }

  Future<void> _loadData() async {
    final files = [...SoundEffect.values.map((s) => s.path), ...BackgroundMusic.values.map((m) => m.path)];
    await FlameAudio.audioCache.loadAll(files);
    _soundState = _storageCenter.settings.soundState;
    _sfxVolume = _storageCenter.settings.sfxVolume;
    _musicVolume = _storageCenter.settings.musicVolume;
  }

  Future<void> _createPools() async {
    _pools[SoundEffect.jump] = await FlameAudio.createPool(SoundEffect.jump.path, maxPlayers: 6);
    _pools[SoundEffect.doubleJump] = await FlameAudio.createPool(SoundEffect.doubleJump.path, maxPlayers: 4);
    _pools[SoundEffect.enemieHit] = await FlameAudio.createPool(SoundEffect.enemieHit.path, maxPlayers: 6);
    _pools[SoundEffect.collected] = await FlameAudio.createPool(SoundEffect.collected.path, maxPlayers: 8);
    _pools[SoundEffect.jumpBoost] = await FlameAudio.createPool(SoundEffect.jumpBoost.path, maxPlayers: 6);
    _pools[SoundEffect.pressurePlate] = await FlameAudio.createPool(SoundEffect.pressurePlate.path, maxPlayers: 8);
    _pools[SoundEffect.tap] = await FlameAudio.createPool(SoundEffect.tap.path, maxPlayers: 8);
  }

  Future<void> dispose() async {
    for (final pool in _pools.values) {
      await pool.dispose();
    }
    _pools.clear();

    await FlameAudio.bgm.dispose();
    await FlameAudio.audioCache.clearAll();
  }

  void playSound(SoundEffect sound) {
    if (_effectiveSfxVolume == 0) return;

    final pool = _pools[sound];
    if (pool != null) {
      pool.start();
    } else {
      FlameAudio.play(sound.path, volume: _sfxVolume);
    }
  }

  void playBackgroundMusic(BackgroundMusic music) => FlameAudio.bgm.play(music.path, volume: _effectiveMusicVolume);

  void stopBackgroundMusic() => FlameAudio.bgm.stop();

  Future<void> _applyBgmVolume() async {
    if (!FlameAudio.bgm.isPlaying) return;
    await FlameAudio.bgm.audioPlayer.setVolume(_effectiveMusicVolume);
  }

  Future<void> toggleSound(SoundState soundState) async {
    _soundState = soundState;

    // notify other sound btns
    SettingsNotifier.instance.notify(SettingsEvent.sound);

    // change bgm sound state
    await _applyBgmVolume();

    // update in storage center
    await _storageCenter.updateSettings(soundState: soundState);
  }

  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume;

    // no global sfx channel in FlameAudio, we apply per-play
    await _storageCenter.updateSettings(sfxVolume: _sfxVolume);
  }

  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume;

    // update current BGM volume without restarting
    await _applyBgmVolume();

    await _storageCenter.updateSettings(musicVolume: _musicVolume);
  }
}
