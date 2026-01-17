import 'dart:async';
import 'package:flame/components.dart' hide Timer;
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/data/audio/audio_center.dart';
import 'package:pixel_adventure/game/level/player/player.dart';
import 'package:pixel_adventure/game/utils/curves.dart';
import 'package:pixel_adventure/game/utils/dummy_character.dart';
import 'package:pixel_adventure/menu/widgets/character_bio.dart';
import 'package:pixel_adventure/pixel_quest.dart';

class MenuDummyCharacter extends SpriteAnimationGroupComponent with HasGameReference<PixelQuest>, DummyCharacter {
  // constructor parameters
  final Vector2 _defaultPosition;
  final CharacterBio _characterBio;

  MenuDummyCharacter({required Vector2 defaultPosition, required CharacterBio characterBio})
    : _defaultPosition = defaultPosition,
      _characterBio = characterBio,
      super(position: defaultPosition, size: DummyCharacter.gridSize);

  // list of animations running in an endless loop
  final List<Future<void> Function(int)> _animationSequence = [];

  // important for the animation loop
  int _loopId = 0;
  bool _animationEnabled = false;
  final List<Effect> _activeEffects = [];

  // height of the jump animation
  static const double _jumpHeight = 42; // [Adjustable]
  late final double _jumpUpDuration;
  late final double _jumpDownDuration;

  @override
  FutureOr<void> onLoad() {
    _setUpAnimationLoop();
    return super.onLoad();
  }

  /// Defines the ordered sequence of demo animations (idle, run, jump, etc.)
  /// and precomputes the jump timings based on [_jumpHeight].
  void _setUpAnimationLoop() {
    // sequence of animations performed by the dummy character
    _animationSequence.addAll([
      (id) => _playState(PlayerState.idle, 8, id),
      (id) => _playState(PlayerState.run, 6, id),
      (id) => _playState(PlayerState.idle, 4, id),
      (id) => _jumpAnimation(id),
      (id) => _playState(PlayerState.idle, 5, id),
      (id) => _playState(PlayerState.run, 5, id),
      (id) => _playState(PlayerState.idle, 3, id),
      (id) => _jumpAnimation(id),
      (id) => _playState(PlayerState.idle, 2, id),
      (id) => _jumpAnimation(id),
      (id) => _playState(PlayerState.idle, 3, id),
      (id) => _playState(PlayerState.run, 8, id),
    ]);

    // calculate jump durations
    _jumpUpDuration = 0.0072 * _jumpHeight;
    _jumpDownDuration = 0.006 * _jumpHeight;
  }

  /// Plays a given [state] (idle, run, etc.) for [duration] seconds for
  /// the animation loop identified by [loopId]. If the loopId no longer
  /// matches, the animation for this state ends early.
  Future<void> _playState(PlayerState state, double duration, int loopId) async {
    if (_loopId != loopId) return;

    // completer that is resolved once the duration has expired or the loop has been stopped
    final completer = Completer<void>();

    // timer checks every 50 ms whether the time has elapsed or the loop has been terminated
    current = state;
    final ms = (duration * 1000).toInt();
    int elapsed = 0;
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_loopId != loopId || elapsed >= ms) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete();
      }
      elapsed += 50;
    });

    await completer.future;
  }

  /// Plays a jump + fall animation for the current loop, moving the dummy
  /// character up by [_jumpHeight] and then back down to [_defaultPosition].
  /// The animation aborts early if the [loopId] no longer matches.
  Future<void> _jumpAnimation(int loopId) async {
    if (_loopId != loopId) return;

    // the jump animation is only complete when all effects have been played or when the loopID is no longer correct and the completer is terminated externally
    final completer = Completer<void>();

    // sequence of up and down effects that imitate jumping in the game
    current = PlayerState.jump;
    final upEffect = MoveEffect.to(
      position - Vector2(0, _jumpHeight),
      EffectController(duration: _jumpUpDuration, curve: Curves.easeOutSine),
      onComplete: () {
        if (_loopId != loopId) {
          if (!completer.isCompleted) completer.complete();
          return;
        }
        current = PlayerState.fall;
        final downEffect = MoveEffect.to(
          _defaultPosition,
          EffectController(duration: _jumpDownDuration, curve: JumpFallCurve()),
          onComplete: () {
            if (!completer.isCompleted) completer.complete();
          },
        );
        add(downEffect);
        _activeEffects.add(downEffect);
      },
    );
    add(upEffect);
    _activeEffects.add(upEffect);

    await completer.future;
  }

  /// Runs the full animation sequence in a loop for the current [_loopId].
  /// The loop automatically stops when [_loopId] changes (e.g. on character
  /// change or when the animation is cleared).
  void _startAnimationLoop() async {
    final loopId = _loopId;

    // runs through the sequence of animations until the loop is ended
    while (_loopId == loopId) {
      for (final action in _animationSequence) {
        if (_loopId != loopId) return;
        await action(loopId);
      }
    }
  }

  /// Stops the current animation loop by incrementing [_loopId], removing
  /// all active effects, and resetting the dummy character back to its
  /// default position.
  void _clearAnimationLoop() {
    // new loop ID, old loops stop automatically
    _loopId++;

    // remove active effects
    for (var e in _activeEffects) {
      if (e.onComplete != null) e.onComplete!();
      e.removeFromParent();
    }
    _activeEffects.clear();

    // reset position
    position = _defaultPosition;
  }

  /// Switches to the next or previous character, saves the selection in storage,
  /// and updates the character bio and animation loop accordingly.
  void switchCharacter({bool next = true}) {
    currentCharacterIndex = (currentCharacterIndex + (next ? 1 : -1)) % allCharacters.length;
    final character = allCharacters[currentCharacterIndex];
    game.storageCenter.updateSettings(character: character);
    _changeAnimation(character);
    _characterBio.setCharacterBio(character);
  }

  /// Changes the active character animation set to [character],
  /// resets the state to idle, and restarts the animation loop
  /// only if animation is currently enabled.
  void _changeAnimation(PlayerCharacter character) {
    if (_animationEnabled) _clearAnimationLoop();

    // change animations for new character
    game.audioCenter.playSound(Sfx.changeCharacter, SfxType.ui);
    animations = allCharacterAnimations[character];
    current = PlayerState.idle;

    // start new loop
    if (_animationEnabled) _startAnimationLoop();
  }

  /// Resumes the dummy character animation: enables the animation loop
  /// and starts the demo sequence if it is currently disabled.
  void resumeAnimation() {
    if (_animationEnabled) return;
    _animationEnabled = true;
    _startAnimationLoop();
  }

  /// Pauses the dummy character animation: disables the animation loop,
  /// clears all active effects, and sets the current state to idle.
  void pauseAnimation() {
    if (!_animationEnabled) return;
    _animationEnabled = false;
    _clearAnimationLoop();
    current = PlayerState.idle;
  }
}
