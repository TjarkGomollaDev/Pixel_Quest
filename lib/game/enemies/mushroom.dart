import 'dart:async';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/collision/collision.dart';
import 'package:pixel_adventure/game/collision/entity_collision.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/utils/animation_state.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum MushroomState implements AnimationState {
  idle('Idle', 14),
  run('Run', 16),
  hit('Hit', 5, loop: false);

  @override
  final String name;
  @override
  final int amount;
  @override
  final bool loop;

  const MushroomState(this.name, this.amount, {this.loop = true});
}

/// A mushroom enemy that patrols horizontally within a specified range.
///
/// This enemy continuously moves left and right within its movement range,
/// pausing briefly and accelerating smoothly when changing direction.
/// The mushroom can be stomped by the [Player], playing a hit animation before disappearing,
/// or it will harm the player if touched from the side.
class Mushroom extends SpriteAnimationGroupComponent with EntityCollision, HasGameReference<PixelAdventure>, CollisionCallbacks {
  // constructor parameters
  final double _offsetNeg;
  final double _offsetPos;
  final bool _isLeft;
  final Player _player;

  Mushroom({required double offsetNeg, required double offsetPos, required bool isLeft, required Player player, required super.position})
    : _offsetPos = offsetPos,
      _offsetNeg = offsetNeg,
      _isLeft = isLeft,
      _player = player,
      super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2.all(32);

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(4, 14), size: Vector2(24, 18));

  // animation settings
  static final Vector2 _textureSize = Vector2.all(32);
  static const String _path = 'Enemies/Mushroom/';
  static const String _pathEnd = ' (32x32).png';

  // range
  late final double _rangeNeg;
  late final double _rangePos;

  // actual borders that compensate for the hitbox and flip offset, depending on the moveDirection
  late double _leftBorder;
  late double _rightBorder;

  // movement
  late int _moveDirection;
  final double _moveSpeed = 48; // [Adjustable]
  double _speedFactor = 1;

  // acceleration
  double _accelProgress = 1;
  final double _accelDuration = 2.6; // [Adjustable]

  // delay after direction change
  double _pauseTimer = 0;
  final double _pauseDuration = 2; // [Adjustable]

  // got stomped
  bool _gotStomped = false;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllSpriteAnimations();
    _setUpRange();
    _setUpMoveDirection();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (!_gotStomped) _movement(dt);
    super.update(dt);
  }

  void _initialSetup() {
    // debug
    if (PixelAdventure.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorEnemie;
      _hitbox.debugColor = AppTheme.debugColorEnemieHitbox;
    }

    // general
    priority = PixelAdventure.enemieLayerLevel;
    _hitbox.collisionType = CollisionType.passive;
    add(_hitbox);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<MushroomState>(game, _path, _pathEnd, PixelAdventure.stepTime, _textureSize);
    animations = {for (var state in MushroomState.values) state: loadAnimation(state)};
    current = MushroomState.run;
  }

  void _setUpRange() {
    _rangeNeg = position.x - _offsetNeg * PixelAdventure.tileSize;
    _rangePos = position.x + _offsetPos * PixelAdventure.tileSize + width;
  }

  void _setUpMoveDirection() {
    _moveDirection = _isLeft ? -1 : 1;
    if (_moveDirection == 1) flipHorizontallyAroundCenter();
    _updateActualBorders();
  }

  void _updateActualBorders() {
    _leftBorder = (_moveDirection == -1) ? _rangeNeg - _hitbox.position.x : _rangeNeg + _hitbox.position.x + _hitbox.width;
    _rightBorder = (_moveDirection == 1) ? _rangePos + _hitbox.position.x : _rangePos - _hitbox.position.x - _hitbox.width;
  }

  void _movement(double dt) {
    // short break after direction change
    if (_pauseTimer > 0) {
      _pauseTimer -= dt;
      return;
    }

    // change move direction if we reached the borders
    if (position.x >= _rightBorder && _moveDirection != -1) {
      _changeDirection(-1);
      return;
    } else if (position.x <= _leftBorder && _moveDirection != 1) {
      _changeDirection(1);
      return;
    }

    if (_accelProgress == 0) current = MushroomState.run;

    // movement
    final currentSpeed = _calculateCurrentSpeed(dt);
    final newPositionX = position.x + _moveDirection * currentSpeed * dt;
    position.x = newPositionX.clamp(_leftBorder, _rightBorder);
  }

  void _changeDirection(int newDirection) {
    current = MushroomState.idle;
    _moveDirection = newDirection;
    flipHorizontallyAroundCenter();

    // after changing the direction, we need to adjust the borders and overwrite the x position manually
    _updateActualBorders();
    position.x = _moveDirection == 1 ? _leftBorder : _rightBorder;

    // reset acceleration and timer
    _speedFactor = 0;
    _accelProgress = 0;
    _pauseTimer = _pauseDuration;
  }

  double _calculateCurrentSpeed(double dt) {
    // check whether we have reached maximum speed
    if (!(_accelProgress < 1)) return _moveSpeed;

    // calculate speed factor
    _accelProgress = (_accelProgress + dt / _accelDuration).clamp(0.0, 1.0);
    _speedFactor = 1 - pow(1 - _accelProgress, 3).toDouble();

    // calculate current speed
    return _moveSpeed * _speedFactor;
  }

  @override
  void onEntityCollision(CollisionSide collisionSide) {
    if (_gotStomped) return;
    if (collisionSide == CollisionSide.Top) {
      _gotStomped = true;
      _player.bounceUp();
      current = MushroomState.hit;
      animationTickers![MushroomState.hit]!.completed.whenComplete(() => removeFromParent());
    } else {
      _player.collidedWithEnemy(collisionSide);
    }
  }

  @override
  ShapeHitbox get entityHitbox => _hitbox;
}
