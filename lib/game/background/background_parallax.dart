import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:pixel_adventure/game/background/background_scene.dart';
import 'package:pixel_adventure/game/game_settings.dart';
import 'package:pixel_adventure/game/utils/visible_components.dart';

/// Parallax background component.
///
/// Can be created as:
/// - a multi-layer "scene" parallax (folder with numbered layers)
/// - a single-image colored background
class BackgroundParallax extends ParallaxComponent with VisibleComponent {
  // constructor parameters
  final List<ParallaxImageData> _layers;
  final Vector2 _baseVelocity;
  final Vector2? _velocityMultiplierDelta;
  final ImageRepeat _repeat;
  final LayerFill _fill;

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
       _fill = fill {
    initVisibility(show);
  }

  /// Creates a multi-layer parallax background from a [BackgroundScene] folder.
  factory BackgroundParallax.scene({
    required BackgroundScene scene,
    Vector2? baseVelocity,
    Vector2? velocityMultiplierDelta,
    Vector2? position,
    Vector2? size,
    bool show = true,
  }) {
    return BackgroundParallax._(
      layers: [for (int i = 1; i <= scene.amount; i++) ParallaxImageData('$_path${scene.fileName}/$i$_pathEnd')],
      baseVelocity: baseVelocity ?? GameSettings.parallaxBaseVelocityLevel,
      velocityMultiplierDelta: velocityMultiplierDelta ?? GameSettings.velocityMultiplierDelta,
      repeat: ImageRepeat.repeatX,
      fill: LayerFill.height,
      position: position,
      size: size,
      show: show,
    );
  }

  /// Creates a single-image colored tile background from a [BackgroundColor] asset.
  factory BackgroundParallax.colored({
    required BackgroundColor color,
    Vector2? baseVelocity,
    Vector2? position,
    Vector2? size,
    bool show = true,
  }) {
    return BackgroundParallax._(
      layers: [ParallaxImageData('$_path$_pathAddColored${color.fileName}$_pathEnd')],
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
  static const String _pathAddColored = 'Colored Tiles/';
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
  }

  /// Builds a background from a string identifier.
  ///
  /// Expects an enum `name` of [BackgroundScene] or [BackgroundColor].
  /// Returns `null` if [type] is `null`, blank, or not recognized.
  static BackgroundParallax? fromType({
    String? type,
    Vector2? baseVelocity,
    Vector2? velocityMultiplierDelta,
    Vector2? position,
    Vector2? size,
    bool show = true,
  }) {
    final trimmed = type?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    final scene = BackgroundScene.fromName(trimmed, orNull: true);
    if (scene != null) {
      return BackgroundParallax.scene(
        scene: scene,
        baseVelocity: baseVelocity,
        velocityMultiplierDelta: velocityMultiplierDelta,
        position: position,
        size: size,
        show: show,
      );
    }

    final color = BackgroundColor.fromName(trimmed, orNull: true);
    return color == null
        ? null
        : BackgroundParallax.colored(color: color, baseVelocity: baseVelocity, position: position, size: size, show: show);
  }
}
