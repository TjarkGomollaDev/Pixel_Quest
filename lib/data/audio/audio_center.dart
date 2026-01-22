import 'dart:async';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/data/storage/storage_center.dart';
part 'package:pixel_adventure/data/audio/sounds.dart';

class AudioCenter {
  // constructor parameters
  final StorageCenter _storageCenter;

  AudioCenter._(this._storageCenter);

  static Future<AudioCenter> init({required StorageCenter storageCenter}) async {
    final audioCenter = AudioCenter._(storageCenter);
    await audioCenter._loadData();
    await audioCenter._createPools();
    await FlameAudio.bgm.initialize();
    return audioCenter;
  }

  // sound
  late SoundState _soundState;
  late double _sfxVolume;
  late double _musicVolume;

  // getter
  SoundState get soundState => _soundState;
  double get sfxVolume => _sfxVolume;
  double get musicVolume => _musicVolume;
  double get effectiveSfxVolume => _soundState.enabled ? _sfxVolume : 0;
  double get effectiveMusicVolume => _soundState.enabled ? _musicVolume : 0;

  // audio pools for extremely quick firing, repetitive or simultaneous sounds
  final Map<Sfx, AudioPool> _pools = {};

  // audio players for loop sounds
  final Map<LoopSfx, AudioPlayer> _loopPlayers = {};

  // loop sounds are loaded lazy, these variables track which ones have already been loaded or are in process
  final Set<LoopSfx> _loadedLoopSfx = {};
  final Map<LoopSfx, Future<void>> _loopLoadInFlight = {};

  // fade configs for loop sounds
  static const Duration _loopFadeInDuration = Duration(milliseconds: 450);
  static const Duration _loopFadeOutDuration = Duration(milliseconds: 550);
  static const int _loopSteps = 30;

  // track current loop volumes
  final Map<LoopSfx, double> _loopVolumes = {};

  // fade cancellation tokens per loop
  final Map<LoopSfx, int> _loopFadeToken = {};
  int _nextFadeToken(LoopSfx loop) => (_loopFadeToken[loop] = (_loopFadeToken[loop] ?? 0) + 1);

  // serializes operations per loop, prevents races between start and stop
  final Map<LoopSfx, Future<void>> _loopOpChain = {};

  // token to invalidate all queued/in-flight loop ops
  int _loopGlobalToken = 0;
  void _bumpLoopGlobalToken() => ++_loopGlobalToken;

  // this is used to decide whether a loop should continue playing or be disposed
  // after asynchronous operations (loading/creating/fading) complete,
  // if a fade-out is running and the loop becomes desired again, we cancel disposal and fade back in instead
  final Map<LoopSfx, bool> _loopDesired = {};
  bool _wantLoop(LoopSfx loop) => _loopDesired[loop] ?? false;

  // the game sounds in the sfx channel should be muted during the start and end animations
  bool _gameSfxMuted = true;
  bool get gameSfxMuted => _gameSfxMuted;

  // the token is used to force all emitters to trigger a sync event after a sound state change
  // or after unmuting game SFX, in order to re-register as an active source if necessary
  int _ambientSyncToken = 0;
  int get ambientSyncToken => _ambientSyncToken;
  void _bumpAmbientSyncToken() => _ambientSyncToken++;

  // all listeners are informed that all ambient loops have been removed
  final List<VoidCallback> _ambientResetListeners = [];
  void addAmbientResetListener(VoidCallback listener) => _ambientResetListeners.add(listener);
  void removeAmbientResetListener(VoidCallback listener) => _ambientResetListeners.remove(listener);

  void _notifyAmbientReset() {
    for (final listener in List.of(_ambientResetListeners)) {
      listener();
    }
  }

  Future<void> _loadData() async {
    final files = [...Sfx.values.map((s) => s.path), ...BackgroundMusic.values.map((m) => m.path)];
    await FlameAudio.audioCache.loadAll(files);
    _soundState = _storageCenter.settings.soundState;
    _sfxVolume = _storageCenter.settings.sfxVolume;
    _musicVolume = _storageCenter.settings.musicVolume;
  }

  Future<void> _createPools() async {
    _pools[Sfx.jump] = await FlameAudio.createPool(Sfx.jump.path, maxPlayers: 6);
    _pools[Sfx.doubleJump] = await FlameAudio.createPool(Sfx.doubleJump.path, maxPlayers: 4);
    _pools[Sfx.popIn] = await FlameAudio.createPool(Sfx.popIn.path, maxPlayers: 4);
    _pools[Sfx.popOut] = await FlameAudio.createPool(Sfx.popOut.path, maxPlayers: 4);
    _pools[Sfx.enemieHit] = await FlameAudio.createPool(Sfx.enemieHit.path, maxPlayers: 6);
    _pools[Sfx.enemieWallHit] = await FlameAudio.createPool(Sfx.enemieWallHit.path, maxPlayers: 8);
    _pools[Sfx.enemieShot] = await FlameAudio.createPool(Sfx.enemieShot.path, maxPlayers: 8);
    _pools[Sfx.collected] = await FlameAudio.createPool(Sfx.collected.path, maxPlayers: 8);
    _pools[Sfx.jumpBoost] = await FlameAudio.createPool(Sfx.jumpBoost.path, maxPlayers: 6);
    _pools[Sfx.pressurePlate] = await FlameAudio.createPool(Sfx.pressurePlate.path, maxPlayers: 8);
    _pools[Sfx.stompRock] = await FlameAudio.createPool(Sfx.stompRock.path, maxPlayers: 8);
    _pools[Sfx.tap] = await FlameAudio.createPool(Sfx.tap.path, maxPlayers: 8);
    _pools[Sfx.jetFlame] = await FlameAudio.createPool(Sfx.jetFlame.path, maxPlayers: 10);
  }

  Future<void> _ensureLoopLoaded(LoopSfx loop) async {
    if (_loadedLoopSfx.contains(loop)) return;

    // check whether the loop is already loading
    final inFlight = _loopLoadInFlight[loop];
    if (inFlight != null) {
      await inFlight;
      return;
    }

    // if not, load the loop into the cache
    final future = FlameAudio.audioCache.load(loop.path);
    _loopLoadInFlight[loop] = future;
    try {
      await future;
      _loadedLoopSfx.add(loop);
    } finally {
      _loopLoadInFlight.remove(loop);
    }
  }

  Future<void> dispose() async {
    // kill everything loop-related
    await stopAllLoops(resetSources: false);

    // dispose pools
    for (final pool in _pools.values) {
      await pool.dispose();
    }
    _pools.clear();

    // dispose BGM and clear cache
    await FlameAudio.bgm.dispose();
    await FlameAudio.audioCache.clearAll();

    // clear internal bookkeeping
    _loadedLoopSfx.clear();
    _loopLoadInFlight.clear();
    _loopVolumes.clear();
    _loopFadeToken.clear();
    _loopOpChain.clear();
    _loopDesired.clear();
  }

  void playSound(Sfx sound, SfxType type) {
    if (effectiveSfxVolume == 0) return;
    if (type == SfxType.game && _gameSfxMuted) return;

    final pool = _pools[sound];
    if (pool != null) {
      pool.start(volume: _sfxVolume);
    } else {
      FlameAudio.play(sound.path, volume: _sfxVolume);
    }
  }

  void playSoundIf(Sfx sound, bool guard, SfxType type) {
    if (!guard) return;
    playSound(sound, type);
  }

  bool isLoopPlaying(LoopSfx loop) => _loopPlayers.containsKey(loop);

  Future<void> _enqueueLoopOp(LoopSfx loop, Future<void> Function(int token) op) {
    final prev = _loopOpChain[loop] ?? Future<void>.value();
    final tokenAtEnqueue = _loopGlobalToken;

    final next = prev
        .then((_) async {
          if (tokenAtEnqueue != _loopGlobalToken) return;
          await op(tokenAtEnqueue);
        })
        .catchError((_) {});

    _loopOpChain[loop] = next;
    return next;
  }

  Future<void> _raiseExistingNow(LoopSfx loop, bool fadeIn) async {
    final player = _loopPlayers[loop];
    if (player == null) return;

    if (fadeIn) {
      await _fadeLoopTo(loop, _sfxVolume, _loopFadeInDuration);
    } else {
      _nextFadeToken(loop);
      _loopVolumes[loop] = _sfxVolume;
      await player.setVolume(_sfxVolume);
    }
  }

  Future<void> startLoop(LoopSfx loop, {bool fadeIn = false}) async {
    _loopDesired[loop] = true;

    if (effectiveSfxVolume == 0 || _gameSfxMuted) return;
    if (isLoopPlaying(loop)) return await _raiseExistingNow(loop, fadeIn);

    return _enqueueLoopOp(loop, (token) async {
      if (token != _loopGlobalToken || !_wantLoop(loop) || effectiveSfxVolume == 0 || _gameSfxMuted) return;
      if (isLoopPlaying(loop)) return await _raiseExistingNow(loop, fadeIn);

      // lazy loading
      await _ensureLoopLoaded(loop);

      // re-check if something happened during previous await
      if (token != _loopGlobalToken || !_wantLoop(loop) || effectiveSfxVolume == 0 || _gameSfxMuted) return;
      if (isLoopPlaying(loop)) return await _raiseExistingNow(loop, fadeIn);

      // start the loop, with a fade-in if desired
      final initialVolume = fadeIn ? 0.0 : _sfxVolume;
      final player = await FlameAudio.loop(loop.path, volume: initialVolume);

      // if the sound has been muted in the meantime, the player can be deleted immediately
      if (token != _loopGlobalToken || !_wantLoop(loop) || effectiveSfxVolume == 0 || _gameSfxMuted) {
        await player.stop();
        await player.dispose();
        return;
      }

      // if another player has been started in the meantime, the player can also be deleted immediately
      // and we'll just use the existing one again
      if (isLoopPlaying(loop)) {
        await player.stop();
        await player.dispose();
        await _raiseExistingNow(loop, fadeIn);
        return;
      }

      // update maps
      _loopPlayers[loop] = player;
      _loopVolumes[loop] = initialVolume;

      if (fadeIn) await _fadeLoopTo(loop, _sfxVolume, _loopFadeInDuration);
    });
  }

  Future<void> stopLoop(LoopSfx loop, {bool fadeOut = false}) async {
    _loopDesired[loop] = false;

    // check whether a player for the loop exists at all
    final player = _loopPlayers[loop];
    if (player == null) return;

    // if we don't have a fade out, we dispose, but not immediately, we put it in the queue
    if (!fadeOut) {
      _nextFadeToken(loop);
      return _disposeLoopSerialized(loop, player);
    }

    // in case we have a fade out
    unawaited(_fadeOutThenMaybeDispose(loop, player));
  }

  Future<void> _fadeOutThenMaybeDispose(LoopSfx loop, AudioPlayer expectedPlayer) async {
    await _fadeLoopTo(loop, 0, _loopFadeOutDuration);

    // if it became desired again, keep it
    if (_wantLoop(loop)) return;

    await _disposeLoopSerialized(loop, expectedPlayer);
  }

  Future<void> _disposeLoopSerialized(LoopSfx loop, AudioPlayer expectedPlayer) {
    return _enqueueLoopOp(loop, (token) async {
      // if it became desired again, keep it
      if (_wantLoop(loop)) return;

      // only dispose if we're still talking about the same player instance.
      final current = _loopPlayers[loop];
      if (current != expectedPlayer) return;

      _loopPlayers.remove(loop);
      _loopVolumes.remove(loop);
      await expectedPlayer.stop();
      await expectedPlayer.dispose();
    });
  }

  Future<void> _fadeLoopTo(LoopSfx loop, double target, Duration duration) async {
    // check whether the passed loop actually exists
    final player = _loopPlayers[loop];
    if (player == null) return;

    // new token
    final token = _nextFadeToken(loop);

    // determine start and end volume
    final start = _loopVolumes[loop] ?? _sfxVolume;
    final end = target.clamp(0.0, 1.0);

    // cancel and set target volume without fade if it doesn't make sense
    if (duration <= Duration.zero || (start - end).abs() < 0.001) {
      _loopVolumes[loop] = end;
      await player.setVolume(end);
      return;
    }

    // actual fade
    final stepMs = (duration.inMilliseconds / _loopSteps).ceil();
    for (int i = 1; i <= _loopSteps; i++) {
      // check whether the fade has been canceled or superseded
      if (_loopFadeToken[loop] != token) return;
      // check whether the loop got stopped while fading
      if (_loopPlayers[loop] != player) return;

      // apply volume step to loop
      final factor = i / _loopSteps;
      final volumeStep = start + (end - start) * factor;
      _loopVolumes[loop] = volumeStep;
      await player.setVolume(volumeStep);

      if (i < _loopSteps) await Future.delayed(Duration(milliseconds: stepMs));
    }
  }

  Future<void> stopAllLoops({bool resetSources = true}) async {
    if (resetSources) _notifyAmbientReset();

    // bump tokens
    _bumpLoopGlobalToken();
    for (final loop in _loopPlayers.keys) {
      _nextFadeToken(loop);
    }

    // drop queued work
    _loopOpChain.clear();

    // hard stop currently playing players (no queue)
    final players = _loopPlayers.values.toList();
    _loopPlayers.clear();
    _loopVolumes.clear();
    await Future.wait([
      for (final player in players)
        () async {
          await player.stop();
          await player.dispose();
        }(),
    ]);
  }

  Future<void> _applyLoopVolumes() async {
    if (effectiveSfxVolume == 0) return await stopAllLoops();
    for (final loop in _loopPlayers.keys) {
      _nextFadeToken(loop);
      _loopVolumes[loop] = _sfxVolume;
    }
    await Future.wait([for (final player in _loopPlayers.values) player.setVolume(_sfxVolume)]);
  }

  Future<void> pauseAllLoops() async => await Future.wait([for (final player in _loopPlayers.values) player.pause()]);

  Future<void> resumeAllLoops() async => await Future.wait([for (final player in _loopPlayers.values) player.resume()]);

  void playBackgroundMusic(BackgroundMusic music) => FlameAudio.bgm.play(music.path, volume: effectiveMusicVolume);

  void stopBackgroundMusic() => FlameAudio.bgm.stop();

  Future<void> _applyBgmVolume() async {
    if (!FlameAudio.bgm.isPlaying) return;
    await FlameAudio.bgm.audioPlayer.setVolume(effectiveMusicVolume);
  }

  Future<void> toggleSound(SoundState soundState) async {
    _soundState = soundState;

    // update current BGM volume  without restarting
    await _applyBgmVolume();

    // depending on the situation, a new sync event is triggered or all loops are removed
    soundState == SoundState.on ? _bumpAmbientSyncToken() : await stopAllLoops();

    await _storageCenter.updateSettings(soundState: soundState);
  }

  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume;

    // update current loop volumes without restarting
    await _applyLoopVolumes();

    await _storageCenter.updateSettings(sfxVolume: _sfxVolume);
  }

  Future<void> setMusicVolume(double volume, {bool automaticSave = true}) async {
    _musicVolume = volume;

    // update current BGM volume without restarting
    await _applyBgmVolume();

    if (automaticSave) await _storageCenter.updateSettings(musicVolume: _musicVolume);
  }

  Future<void> muteGameSfx() async {
    if (_gameSfxMuted) return;
    _gameSfxMuted = true;
    await stopAllLoops();
  }

  void unmuteGameSfx() {
    if (!_gameSfxMuted) return;
    _gameSfxMuted = false;
    _bumpAmbientSyncToken();
  }
}
