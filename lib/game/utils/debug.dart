import 'dart:ui';
import 'package:flame/components.dart';

/// A [SpriteComponent] that only renders a debug outline of its bounds.
///
/// Unlike the default debug mode in Flame, this component does **not** render coordinates or other
/// debug information—only the rectangular frame of the sprite's size is drawn.
///
/// You can customize the color of the outline via [debugColor], and it respects the component's
/// [size], [position], and [priority].
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
