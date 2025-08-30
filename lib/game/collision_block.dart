import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class CollisionBlock extends PositionComponent with HasGameReference<PixelAdventure>, CollisionCallbacks, SolidBlock {
  final bool isPlattform;
  CollisionBlock({this.isPlattform = false, super.position, super.size});
  late final RectangleHitbox hitbox;

  @override
  FutureOr<void> onLoad() {
    hitbox = RectangleHitbox(size: size)..collisionType = CollisionType.passive;
    add(hitbox);
    debugMode = game.customDebug;
    isPlattform ? debugColor = Colors.amberAccent : debugColor = Colors.yellow;
    return super.onLoad();
  }

  @override
  void onMount() {
    debugPrint(hitbox.toAbsoluteRect().toString());
    super.onMount();
  }
}

mixin SolidBlock {}
