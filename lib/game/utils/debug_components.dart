import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

/// Debug helper that renders **only** a rectangular outline of the component bounds.
///
/// - No coordinates
/// - No extra debug overlays
/// - Uses the component's [debugColor]
///
/// Apply this to any [PositionComponent] (or subclasses) to keep debug visuals
/// minimal and clean.
mixin DebugOutlineOnly on PositionComponent {
  @override
  void renderDebugMode(Canvas canvas) {
    final paint = Paint()
      ..color = debugColor
      ..style = PaintingStyle.stroke;

    canvas.drawRect(size.toRect(), paint);
  }
}

/// A [SpriteComponent] that keeps Flame's debug rendering minimal.
///
/// When [debugMode] is enabled, this draws **only** the rectangular frame of the
/// sprite's bounds (via [DebugOutlineOnly]) and avoids Flame's default debug
/// output like coordinates.
class DebugSpriteComponent extends SpriteComponent with DebugOutlineOnly {
  DebugSpriteComponent({
    super.sprite,
    super.autoResize,
    super.paint,
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.nativeAngle,
    super.anchor,
    super.children,
    super.priority,
    super.bleed,
    super.key,
  });
}

/// A [RectangleHitbox] that keeps Flame's debug rendering minimal.
///
/// When [debugMode] is enabled, this draws **only** the rectangular frame of the
/// hitbox's bounds (via [DebugOutlineOnly]) and avoids Flame's default debug
/// output like coordinates.
class DebugRectangleHitbox extends RectangleHitbox with DebugOutlineOnly {
  DebugRectangleHitbox({super.position, super.size, super.angle, super.anchor, super.priority, super.isSolid, super.collisionType});
}

/// A [CircleHitbox] that keeps Flame's debug rendering minimal.
///
/// When [debugMode] is enabled, this draws **only** the rectangular frame of the
/// hitbox's bounds (via [DebugOutlineOnly]) and avoids Flame's default debug
/// output like coordinates.
class DebugCircleHitbox extends CircleHitbox with DebugOutlineOnly {
  DebugCircleHitbox({super.radius, super.position, super.angle, super.anchor, super.isSolid, super.collisionType});
}
