import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/rendering.dart';

// ignore: constant_identifier_names
enum BackgroundTileColor { Blue, Brown, Gray, Green, Pink, Purple, Yellow }

class BackgroundColored extends ParallaxComponent {
  final BackgroundTileColor _color;

  BackgroundColored({required BackgroundTileColor color, required super.position, required super.size}) : _color = color;

  // animation settings
  static const String _path = 'Background/';
  static const String _pathEnd = '.png';
  static final Vector2 _baseVelocity = Vector2(0, 40);

  @override
  Future<void> onLoad() async {
    parallax = await game.loadParallax(
      [ParallaxImageData('$_path${_color.name}$_pathEnd')],
      baseVelocity: _baseVelocity,
      repeat: ImageRepeat.repeat,
      fill: LayerFill.none,
    );
    return super.onLoad();
  }
}
