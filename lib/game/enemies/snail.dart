import 'dart:async';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/collision/collision.dart';
import 'package:pixel_adventure/game/collision/entity_collision.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/utils/animation_state.dart';
import 'package:pixel_adventure/game/utils/grid.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum SnailState implements AnimationState {
  // snail
  snailIdle('Idle', 15),
  snailWalk('Walk', 10),
  snailHit('Hit', 5, loop: false),

  // shell
  shellIdle('Shell Idle', 1),
  shellSpin('Shell Idle', 6),
  shellWallHit('Shell Wall Hit', 4, loop: false),
  shellTopHit('Shell Top Hit', 5, loop: false);

  @override
  final String name;
  @override
  final int amount;
  @override
  final bool loop;

  const SnailState(this.name, this.amount, {this.loop = true});
}

class Snail extends PositionComponent
    with FixedGridOriginalSizeGroupAnimation, EntityCollision, HasGameReference<PixelAdventure>, CollisionCallbacks {
  final double _offsetNeg;
  final double _offsetPos;
  final bool _isLeft;
  final Player _player;

  Snail({required double offsetNeg, required double offsetPos, required bool isLeft, required Player player, required super.position})
    : _offsetNeg = offsetNeg,
      _offsetPos = offsetPos,
      _isLeft = isLeft,
      _player = player,
      super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2(48, 32);

  // actual snail hitbox
  final _hitbox = RectangleHitbox(position: Vector2(11, 11), size: Vector2(28, 21));

  // actual shell hitbox
  final _shellHitbox = RectangleHitbox(position: Vector2(16, 13), size: Vector2(20, 19));

  // animation settings
  static final Vector2 _textureSize = Vector2(38, 24);
  static const String _path = 'Enemies/Snail/';
  static const String _pathEnd = ' (38x24).png';

  // range
  late final double _rangeNeg;
  late final double _rangePos;

  // actual borders that compensate for the hitbox and flip offset, depending on the moveDirection
  late double _leftBorder;
  late double _rightBorder;

  // snail movement
  late int _moveDirection;
  final double _moveSpeed = 28; // [Adjustable]
  double _speedFactor = 1;

  // snail acceleration
  double _accelProgress = 1;
  final double _accelDuration = 1.4; // [Adjustable]

  // delay after direction change
  double _pauseTimer = 0;
  final double _pauseDuration = 1.2; // [Adjustable]

  // shell movement
  late double _shellMoveDirection;
  final double _shellMoveSpeed = 220; // [Adjustable]

  // status
  bool _snailGotStomped = false;
  bool _shellGotKicked = false;
  bool _shellGotStomped = false;

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
    if (_shellGotStomped) return super.update(dt);
    if (!_snailGotStomped) {
      _snailMovement(dt);
    } else if (_shellGotKicked) {
      _shellMovement(dt);
    }
    super.update(dt);
  }

  void _initialSetup() {
    // debug
    if (GameSettings.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorEnemie;
      _hitbox.debugColor = AppTheme.debugColorEnemieHitbox;
      _shellHitbox.debugColor = AppTheme.debugColorEnemieHitbox;
    }

    // general
    priority = GameSettings.enemieLayerLevel;
    _hitbox.collisionType = CollisionType.passive;
    _shellHitbox.collisionType = CollisionType.passive;
    add(_hitbox);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<SnailState>(game, _path, _pathEnd, GameSettings.stepTime, _textureSize);
    final animations = {for (var state in SnailState.values) state: loadAnimation(state)};
    addAnimationGroupComponent(textureSize: _textureSize, animations: animations, current: SnailState.snailWalk);
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
    _leftBorder = (_snailGotStomped ? _shellMoveDirection == -1 : _moveDirection == -1)
        ? _rangeNeg - _hitbox.position.x
        : _rangeNeg + _hitbox.position.x + _hitbox.width;
    _rightBorder = (_snailGotStomped ? _shellMoveDirection == 1 : _moveDirection == 1)
        ? _rangePos + _hitbox.position.x
        : _rangePos - _hitbox.position.x - _hitbox.width;
  }

  void _snailMovement(double dt) {
    // short break after direction change
    if (_pauseTimer > 0) {
      _pauseTimer -= dt;
      return;
    }

    // change move direction if we reached the borders
    if (position.x >= _rightBorder && _moveDirection != -1) {
      _changeSnailDirection(-1);
      return;
    } else if (position.x <= _leftBorder && _moveDirection != 1) {
      _changeSnailDirection(1);
      return;
    }

    if (_accelProgress == 0) animationGroupComponent.current = SnailState.snailWalk;

    // movement
    final currentSpeed = _calculateCurrentSnailSpeed(dt);
    final newPositionX = position.x + _moveDirection * currentSpeed * dt;
    position.x = newPositionX.clamp(_leftBorder, _rightBorder);
  }

  void _changeSnailDirection(int newDirection) {
    animationGroupComponent.current = SnailState.snailIdle;
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

  double _calculateCurrentSnailSpeed(double dt) {
    // check whether we have reached maximum speed
    if (!(_accelProgress < 1)) return _moveSpeed;

    // calculate speed factor
    _accelProgress = (_accelProgress + dt / _accelDuration).clamp(0.0, 1.0);
    _speedFactor = 1 - pow(1 - _accelProgress, 3).toDouble();

    // calculate current speed
    return _moveSpeed * _speedFactor;
  }

  void _shellMovement(double dt) {
    // change move direction if we reached the borders
    if (position.x >= _rightBorder && _shellMoveDirection != -1) {
      _changeShellDirection(-1);
      return;
    } else if (position.x <= _leftBorder && _shellMoveDirection != 1) {
      _changeShellDirection(1);
      return;
    }

    // movement
    final newPositionX = position.x + _shellMoveDirection * _shellMoveSpeed * dt;
    position.x = newPositionX.clamp(_leftBorder, _rightBorder);
  }

  void _changeShellDirection(double newDirection) {
    _shellWallHit();
    animationGroupComponent.current = SnailState.shellWallHit;
    _shellMoveDirection = newDirection;
    flipHorizontallyAroundCenter();

    // after changing the direction, we need to adjust the borders and overwrite the x position manually
    _updateActualBorders();
    position.x = _shellMoveDirection == 1 ? _leftBorder : _rightBorder;
  }

  Future<void> _shellWallHit() async {
    animationGroupComponent.current = SnailState.shellWallHit;
    await animationGroupComponent.animationTickers![SnailState.shellWallHit]!.completed;
    animationGroupComponent.current = SnailState.shellSpin;
  }

  @override
  void onEntityCollision(CollisionSide collisionSide) {
    if (!_snailGotStomped) {
      _handleSnailStomp(collisionSide);
    } else if (!_shellGotKicked) {
      _handleShellKick();
    } else if (!_shellGotStomped) {
      _handleShellStomp(collisionSide);
    }
  }

  Future<void> _handleSnailStomp(CollisionSide collisionSide) async {
    if (collisionSide == CollisionSide.Top) {
      _snailGotStomped = true;
      _player.bounceUp();
      animationGroupComponent.current = SnailState.snailHit;
      await animationGroupComponent.animationTickers![SnailState.snailHit]!.completed;
      if (_shellGotStomped) return;
      animationGroupComponent.current = SnailState.shellIdle;

      // change snail to shell and update hitbox
      _hitbox.position = _shellHitbox.position;
      _hitbox.size = _shellHitbox.size;
    } else {
      _player.collidedWithEnemy(collisionSide);
    }
  }

  void _handleShellKick() {
    animationGroupComponent.current = SnailState.shellSpin;
    _shellGotKicked = true;
    final shellPositionLeftX = (scale.x > 0) ? position.x + _hitbox.position.x : position.x - _hitbox.position.x - _hitbox.width;
    final shellPositionRightX = shellPositionLeftX + _hitbox.width;
    final shellCenter = (shellPositionLeftX + shellPositionRightX) / 2;
    final playerCenter = (_player.hitboxLeft + _player.hitboxRight) / 2;
    _shellMoveDirection = playerCenter >= shellCenter ? -1 : 1;
    if (_shellMoveDirection != _moveDirection) flipHorizontallyAroundCenter();
    _updateActualBorders();
  }

  void _handleShellStomp(CollisionSide collisionSide) {
    if (collisionSide == CollisionSide.Top) {
      _shellGotStomped = true;
      _player.bounceUp();
      animationGroupComponent.animationTickers![SnailState.snailHit]?.onComplete?.call();
      animationGroupComponent.current = SnailState.shellTopHit;
      animationGroupComponent.animationTickers![SnailState.shellTopHit]!.completed.then((_) => removeFromParent());
    } else {
      _player.collidedWithEnemy(collisionSide);
    }
  }

  @override
  ShapeHitbox get entityHitbox => _hitbox;
}
