import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game_components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class Spikes extends PositionComponent with HasGameReference<PixelAdventure>, CollisionCallbacks {
  final int side;

  Spikes({required this.side, required super.position, required super.size});

  // actual hitbox
  late final RectangleHitbox hitbox;

  // count spikes
  late final double _count;

  // animation settings
  final String _path = 'Traps/Spikes/Idle.png';

  @override
  FutureOr<void> onLoad() {
    _setupHitbox();
    _initialSetup();
    _loadAnimation();
    return super.onLoad();
  }

  void _initialSetup() {
    // debug
    if (game.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
      hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    _count = (side.isOdd ? width : height) / game.tileSize;
    priority = PixelAdventure.trapLayerLevel;
    hitbox.collisionType = CollisionType.passive;
    add(hitbox);
  }

  void _setupHitbox() {
    hitbox = switch (side) {
      // right, bottom, left and default top
      2 => RectangleHitbox(position: Vector2.zero(), size: Vector2(8, height)),
      3 => RectangleHitbox(position: Vector2.zero(), size: Vector2(width, 8)),
      4 => RectangleHitbox(position: Vector2(8, 0), size: Vector2(8, height)),
      _ => RectangleHitbox(position: Vector2(0, 8), size: Vector2(width, 8)),
    };
  }

  void _loadAnimation() {
    final sprite = loadSprite(game, _path);

    for (int i = 0; i < _count; i++) {
      final spriteComponent = SpriteComponent(sprite: sprite, size: Vector2(game.tileSize, game.tileSize))..debugColor = Colors.transparent;
      final angle = [0.0, 1.5708, 3.1416, 4.7124][side > 4 || side < 1 ? 0 : (side - 1)];
      final position = switch (side) {
        // right, bottom, left and default top
        2 => Vector2(width, i * game.tileSize),
        3 => Vector2(width - i * game.tileSize, height),
        4 => Vector2(0, i * game.tileSize + width),
        _ => Vector2(i * game.tileSize, 0),
      };
      spriteComponent
        ..angle = angle
        ..position = position;
      add(spriteComponent);
    }
  }
}
