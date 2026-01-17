import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/data/audio/audio_center.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_quest.dart';

enum StarVariant { filled, outline }

class Star extends SpriteComponent with HasGameReference<PixelQuest> implements OpacityProvider {
  // constructor parameters
  final StarVariant _variant;
  final bool _spawnSizeZero;

  Star({required StarVariant variant, super.position, Vector2? size, bool spawnSizeZero = false})
    : _variant = variant,
      _spawnSizeZero = spawnSizeZero,
      super(size: size ?? defaultSize);

  // size
  static final Vector2 defaultSize = Vector2.all(24);

  // animation settings
  static const String _pathFilled = 'Other/Star.png';
  static const String _pathOutline = 'Other/Star Outline.png';

  // active animations are saved so that they can be canceled
  final Map<String, Effect> _activeEffects = {};
  final Map<String, Completer<void>> _activeCompleters = {};
  final Map<String, Vector2> _resetPositions = {};

  // animation keys
  static const String _keyFlyTo = 'fly-to';
  static const String _keyFallTo = 'fall-to';
  static const String _keyPopIn = 'pop-in';
  static const String _keyScaleIn = 'scale-in';
  static const String _keyFadeOut = 'fade-out';

  @override
  Future<void> onLoad() async {
    _initialSetup();
    _loadSprite();
  }

  void _initialSetup() {
    // debug
    if (GameSettings.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
    }

    // general
    priority = GameSettings.spotlightAnimationContentLayer;
    anchor = Anchor.center;
  }

  void _loadSprite() {
    sprite = loadSprite(game, _variant == StarVariant.filled ? _pathFilled : _pathOutline);
    if (_spawnSizeZero) scale = Vector2.zero();
  }

  void _cancelKey(String key) {
    final effect = _activeEffects.remove(key);
    final completer = _activeCompleters.remove(key);

    // remove effect and complete completer
    if (effect != null && effect.parent != null) remove(effect);
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  void cancelAnimations({bool resetVisuals = true}) {
    // cancel all registered animations
    for (final k in _activeEffects.keys.toList()) {
      _cancelKey(k);
    }

    // reset visuals
    if (resetVisuals) {
      scale = Vector2.all(1);
      opacity = 1;
    }

    // reset position in a predictable priority (fallTo > flyTo)
    final reset = _resetPositions[_keyFallTo] ?? _resetPositions[_keyFlyTo];
    if (reset != null) position = reset;
    _resetPositions.clear();
  }

  Future<void> flyTo(Vector2 target, {double flyDuration = 1}) async {
    _cancelKey(_keyFlyTo);
    final completer = Completer<void>();
    _activeCompleters[_keyFlyTo] = completer;
    _resetPositions[_keyFlyTo] = position.clone();

    // add visual effect
    final effect = SequenceEffect(
      [
        ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.1, curve: Curves.easeOut)),
        MoveEffect.to(target, EffectController(duration: flyDuration, curve: Curves.easeOutBack)),
      ],
      onComplete: () {
        game.audioCenter.playSound(Sfx.star, SfxType.level);
        _resetPositions.remove(_keyFlyTo);
        _activeEffects.remove(_keyFlyTo);
        _activeCompleters.remove(_keyFlyTo);
        if (!completer.isCompleted) completer.complete();
      },
    );
    _activeEffects[_keyFlyTo] = effect;
    add(effect);

    return completer.future;
  }

  Future<void> fallTo(Vector2 target, {double fallDuration = 0.4}) async {
    _cancelKey(_keyFallTo);
    final completer = Completer<void>();
    _activeCompleters[_keyFallTo] = completer;
    final startPosition = position.clone();
    _resetPositions[_keyFallTo] = startPosition;

    // play sound effect
    game.audioCenter.playSound(Sfx.collected, SfxType.level);

    // add visual effect
    final effect = SequenceEffect(
      [
        MoveEffect.to(target, EffectController(duration: fallDuration, curve: Curves.easeOutBack)),
        ScaleEffect.to(Vector2.all(1.3), EffectController(duration: 0.1, curve: Curves.easeOut)),
        ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.1, curve: Curves.easeIn)),
      ],
      onComplete: () {
        position = startPosition;
        _resetPositions.remove(_keyFallTo);
        _activeCompleters.remove(_keyFallTo);
        _activeEffects.remove(_keyFallTo);
        completer.complete();
      },
    );
    _activeEffects[_keyFallTo] = effect;
    add(effect);

    return completer.future;
  }

  Future<void> popIn({double duration = 0.6}) async {
    _cancelKey(_keyPopIn);
    final completer = Completer<void>();
    _activeCompleters[_keyPopIn] = completer;

    // play sound effect
    game.audioCenter.playSound(Sfx.star, SfxType.level);

    // add visual effect
    final effect = SequenceEffect(
      [
        ScaleEffect.to(Vector2.all(1.4), EffectController(duration: duration * 0.6, curve: Curves.easeOutBack)),
        ScaleEffect.to(Vector2.all(1.0), EffectController(duration: duration * 0.4, curve: Curves.easeIn)),
      ],
      onComplete: () {
        _activeEffects.remove(_keyPopIn);
        _activeCompleters.remove(_keyPopIn);
        if (!completer.isCompleted) completer.complete();
      },
    );
    _activeEffects[_keyPopIn] = effect;
    add(effect);

    return completer.future;
  }

  Future<void> scaleIn({double duration = 0.6}) {
    _cancelKey(_keyScaleIn);
    final completer = Completer<void>();
    _activeCompleters[_keyScaleIn] = completer;

    // add visual effect
    final effect = ScaleEffect.to(
      Vector2.all(1.0),
      EffectController(duration: duration, curve: Curves.fastEaseInToSlowEaseOut),
      onComplete: () {
        _activeEffects.remove(_keyScaleIn);
        _activeCompleters.remove(_keyScaleIn);
        if (!completer.isCompleted) completer.complete();
      },
    );
    _activeEffects[_keyScaleIn] = effect;
    add(effect);

    return completer.future;
  }

  Future<void> fadeOut({double duration = 0.1, bool removeAfter = true}) {
    _cancelKey(_keyFadeOut);
    final completer = Completer<void>();
    _activeCompleters[_keyFadeOut] = completer;

    // add visual effect
    final effect = OpacityEffect.to(
      0,
      EffectController(duration: duration, curve: Curves.easeIn),
      onComplete: () {
        _activeEffects.remove(_keyFadeOut);
        _activeCompleters.remove(_keyFadeOut);
        if (!completer.isCompleted) completer.complete();
        if (removeAfter) removeFromParent();
      },
    );
    _activeEffects[_keyFadeOut] = effect;
    add(effect);

    return completer.future;
  }
}
