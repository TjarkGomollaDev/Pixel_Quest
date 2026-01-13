import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/game/collision/collision.dart';

enum EntityCollisionType { side, any }

mixin EntityCollision on PositionComponent {
  void onEntityCollision(CollisionSide collisionSide);
  EntityCollisionType get collisionType => EntityCollisionType.side;
  ShapeHitbox get entityHitbox;
}

mixin EntityCollisionEnd on PositionComponent {
  void onEntityCollisionEnd();
}
