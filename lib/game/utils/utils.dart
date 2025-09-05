import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

/// Renders a row of sprites or sprite animations along the given side of a [PositionComponent].
///
/// The components are positioned in a straight line (horizontal or vertical) depending on [side],
/// and rotated accordingly (0 = top, 1 = right, 2 = bottom, 3 = left).
///
/// You must provide either a [sprite] **or** a [spriteAnimation].
/// If both are provided, [spriteAnimation] takes precedence.
void addSpriteRow({
  required PixelAdventure game,
  required int side,
  required double count,
  required PositionComponent parent,
  Sprite? sprite,
  SpriteAnimation? animation,
}) {
  for (int i = 0; i < count; i++) {
    final component = animation != null
        ? SpriteAnimationComponent(animation: animation, size: Vector2(PixelAdventure.tileSize, PixelAdventure.tileSize))
        : SpriteComponent(sprite: sprite, size: Vector2(PixelAdventure.tileSize, PixelAdventure.tileSize));

    component.debugColor = Colors.transparent;

    final angle = [0.0, 1.5708, 3.1416, 4.7124][side - 1];
    final position = switch (side) {
      2 => Vector2(parent.size.x, i * PixelAdventure.tileSize),
      3 => Vector2(parent.size.x - i * PixelAdventure.tileSize, parent.size.y),
      4 => Vector2(0, i * PixelAdventure.tileSize + parent.size.x),
      _ => Vector2(i * PixelAdventure.tileSize, 0),
    };

    component
      ..angle = angle
      ..position = position;

    parent.add(component);
  }
}

mixin Respawnable on PositionComponent {
  void onRespawn();
}
