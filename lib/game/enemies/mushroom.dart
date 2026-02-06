import 'dart:async';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_quest/app_theme.dart';
import 'package:pixel_quest/data/audio/ambient_loop_emitter.dart';
import 'package:pixel_quest/game/collision/collision.dart';
import 'package:pixel_quest/game/collision/entity_collision.dart';
import 'package:pixel_quest/game/hud/mini%20map/entity_on_mini_map.dart';
import 'package:pixel_quest/game/level/player/player.dart';
import 'package:pixel_quest/game/utils/animation_state.dart';
import 'package:pixel_quest/game/utils/load_sprites.dart';
import 'package:pixel_quest/game/game_settings.dart';
import 'package:pixel_quest/game/game.dart';

enum _MushroomState implements AnimationState {
  idle('Idle', 14),
  run('Run', 16),
  hit('Hit', 5, loop: false);

  @override
  final String fileName;
  @override
  final int amount;
  @override
  final bool loop;

  const _MushroomState(this.fileName, this.amount, {this.loop = true});
}

/// A mushroom enemy that patrols horizontally within a specified range.
///
/// This enemy continuously moves left and right within its movement range,
/// pausing briefly and accelerating smoothly when changing direction.
class Mushroom extends SpriteAnimationGroupComponent
    with EntityCollision, EntityOnMiniMap, HasGameReference<PixelQuest>, AmbientLoopEmitter {
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
  static final Vector2 gridSize = .all(32);

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(4, 14), size: Vector2(24, 18));

  // animation settings
  static final Vector2 _textureSize = .all(32);
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

  @override
  void onEntityCollision(CollisionSide collisionSide) {
    if (_gotStomped) return;
    if (collisionSide == .top) {
      _gotStomped = true;
      _player.bounceUp();

      // play hit animation and then remove from level
      game.audioCenter.playSound(.enemieHit, .game);
      stopAmbientLoop();
      current = _MushroomState.hit;
      animationTickers![_MushroomState.hit]!.completed.whenComplete(() => removeFromParent());
    } else {
      _player.collidedWithEnemy(collisionSide);
    }
  }

  @override
  ShapeHitbox get entityHitbox => _hitbox;

  void _initialSetup() {
    // debug
    if (GameSettings.customDebugMode) {
      debugMode = true;
      debugColor = AppTheme.debugColorEnemie;
      _hitbox.debugColor = AppTheme.debugColorEnemieHitbox;
    }

    // general
    priority = GameSettings.enemieLayerLevel;
    _hitbox.collisionType = .passive;
    add(_hitbox);
    configureAmbientLoop(loop: .mushroom, hitbox: _hitbox, guard: () => _speedFactor > 0.0001, guardFadeOut: false);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<_MushroomState>(game, _path, _pathEnd, GameSettings.stepTime, _textureSize);
    animations = {for (final state in _MushroomState.values) state: loadAnimation(state)};
    current = _MushroomState.run;
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

    if (_accelProgress == 0) current = _MushroomState.run;

    // movement
    final currentSpeed = _calculateCurrentSpeed(dt);
    final newPositionX = position.x + _moveDirection * currentSpeed * dt;
    position.x = newPositionX.clamp(_leftBorder, _rightBorder);
  }

  void _changeDirection(int newDirection) {
    current = _MushroomState.idle;
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
}
