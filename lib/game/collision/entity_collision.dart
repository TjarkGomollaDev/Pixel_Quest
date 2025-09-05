import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/game/collision/collision.dart';

// ignore: constant_identifier_names
enum EntityCollisionType { Side, Any }

mixin EntityCollision on PositionComponent {
  void onEntityCollision(CollisionSide collisionSide);
  EntityCollisionType get collisionType;
  ShapeHitbox get entityHitbox;
}

mixin EntityCollisionEnd on PositionComponent {
  void onEntityCollisionEnd();
}

// snail ... check
// turtle ... check
// fire trap -> 2 hitboxen ... check
// moving platform ... check
// spike head ... check

// saw, single saw, spiked ball ... check

// collision check type überall einbauen ..check
