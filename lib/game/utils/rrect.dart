import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class RRectComponent extends PositionComponent with HasVisibility {
  final double borderRadius;
  final Color? color;

  RRectComponent({this.color, required super.size, required super.position, this.borderRadius = 0, super.anchor, bool show = true}) {
    if (!show) hide();
  }

  void show() => isVisible = true;
  void hide() => isVisible = false;

  double opacity = 1;

  @override
  void render(Canvas canvas) {
    if (color == null) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, width, height), Radius.circular(borderRadius)),
      Paint()
        ..color = color!.withAlpha((color!.a * 255 * opacity).toInt())
        ..style = PaintingStyle.fill,
    );
  }
}
