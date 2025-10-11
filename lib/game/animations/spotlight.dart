import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

/// A spotlight effect that covers the entire screen with black
/// except for a circular area around a target center. Can animate
/// shrinking the circle to reveal or hide the world.
class Spotlight extends PositionComponent with HasGameReference<PixelAdventure> {
  final Vector2 targetCenter;
  final double targetRadius;

  Spotlight({required this.targetCenter, this.targetRadius = 50});

  late double radius;

  @override
  FutureOr<void> onLoad() {
    radius = game.size.x;
    priority = GameSettings.spotlightAnimationLayer;
    return super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // create a new layer to safely apply the blend mode
    final layerPaint = Paint();
    canvas.saveLayer(Rect.fromLTWH(game.camera.viewfinder.position.x, 0, game.size.x, game.size.y), layerPaint);

    // draw a full black rectangle covering the entire screen
    final paint = Paint()..color = Colors.black;
    canvas.drawRect(game.camera.visibleWorldRect, paint);

    // draw a transparent circle to "cut out" the spotlight
    final clearPaint = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill;
    canvas.drawCircle(targetCenter.toOffset(), radius, clearPaint);

    canvas.restore();
  }

  /// Animates the spotlight from the current radius to the target radius
  /// over the given duration using an ease-in curve.
  Future<void> startAnimation(double duration) {
    final completer = Completer<void>();

    final controller = CurvedEffectController(duration, Curves.easeInOutCubicEmphasized);
    add(
      FunctionEffect<Spotlight>(
        (spotlight, progress) {
          radius = game.size.length - (game.size.length - targetRadius) * progress;
        },
        controller,
        onComplete: () => completer.complete(),
      ),
    );

    return completer.future;
  }

  /// Animates the spotlight to shrink the circle down to zero radius,
  /// effectively making the entire screen black over the given duration.
  Future<void> shrinkToBlack(double duration) {
    final completer = Completer<void>();

    final startRadius = radius;
    final controller = CurvedEffectController(duration, Curves.easeInOutCubicEmphasized);
    add(
      FunctionEffect<Spotlight>(
        (spotlight, progress) {
          radius = startRadius * (1 - progress);
        },
        controller,
        onComplete: () {
          completer.complete();
        },
      ),
    );

    return completer.future;
  }
}
