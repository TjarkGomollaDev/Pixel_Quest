import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_quest.dart';

/// Renders a row of sprites or sprite animations along the given side of a [PositionComponent].
///
/// The components are positioned in a straight line (horizontal or vertical) depending on [side],
/// and rotated accordingly (0 = top, 1 = right, 2 = bottom, 3 = left).
///
/// You must provide either a [sprite] **or** a [spriteAnimation].
/// If both are provided, [spriteAnimation] takes precedence.
void addSpriteRow({
  required PixelQuest game,
  required int side,
  required double count,
  required PositionComponent parent,
  Sprite? sprite,
  SpriteAnimation? animation,
}) {
  for (int i = 0; i < count; i++) {
    final component = animation != null
        ? SpriteAnimationComponent(animation: animation, size: Vector2(GameSettings.tileSize, GameSettings.tileSize))
        : SpriteComponent(sprite: sprite, size: Vector2(GameSettings.tileSize, GameSettings.tileSize));

    component.debugColor = AppTheme.transparent;

    final angle = [0.0, 1.5708, 3.1416, 4.7124][side - 1];
    final position = switch (side) {
      2 => Vector2(parent.size.x, i * GameSettings.tileSize),
      3 => Vector2(parent.size.x - i * GameSettings.tileSize, parent.size.y),
      4 => Vector2(0, i * GameSettings.tileSize + parent.size.x),
      _ => Vector2(i * GameSettings.tileSize, 0),
    };

    component
      ..angle = angle
      ..position = position;

    // to make it look nicer in the end, the animations should not all start on the same frame
    if (component is SpriteAnimationComponent) {
      final amount = component.animation!.frames.length;
      final randomIndex = Random().nextInt(amount);
      component.animationTicker!.currentIndex = randomIndex;
    }

    parent.add(component);
  }
}

mixin Respawnable on PositionComponent {
  void onRespawn();
}

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
