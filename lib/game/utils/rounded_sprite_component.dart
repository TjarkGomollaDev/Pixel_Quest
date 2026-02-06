import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class RoundedSpriteComponent extends SpriteComponent {
  // constructor parameters
  final double cornerRadius;

  RoundedSpriteComponent({
    this.cornerRadius = 0,
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

  @override
  void render(Canvas canvas) {
    if (cornerRadius <= 0) return super.render(canvas);

    // use clip rrect
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.save();
    canvas.clipRRect(.fromRectAndRadius(rect, .circular(cornerRadius)), doAntiAlias: true);
    super.render(canvas);
    canvas.restore();
  }
}
