import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/data/audio/audio_center.dart';
import 'package:pixel_adventure/game/collision/collision.dart';
import 'package:pixel_adventure/game/collision/entity_collision.dart';
import 'package:pixel_adventure/game/hud/mini%20map/entity_on_mini_map.dart';
import 'package:pixel_adventure/game/level/player/player.dart';
import 'package:pixel_adventure/game/utils/animation_state.dart';
import 'package:pixel_adventure/game/utils/camera_culling.dart';
import 'package:pixel_adventure/game/utils/grid.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game/game_settings.dart';
import 'package:pixel_adventure/game/game.dart';

enum _ChickenState implements AnimationState {
  idle('Idle', 13),
  run('Run', 14),
  hit('Hit', 5, loop: false);

  @override
  final String fileName;
  @override
  final int amount;
  @override
  final bool loop;

  const _ChickenState(this.fileName, this.amount, {this.loop = true});
}

/// A ground-based enemy that reacts to the player within a defined patrol range.
///
/// The Chicken stays idle until the player enters its range, then runs toward them
/// (with a small attack sound trigger) while respecting its movement boundaries.
class Chicken extends PositionComponent
    with FixedGridOriginalSizeGroupAnimation, EntityCollision, EntityOnMiniMap, HasGameReference<PixelQuest> {
  // constructor parameters
  final double _offsetNeg;
  final double _offsetPos;
  final bool _isLeft;
  final Player _player;

  Chicken({required double offsetNeg, required double offsetPos, required bool isLeft, required Player player, required super.position})
    : _offsetNeg = offsetNeg,
      _offsetPos = offsetPos,
      _isLeft = isLeft,
      _player = player,
      super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2(32, 48);

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(4, 22), size: Vector2(24, 26));

  // these are the correct x values for the chicken, one for the left side of the hitbox and one for the right side of the hitbox
  late double _hitboxLeft;
  late double _hitboxRight;

  // animation settings
  static final Vector2 _textureSize = Vector2(32, 34);
  static const String _path = 'Enemies/Chicken/';
  static const String _pathEnd = ' (32x34).png';

  // range
  late final double _rangeNeg;
  late final double _rangePos;

  // actual borders that compensate for the hitbox and flip offset, depending on the moveDirection
  late double _leftBorder;
  late double _rightBorder;

  // movement
  final Vector2 _velocity = Vector2.zero();
  late int _moveDirection;
  final double _runSpeed = 80; // [Adjustable]

  // attack sound
  bool _attackSoundPlayedThisRange = false;
  static const double _attackSoundCooldown = 0.4; // [Adjustable]
  double _timeSinceLastAttackSound = double.infinity;

  // got stomped
  bool _gotStomped = false;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllSpriteAnimations();
    _setUpRange();
    _setUpMoveDirection();
    _updateHitboxEdges();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (!_gotStomped) {
      _timeSinceLastAttackSound += dt;
      _movement(dt);
      _updateState();
    }
    super.update(dt);
  }

  @override
  void onEntityCollision(CollisionSide collisionSide) {
    if (_gotStomped) return;
    if (collisionSide == CollisionSide.top) {
      _gotStomped = true;
      _player.bounceUp();

      // play hit animation and then remove from level
      game.audioCenter.playSound(Sfx.enemieHit, SfxType.game);
      animationGroupComponent.current = _ChickenState.hit;
      animationGroupComponent.animationTickers![_ChickenState.hit]!.completed.whenComplete(() => removeFromParent());
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
    _hitbox.collisionType = CollisionType.passive;
    add(_hitbox);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<_ChickenState>(game, _path, _pathEnd, GameSettings.stepTime, _textureSize);
    final animations = {for (var state in _ChickenState.values) state: loadAnimation(state)};
    addAnimationGroupComponent(textureSize: _textureSize, animations: animations, current: _ChickenState.idle);
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

  void _updateHitboxEdges() {
    _hitboxLeft = (scale.x > 0) ? position.x + _hitbox.position.x : position.x - width + _hitbox.position.x;
    _hitboxRight = _hitboxLeft + _hitbox.width;
  }

  void _movement(double dt) {
    _velocity.x = 0;

    // camera culling
    if (!game.isEntityInVisibleWorldRectX(_hitbox)) {
      _attackSoundPlayedThisRange = false;
      return;
    }

    // first, we check whether the player is within the range in which the chicken can move
    if (_playerInRange(_player.hitboxAbsoluteLeft, _player.hitboxAbsoluteRight, _player.hitboxAbsoluteBottom)) {
      if (!_attackSoundPlayedThisRange && _timeSinceLastAttackSound >= _attackSoundCooldown) {
        game.audioCenter.playSound(Sfx.chicken, SfxType.game);
        _timeSinceLastAttackSound = 0;
      }
      _attackSoundPlayedThisRange = true;
    } else {
      _attackSoundPlayedThisRange = false;
      return;
    }

    // secondly, now that we know the player is in range, we check whether he is to the left or right of the chicken
    if (_player.hitboxAbsoluteRight < _hitboxLeft) {
      _moveDirection = -1;
    } else if (_player.hitboxAbsoluteLeft > _hitboxRight) {
      _moveDirection = 1;
    }

    // movement towards the player
    _velocity.x = _moveDirection * _runSpeed;
    final newPositionX = position.x + _velocity.x * dt;
    position.x = newPositionX.clamp(_leftBorder, _rightBorder);
    _updateHitboxEdges();
  }

  bool _playerInRange(double playerHitboxLeft, double playerHitboxRight, double playerHitboxBottom) {
    return playerHitboxRight >= _rangeNeg &&
        playerHitboxLeft <= _rangePos &&
        playerHitboxBottom >= position.y + _hitbox.position.y &&
        playerHitboxBottom <= position.y + height;
  }

  void _updateState() {
    animationGroupComponent.current = (_velocity.x != 0) ? _ChickenState.run : _ChickenState.idle;

    // detection of a change in direction
    if ((_moveDirection > 0 && scale.x > 0) || (_moveDirection < 0 && scale.x < 0)) {
      flipHorizontallyAroundCenter();
      _updateActualBorders();
      _updateHitboxEdges();
    }
  }
}
