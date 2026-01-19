import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/app_theme.dart';

class CornerOutline extends PositionComponent {
  // constructor parameters
  final double cornerLength;
  final double strokeWidth;
  final Color color;

  CornerOutline({
    required super.size,
    this.cornerLength = 6,
    this.strokeWidth = 2,
    this.color = AppTheme.ingameText,
    super.anchor,
    super.position,
  });

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final halfStroke = strokeWidth / 2;
    final w = size.x;
    final h = size.y;

    // clamp so we never draw outside even if cornerLength is too large
    final cl = cornerLength.clamp(0, (w < h ? w : h) / 2);

    final left = halfStroke;
    final top = halfStroke;
    final right = w - halfStroke;
    final bottom = h - halfStroke;

    // top left
    canvas.drawLine(Offset(0, top), Offset(left + cl, top), paint); // horizontal
    canvas.drawLine(Offset(left, 0), Offset(left, top + cl), paint); // vertical

    // top right
    canvas.drawLine(Offset(right - cl, top), Offset(w, top), paint); // horizontal
    canvas.drawLine(Offset(right, 0), Offset(right, top + cl), paint); // vertical

    // bottom left
    canvas.drawLine(Offset(0, bottom), Offset(left + cl, bottom), paint); // horizontal
    canvas.drawLine(Offset(left, bottom - cl), Offset(left, h), paint); // vertical

    // bottom right
    canvas.drawLine(Offset(right - cl, bottom), Offset(w, bottom), paint); // horizontal
    canvas.drawLine(Offset(right, bottom - cl), Offset(right, h), paint); // vertical
  }
}
