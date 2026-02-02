import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:pixel_quest/game/level/player/player.dart';
import 'package:pixel_quest/game/utils/cancelable_effects.dart';
import 'package:pixel_quest/game/utils/curves.dart';
import 'package:pixel_quest/game/utils/dummy_character.dart';
import 'package:pixel_quest/game/game.dart';

enum _DummyState { hidden, fallingIn, hovering, fallingOut }

/// Animated “loading” character that falls into view, hovers in a small loop, and falls out again.
class LoadingDummyCharacter extends SpriteAnimationGroupComponent with HasGameReference<PixelQuest>, DummyCharacter, CancelableAnimations {
  LoadingDummyCharacter({required Vector2 screenSize}) {
    size = DummyCharacter.gridSize;

    // position points
    _startPosition = Vector2(screenSize.x / 2, -size.y);
    _hoverPosition = Vector2(_startPosition.x, screenSize.y / 2 - _swingOffset.y);
    _endPosition = Vector2(_startPosition.x, screenSize.y + size.y);
    position = _startPosition;
  }

  // current state
  _DummyState _state = _DummyState.hidden;

  // fixed positions outside the screen and hover position
  late final Vector2 _startPosition;
  late final Vector2 _hoverPosition;
  late final Vector2 _endPosition;

  // durations for fall effect
  static const double _jumpDownMultiplier = 0.002; // [Adjustable]
  late final double _jumpDownDurationFallIn;
  late final double _jumpDownDurationFallOut;

  // swing setup for hovering
  static final Vector2 _swingOffset = Vector2(4, 18); // [Adjustable]
  late final List<Vector2> _swingCornerPoints;
  static const double _swingTimePointToPoint = 0.36; // [Adjustable]

  // completer to terminate the hover state
  Completer<void>? _hoverCompleter;

  // animation keys
  static const String _keyFall = 'fall';
  static const String _keyMoveToCorner = 'move-to-corner';

  @override
  FutureOr<void> onLoad() {
    _setUpSingleSwing();
    _setUpFallDuration();
    return super.onLoad();
  }

  void _setUpSingleSwing() {
    _swingCornerPoints = [
      _hoverPosition + Vector2(-_swingOffset.x, _swingOffset.y), // left center
      _hoverPosition + Vector2(0, 2 * _swingOffset.y), // bottom center
      _hoverPosition + Vector2(_swingOffset.x, _swingOffset.y), // right center
      _hoverPosition, // top center -> starting point
    ];
  }

  void _setUpFallDuration() {
    _jumpDownDurationFallIn = _jumpDownMultiplier * (_hoverPosition.y - _startPosition.y);
    _jumpDownDurationFallOut = _jumpDownMultiplier * (_endPosition.y - _hoverPosition.y);
  }

  @override
  void cancelAnimations() {
    super.cancelAnimations();

    // finish hover completer
    if (_hoverCompleter != null && !_hoverCompleter!.isCompleted) _hoverCompleter!.complete();
    _hoverCompleter = null;

    // initial state
    _state = _DummyState.hidden;
  }

  Future<void> fallIn() async {
    if (_state != _DummyState.hidden) return;
    _state = _DummyState.fallingIn;
    final token = bumpToken();

    // reset position in every fall in
    position = _startPosition;

    // choose correct dummy character
    changeChracter(game.storageCenter.inventory.character);
    current = PlayerState.fall;

    // fall in animation
    await _fall(_hoverPosition, _jumpDownDurationFallIn);
    if (token != animationToken) return;

    // start hover loop
    await Future.delayed(Duration(milliseconds: 50));
    if (token != animationToken) return;
    _startHoverLoop(token);
  }

  Future<void> fallOut() async {
    if (_state != _DummyState.hovering) return;
    _state = _DummyState.fallingOut;
    final token = bumpToken();

    // since we are no longer in the over state, the hover loop ends itself
    await _hoverCompleter?.future;
    if (token != animationToken) return;

    // fall out animation
    await _fall(_endPosition, _jumpDownDurationFallOut);
    if (token != animationToken) return;

    // update state
    _state = _DummyState.hidden;
  }

  void _startHoverLoop(int token) {
    _state = _DummyState.hovering;
    _hoverCompleter = Completer<void>();
    _runHoverLoop(token);
  }

  Future<void> _runHoverLoop(int token) async {
    while (_state == _DummyState.hovering && token == animationToken) {
      await _singleSwing(token);
    }
    if (_hoverCompleter != null && !_hoverCompleter!.isCompleted) _hoverCompleter!.complete();
    _hoverCompleter = null;
  }

  Future<void> _singleSwing(int token) async {
    for (int i = 0; i < 4; i++) {
      if (token != animationToken) return;
      await _moveToCorner(_swingCornerPoints[i]);
    }
  }

  Future<void> _moveToCorner(Vector2 target) {
    // create effect
    final effect = MoveEffect.to(target, EffectController(duration: _swingTimePointToPoint));

    // register effect and return future
    return registerEffect(_keyMoveToCorner, effect);
  }

  Future<void> _fall(Vector2 targetPosition, double duration) {
    // create effect
    final effect = MoveEffect.to(targetPosition, EffectController(duration: duration, curve: JumpFallCurve()));

    // register effect and return future
    return registerEffect(_keyFall, effect);
  }
}
