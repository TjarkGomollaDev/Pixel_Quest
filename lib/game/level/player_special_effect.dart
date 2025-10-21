import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/geometry.dart';
import 'package:flame/image_composition.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/collision/collision.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/utils/animation_state.dart';
import 'package:pixel_adventure/game/utils/curves.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_quest.dart';

enum PlayerSpecialEffectState implements AnimationState {
  appearing('Appearing', 7, loop: false, special: true),
  disappearing('Disappearing', 7, loop: false, special: true);

  @override
  final String fileName;
  @override
  final int amount;
  @override
  final bool loop;
  final bool special;

  const PlayerSpecialEffectState(this.fileName, this.amount, {this.loop = true, this.special = false});
}

class PlayerSpecialEffect extends SpriteAnimationGroupComponent with HasGameReference<PixelQuest>, HasVisibility {
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
    final loadAnimation = spriteAnimationWrapper<PlayerSpecialEffectState>(game, _path, _pathEnd, GameSettings.stepTime, _textureSize);
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
      priority: GameSettings.flashEffectLayerLevel,
    );

    game.world.add(flash);
    flash.add(OpacityEffect.to(0, EffectController(duration: 0.2, curve: Curves.easeOut), onComplete: () => game.world.remove(flash)));
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
  static final _hopHeight = 40;
  static const _hopDuration = 0.3;
  static const _buffer = 20;
  static const _msPerPixelHorizontal = 2.6;
  static const _msPerPixelVertical = 2.8;

  EffectController _deathController(double duration) => EffectController(duration: duration, curve: FastStartAccelerateCurve());

  double _calculateDuration(double verticalDistance, double msPerPixel) => (verticalDistance * msPerPixel) / 1000;

  Future<void> _deathOnHorizontalCollision(CollisionSide collisionSide) async {
    final completer = Completer<void>();

    // control point
    final controlPointX = collisionSide == CollisionSide.Left ? player.x - _offsetControlPoint.x : player.x + _offsetControlPoint.x;
    final controlPointY = player.y - _offsetControlPoint.y;

    // end point
    final endPointY = game.camera.visibleWorldRect.bottom + _buffer;
    final verticalDistance = endPointY - controlPointY;
    final endPointX = collisionSide == CollisionSide.Left
        ? controlPointX - (verticalDistance * 0.02)
        : controlPointX + (verticalDistance * 0.02);

    // duration depends on distance
    final durationMs = _calculateDuration(verticalDistance, _msPerPixelHorizontal);

    // path for the move effect
    final path = Path()
      ..moveTo(player.x, player.y)
      ..quadraticBezierTo(controlPointX, controlPointY, endPointX, endPointY);

    // move the player outside the screen
    final moveEffect = MoveAlongPathEffect(path, _deathController(durationMs), absolute: true, onComplete: () => completer.complete());

    // rotate player while moving
    final rotateEffect = RotateEffect.by((collisionSide == CollisionSide.Right) ? -tau / 4 : tau / 4, _deathController(durationMs));

    // add effects
    player.add(moveEffect);
    player.add(rotateEffect);

    return completer.future;
  }

  Future<void> _deathOnVerticalCollision(CollisionSide collisionSide) async {
    final completer = Completer<void>();

    // end point
    final endPointY = game.camera.visibleWorldRect.bottom + _buffer;
    final verticalDistance = collisionSide == CollisionSide.Top ? endPointY - player.y + _hopHeight : endPointY - player.y;

    // duration depends on distance
    final durationMs = _calculateDuration(verticalDistance, _msPerPixelVertical);

    // move the player outside the screen
    final moveEffect = MoveEffect.to(Vector2(player.x, endPointY), _deathController(durationMs), onComplete: () => completer.complete());

    // possibly add a small hop effect before the move effect
    if (collisionSide == CollisionSide.Top) {
      final hopEffect = MoveEffect.to(
        Vector2(player.x, player.y - _hopHeight),
        EffectController(duration: _hopDuration, curve: Curves.easeOut),
      );
      hopEffect.onComplete = () => player.add(moveEffect);
      player.add(hopEffect);
    } else {
      player.add(moveEffect);
    }

    return completer.future;
  }

  Future<void> playDeathTrajectory(CollisionSide collisionSide) async {
    if (collisionSide == CollisionSide.Left || collisionSide == CollisionSide.Right) {
      await _deathOnHorizontalCollision(collisionSide);
    } else {
      await _deathOnVerticalCollision(collisionSide);
    }
    player.angle = 0;
  }
}
