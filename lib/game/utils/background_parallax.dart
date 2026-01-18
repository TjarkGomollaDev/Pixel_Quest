import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/painting.dart';
import 'package:pixel_adventure/game/game_settings.dart';

enum BackgroundSzene {
  szene1('Szene 1', 4),
  szene2('Szene 2', 5),
  szene3('Szene 3', 4),
  szene4('Szene 4', 5),
  szene5('Szene 5', 3),
  szene6('Szene 6', 4);

  final String fileName;
  final int amount;
  const BackgroundSzene(this.fileName, this.amount);

  static const BackgroundSzene defaultSzene = BackgroundSzene.szene1;
  static BackgroundSzene fromName(String name) => BackgroundSzene.values.firstWhere((e) => e.name == name, orElse: () => defaultSzene);
}

enum BackgroundColor {
  blue('Blue'),
  brown('Brown'),
  gray('Gray'),
  green('Green'),
  pink('Pink'),
  purple('Purple'),
  yellow('Yellow');

  final String fileName;
  const BackgroundColor(this.fileName);

  static const BackgroundColor defaultColor = BackgroundColor.blue;
  static BackgroundColor fromName(String name) => BackgroundColor.values.firstWhere((e) => e.name == name, orElse: () => defaultColor);
}

class BackgroundParallax extends ParallaxComponent with HasVisibility {
  // constructor parameters
  final List<ParallaxImageData> _layers;
  final Vector2 _baseVelocity;
  final Vector2? _velocityMultiplierDelta;
  final ImageRepeat _repeat;
  final LayerFill _fill;
  final bool _show;

  BackgroundParallax._({
    required List<ParallaxImageData> layers,
    required Vector2 baseVelocity,
    Vector2? velocityMultiplierDelta,
    required ImageRepeat repeat,
    required LayerFill fill,
    super.position,
    super.size,
    bool show = true,
  }) : _layers = layers,
       _baseVelocity = baseVelocity,
       _velocityMultiplierDelta = velocityMultiplierDelta,
       _repeat = repeat,
       _fill = fill,
       _show = show;

  factory BackgroundParallax.szene({
    required BackgroundSzene szene,
    Vector2? baseVelocity,
    Vector2? velocityMultiplierDelta,
    Vector2? position,
    Vector2? size,
    bool show = true,
  }) {
    return BackgroundParallax._(
      layers: [for (var i = 1; i <= szene.amount; i++) ParallaxImageData('$_path${szene.fileName}/$i$_pathEnd')],
      baseVelocity: baseVelocity ?? GameSettings.parallaxBaseVelocityLevel,
      velocityMultiplierDelta: velocityMultiplierDelta ?? GameSettings.velocityMultiplierDelta,
      repeat: ImageRepeat.repeatX,
      fill: LayerFill.height,
      position: position,
      size: size,
      show: show,
    );
  }

  factory BackgroundParallax.colored({
    required BackgroundColor color,
    Vector2? baseVelocity,
    Vector2? position,
    Vector2? size,
    bool show = true,
  }) {
    return BackgroundParallax._(
      layers: [ParallaxImageData('$_path${color.fileName}$_pathEnd')],
      baseVelocity: baseVelocity ?? GameSettings.coloredBaseVelocity,
      repeat: ImageRepeat.repeat,
      fill: LayerFill.none,
      position: position,
      size: size,
      show: show,
    );
  }

  // animation settings
  static const String _path = 'Background/';
  static const String _pathEnd = '.png';

  @override
  Future<void> onLoad() async {
    await _loadParallax();
    return super.onLoad();
  }

  Future<void> _loadParallax() async {
    parallax = await game.loadParallax(
      _layers,
      baseVelocity: _baseVelocity,
      velocityMultiplierDelta: _velocityMultiplierDelta,
      repeat: _repeat,
      fill: _fill,
    );
    _show ? show() : hide();
  }

  void show() => isVisible = true;
  void hide() => isVisible = false;
}
