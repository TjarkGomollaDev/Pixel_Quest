import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
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
      _targetCenter = targetCenter {
    size = game.size;
  }

  // default target radius for player
  static const double playerTargetRadius = 60;

  // current spotlight radius
  late double _radius;

  // max spotlight radius
  late final double _fullRadius;

  // getter
  Vector2 get targetCenter => _targetCenter;

  @override
  FutureOr<void> onLoad() {
    _computeFullRadius();
    debugPrint(targetCenter.toString());
    _radius = _fullRadius;
    priority = GameSettings.spotlightAnimationLayer;
    return super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    final rect = game.camera.visibleWorldRect;

    // create a new layer to safely apply the blend mode
    canvas.saveLayer(rect, Paint());

    // draw a full black rectangle covering the entire screen
    canvas.drawRect(rect, Paint()..color = AppTheme.black);

    // draw a transparent circle to "cut out" the spotlight
    final clearPaint = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill;
    canvas.drawCircle(_targetCenter.toOffset(), _radius, clearPaint);

    canvas.restore();
    super.render(canvas);
  }

  void _computeFullRadius({double buffer = 2.0}) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    final corners = [
      Vector2(rect.left, rect.top),
      Vector2(rect.right, rect.top),
      Vector2(rect.left, rect.bottom),
      Vector2(rect.right, rect.bottom),
    ];

    // determine maximum distance
    double maxDist = 0;
    for (final corner in corners) {
      final d = (corner - _targetCenter).length;
      if (d > maxDist) maxDist = d;
    }
    debugPrint(maxDist.toString());
    _fullRadius = maxDist + buffer;
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
          _radius = _fullRadius - (_fullRadius - _targetRadius) * progress;
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
    final endRadius = _fullRadius;

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
