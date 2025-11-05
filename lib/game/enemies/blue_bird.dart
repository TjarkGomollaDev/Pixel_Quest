import 'dart:async';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/collision/collision.dart';
import 'package:pixel_adventure/game/collision/entity_collision.dart';
import 'package:pixel_adventure/game/hud/entity_on_mini_map.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/utils/animation_state.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_quest.dart';

enum BlueBirdState implements AnimationState {
  fly('Flying', 9),
  hit('Hit', 5, loop: false);

  @override
  final String fileName;
  @override
  final int amount;
  @override
  final bool loop;

  const BlueBirdState(this.fileName, this.amount, {this.loop = true});
}

class BlueBird extends SpriteAnimationGroupComponent with EntityCollision, EntityOnMiniMap, HasGameReference<PixelQuest> {
  // constructor parameters
  final double _offsetNeg;
  final double _offsetPos;
  final bool _isLeft;
  final Player _player;

  BlueBird({required double offsetNeg, required double offsetPos, required bool isLeft, required Player player, required super.position})
    : _offsetNeg = offsetNeg,
      _offsetPos = offsetPos,
      _isLeft = isLeft,
      _player = player,
      super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2.all(32);

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(4, 6), size: Vector2(24, 19));

  // animation settings
  static final Vector2 _textureSize = Vector2.all(32);
  static const String _path = 'Enemies/BlueBird/';
  static const String _pathEnd = ' (32x32).png';

  // range
  late final double _rangeNeg;
  late final double _rangePos;

  // actual borders that compensate for the hitbox and flip offset, depending on the moveDirection
  late double _leftBorder;
  late double _rightBorder;

  // movement
  late int _moveDirection;
  final double _moveSpeed = 24; // [Adjustable]
  double _speedFactor = 1;

  // acceleration
  double _accelProgress = 1;
  final double _accelDuration = 1.4; // [Adjustable]

  // vertical wave movement
  late final double _startY;
  double _waveTime = 0;
  final double _waveAmplitude = 4; // [Adjustable] height of upward/downward movement
  final double _waveSpeed = 11; // [Adjustable]

  // delay after direction change
  double _pauseTimer = 0;
  final double _pauseDuration = 1; // [Adjustable]

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
    if (GameSettings.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorEnemie;
      _hitbox.debugColor = AppTheme.debugColorEnemieHitbox;
    }

    // general
    priority = GameSettings.enemieLayerLevel;
    _hitbox.collisionType = CollisionType.passive;
    _startY = position.y;
    add(_hitbox);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<BlueBirdState>(game, _path, _pathEnd, GameSettings.stepTime, _textureSize);
    animations = {for (var state in BlueBirdState.values) state: loadAnimation(state)};
    current = BlueBirdState.fly;
  }

  void _setUpRange() {
    _rangeNeg = position.x - _offsetNeg * GameSettings.tileSize;
    _rangePos = position.x + _offsetPos * GameSettings.tileSize + width;
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
    // vertical wave movement
    _waveTime += dt * _waveSpeed;
    position.y = _startY + sin(_waveTime) * _waveAmplitude;

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

    // movement
    final currentSpeed = _calculateCurrentSpeed(dt);
    final newPositionX = position.x + _moveDirection * currentSpeed * dt;
    position.x = newPositionX.clamp(_leftBorder, _rightBorder);
  }

  void _changeDirection(int newDirection) {
    _moveDirection = newDirection;
    flipHorizontallyAroundCenter();

    // after changing the direction, we need to adjust the borders and overwrite the x position
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
      current = BlueBirdState.hit;
      animationTickers![BlueBirdState.hit]!.completed.then((_) => removeFromParent());
    } else {
      _player.collidedWithEnemy(collisionSide);
    }
  }

  @override
  ShapeHitbox get entityHitbox => _hitbox;
}
