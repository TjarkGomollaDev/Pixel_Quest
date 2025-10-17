import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_quest.dart';

class OutlineStar extends SpriteComponent with HasGameReference<PixelQuest> {
  final bool _spawnAnimation;

  OutlineStar({required Vector2 position, bool spawnAnimation = false})
    : _spawnAnimation = spawnAnimation,
      super(position: position, size: Vector2.all(24));

  // animation settings
  static const String _path = 'Other/Star Outline.png';

  @override
  Future<void> onLoad() async {
    _initialSetup();
    _loadSprite();
    if (_spawnAnimation) _addSpawnAnimation();
  }

  void _initialSetup() {
    // debug
    if (GameSettings.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
    }

    // general
    priority = GameSettings.spotlightAnimationStarsLayer;
    anchor = Anchor.center;
  }

  void _loadSprite() => sprite = loadSprite(game, _path);

  void _addSpawnAnimation() {
    scale = Vector2.zero();
    add(ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.6, curve: Curves.fastEaseInToSlowEaseOut)));
  }

  void fadeOut() => add(OpacityEffect.to(0, EffectController(duration: 0.1, curve: Curves.easeIn), onComplete: () => removeFromParent()));
}

class Star extends SpriteComponent with HasGameReference<PixelQuest> {
  final bool _spawnAnimation;

  Star({required Vector2 position, bool spawnAnimation = false})
    : _spawnAnimation = spawnAnimation,
      super(position: position, size: Vector2.all(24));

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
    priority = GameSettings.spotlightAnimationStarsLayer;
    anchor = Anchor.center;
  }

  void _loadSprite() {
    sprite = loadSprite(game, _path);
    if (_spawnAnimation) scale = Vector2.zero();
  }

  Future<void> flyTo(Vector2 target) async {
    final completer = Completer<void>();
    addAll([
      ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.1, curve: Curves.easeOut)),
      MoveEffect.to(target, EffectController(duration: 1, curve: Curves.easeOutBack), onComplete: () => completer.complete()),
    ]);

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
