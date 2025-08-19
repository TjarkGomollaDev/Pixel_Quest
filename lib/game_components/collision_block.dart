import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class CollisionBlock extends PositionComponent with HasGameReference<PixelAdventure>, CollisionCallbacks {
  final bool isPlattform;
  CollisionBlock({this.isPlattform = false, super.position, super.size});

  @override
  FutureOr<void> onLoad() {
    add(RectangleHitbox()..collisionType = CollisionType.passive);
    debugMode = game.customDebug;
    isPlattform ? debugColor = Colors.amberAccent : debugColor = Colors.yellow;
    return super.onLoad();
  }
}
