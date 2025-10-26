import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class RRectComponent extends PositionComponent {
  final double borderRadius;
  final Color? color;

  RRectComponent({this.color, required super.size, required super.position, this.borderRadius = 0, super.anchor});

  double opacityy = 1;

  @override
  void render(Canvas canvas) {
    if (color == null) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, width, height), Radius.circular(borderRadius)),
      Paint()
        ..color = color!.withAlpha((color!.a * 255 * opacityy).toInt())
        ..style = PaintingStyle.fill,
    );
  }
}
