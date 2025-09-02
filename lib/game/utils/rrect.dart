import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class RoundedComponent extends PositionComponent {
  final double borderRadius;
  final Color? color;

  RoundedComponent({this.color, required super.size, required super.position, this.borderRadius = 0, super.anchor});

  @override
  void render(Canvas canvas) {
    if (color == null) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, width, height), Radius.circular(borderRadius)),
      Paint()
        ..color = color!
        ..style = PaintingStyle.fill,
    );
  }
}
