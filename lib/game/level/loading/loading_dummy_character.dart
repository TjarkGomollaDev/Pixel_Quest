import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:pixel_adventure/game/level/player/player.dart';
import 'package:pixel_adventure/game/utils/curves.dart';
import 'package:pixel_adventure/game/utils/dummy_character.dart';
import 'package:pixel_adventure/game/game.dart';

class LoadingDummyCharacter extends SpriteAnimationGroupComponent with HasGameReference<PixelQuest>, DummyCharacter {
  LoadingDummyCharacter({required Vector2 screenSize}) {
    size = DummyCharacter.gridSize;

    // position points
    _startPosition = Vector2(screenSize.x / 2, -size.y);
    _midPosition = Vector2(_startPosition.x, screenSize.y / 2 - _swingOffset.y);
    _endPosition = Vector2(_startPosition.x, screenSize.y + size.y);
    position = _startPosition;
  }

  // fixed positions outside the screen
  late final Vector2 _startPosition;
  late final Vector2 _midPosition;
  late final Vector2 _endPosition;

  // duration for fall effect
  late final double _jumpDownDurationFallIn;
  late final double _jumpDownDurationFallOut;
  static const double _jumpDownMultiplier = 0.002; // [Adjustable]

  // hover state
  bool _isHovering = false;
  Completer<void>? _hoverCompleter;

  // flag indicating whether the dummy is currently being shown
  bool _isShown = false;

  // swing setup
  static final Vector2 _swingOffset = Vector2(4, 18); // [Adjustable]
  late final List<Vector2> _swingCornerPoints;
  static const double _swingTimePointToPoint = 0.36; // [Adjustable]

  @override
  FutureOr<void> onLoad() {
    _setUpSingleSwing();
    _setUpFallDuration();
    return super.onLoad();
  }

  void _setUpSingleSwing() {
    _swingCornerPoints = [
      _midPosition + Vector2(-_swingOffset.x, _swingOffset.y), // left center
      _midPosition + Vector2(0, 2 * _swingOffset.y), // bottom center
      _midPosition + Vector2(_swingOffset.x, _swingOffset.y), // right center
      _midPosition, // top center -> starting point
    ];
  }

  void _setUpFallDuration() {
    _jumpDownDurationFallIn = _jumpDownMultiplier * (_midPosition.y - _startPosition.y);
    _jumpDownDurationFallOut = _jumpDownMultiplier * (_endPosition.y - _midPosition.y);
  }

  Future<void> fallIn() async {
    if (_isShown) return;
    _isShown = true;

    // choose correct character
    animations = allCharacterAnimations[game.storageCenter.settings.character];
    current = PlayerState.fall;

    // start effects
    await _fallEffect(_midPosition, _jumpDownDurationFallIn);
    await Future.delayed(Duration(milliseconds: 50));
    _startHoverLoop();
  }

  Future<void> fallOut() async {
    if (!_isShown) return;
    _isShown = false;
    await _stopHoverLoop();
    await _fallEffect(_endPosition, _jumpDownDurationFallOut);
    position = _startPosition;
  }

  Future<void> _fallEffect(Vector2 targetPosition, double duration) {
    final completer = Completer<void>();
    final fallEffect = MoveEffect.to(
      targetPosition,
      EffectController(duration: duration, curve: JumpFallCurve()),
      onComplete: () => completer.complete(),
    );
    add(fallEffect);

    return completer.future;
  }

  void _startHoverLoop() {
    _isHovering = true;
    _hoverCompleter = Completer<void>();
    _runHoverLoop();
  }

  Future<void> _stopHoverLoop() async {
    _isHovering = false;
    await _hoverCompleter?.future;
  }

  Future<void> _runHoverLoop() async {
    while (_isHovering) {
      await _singleSwing();
    }
    _hoverCompleter?.complete();
  }

  Future<void> _singleSwing() async {
    for (var i = 0; i < 4; i++) {
      await _moveTo(_swingCornerPoints[i]);
    }
  }

  Future<void> _moveTo(Vector2 target) {
    final completer = Completer<void>();
    final effect = MoveEffect.to(target, EffectController(duration: _swingTimePointToPoint), onComplete: () => completer.complete());
    add(effect);
    return completer.future;
  }
}
