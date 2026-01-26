import 'package:flame/components.dart';
import 'package:flame/events.dart';

/// A simple overlay component that can block tap input when enabled.
///
/// Useful to prevent interaction with components behind it.
class InputBlocker extends PositionComponent with TapCallbacks {
  // constructor parameters
  bool _enabled;

  InputBlocker({required super.size, super.priority, bool enabled = false}) : _enabled = enabled;

  @override
  bool containsLocalPoint(Vector2 point) => _enabled;

  @override
  void onTapDown(TapDownEvent event) {
    if (!_enabled) return;
    event.handled = true;
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!_enabled) return;
    event.handled = true;
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    if (!_enabled) return;
    event.handled = true;
  }

  void enable() => _enabled = true;
  void disable() => _enabled = false;
}
