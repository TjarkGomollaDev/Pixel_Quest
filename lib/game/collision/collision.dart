import 'dart:ui';
import 'package:flame/components.dart';

/// Describes on which side the player collided with something.
enum CollisionSide { top, right, bottom, left, none, any }

/// Returns the horizontal overlap distance between two rects (positive => overlapping).
double calculateOverlapX(Rect playerRect, Rect otherRect) =>
    (playerRect.center.dx < otherRect.center.dx) ? (playerRect.right - otherRect.left) : (otherRect.right - playerRect.left);

/// Returns the vertical overlap distance between two rects (positive => overlapping).
double calculateOverlapY(Rect playerRect, Rect otherRect) =>
    (playerRect.center.dy < otherRect.center.dy) ? (playerRect.bottom - otherRect.top) : (otherRect.bottom - playerRect.top);

/// Returns true if the rects overlap on the Y-axis (required for a horizontal collision to be valid).
bool checkVerticalIntersection(Rect playerRect, Rect otherRect) => playerRect.top < otherRect.bottom && playerRect.bottom > otherRect.top;

/// Returns true if the rects overlap on the X-axis (required for a vertical collision to be valid).
bool checkHorizontalIntersection(Rect playerRect, Rect otherRect) => playerRect.left < otherRect.right && playerRect.right > otherRect.left;

/// Resolves the collision side between two AABBs based on overlap and intersection checks.
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
      return CollisionSide.left;
    } else {
      return CollisionSide.right;
    }
  } else if (hasHorizontalIntersection) {
    // vertical collision
    if (playerRect.center.dy < otherRect.center.dy) {
      return CollisionSide.top;
    } else {
      return CollisionSide.bottom;
    }
  }
  return CollisionSide.none;
}

/// Mixin for fast-moving colliders that expose their previous Y position for swept collision checks.
mixin FastCollision on PositionComponent {
  /// The collider's Y-position in the previous frame (used to detect "tunneling" on fast movement).
  double get previousY;
}

/// Returns true if a fast-moving collider swept through the player's rect vertically since the last frame.
bool verticalSweptCheck(Rect playerRect, FastCollision other, bool hasHorizontalIntersection) {
  final oldTop = other.previousY;
  final newBottom = other.position.y + other.height;

  // check whether the block intersected the player hitbox in the last frame, only the y values are checked
  return hasHorizontalIntersection && playerRect.bottom > oldTop && playerRect.top < newBottom;
}

/// Returns true if two 1D ranges on the Y-axis intersect.
bool checkRangeIntersection(double rangeMinY, double rangeMaxY, double otherMinY, double otherMaxY) =>
    rangeMaxY >= otherMinY && rangeMinY <= otherMaxY;
