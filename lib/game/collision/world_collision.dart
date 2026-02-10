import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_quest/app_theme.dart';
import 'package:pixel_quest/game/game_settings.dart';
import 'package:pixel_quest/game/game.dart';

/// Contract for components that participate in "world" collision.
///
/// The player resolves collisions against [worldHitbox] and applies movement correction (blocking, landing, etc.).
mixin WorldCollision on PositionComponent {
  /// The hitbox used for world collision checks (absolute rect is derived from this).
  ShapeHitbox get worldHitbox;
}

/// Optional hook for world objects that need to react when the player leaves contact.
mixin WorldCollisionEnd on PositionComponent {
  /// Called by the player when the collision with this world object ends.
  void onWorldCollisionEnd();
}

/// Solid world geometry block that the player collides with.
///
/// Can optionally be a one-way platform (handled by the player via [isPlatform]).
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
    debugMode = GameSettings.showDebug;
    debugColor = AppTheme.debugColorWorldBlock;
    collisionType = .passive;
  }

  @override
  void renderDebugMode(Canvas canvas) {
    if (!toAbsoluteRect().overlaps(game.camera.visibleWorldRect)) return;
    super.renderDebugMode(canvas);
  }
}
