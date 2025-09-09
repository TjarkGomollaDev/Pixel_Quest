import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/geometry.dart';
import 'package:flame/image_composition.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/utils/animation_state.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum PlayerSpecialEffectState implements AnimationState {
  appearing('Appearing', 7, loop: false, special: true),
  disappearing('Disappearing', 7, loop: false, special: true);

  @override
  final String name;
  @override
  final int amount;
  @override
  final bool loop;
  final bool special;

  const PlayerSpecialEffectState(this.name, this.amount, {this.loop = true, this.special = false});
}

class PlayerSpecialEffect extends SpriteAnimationGroupComponent with HasGameReference<PixelAdventure>, HasVisibility {
  final Player player;

  PlayerSpecialEffect({required this.player}) : super(position: Vector2.zero(), size: gridSize);

  // size
  static final Vector2 gridSize = Vector2.all(96);

  // offset
  static final Vector2 _offset = (gridSize - Player.gridSize) / 2;

  // animation settings
  static final Vector2 _textureSize = Vector2(96, 96);
  static const String _path = 'Main Characters/';
  static const String _pathEnd = ' (96x96).png';

  @override
  Future<void> onLoad() async {
    _loadAllSpriteAnimations();
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<PlayerSpecialEffectState>(game, _path, _pathEnd, PixelAdventure.stepTime, _textureSize);
    animations = {for (var state in PlayerSpecialEffectState.values) state: loadAnimation(state)};
    isVisible = false;
  }

  Future<void> playAppearing(Vector2 effectPosition) async {
    position = effectPosition - _offset;
    isVisible = true;
    current = PlayerSpecialEffectState.appearing;
    await animationTickers![PlayerSpecialEffectState.appearing]!.completed;
    isVisible = false;
  }

  Future<void> playDisappearing(Vector2 effectPosition) async {
    position = effectPosition - _offset;
    isVisible = true;
    current = PlayerSpecialEffectState.disappearing;
    await animationTickers![PlayerSpecialEffectState.disappearing]!.completed;
    isVisible = false;
  }

  void playFlashScreen() {
    final flash = RectangleComponent(
      position: game.camera.visibleWorldRect.topLeft.toVector2(),
      size: game.camera.viewport.size,
      paint: Paint()..color = AppTheme.white.withAlpha(70),
      priority: PixelAdventure.flashEffectLayerLevel,
    );

    game.world.add(flash);

    flash.add(OpacityEffect.to(0, EffectController(duration: 0.2, curve: Curves.easeOut), onComplete: () => removeFromParent()));
  }

  Future<void> shakeCamera({int shakes = 3, double intensity = 10, double duration = 0.04}) async {
    final originalPos = game.camera.viewfinder.position;

    for (int i = 0; i < shakes; i++) {
      final offsetX = (i % 2 == 0 ? intensity : -intensity);
      final offset = Vector2(offsetX, 0);

      game.camera.moveTo(originalPos + offset);
      await Future.delayed(Duration(milliseconds: (duration * 1000).toInt()));
    }
    game.camera.moveTo(originalPos);
  }

  static final _offsetControlPoint = Vector2(40, 120);
  static const _buffer = 20.0;
  static const _msPerPixel = 2.8;

  Future<void> playDeathTrajectory() async {
    final completer = Completer<void>();

    // control point
    final controlPointX = player.x - _offsetControlPoint.x;
    final controlPointY = player.y - _offsetControlPoint.y;

    // end point
    final endPointY = game.camera.visibleWorldRect.bottom + _buffer;
    final verticalDistance = endPointY - controlPointY;
    final endPointX = controlPointX - (verticalDistance * 0.02);

    // duration depends on distance
    final durationMs = (verticalDistance * _msPerPixel) / 1000;

    // path for the move effect
    final path = Path()
      ..moveTo(player.x, player.y)
      ..quadraticBezierTo(controlPointX, controlPointY, endPointX, endPointY);

    // move the player outside the screen
    final moveEffect = MoveAlongPathEffect(
      path,
      EffectController(duration: durationMs, curve: FastStartAccelerateCurve()),
      absolute: true,
      onComplete: () => completer.complete(),
    );

    // rotate player while moving
    final rotateEffect = RotateEffect.by(tau / 4, EffectController(duration: durationMs, curve: FastStartAccelerateCurve()));

    // add effects
    player.add(moveEffect);
    player.add(rotateEffect);

    await completer.future;
    player.angle = 0;
    game.camera.follow(PlayerHitboxPositionProvider(player), horizontalOnly: true); // zurückdrehen
  }
}

class FastStartAccelerateCurve extends Curve {
  @override
  double transform(double t) => 0.4 * t + 0.6 * t * t;
}
