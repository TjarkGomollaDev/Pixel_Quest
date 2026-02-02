import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/geometry.dart';
import 'package:flame/image_composition.dart';
import 'package:flutter/material.dart';
import 'package:pixel_quest/app_theme.dart';
import 'package:pixel_quest/game/collision/collision.dart';
import 'package:pixel_quest/game/level/player/player.dart';
import 'package:pixel_quest/game/utils/animation_state.dart';
import 'package:pixel_quest/game/utils/curves.dart';
import 'package:pixel_quest/game/utils/load_sprites.dart';
import 'package:pixel_quest/game/game_settings.dart';
import 'package:pixel_quest/game/game.dart';

enum _PlayerEffectState implements AnimationState {
  appearing('Appearing', 7, loop: false, special: true),
  disappearing('Disappearing', 7, loop: false, special: true);

  @override
  final String fileName;
  @override
  final int amount;
  @override
  final bool loop;
  final bool special;

  const _PlayerEffectState(this.fileName, this.amount, {this.loop = true, this.special = false});
}

/// Dedicated helper component for the player's special visual effects.
///
/// Keeps non-core, “extra” effect logic (e.g. visuals/camera feedback) separated from
/// the main player implementation so the player class stays clean and focused.
class PlayerEffects extends SpriteAnimationGroupComponent with HasGameReference<PixelQuest>, HasVisibility {
  // constructor parameters
  final Player player;

  PlayerEffects({required this.player}) : super(position: Vector2.zero(), size: gridSize);

  // size
  static final Vector2 gridSize = Vector2.all(96);

  // offset
  static final Vector2 _offset = (gridSize - Player.gridSize) / 2;

  // animation settings
  static final Vector2 _textureSize = Vector2(96, 96);
  static const String _path = 'Main Characters/';
  static const String _pathEnd = ' (96x96).png';

  // death animation
  static const _bufferPlayerOutsideScreen = 20;
  static final _offsetControlPoint = Vector2(40, 120);
  static final _hopHeight = 40; // [Adjustable]
  static const _hopDuration = 0.3; // [Adjustable]
  static const _msPerPixelHorizontal = 2.6; // [Adjustable]
  static const _msPerPixelVertical = 2.8; // [Adjustable]

  @override
  Future<void> onLoad() async {
    _loadAllSpriteAnimations();
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<_PlayerEffectState>(game, _path, _pathEnd, GameSettings.stepTime, _textureSize);
    animations = {for (final state in _PlayerEffectState.values) state: loadAnimation(state)};
    isVisible = false;
  }

  /// Plays the “appearing” effect at the given world-space [effectPosition].
  ///
  /// The effect is centered on the player by applying a fixed offset and hides itself
  /// again once the one-shot animation has finished.

  Future<void> playAppearing(Vector2 effectPosition) async {
    position = effectPosition - _offset;
    isVisible = true;
    current = _PlayerEffectState.appearing;
    await animationTickers![_PlayerEffectState.appearing]!.completed;
    isVisible = false;
  }

  /// Plays the “disappearing” effect at the given world-space [effectPosition].
  ///
  /// The effect is centered on the player by applying a fixed offset and hides itself
  /// again once the one-shot animation has finished.
  Future<void> playDisappearing(Vector2 effectPosition) async {
    position = effectPosition - _offset;
    isVisible = true;
    current = _PlayerEffectState.disappearing;
    await animationTickers![_PlayerEffectState.disappearing]!.completed;
    isVisible = false;
  }

  /// Briefly flashes a translucent white rectangle over the visible camera area.
  ///
  /// Useful as a quick “impact” cue; the flash fades out automatically and removes
  /// itself from the world when the opacity animation completes.
  void playFlashScreen({double duration = 0.2}) {
    final flash = RectangleComponent(
      position: game.camera.visibleWorldRect.topLeft.toVector2() - Vector2(20, 0),
      size: game.camera.viewport.size + Vector2(40, 0),
      paint: Paint()..color = AppTheme.white.withAlpha(100),
      priority: GameSettings.flashEffectLayerLevel,
    );

    game.world.add(flash);
    flash.add(
      OpacityEffect.to(
        0,
        EffectController(duration: duration, curve: Curves.bounceInOut),
        onComplete: () => game.world.remove(flash),
      ),
    );
  }

  /// Shakes the camera horizontally by alternating offsets around its original position.
  ///
  /// [shakes] controls how many left/right steps are performed, [intensity] the offset
  /// in pixels/world-units (depending on your camera setup), and [duration] the delay
  /// per step before resetting back to the original position.
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

  /// Plays the player’s death movement based on the [collisionSide].
  ///
  /// Horizontal collisions launch the player along a curved bezier arc with rotation,
  /// while vertical collisions drop the player down (optionally with a small hop first).
  Future<void> playDeathTrajectory(CollisionSide collisionSide) async {
    if (collisionSide == CollisionSide.left || collisionSide == CollisionSide.right) {
      await _deathOnHorizontalCollision(collisionSide);
    } else {
      await _deathOnVerticalCollision(collisionSide);
    }
    player.angle = 0;
  }

  Future<void> _deathOnHorizontalCollision(CollisionSide collisionSide) async {
    final completer = Completer<void>();

    // control point
    final controlPointX = collisionSide == CollisionSide.left ? player.x - _offsetControlPoint.x : player.x + _offsetControlPoint.x;
    final controlPointY = player.y - _offsetControlPoint.y;

    // end point
    final endPointY = game.camera.visibleWorldRect.bottom + _bufferPlayerOutsideScreen;
    final verticalDistance = endPointY - controlPointY;
    final endPointX = collisionSide == CollisionSide.left
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
    final rotateEffect = RotateEffect.by((collisionSide == CollisionSide.right) ? -tau / 4 : tau / 4, _deathController(durationMs));

    // add effects
    player.add(moveEffect);
    player.add(rotateEffect);

    return completer.future;
  }

  Future<void> _deathOnVerticalCollision(CollisionSide collisionSide) async {
    final completer = Completer<void>();

    // end point
    final endPointY = game.camera.visibleWorldRect.bottom + _bufferPlayerOutsideScreen;
    final verticalDistance = collisionSide == CollisionSide.top ? endPointY - player.y + _hopHeight : endPointY - player.y;

    // duration depends on distance
    final durationMs = _calculateDuration(verticalDistance, _msPerPixelVertical);

    // move the player outside the screen
    final moveEffect = MoveEffect.to(Vector2(player.x, endPointY), _deathController(durationMs), onComplete: () => completer.complete());

    // possibly add a small hop effect before the move effect
    if (collisionSide == CollisionSide.top) {
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

  EffectController _deathController(double duration) => EffectController(duration: duration, curve: FastStartAccelerateCurve());

  double _calculateDuration(double verticalDistance, double msPerPixel) => (verticalDistance * msPerPixel) / 1000;
}
