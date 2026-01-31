import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

/// `SwipeHandler` adds horizontal swipe detection to any scene.
///
/// It supports:
/// - Left / right swipe callbacks (`onSwipeLeft`, `onSwipeRight`)
/// - Distance and velocity thresholds
/// - A short cooldown to avoid double triggers
/// - Async-safe blocking when a callback returns a `Future`
///
/// ---
/// ### HOW IT WORKS
///
/// The handler tracks a single active pointer:
/// - Accumulates total drag distance (`_dx`, `_dy`)
/// - Estimates horizontal velocity (`_vx`) using real time between updates
///
/// A swipe is triggered on drag end if:
/// - The gesture is mostly horizontal
/// - AND either distance OR velocity threshold is passed
///
/// If the callback returns a `Future`, swipes are blocked until it completes.
class SwipeHandler extends PositionComponent with DragCallbacks {
  // constructor parameters
  final FutureOr<void> Function()? _onSwipeLeft;
  final FutureOr<void> Function()? _onSwipeRight;
  final double _minSwipeDistance;
  final double _minSwipeVelocity;

  SwipeHandler({
    FutureOr<void> Function()? onSwipeLeft,
    FutureOr<void> Function()? onSwipeRight,
    double minSwipeDistance = 24,
    double minSwipeVelocity = 250,
    super.position,
    super.size,
  }) : _onSwipeLeft = onSwipeLeft,
       _onSwipeRight = onSwipeRight,
       _minSwipeDistance = minSwipeDistance,
       _minSwipeVelocity = minSwipeVelocity;

  // cooldwon
  static const Duration _cooldown = Duration(milliseconds: 150);

  // flags to block further swipes during cooldown or while awaiting async callbacks
  bool _executing = false;
  bool _cooldownLocked = false;

  // drag tracking
  int? _activePointerId;
  double _dx = 0;
  double _dy = 0;
  double _vx = 0;
  int _lastUpdateUs = 0;

  // helpers
  bool get _hasCallbacks => _onSwipeLeft != null || _onSwipeRight != null;
  bool get _canSwipe => !_executing && !_cooldownLocked && _hasCallbacks;

  @override
  void onDragStart(DragStartEvent event) {
    if (!_canSwipe || _activePointerId != null) return;

    // start tracking this pointer
    _activePointerId = event.pointerId;

    // reset accumulators
    _dx = 0;
    _dy = 0;
    _vx = 0;

    // init timestamp for velocity estimation
    _lastUpdateUs = DateTime.now().microsecondsSinceEpoch;

    super.onDragStart(event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_activePointerId != event.pointerId) return;

    // delta in screen-space
    final d = event.canvasDelta;

    // accumulate total drag distance
    _dx += d.x;
    _dy += d.y;

    // estimate horizontal velocity using real-time delta
    final nowUs = DateTime.now().microsecondsSinceEpoch;
    final dt = (nowUs - _lastUpdateUs) / 1e6;
    if (dt > 0) _vx = d.x / dt;
    _lastUpdateUs = nowUs;

    super.onDragUpdate(event);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (_activePointerId != event.pointerId) return;

    // stop tracking
    _activePointerId = null;

    if (!_canSwipe) return;

    // ignore mostly-vertical gestures
    if (_dy.abs() > _dx.abs()) return;

    // pass if distance OR velocity threshold is met
    final passedDistance = _dx.abs() >= _minSwipeDistance;
    final passedVelocity = _vx.abs() >= _minSwipeVelocity;
    if (!(passedDistance || passedVelocity)) return;

    // pick callback based on swipe direction
    final isLeft = _dx < 0;
    final cb = isLeft ? _onSwipeLeft : _onSwipeRight;
    if (cb == null) return;

    // start cooldown to avoid double triggering
    _cooldownLocked = true;
    Future.delayed(_cooldown, () => _cooldownLocked = false);

    // execute callback and block if it returns a Future
    final result = cb();
    if (result is Future) {
      _executing = true;
      result.whenComplete(() => _executing = false);
    }

    super.onDragEnd(event);
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    if (_activePointerId != event.pointerId) return;

    // stop tracking and reset accumulators
    _activePointerId = null;
    _dx = 0;
    _dy = 0;
    _vx = 0;

    super.onDragCancel(event);
  }
}
