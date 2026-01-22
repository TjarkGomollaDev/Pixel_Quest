import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/game_settings.dart';
import 'package:pixel_adventure/game/game.dart';

mixin WorldCollision on PositionComponent {
  ShapeHitbox get worldHitbox;
}

mixin WorldCollisionEnd on PositionComponent {
  void onWorldCollisionEnd();
}

class WorldBlock extends PositionComponent with HasGameReference<PixelQuest>, CollisionCallbacks, WorldCollision {
  // constructor parameters
  final bool isPlatform;

  WorldBlock({this.isPlatform = false, required super.position, required super.size});

  // actual hitbox
  late final _WorldBlockHitbox _hitbox;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    return super.onLoad();
  }

  void _initialSetup() {
    // general
    _hitbox = _WorldBlockHitbox(size: size);
    add(_hitbox);
  }

  @override
  ShapeHitbox get worldHitbox => _hitbox;
}

/// A custom rectangle hitbox for WorldBlock that supports debug rendering with viewport culling.
///
/// This hitbox extends `RectangleHitbox` and overrides `renderDebugMode` to only draw itself
/// when it overlaps the visible portion of the camera. This improves performance when many
/// blocks exist in the level.
class _WorldBlockHitbox extends RectangleHitbox with HasGameReference<PixelQuest> {
  _WorldBlockHitbox({required super.size}) {
    debugMode = GameSettings.customDebugMode;
    debugColor = AppTheme.debugColorWorldBlock;
    collisionType = CollisionType.passive;
  }

  @override
  void renderDebugMode(Canvas canvas) {
    if (!toAbsoluteRect().overlaps(game.camera.visibleWorldRect)) return;
    super.renderDebugMode(canvas);
  }
}
