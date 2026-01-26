import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';
import 'package:pixel_adventure/data/audio/audio_center.dart';
import 'package:pixel_adventure/game/utils/cancelable_effects.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game/game_settings.dart';
import 'package:pixel_adventure/game/game.dart';

enum StarVariant { filled, outline }

/// Star UI component used for level rewards and spotlight animations.
///
/// Supports filled/outline variants and a small set of reusable effects
class Star extends SpriteComponent with HasGameReference<PixelQuest>, CancelableAnimations implements OpacityProvider {
  // constructor parameters
  final StarVariant _variant;
  final bool _spawnSizeZero;

  Star({required StarVariant variant, super.position, Vector2? size, bool spawnSizeZero = false})
    : _variant = variant,
      _spawnSizeZero = spawnSizeZero {
    this.size = size ?? defaultSize;
    priority = GameSettings.spotlightAnimationContentLayer;
    anchor = Anchor.center;
  }

  // size
  static final Vector2 defaultSize = Vector2.all(24);

  // animation settings
  static const String _pathFilled = 'Other/Star.png';
  static const String _pathOutline = 'Other/Star Outline.png';

  // animation keys
  static const String _keyFlyToAndScaleIn = 'fly-to-and-scale-in';
  static const String _keyFallToPopIn = 'fall-to-pop-in';
  static const String _keyPopIn = 'pop-in';
  static const String _keyScaleIn = 'scale-in';
  static const String _keyFadeOut = 'fade-out';

  // for some animations, positions are saved to which the star is reset when the animation is canceled
  final Map<String, Vector2> _resetPositions = {};

  @override
  Future<void> onLoad() async {
    _loadSprite();
  }

  @override
  void cancelAnimations() {
    super.cancelAnimations();

    // reset visuals
    scale = Vector2.all(1);
    opacity = 1;

    // reset position in a predictable priority (fallTo > flyTo)
    final reset = _resetPositions[_keyFallToPopIn] ?? _resetPositions[_keyFlyToAndScaleIn];
    if (reset != null) position = reset;
    _resetPositions.clear();
  }

  void _loadSprite() {
    sprite = loadSprite(game, _variant == StarVariant.filled ? _pathFilled : _pathOutline);
    if (_spawnSizeZero) scale = Vector2.zero();
  }

  /// Animates the star flying to a target position while scaling up to full size.
  Future<void> flyToAndScaleIn(Vector2 target, {double flyDuration = 1, double scaleDuration = 0.3, bool playSound = true}) {
    // create effect
    final effect = CombinedEffect([
      MoveEffect.to(target, EffectController(duration: flyDuration, curve: Curves.easeOutBack)),
      ScaleEffect.to(Vector2.all(1.0), EffectController(duration: scaleDuration, curve: Curves.easeOut)),
    ]);

    // register effect and return future
    return registerEffect(
      _keyFlyToAndScaleIn,
      effect,
      additionallyOnStart: () => _resetPositions[_keyFlyToAndScaleIn] = position.clone(),
      additionallyInOnComplete: () {
        _resetPositions.remove(_keyFlyToAndScaleIn);
        if (playSound) game.audioCenter.playSound(Sfx.star, SfxType.level);
      },
    );
  }

  /// Drops the star to a target and does a quick pop-in squash/stretch.
  Future<void> fallToPopIn(Vector2 target, {double fallDuration = 0.4, double popInDuration = 0.15, bool playSound = true}) {
    // create effect
    final effect = SequenceEffect([
      MoveEffect.to(target, EffectController(duration: fallDuration, curve: Curves.easeOutBack)),
      ScaleEffect.to(Vector2.all(1.4), EffectController(duration: popInDuration * 0.5, curve: Curves.easeOut)),
      ScaleEffect.to(Vector2.all(1.0), EffectController(duration: popInDuration * 0.5, curve: Curves.easeIn)),
    ]);

    // register effect and return future
    final startPosition = position.clone();
    return registerEffect(
      _keyFallToPopIn,
      effect,
      additionallyOnStart: () {
        _resetPositions[_keyFallToPopIn] = startPosition;
        if (playSound) game.audioCenter.playSound(Sfx.collected, SfxType.level);
      },
      additionallyInOnComplete: () {
        position = startPosition;
        _resetPositions.remove(_keyFallToPopIn);
      },
    );
  }

  /// Quick pop-in animation (overshoot then settle).
  Future<void> popIn({double duration = 0.6, bool playSound = true}) {
    // create effect
    final effect = SequenceEffect([
      ScaleEffect.to(Vector2.all(1.4), EffectController(duration: duration * 0.5, curve: Curves.easeOutBack)),
      ScaleEffect.to(Vector2.all(1.0), EffectController(duration: duration * 0.5, curve: Curves.easeIn)),
    ]);

    // register effect and return future
    return registerEffect(
      _keyPopIn,
      effect,
      additionallyOnStart: playSound ? () => game.audioCenter.playSound(Sfx.star, SfxType.level) : null,
    );
  }

  /// Smooth scale-in to full size, useful when the star spawns at zero scale.
  Future<void> scaleIn({double duration = 0.6}) {
    // create effect
    final effect = ScaleEffect.to(Vector2.all(1.0), EffectController(duration: duration, curve: Curves.fastEaseInToSlowEaseOut));

    // register effect and return future
    return registerEffect(_keyScaleIn, effect);
  }

  /// Fades the star out and optionally removes it from the component tree afterwards.
  Future<void> fadeOut({double duration = 0.1, bool removeAfter = true}) {
    // create effect
    final effect = OpacityEffect.to(0, EffectController(duration: duration, curve: Curves.easeIn));

    // register effect and return future
    return registerEffect(_keyFadeOut, effect, additionallyInOnComplete: removeAfter ? removeFromParent : null);
  }
}
