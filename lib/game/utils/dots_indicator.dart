import 'dart:ui';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';

/// A lightweight page indicator made of dots.
class DotsIndicator extends PositionComponent {
  // constructor parameters
  final int _dotCount;
  final double _dotRadius;
  final double _dotSpacing;
  final Paint _activePaint;
  final Paint _inactivePaint;
  final Paint? _bgPaint;
  final double _bgPaddingHorizontal;
  final double _bgPaddingVertical;
  final double _bgRadius;

  DotsIndicator({
    required int dotCount,
    int startIndex = 0,
    double dotRadius = 2.5,
    double spacing = 4,
    Color activeColor = AppTheme.white,
    Color inactiveColor = AppTheme.grayDark3,
    Color? backgroundColor = AppTheme.grayLight3,
    double paddingHorizontal = 4,
    double paddingVertical = 3,
    double backgroundRadius = 3,
    super.position,
    super.anchor = Anchor.topCenter,
    super.priority,
  }) : _dotCount = dotCount,
       _dotSpacing = spacing,
       _dotRadius = dotRadius,
       _activeIndex = startIndex,
       _activePaint = Paint()..color = activeColor,
       _inactivePaint = Paint()..color = inactiveColor,
       _bgPaint = backgroundColor != null ? (Paint()..color = backgroundColor) : null,
       _bgPaddingHorizontal = paddingHorizontal,
       _bgPaddingVertical = paddingVertical,
       _bgRadius = backgroundRadius {
    _computeSize();
    _activeIndex = startIndex.clamp(0, _dotCount - 1);
  }

  // active index
  int _activeIndex;

  // getter
  int get activeIndex => _activeIndex;

  // setter
  set activeIndex(int index) => _activeIndex = index.clamp(0, _dotCount - 1);

  void _computeSize() {
    final diameter = _dotRadius * 2;

    // dots content size
    final contentW = _dotCount <= 0 ? 0.0 : (_dotCount * diameter) + ((_dotCount - 1) * _dotSpacing);
    final contentH = diameter;

    // if background enabled, include padding, otherwise just content
    final w = _bgPaint != null ? contentW + _bgPaddingHorizontal * 2 : contentW;
    final h = _bgPaint != null ? contentH + _bgPaddingVertical * 2 : contentH;

    size = Vector2(w, h);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_dotCount <= 0) return;
    final diameter = _dotRadius * 2;

    // render optional background
    if (_bgPaint != null) {
      final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.x, size.y), Radius.circular(_bgRadius));
      canvas.drawRRect(rrect, _bgPaint);
    }

    // dots offsets depend on background
    final offsetX = _bgPaint != null ? _bgPaddingHorizontal : 0;
    final offsetY = _bgPaint != null ? _bgPaddingVertical : 0;
    final centerY = offsetY + (diameter / 2);

    // render dots
    for (var i = 0; i < _dotCount; i++) {
      final cx = offsetX + _dotRadius + i * (diameter + _dotSpacing);
      final paint = (i == _activeIndex) ? _activePaint : _inactivePaint;
      canvas.drawCircle(Offset(cx, centerY), _dotRadius, paint);
    }
  }
}
