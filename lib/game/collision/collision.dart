import 'dart:ui';
import 'package:flame/components.dart';

// ignore: constant_identifier_names
enum CollisionSide { Top, Right, Bottom, Left, None, Any }

double calculateOverlapX(Rect playerRect, Rect otherRect) {
  return (playerRect.center.dx < otherRect.center.dx) ? (playerRect.right - otherRect.left) : (otherRect.right - playerRect.left);
}

double calculateOverlapY(Rect playerRect, Rect otherRect) {
  return (playerRect.center.dy < otherRect.center.dy) ? (playerRect.bottom - otherRect.top) : (otherRect.bottom - playerRect.top);
}

// check whether the y ranges overlap → otherwise no horizontal collision
bool checkVerticalIntersection(Rect playerRect, Rect otherRect) {
  return playerRect.top < otherRect.bottom && playerRect.bottom > otherRect.top;
}

// check whether the x ranges overlap → otherwise no vertical collision
bool checkHorizontalIntersection(Rect playerRect, Rect otherRect) {
  return playerRect.left < otherRect.right && playerRect.right > otherRect.left;
}

CollisionSide resolveAABBCollision(
  Rect playerRect,
  Rect otherRect,
  double overlapX,
  double overlapY,
  bool hasVerticalIntersection,
  bool hasHorizontalIntersection,
  bool forceVertical,
) {
  if (overlapX < overlapY && hasVerticalIntersection && !forceVertical) {
    // horizontal collision
    if (playerRect.center.dx < otherRect.center.dx) {
      return CollisionSide.Left;
    } else {
      return CollisionSide.Right;
    }
  } else if (hasHorizontalIntersection) {
    // vertical collision
    if (playerRect.center.dy < otherRect.center.dy) {
      return CollisionSide.Top;
    } else {
      // _resolveBottomCollision(other.bottom, other);
      return CollisionSide.Bottom;
    }
  }
  return CollisionSide.None;
}

mixin FastCollision on PositionComponent {
  double get previousY;
}

bool verticalSweptCheck(Rect playerRect, FastCollision other, bool hasHorizontalIntersection) {
  final oldTop = other.previousY;
  final newBottom = other.position.y + other.height;

  // check whether the block intersected the player hitbox in the last frame, only the y values are checked
  return hasHorizontalIntersection && playerRect.bottom > oldTop && playerRect.top < newBottom;
}
