import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class CornerOutline extends PositionComponent {
  final double cornerLength; // Länge jeder Ecke
  final double strokeWidth;
  final Color color;

  CornerOutline({
    required Vector2 size,
    required this.cornerLength,
    this.strokeWidth = 2.0,
    this.color = Colors.white,
    super.anchor,
    super.position,
  }) {
    this.size = size;
  }

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

    // top left
    canvas.drawLine(Offset(-halfStroke, 0), Offset(cornerLength, 0), paint); // horizontal
    canvas.drawLine(Offset(0, -halfStroke), Offset(0, cornerLength), paint); // vertical

    // top right
    canvas.drawLine(Offset(w - cornerLength, 0), Offset(w + halfStroke, 0), paint); // horizontal
    canvas.drawLine(Offset(w, -halfStroke), Offset(w, cornerLength), paint); // vertical

    // bottom left
    canvas.drawLine(Offset(-halfStroke, h), Offset(cornerLength, h), paint); // horizontal
    canvas.drawLine(Offset(0, h - cornerLength), Offset(0, h + halfStroke), paint); // vertical

    // bottom right
    canvas.drawLine(Offset(w - cornerLength, h), Offset(w + halfStroke, h), paint); // horizontal
    canvas.drawLine(Offset(w, h - cornerLength), Offset(w, h + halfStroke), paint); // vertical
  }
}
