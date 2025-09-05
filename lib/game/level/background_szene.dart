import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/rendering.dart';

enum Szene {
  szene1('Szene 1', 4),
  szene2('Szene 2', 5),
  szene3('Szene 3', 4),
  szene4('Szene 4', 5);

  final String name;
  final int amount;

  const Szene(this.name, this.amount);
}

class BackgroundSzene extends ParallaxComponent {
  final Szene _szene;

  BackgroundSzene({required Szene szene, required super.position, required super.size}) : _szene = szene;

  // animation settings
  static const String _path = 'Background/';
  static const String _pathEnd = '.png';
  static final Vector2 _baseVelocity = Vector2(0.5, 0);
  static final Vector2 _velocityMultiplierDelta = Vector2(1.8, 0);

  @override
  Future<void> onLoad() async {
    parallax = await game.loadParallax(
      [for (var i = 1; i <= _szene.amount; i++) ParallaxImageData('$_path${_szene.name}/$i$_pathEnd')],
      baseVelocity: _baseVelocity,
      velocityMultiplierDelta: _velocityMultiplierDelta,
      repeat: ImageRepeat.repeatX,
      fill: LayerFill.height,
    );
    return super.onLoad();
  }
}
