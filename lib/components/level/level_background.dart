import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/rendering.dart';

class LevelBackground extends ParallaxComponent {
  final String color;

  LevelBackground({this.color = 'Gray', super.position});

  final double scrollSpeed = 40;

  @override
  Future<void> onLoad() async {
    size = Vector2.all(64);
    parallax = await game.loadParallax(
      [ParallaxImageData('Background/$color.png')],
      baseVelocity: Vector2(0, -scrollSpeed),
      repeat: ImageRepeat.repeat,
      fill: LayerFill.none,
    );
    return super.onLoad();
  }
}
