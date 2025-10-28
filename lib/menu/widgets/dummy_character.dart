import 'dart:async';
import 'package:flame/components.dart' hide Timer;
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/utils/curves.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/menu/widgets/character_bio.dart';
import 'package:pixel_adventure/pixel_quest.dart';

class DummyCharacter extends SpriteAnimationGroupComponent with HasGameReference<PixelQuest> {
  // constructor parameters
  final Vector2 _defaultPosition;
  final CharacterBio _characterBio;

  DummyCharacter({required Vector2 defaultPosition, required CharacterBio characterBio})
    : _defaultPosition = defaultPosition,
      _characterBio = characterBio,
      super(position: defaultPosition, size: gridSize);

  // animation settings
  static final Vector2 gridSize = Vector2.all(32);
  static final Vector2 _textureSize = Vector2(32, 32);
  static const String _path = 'Main Characters/';
  static const String _pathEnd = ' (32x32).png';

  // all available characters and the current index
  final List<PlayerCharacter> _allCharacters = [];
  int _currentCharacterIndex = 0;

  // contains all animations of all characters
  final Map<PlayerCharacter, Map<PlayerState, SpriteAnimation>> _allCharacterAnimations = {};

  // list of animations running in an endless loop
  final List<Future<void> Function(int)> _animationSequence = [];

  // important for the animation loop
  int _loopId = 0;
  final List<Effect> _activeEffects = [];

  // height of the jump animation
  static const double _jumpHeight = 42; // [Adjustable]
  static late double _jumpUpDuration;
  static late double _jumpDownDuration;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _setUpAllCharacters();
    _loadAllSpriteAnimations();
    _setUpAnimationLoop();
    _startAnimationLoop(_loopId);
    return super.onLoad();
  }

  void _initialSetup() {
    // debug
    if (GameSettings.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorMenu;
    }

    // general
    anchor = Anchor.center;
    priority = 5;
  }

  void _setUpAllCharacters() {
    _allCharacters.addAll(PlayerCharacter.values);
    _currentCharacterIndex = _allCharacters.indexOf(game.storageCenter.settings.character);
  }

  void _loadAllSpriteAnimations() {
    for (var character in PlayerCharacter.values) {
      final loadAnimation = spriteAnimationWrapper<PlayerState>(
        game,
        '$_path${character.fileName}/',
        _pathEnd,
        GameSettings.stepTime,
        _textureSize,
      );
      _allCharacterAnimations[character] = {for (final s in PlayerState.values) s: loadAnimation(s)};
    }

    animations = _allCharacterAnimations[game.storageCenter.settings.character];
    current = PlayerState.idle;
  }

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

  void _startAnimationLoop(int loopId) async {
    // runs through the sequence of animations until the loop is ended by a character change
    while (_loopId == loopId) {
      for (final action in _animationSequence) {
        if (_loopId != loopId) return;
        await action(loopId);
      }
    }
  }

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

  void _chnageAnimation(PlayerCharacter character) {
    _clearAnimationLoop();

    // change animations for new character
    animations = _allCharacterAnimations[character];
    current = PlayerState.idle;

    // start new loop
    _startAnimationLoop(_loopId);
  }

  void switchCharacter({bool next = true}) {
    _currentCharacterIndex = (_currentCharacterIndex + (next ? 1 : -1)) % _allCharacters.length;
    final character = _allCharacters[_currentCharacterIndex];
    game.storageCenter.saveSettings(game.storageCenter.settings.copyWith(character: character));
    _chnageAnimation(character);
    _characterBio.setCharacterBio(character);
  }

  void pauseAnimation() {
    _clearAnimationLoop();
    current = PlayerState.idle;
  }

  void resumeAnimation() => _startAnimationLoop(_loopId);
}
