import 'dart:ui';
import 'package:flame/components.dart';

class DebugSpriteComponent extends SpriteComponent {
  DebugSpriteComponent({super.sprite, super.size, super.position, super.priority});

  @override
  void renderDebugMode(Canvas canvas) {
    // only draw the frame of the hitbox, no coordinates
    final paint = Paint()
      ..color = debugColor
      ..style = PaintingStyle.stroke;
    canvas.drawRect(size.toRect(), paint);
  }
}
