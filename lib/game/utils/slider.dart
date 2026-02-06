import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:pixel_quest/app_theme.dart';
import 'package:pixel_quest/game/utils/rrect.dart';
import 'package:pixel_quest/game/game.dart';

/// A simple horizontal slider component (value range `0..1`).
///
/// Supports dragging and tapping on the track to change the value.
/// You can react to the final value via [onChanged] and optionally receive
/// continuous updates while dragging via [onChangedContinuous].
class Slider extends PositionComponent with HasGameReference<PixelQuest>, DragCallbacks, TapCallbacks {
  // constructor parameters
  final void Function(double value) onChanged;
  final void Function(double value)? onChangedContinuous;

  Slider({
    required this.onChanged,
    required double width,
    this.onChangedContinuous,
    super.position,
    double initialValue = 0,
    bool enabled = true,
    super.anchor = Anchor.topCenter,
  }) : _enabled = enabled {
    size = Vector2(width, _SliderThumb._thumbSize.y);
    _value = initialValue.clamp(0, 1);
  }

  // height
  static final double defaultHeight = _SliderThumb._thumbSize.y;

  // styling
  static const double _trackHeight = 5; // [Adjustable]
  static const Color _trackColorEnabled = AppTheme.grayLight3; // [Adjustable]
  static const Color _trackColorDisabled = AppTheme.grayDark1; // [Adjustable]
  static const Color _fillColor = AppTheme.greenDark; // [Adjustable]

  // layer
  late final RRectComponent _track;
  late final RRectComponent _fill;
  late final _SliderThumb _thumb;

  // internal
  late double _value;
  late final double _minX;
  late final double _maxX;
  late final double _trackWidth;
  bool _enabled;

  @override
  Future<void> onLoad() async {
    _setUpRange();
    _setUpTrack();
    _setUpFill();
    _setUpThumb();
  }

  void _setUpRange() {
    _minX = _SliderThumb._thumbSize.x / 2;
    _maxX = size.x - _SliderThumb._thumbSize.x / 2;
    _trackWidth = _maxX - _minX;
  }

  @override
  bool onDragUpdate(DragUpdateEvent event) {
    if (!_enabled) return true;
    final localX = event.localEndPosition.x;
    _setValueFromX(localX);
    onChangedContinuous?.call(_value);
    return true;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (!_enabled) return;
    onChanged(_value);
    super.onDragEnd(event);
  }

  @override
  bool onTapDown(TapDownEvent event) {
    if (!_enabled) return true;

    // ignore tap on thumb
    if (_thumb.toRect().contains(Offset(event.localPosition.x, event.localPosition.y))) return true;

    _setValueFromX(event.localPosition.x);
    onChanged(_value);
    return true;
  }

  void _setUpTrack() {
    _track = RRectComponent(
      size: Vector2(size.x - _SliderThumb._thumbSize.x, _trackHeight),
      position: Vector2(_minX, size.y / 2 - _trackHeight / 2),
      borderRadius: 4,
      color: _enabled ? _trackColorEnabled : _trackColorDisabled,
    );
    add(_track);
  }

  void _setUpFill() {
    _fill = RRectComponent(
      size: Vector2(_enabled ? _value * _trackWidth : 0, _trackHeight),
      position: _track.position,
      borderRadius: _track.borderRadius,
      color: _fillColor,
    );
    add(_fill);
  }

  void _setUpThumb() {
    _thumb = _SliderThumb(position: Vector2(_enabled ? _minX + _value * _trackWidth : _minX, size.y / 2));
    add(_thumb);
  }

  void _setValueFromX(double x) {
    // clamp X to thumb travel range
    final clampedX = x.clamp(_minX, _maxX);

    // map to 0..1 within track
    final newValue = ((clampedX - _minX) / _trackWidth).clamp(0.0, 1.0);

    if (newValue == _value) return;
    _value = newValue;
    _updateVisuals();
  }

  void _updateVisuals() {
    // map value back to thumb center x
    final x = _minX + _value * _trackWidth;

    // update fill size and thumb position
    _fill.size.x = x - _minX;
    _thumb.position.x = x;
  }

  /// Disables interaction and shows the slider in its disabled visual state.
  void disable() {
    _enabled = false;
    if (!isLoaded) return;
    _fill.size.x = 0;
    _thumb.position.x = _minX;
    _track.color = AppTheme.grayDark1;
  }

  /// Enables interaction and restores the current value visuals.
  void enable() {
    _enabled = true;
    if (!isLoaded) return;
    _track.color = _trackColorEnabled;
    _updateVisuals();
  }
}

/// Visual thumb used by [Slider]. Purely a UI component (no input handling).
class _SliderThumb extends PositionComponent {
  _SliderThumb({super.position}) : super(size: _thumbSize, anchor: .center);

  // styling
  static final Vector2 _thumbSize = Vector2(7, 11); // [Adjustable]
  static const Color _thumbColor = AppTheme.grayDark3; // [Adjustable]
  static const Color _lineColor = AppTheme.grayDark6; // [Adjustable]

  @override
  Future<void> onLoad() async {
    _setUpThumb();
    return super.onLoad();
  }

  void _setUpThumb() {
    // background
    final bg = RRectComponent(size: size, borderRadius: 2.5, color: _thumbColor);

    // lines
    final upperLine = RRectComponent(
      color: _lineColor,
      size: Vector2(size.x - 4, 1),
      position: Vector2(size.x / 2, 2 / 5 * size.y),
      borderRadius: 2,
      anchor: .center,
    );
    final lowerLine = RRectComponent(
      color: _lineColor,
      size: upperLine.size,
      position: Vector2(size.x / 2, 3 / 5 * size.y),
      borderRadius: upperLine.borderRadius,
      anchor: upperLine.anchor,
    );

    addAll([bg, upperLine, lowerLine]);
  }
}
