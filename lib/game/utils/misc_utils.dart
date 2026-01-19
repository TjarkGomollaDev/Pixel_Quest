import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

Vector2 offsetToVector(Offset offset) => Vector2(offset.dx, offset.dy);

/// Yields execution to Flutter for a frame.
///
/// Calling this allows the main isolate to briefly return control to the
/// Flutter engine so it can render pending frames or process UI updates.
///
/// This is useful when performing heavy synchronous work in multiple steps.
/// By yielding between chunks, the UI remains responsive and avoids visible
/// stutter or frame drops.
Future<void> yieldFrame() => WidgetsBinding.instance.endOfFrame;

List<Vector2> calculateStarPositions(Vector2 center, double radius) {
  final positions = <Vector2>[];
  final baseAngle = -90.0; // -90° upward
  final offsets = [-28, 0, 28]; // left, center, right

  for (final offset in offsets) {
    final rad = (baseAngle + offset) * (pi / 180.0);
    positions.add(Vector2(center.x + radius * cos(rad), center.y + radius * sin(rad)));
  }

  return positions;
}

mixin Respawnable on PositionComponent {
  void onRespawn();
}
