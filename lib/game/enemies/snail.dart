import 'dart:async';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/data/audio/audio_center.dart';
import 'package:pixel_adventure/game/collision/collision.dart';
import 'package:pixel_adventure/game/collision/entity_collision.dart';
import 'package:pixel_adventure/game/events/game_event_bus.dart';
import 'package:pixel_adventure/game/hud/mini%20map/entity_on_mini_map.dart';
import 'package:pixel_adventure/game/level/player/player.dart';
import 'package:pixel_adventure/game/utils/animation_state.dart';
import 'package:pixel_adventure/game/utils/camera_culling.dart';
import 'package:pixel_adventure/game/utils/grid.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game/game_settings.dart';
import 'package:pixel_adventure/game/game.dart';

enum _SnailState implements AnimationState {
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
  final String fileName;
  @override
  final int amount;
  @override
  final bool loop;

  const _SnailState(this.fileName, this.amount, {this.loop = true});
}

/// A patrol enemy that turns into a kickable shell after being stomped.
///
/// The Snail starts by walking within a configured range. When the player stomps it,
/// it retreats into its shell, which can then be kicked to slide across the level and
/// bounce off walls.
class Snail extends PositionComponent
    with FixedGridOriginalSizeGroupAnimation, EntityCollision, EntityCollisionEnd, EntityOnMiniMap, HasGameReference<PixelQuest> {
  // constructor parameters
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

  // collision
  bool _playerHasLeftCollision = true;

  // subscription for game events
  GameSubscription? _sub;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _addSubscription();
    _loadAllSpriteAnimations();
    _setUpRange();
    _setUpMoveDirection();
    return super.onLoad();
  }

  @override
  void onRemove() {
    _removeSubscription();
    super.onRemove();
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

  @override
  void onEntityCollision(CollisionSide collisionSide) {
    if (!_snailGotStomped) {
      _playerHasLeftCollision = false;
      unawaited(_handleSnailStomp(collisionSide));
    } else if (!_shellGotKicked && _playerHasLeftCollision) {
      _playerHasLeftCollision = false;
      _handleShellKick(collisionSide);
    } else if (!_shellGotStomped && _playerHasLeftCollision) {
      _handleShellStomp(collisionSide);
    }
  }

  @override
  void onEntityCollisionEnd() => _playerHasLeftCollision = true;

  @override
  ShapeHitbox get entityHitbox => _hitbox;

  void _initialSetup() {
    // debug
    if (GameSettings.customDebugMode) {
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
    GameEventBus;
  }

  void _addSubscription() {
    _sub = game.eventBus.listen<PlayerRespawned>((_) => onEntityCollisionEnd());
  }

  void _removeSubscription() {
    _sub?.cancel();
    _sub = null;
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<_SnailState>(game, _path, _pathEnd, GameSettings.stepTime, _textureSize);
    final animations = {for (var state in _SnailState.values) state: loadAnimation(state)};
    addAnimationGroupComponent(textureSize: _textureSize, animations: animations, current: _SnailState.snailWalk);
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

    if (_accelProgress == 0) animationGroupComponent.current = _SnailState.snailWalk;

    // movement
    final currentSpeed = _calculateCurrentSnailSpeed(dt);
    final newPositionX = position.x + _moveDirection * currentSpeed * dt;
    position.x = newPositionX.clamp(_leftBorder, _rightBorder);
  }

  void _changeSnailDirection(int newDirection) {
    animationGroupComponent.current = _SnailState.snailIdle;
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
    unawaited(_shellWallHitAnimation());
    _shellMoveDirection = newDirection;
    flipHorizontallyAroundCenter();

    // after changing the direction, we need to adjust the borders and overwrite the x position manually
    _updateActualBorders();
    position.x = _shellMoveDirection == 1 ? _leftBorder : _rightBorder;
  }

  Future<void> _shellWallHitAnimation() async {
    game.audioCenter.playSoundIf(Sfx.enemieWallHit, game.isEntityInVisibleWorldRectX(_hitbox), SfxType.game);
    animationGroupComponent.current = _SnailState.shellWallHit;
    await animationGroupComponent.animationTickers![_SnailState.shellWallHit]!.completed;
    animationGroupComponent.current = _SnailState.shellSpin;
  }

  Future<void> _handleSnailStomp(CollisionSide collisionSide) async {
    if (collisionSide == CollisionSide.top) {
      _snailGotStomped = true;
      _player.bounceUp();

      // play hit animation
      game.audioCenter.playSound(Sfx.enemieHit, SfxType.game);
      animationGroupComponent.current = _SnailState.snailHit;
      await animationGroupComponent.animationTickers![_SnailState.snailHit]!.completed;
      if (_shellGotStomped) return;
      animationGroupComponent.current = _SnailState.shellIdle;

      // change snail to shell and update hitbox
      _hitbox.position = _shellHitbox.position;
      _hitbox.size = _shellHitbox.size;
    } else {
      _player.collidedWithEnemy(collisionSide);
    }
  }

  void _handleShellKick(CollisionSide collisionSide) {
    animationGroupComponent.current = _SnailState.shellSpin;
    _shellGotKicked = true;

    // depending on the collisionSide, the shell is kicked in the corresponding direction
    switch (collisionSide) {
      case CollisionSide.left:
        _shellMoveDirection = 1;
        break;
      case CollisionSide.right:
        _shellMoveDirection = -1;
        break;
      case CollisionSide.top:
        final shellLeft = scale.x > 0 ? position.x + _hitbox.position.x : position.x - _hitbox.position.x - _hitbox.width;
        final shellCenter = shellLeft + _hitbox.width / 2;
        final playerCenter = (_player.hitboxAbsoluteLeft + _player.hitboxAbsoluteRight) / 2;
        _shellMoveDirection = playerCenter >= shellCenter ? -1 : 1;
        _player.bounceUp();
        break;
      default:
        return _player.collidedWithEnemy(collisionSide);
    }

    // flip shell if direction changes and update borders
    if (_shellMoveDirection != _moveDirection) flipHorizontallyAroundCenter();
    _updateActualBorders();
    game.audioCenter.playSound(Sfx.enemieHit, SfxType.game);
  }

  void _handleShellStomp(CollisionSide collisionSide) {
    if (collisionSide == CollisionSide.top) {
      _shellGotStomped = true;
      _player.bounceUp();

      // play hit animation and then remove from level
      game.audioCenter.playSound(Sfx.enemieHit, SfxType.game);
      animationGroupComponent.animationTickers![_SnailState.snailHit]?.onComplete?.call();
      animationGroupComponent.current = _SnailState.shellTopHit;
      animationGroupComponent.animationTickers![_SnailState.shellTopHit]!.completed.then((_) => removeFromParent());
    } else {
      _player.collidedWithEnemy(collisionSide);
    }
  }
}
