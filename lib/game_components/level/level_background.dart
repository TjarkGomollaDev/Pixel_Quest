import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/rendering.dart';

// ignore: constant_identifier_names
enum BackgroundTileColor { Blue, Brown, Gray, Green, Pink, Purple, Yellow }

class LevelBackground extends ParallaxComponent {
  final String color;

  LevelBackground({required this.color, required super.position, required super.size});

  final double scrollSpeed = 40;

  @override
  Future<void> onLoad() async {
    parallax = await game.loadParallax(
      [ParallaxImageData('Background/$color.png')],
      baseVelocity: Vector2(0, -scrollSpeed),
      repeat: ImageRepeat.repeat,
      fill: LayerFill.none,
    );
    return super.onLoad();
  }
}
