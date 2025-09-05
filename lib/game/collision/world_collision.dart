import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

/// A block in the game world that can act as a solid tile or platform for collision detection.
///
/// This component contains a dedicated hitbox (`_WorldBlockHitbox`) that handles
/// collisions with the player and other entities. The hitbox is rendered for debugging
/// purposes only when it overlaps the camera's visible viewport to improve performance
/// on large levels.
///
/// The block can be either a full solid block or a thin platform depending on `isPlatform`.
class WorldBlock extends PositionComponent with HasGameReference<PixelAdventure>, CollisionCallbacks, WorldCollision {
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
  void renderDebugMode(Canvas canvas) {
    if (!_hitbox.toAbsoluteRect().overlaps(game.camera.visibleWorldRect)) return;
    super.renderDebugMode(canvas);
  }

  @override
  ShapeHitbox get worldHitbox => _hitbox;
}

mixin WorldCollision on PositionComponent {
  ShapeHitbox get worldHitbox;
}

mixin WorldCollisionEnd on PositionComponent {
  void onWorldCollisionEnd();
}

/// A custom rectangle hitbox for WorldBlock that supports debug rendering with viewport culling.
///
/// This hitbox extends `RectangleHitbox` and overrides `renderDebugMode` to only draw itself
/// when it overlaps the visible portion of the camera. This improves performance when many
/// blocks exist in the level.
class _WorldBlockHitbox extends RectangleHitbox with HasGameReference<PixelAdventure> {
  _WorldBlockHitbox({required super.size}) {
    debugMode = PixelAdventure.customDebug;
    debugColor = AppTheme.debugColorWorldBlock;
    collisionType = CollisionType.passive;
  }

  @override
  void renderDebugMode(Canvas canvas) {
    if (!toAbsoluteRect().overlaps(game.camera.visibleWorldRect)) return;
    super.renderDebugMode(canvas);
  }
}
