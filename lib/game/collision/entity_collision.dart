import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/game/collision/collision.dart';

/// Defines how detailed the collision resolution should be for an entity.
///
/// - `side`: compute and report the actual collision side (top/left/right/bottom)
/// - `any`: skip side computation and just report a generic collision
enum EntityCollisionType { side, any }

/// Contract for components that can collide with the player as "entities".
///
/// The player computes collision direction and calls [onEntityCollision]. The entity provides
/// a hitbox via [entityHitbox] and can optional into cheaper collision handling via [collisionType].
mixin EntityCollision on PositionComponent {
  /// Called by the player when an entity collision is detected/resolved.
  void onEntityCollision(CollisionSide collisionSide);

  /// Determines whether the player should resolve a collision side (`side`) or just send `any`.
  ///
  /// Defaults to `side`. Use `any` for entities where the exact side doesn't matter (and you want to skip extra collision math).
  EntityCollisionType get collisionType => EntityCollisionType.side;

  /// The hitbox used for entity collision checks (absolute rect is derived from this).
  ShapeHitbox get entityHitbox;
}

/// Optional hook for entities that want to react when the collision ends.
mixin EntityCollisionEnd on PositionComponent {
  /// Called by the player when the collision with this entity ends.
  void onEntityCollisionEnd();
}
