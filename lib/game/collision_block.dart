import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class WorldBlock extends PositionComponent with HasGameReference<PixelAdventure>, CollisionCallbacks, CollisionBlock {
  final bool isPlattform;
  WorldBlock({this.isPlattform = false, super.position, super.size});
  late final RectangleHitbox _hitbox;

  @override
  FutureOr<void> onLoad() {
    _hitbox = RectangleHitbox(size: size)..collisionType = CollisionType.passive;
    add(_hitbox);
    debugMode = game.customDebug;
    isPlattform ? debugColor = Colors.amberAccent : debugColor = Colors.yellow;
    return super.onLoad();
  }

  @override
  ShapeHitbox get solidHitbox => _hitbox;
}

mixin CollisionBlock {
  ShapeHitbox get solidHitbox;
}
