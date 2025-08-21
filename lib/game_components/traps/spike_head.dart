import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game_components/level/player.dart';
import 'package:pixel_adventure/game_components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum SpikeHeadState implements AnimationState {
  idle('Idle', 1),
  blink('Blink', 4, loop: false),
  topHit('Top Hit', 4, loop: false),
  bottomHit('Bottom Hit', 4, loop: false);

  @override
  final String name;
  @override
  final int amount;
  @override
  final bool loop;

  const SpikeHeadState(this.name, this.amount, {this.loop = true});
}

class SpikeHead extends PositionComponent
    with FixedGridOriginalSizeGroupAnimation, PlayerCollision, HasGameReference<PixelAdventure>, CollisionCallbacks {
  // constructor parameters
  final double _offsetPos;
  final Player _player;

  SpikeHead({required double offsetPos, required Player player, required super.position})
    : _offsetPos = offsetPos,
      _player = player,
      super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2.all(64);

  // actual hitbox
  late final CompositeHitbox _hitbox;

  // animation settings
  static const double _stepTime = 0.05;
  static final Vector2 _textureSize = Vector2(54, 52);
  static const String _path = 'Traps/Spike Head/';
  static const String _pathEnd = ' (54x52).png';

  // range
  late final double _rangeNeg;
  late final double _rangePos;

  // actual borders that compensate for the hitbox
  late final double _topBorder;
  late final double _bottomtBorder;

  // movement
  double _moveDirection = 1;
  late double _moveSpeed;
  final double _moveSpeedUp = 100; // [Adjustable]
  final double _moveSpeedDown = 850; // [Adjustable]

  // direction change
  bool _directionChangePending = false;
  final Duration _delayAtBottom = Duration(milliseconds: 1200); // [Adjustable]
  final Duration _delayAtTop = Duration(milliseconds: 2000); // [Adjustable]
  final Duration _delayBlinkBeforeMove = Duration(milliseconds: 400); // [Adjustable]

  @override
  FutureOr<void> onLoad() {
    _setUpHitbox();
    _initialSetup();
    _loadAllSpriteAnimations();
    _setUpRange();
    _setUpActualBorders();
    _correctingStartPosition();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (!_directionChangePending) _movement(dt);
    super.update(dt);
  }

  void _setUpHitbox() {
    _hitbox = CompositeHitbox(
      position: Vector2(10, 10),
      size: Vector2(44, 44),
      children: [
        _makeHitbox(Vector2(8, 0), Vector2(28, 8)), // top
        _makeHitbox(Vector2(36, 8), Vector2(8, 28)), // right
        _makeHitbox(Vector2(8, 36), Vector2(28, 8)), // bottom
        _makeHitbox(Vector2(0, 8), Vector2(8, 28)), // left
      ],
    );
  }

  RectangleHitbox _makeHitbox(Vector2 position, Vector2 size) =>
      RectangleHitbox(position: position, size: size, collisionType: CollisionType.passive)..debugColor = AppTheme.debugColorTrapHitbox;

  void _initialSetup() {
    // debug
    if (game.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
      _hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    priority = PixelAdventure.trapLayerLevel;
    add(_hitbox);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<SpikeHeadState>(game, _path, _pathEnd, _stepTime, _textureSize);
    final animations = {for (var state in SpikeHeadState.values) state: loadAnimation(state)};
    addAnimationGroupComponent(textureSize: _textureSize, animations: animations, current: SpikeHeadState.idle, isBottomCenter: false);
  }

  void _setUpRange() {
    _rangeNeg = position.y;
    _rangePos = position.y + height + _offsetPos * PixelAdventure.tileSize;
  }

  void _setUpActualBorders() {
    _topBorder = _rangeNeg - _hitbox.position.y;
    _bottomtBorder = _rangePos - height + _hitbox.position.y;
  }

  void _correctingStartPosition() {
    position.y = _topBorder;
    _moveSpeed = _moveSpeedDown;
  }

  void _movement(double dt) {
    // change move direction if we reached the borders
    if (position.y >= _bottomtBorder && _moveDirection != -1) {
      _changeDirection(-1);
    } else if (position.y <= _topBorder && _moveDirection != 1) {
      _changeDirection(1);
    } else {
      // movement
      final newPositionY = position.y + _moveDirection * _moveSpeed * dt;
      position.y = newPositionY.clamp(_topBorder, _bottomtBorder);
    }
  }

  Future<void> _changeDirection(double newDirection) async {
    _directionChangePending = true;
    final SpikeHeadState hitAnimation;
    if (newDirection == 1) {
      hitAnimation = SpikeHeadState.topHit;
      _moveSpeed = _moveSpeedDown;
    } else {
      hitAnimation = SpikeHeadState.bottomHit;
      _moveSpeed = _moveSpeedUp;
    }
    _moveDirection = newDirection;
    animationGroupComponent.current = hitAnimation;
    await animationGroupComponent.animationTickers![hitAnimation]!.completed;
    animationGroupComponent.current = SpikeHeadState.idle;
    await Future.delayed((newDirection == 1 ? _delayAtTop : _delayAtBottom) - _delayBlinkBeforeMove);
    animationGroupComponent.current = SpikeHeadState.blink;
    await animationGroupComponent.animationTickers![SpikeHeadState.blink]!.completed;
    await Future.delayed(_delayBlinkBeforeMove);
    _directionChangePending = false;
  }

  @override
  void onPlayerCollisionStart(Vector2 intersectionPoint) => _player.collidedWithEnemy();
}
