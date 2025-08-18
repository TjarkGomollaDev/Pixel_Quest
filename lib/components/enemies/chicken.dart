import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/components/level/player.dart';
import 'package:pixel_adventure/components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum ChickenState implements AnimationState {
  idle('Idle', 13),
  run('Run', 14),
  hit('Hit', 5, loop: false);

  @override
  final String name;
  @override
  final int amount;
  @override
  final bool loop;

  const ChickenState(this.name, this.amount, {this.loop = true});
}

class Chicken extends SpriteAnimationGroupComponent with HasGameReference<PixelAdventure>, CollisionCallbacks {
  final double offsetNeg;
  final double offsetPos;
  final bool isLeft;

  Chicken({
    required this.offsetNeg,
    required this.offsetPos,
    required this.isLeft,
    required super.position,
    required super.size,
    required Player player,
  }) : _player = player;

  // actual hitbox
  final RectangleHitbox hitbox = RectangleHitbox(position: Vector2(4, 6), size: Vector2(24, 26));

  // player ref
  final Player _player;

  // these are the correct x values for the chicken, one for the left side of the hitbox and one for the right side of the hitbox
  late double _hitboxPositionLeftX;
  late double _hitboxPositionRightX;

  // animation settings
  final double _stepTime = 0.05;
  final Vector2 _textureSize = Vector2(32, 34);
  final String _path = 'Enemies/Chicken/';
  final String _pathEnd = ' (32x34).png';

  // range
  late final double _rangeNeg;
  late final double _rangePos;

  // actual borders that compensate for the hitbox and flip offset, depending on the moveDirection
  late double _leftBorder;
  late double _rightBorder;

  // movement
  final Vector2 _velocity = Vector2.zero();
  late double _moveDirection;
  final double _runSpeed = 80; // [Adjustable]

  // got stomped
  bool _gotStomped = false;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllAnimations();
    _setUpRange();
    _setUpMoveDirection();
    _updateHitboxEdges();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (!_gotStomped) {
      _updateState();
      _movement(dt);
    }
    super.update(dt);
  }

  void _initialSetup() {
    // debug
    if (game.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorEnemie;
      hitbox.debugColor = AppTheme.debugColorEnemieHitbox;
    }

    // general
    priority = PixelAdventure.enemieLayerLevel;
    hitbox.collisionType = CollisionType.passive;
    add(hitbox);
  }

  void _loadAllAnimations() {
    final loadAnimation = spriteAnimationWrapper<ChickenState>(game, _path, _pathEnd, _stepTime, _textureSize);

    // list of all animations
    animations = {for (var state in ChickenState.values) state: loadAnimation(state)};

    // set current animation state
    current = ChickenState.idle;
  }

  void _setUpRange() {
    _rangeNeg = position.x - offsetNeg * game.tileSize;
    _rangePos = position.x + offsetPos * game.tileSize + width;
  }

  void _setUpMoveDirection() {
    _moveDirection = isLeft ? -1 : 1;
    if (_moveDirection == 1) flipHorizontallyAroundCenter();
    _updateActualBorders();
  }

  void _updateActualBorders() {
    _leftBorder = (_moveDirection == -1) ? _rangeNeg - hitbox.position.x : _rangeNeg + hitbox.position.x + hitbox.width;
    _rightBorder = (_moveDirection == 1) ? _rangePos + hitbox.position.x : _rangePos - hitbox.position.x - hitbox.width;
  }

  void _updateHitboxEdges() {
    _hitboxPositionLeftX = (scale.x > 0) ? position.x + hitbox.position.x : position.x - hitbox.position.x - hitbox.width;
    _hitboxPositionRightX = _hitboxPositionLeftX + hitbox.width;
  }

  void _movement(double dt) {
    _velocity.x = 0;

    // get player hitbox positions
    final playerHitboxPositionLeftX = _player.hitboxPositionLeftX;
    final playerHitboxPositionRightX = _player.hitboxPositionRightX;

    // first, we check whether the player is within the range in which the chicken can move
    if (!_playerInRange(playerHitboxPositionLeftX, playerHitboxPositionRightX)) return;

    // secondly, now that we know the player is in range, we check whether he is to the left or right of the chicken
    if (playerHitboxPositionRightX < _hitboxPositionLeftX) {
      _moveDirection = -1;
    } else if (playerHitboxPositionLeftX > _hitboxPositionRightX) {
      _moveDirection = 1;
    } else {
      // this only occurs when we disable collisions with the player, it ensures that the chicken does not constantly change direction because we are standing in the chicken
      return;
    }

    // movement towards the player
    _velocity.x = _moveDirection * _runSpeed;
    final newPositionX = position.x + _velocity.x * dt;
    position.x = newPositionX.clamp(_leftBorder, _rightBorder);
    _updateHitboxEdges();
  }

  bool _playerInRange(double playerPositionLeftX, double playerPositionRightX) {
    return playerPositionRightX >= _rangeNeg &&
        playerPositionLeftX <= _rangePos &&
        _player.y + _player.height <= position.y + height &&
        _player.y + _player.height >= position.y + hitbox.position.y;
  }

  void _updateState() {
    current = (_velocity.x != 0) ? ChickenState.run : ChickenState.idle;

    // detection of a change in direction
    if ((_moveDirection > 0 && scale.x > 0) || (_moveDirection < 0 && scale.x < 0)) {
      flipHorizontallyAroundCenter();
      _updateActualBorders();
      _updateHitboxEdges();
    }
  }

  void collidedWithPlayer(Vector2 collisionPoint) {
    if (_gotStomped) return;
    if (_player.velocity.y > 0 && collisionPoint.y < position.y + hitbox.position.y + game.toleranceEnemieCollision) {
      current = ChickenState.hit;
      _gotStomped = true;
      _player.bounceUp();
      animationTickers![ChickenState.hit]!.completed.whenComplete(() => removeFromParent());
    } else {
      _player.collidedWithEnemy();
    }
  }
}
