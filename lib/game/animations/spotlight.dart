import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/game_settings.dart';
import 'package:pixel_adventure/game/game.dart';

/// A spotlight effect that covers the entire screen with black
/// except for a circular area around a target center. Can animate
/// shrinking the circle to reveal or hide the world.
class Spotlight extends PositionComponent with HasGameReference<PixelQuest> {
  // constructor parameters
  final Vector2 _targetCenter;
  final double _targetRadius;

  Spotlight({required Vector2 targetCenter, double targetRadius = playerTargetRadius})
    : _targetRadius = targetRadius,
      _targetCenter = targetCenter;

  // default target radius for player
  static const double playerTargetRadius = 60;

  // spotlight radius
  late double _radius;

  @override
  FutureOr<void> onLoad() {
    _radius = game.size.length;
    priority = GameSettings.spotlightAnimationLayer;
    return super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    // create a new layer to safely apply the blend mode
    final layerPaint = Paint();
    canvas.saveLayer(Rect.fromLTWH(game.camera.viewfinder.position.x, 0, game.size.x, game.size.y), layerPaint);

    // draw a full black rectangle covering the entire screen
    final paint = Paint()..color = AppTheme.black;
    canvas.drawRect(game.camera.visibleWorldRect, paint);

    // draw a transparent circle to "cut out" the spotlight
    final clearPaint = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill;
    canvas.drawCircle(_targetCenter.toOffset(), _radius, clearPaint);

    canvas.restore();
    super.render(canvas);
  }

  /// Animates the spotlight from full screen to the target radius
  /// over the given duration using an ease-in curve.
  Future<void> focusOnTarget({double duration = 2}) {
    final completer = Completer<void>();

    // add visual effect
    add(
      FunctionEffect<Spotlight>(
        (spotlight, progress) {
          // interpolate from full screen to target radius
          _radius = game.size.length - (game.size.length - _targetRadius) * progress;
        },
        CurvedEffectController(duration, Curves.easeInOutCubicEmphasized),
        onComplete: () {
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );

    return completer.future;
  }

  /// Animates the spotlight to expand back to full size,
  /// effectively revealing the whole screen again.
  Future<void> expandToFull({double duration = 2}) {
    final completer = Completer<void>();
    final startRadius = _radius;
    final endRadius = game.size.length;

    // add visual effect
    add(
      FunctionEffect<Spotlight>(
        (spotlight, progress) {
          // interpolate from current radius to full screen
          _radius = startRadius + (endRadius - startRadius) * progress;
        },
        CurvedEffectController(duration, Curves.easeInOutCubicEmphasized),
        onComplete: () {
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );

    return completer.future;
  }

  /// Animates the spotlight to shrink the circle down to zero radius,
  /// effectively making the entire screen black over the given duration.
  Future<void> shrinkToBlack({double duration = 0.4}) {
    final completer = Completer<void>();
    final startRadius = _radius;

    // add visual effect
    add(
      FunctionEffect<Spotlight>(
        (spotlight, progress) {
          _radius = startRadius * (1 - progress);
        },
        CurvedEffectController(duration, Curves.easeInOutCubicEmphasized),
        onComplete: () {
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );

    return completer.future;
  }
}
