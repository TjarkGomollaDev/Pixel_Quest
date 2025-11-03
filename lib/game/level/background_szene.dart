import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/rendering.dart';

enum Szene {
  szene1('Szene 1', 4),
  szene2('Szene 2', 5),
  szene3('Szene 3', 4),
  szene4('Szene 4', 5),
  szene5('Szene 5', 3),
  szene6('Szene 6', 4);

  final String fileName;
  final int amount;

  const Szene(this.fileName, this.amount);

  static const Szene defaultSzene = Szene.szene1;

  static Szene getDefault() => defaultSzene;

  static Szene fromName(String name) => Szene.values.firstWhere((e) => e.name == name, orElse: () => defaultSzene);
}

class BackgroundSzene extends ParallaxComponent with HasVisibility {
  final Szene _szene;
  final bool _show;

  BackgroundSzene({required Szene szene, required super.position, required super.size, bool show = true}) : _szene = szene, _show = show;

  // animation settings
  static const String _path = 'Background/';
  static const String _pathEnd = '.png';
  static final Vector2 _baseVelocity = Vector2(0.5, 0);
  static final Vector2 _velocityMultiplierDelta = Vector2(1.8, 0);

  @override
  Future<void> onLoad() async {
    parallax = await game.loadParallax(
      [for (var i = 1; i <= _szene.amount; i++) ParallaxImageData('$_path${_szene.fileName}/$i$_pathEnd')],
      velocityMultiplierDelta: _velocityMultiplierDelta,
      repeat: ImageRepeat.repeatX,
      fill: LayerFill.height,
    );

    _show ? show() : hide();
  }

  void show() {
    isVisible = true;
    parallax!.baseVelocity = _baseVelocity;
  }

  void hide() {
    isVisible = false;
    parallax!.baseVelocity = Vector2.zero();
  }
}
