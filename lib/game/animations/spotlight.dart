import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:pixel_quest/app_theme.dart';
import 'package:pixel_quest/game/game_settings.dart';
import 'package:pixel_quest/game/game.dart';
import 'package:pixel_quest/game/utils/cancelable_effects.dart';

/// A spotlight effect that covers the entire screen with black
/// except for a circular area around a target center. Can animate
/// shrinking the circle to reveal or hide the world.
class Spotlight extends PositionComponent with HasGameReference<PixelQuest>, CancelableAnimations {
  // constructor parameters
  final Vector2 _targetCenter;
  final double _targetRadius;

  Spotlight({
    required Vector2 localTargetCenter,
    double targetRadius = playerTargetRadius,
    super.position,
    super.priority = GameSettings.spotlightAnimationLayer,
  }) : _targetRadius = targetRadius,
       _targetCenter = localTargetCenter + Vector2.all(_bufferPad);

  // default target radius for player
  static const double playerTargetRadius = 60; // [Adjustable]

  // current spotlight radius
  late double _radius;

  // max spotlight radius
  late final double _fullRadius;

  // rect in the size of the spotlight layer
  late final Rect _spotlightRect;

  // buffer to avoid unexpected artefacts
  static const double _bufferPad = 2;

  // animation keys
  static const String _keyFocusOnTarget = 'focus-on-target';
  static const String _keyExpandToFull = 'expand-to-full';
  static const String _keyShrinkToBlack = 'shrink-to-black';

  @override
  FutureOr<void> onLoad() {
    _setUpSpotlight();
    return super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    // create a new layer to safely apply the blend mode
    canvas.saveLayer(_spotlightRect, Paint());

    // draw a full black rectangle covering the entire screen
    canvas.drawRect(_spotlightRect, Paint()..color = AppTheme.black);

    // draw a transparent circle to "cut out" the spotlight
    final clearPaint = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill;
    canvas.drawCircle(_targetCenter.toOffset(), _radius, clearPaint);

    canvas.restore();
    super.render(canvas);
  }

  @override
  void cancelAnimations() {
    super.cancelAnimations();
    _radius = _fullRadius;
  }

  void _setUpSpotlight() {
    size = game.camera.visibleWorldRect.toVector2() + Vector2.all(_bufferPad * 2);
    position -= Vector2.all(_bufferPad);
    _spotlightRect = Rect.fromLTWH(0, 0, size.x, size.y);
    _fullRadius = _computeFullRadius();
    _radius = _fullRadius;
  }

  double _computeFullRadius() {
    final corners = [
      Vector2(_spotlightRect.left, _spotlightRect.top),
      Vector2(_spotlightRect.right, _spotlightRect.top),
      Vector2(_spotlightRect.left, _spotlightRect.bottom),
      Vector2(_spotlightRect.right, _spotlightRect.bottom),
    ];

    // determine maximum distance
    double maxDist = 0;
    for (final corner in corners) {
      final d = (corner - _targetCenter).length;
      if (d > maxDist) maxDist = d;
    }

    return maxDist;
  }

  /// Animates the spotlight from full screen to the target radius
  /// over the given duration using an ease-in curve.
  Future<void> focusOnTarget({double duration = 2}) {
    // create effect
    final effect = FunctionEffect<Spotlight>((spotlight, progress) {
      // interpolate from full screen to target radius
      _radius = _fullRadius - (_fullRadius - _targetRadius) * progress;
    }, CurvedEffectController(duration, Curves.easeInOutCubicEmphasized));

    // register effect and return future
    return registerEffect(_keyFocusOnTarget, effect);
  }

  /// Animates the spotlight to expand back to full size,
  /// effectively revealing the whole screen again.
  Future<void> expandToFull({double duration = 2}) {
    final startRadius = _radius;
    final endRadius = _fullRadius;

    // create effect
    final effect = FunctionEffect<Spotlight>((spotlight, progress) {
      // interpolate from current radius to full screen
      _radius = startRadius + (endRadius - startRadius) * progress;
    }, CurvedEffectController(duration, Curves.easeInOutCubicEmphasized));

    // register effect and return future
    return registerEffect(_keyExpandToFull, effect);
  }

  /// Animates the spotlight to shrink the circle down to zero radius,
  /// effectively making the entire screen black over the given duration.
  Future<void> shrinkToBlack({double duration = 0.4}) {
    final startRadius = _radius;

    // create effect
    final effect = FunctionEffect<Spotlight>((spotlight, progress) {
      _radius = startRadius * (1 - progress);
    }, CurvedEffectController(duration, Curves.easeInOutCubicEmphasized));

    // register effect and return future
    return registerEffect(_keyShrinkToBlack, effect);
  }
}
