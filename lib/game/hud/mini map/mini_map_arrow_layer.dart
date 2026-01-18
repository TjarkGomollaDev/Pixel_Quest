import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/hud/mini%20map/entity_on_mini_map.dart';
import 'package:pixel_adventure/game/hud/mini%20map/mini_map.dart';
import 'package:pixel_adventure/game/game.dart';

/// A thin bar placed below the mini map frame that draws upward-pointing
/// triangle markers for entities currently obscured by the mini map.
///
/// This layer does not decide *which* entities belong on the mini map.
/// It only:
/// - receives a pre-filtered list of arrow candidates,
/// - checks which candidates are inside the mini map frame in world space,
/// - draws a triangle at the corresponding x-position within the bar.
///
/// Notes:
/// - The triangle x coordinate matches the entity occlusion center x.
/// - The camera moves only horizontally, therefore the frame's top/bottom y
///   bounds are precomputed once on load.
class MiniMapArrowLayer extends PositionComponent with HasGameReference<PixelQuest>, HasVisibility {
  // constructor parameters
  final MiniMap _miniMap;
  final List<EntityOnMiniMap> _arrowCandidates;

  MiniMapArrowLayer({required MiniMap miniMap, required List<EntityOnMiniMap> arrowCandidates, required super.position, bool show = true})
    : _miniMap = miniMap,
      _arrowCandidates = arrowCandidates {
    size = Vector2(_frameSize.x, _arrowSize.y);
    if (!show) hide();
  }

  // arrow settings
  static final Vector2 _arrowSize = Vector2(6, 7); // [Adjustable]
  late final Paint _arrowMarkerPaint;

  // internal values for correct calculation
  static final Vector2 _frameSize = MiniMap.frameSize;
  late final Vector2 _frameTopLeftToScreenTopRightOffset;
  late final double _frameTop;
  late final double _frameBottom;

  @override
  FutureOr<void> onLoad() {
    _setUpMarker();
    _setUpPreCalculations();
    return super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    _renderArrowMarkers(canvas);
    super.render(canvas);
  }

  /// Initializes paint and marker appearance.
  void _setUpMarker() => _arrowMarkerPaint = Paint()..color = AppTheme.ingameText;

  /// Precomputes values that do not change during gameplay.
  void _setUpPreCalculations() {
    _frameTopLeftToScreenTopRightOffset = _miniMap.frameTopLeftToScreenTopRightOffset;

    // because the camera only moves horizontally, the top and bottom are fixed values
    _frameTop = game.cameraWorldYBounds.top + _frameTopLeftToScreenTopRightOffset.y;
    _frameBottom = _frameTop + _frameSize.y;
  }

  /// Renders a triangle marker for every entity whose occlusion center
  /// lies within the mini map frame in world space.
  void _renderArrowMarkers(Canvas canvas) {
    // mapping the left and right of the mini map frame in the global level coordinate system
    final frameLeft = game.camera.visibleWorldRect.right - _frameTopLeftToScreenTopRightOffset.x;
    final frameRight = frameLeft + _frameSize.x;

    // based on all four values, it is now very easy to check which entities are obscured by the minimap
    for (final entity in _arrowCandidates) {
      final entityCenter = entity.occlusionPosition;
      if (entityCenter.x > frameLeft && entityCenter.y > _frameTop && entityCenter.x < frameRight && entityCenter.y < _frameBottom) {
        _renderTriangleArrowMarker(canvas, entityCenter.x - frameLeft);
      }
    }
  }

  /// Draws an upward-pointing triangle.
  void _renderTriangleArrowMarker(Canvas canvas, double x) {
    final triangle = Path()
      ..moveTo(x, 0)
      ..lineTo(x - _arrowSize.x / 2, _arrowSize.y)
      ..lineTo(x + _arrowSize.x / 2, _arrowSize.y)
      ..close();
    canvas.drawPath(triangle, _arrowMarkerPaint);
  }

  void show() => isVisible = true;
  void hide() => isVisible = false;
}
