import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/data/audio/audio_center.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_quest.dart';

class OutlineStar extends SpriteComponent with HasGameReference<PixelQuest> implements OpacityProvider {
  final bool _spawnSizeZero;

  OutlineStar({required Vector2 position, Vector2? size, bool spawnSizeZero = false})
    : _spawnSizeZero = spawnSizeZero,
      super(position: position, size: size ?? defaultSize);

  // size
  static final Vector2 defaultSize = Vector2.all(24);

  // animation settings
  static const String _path = 'Other/Star Outline.png';

  @override
  Future<void> onLoad() async {
    _initialSetup();
    _loadSprite();
    if (_spawnSizeZero) _addSpawnAnimation();
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

  void _loadSprite() => sprite = loadSprite(game, _path);

  void _addSpawnAnimation() {
    scale = Vector2.zero();
    add(ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.6, curve: Curves.fastEaseInToSlowEaseOut)));
  }

  void fadeOut() => add(OpacityEffect.to(0, EffectController(duration: 0.1, curve: Curves.easeIn), onComplete: () => removeFromParent()));
}

class Star extends SpriteComponent with HasGameReference<PixelQuest> implements OpacityProvider {
  final bool _spawnSizeZero;

  Star({required Vector2 position, Vector2? size, bool spawnSizeZero = false})
    : _spawnSizeZero = spawnSizeZero,
      super(position: position, size: size ?? defaultSize);

  // size
  static final Vector2 defaultSize = Vector2.all(24);

  // animation settings
  static const String _path = 'Other/Star.png';

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
    sprite = loadSprite(game, _path);
    if (_spawnSizeZero) scale = Vector2.zero();
  }

  Future<void> flyTo(Vector2 target, {double flyDuration = 1}) async {
    final completer = Completer<void>();
    addAll([
      ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.1, curve: Curves.easeOut)),
      MoveEffect.to(
        target,
        EffectController(duration: flyDuration, curve: Curves.easeOutBack),
        onComplete: () {
          game.audioCenter.playSound(Sfx.star, SfxType.level);
          completer.complete();
        },
      ),
    ]);

    return completer.future;
  }

  Future<void> fallTo(Vector2 target, {double fallDuration = 0.4}) async {
    final startPosition = position.clone();
    final completer = Completer<void>();
    game.audioCenter.playSound(Sfx.collected, SfxType.level);
    add(
      SequenceEffect(
        [
          MoveEffect.to(target, EffectController(duration: fallDuration, curve: Curves.easeOutBack)),
          ScaleEffect.to(Vector2.all(1.3), EffectController(duration: 0.1, curve: Curves.easeOut)),
          ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.1, curve: Curves.easeIn)),
        ],
        onComplete: () {
          position = startPosition;
          completer.complete();
        },
      ),
    );

    return completer.future;
  }

  Future<void> popIn({double duration = 0.6}) async {
    final completer = Completer<void>();
    game.audioCenter.playSound(Sfx.star, SfxType.level);
    add(
      SequenceEffect([
        ScaleEffect.to(Vector2.all(1.4), EffectController(duration: duration * 0.6, curve: Curves.easeOutBack)),
        ScaleEffect.to(Vector2.all(1.0), EffectController(duration: duration * 0.4, curve: Curves.easeIn)),
      ], onComplete: () => completer.complete()),
    );

    return completer.future;
  }

  void fadeOut() => add(OpacityEffect.to(0, EffectController(duration: 0.1, curve: Curves.easeIn), onComplete: () => removeFromParent()));
}

List<Vector2> calculateStarPositions(Vector2 center, double radius) {
  final positions = <Vector2>[];
  final baseAngle = -90.0; // -90° upward
  final offsets = [-28, 0, 28]; // left, center, right

  for (final offset in offsets) {
    final rad = (baseAngle + offset) * (pi / 180.0);
    positions.add(Vector2(center.x + radius * cos(rad), center.y + radius * sin(rad)));
  }

  return positions;
}
