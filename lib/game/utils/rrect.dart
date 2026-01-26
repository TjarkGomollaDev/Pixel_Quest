import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/game/utils/visible_components.dart';

/// A lightweight rounded-rectangle component.
class RRectComponent extends PositionComponent with VisibleComponent {
  // constructor parameters
  final double borderRadius;
  Color? color;

  RRectComponent({this.color, required super.size, super.position, this.borderRadius = 0, super.anchor, bool show = true}) {
    initVisibility(show);
  }

  // intern opacity value 0..1
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
