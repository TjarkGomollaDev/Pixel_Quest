import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/components/level/player.dart';
import 'package:pixel_adventure/components/collision_block.dart';
import 'package:pixel_adventure/components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum MovingPlatformState implements AnimationState {
  off('Off', 1),
  on('On', 8);

  @override
  final String name;
  @override
  final int amount;
  @override
  final bool loop = true;

  const MovingPlatformState(this.name, this.amount);
}

class MovingPlatform extends SpriteAnimationGroupComponent with HasGameReference<PixelAdventure>, CollisionCallbacks {
  final bool isVertical;
  final double offsetNeg;
  final double offsetPos;

  MovingPlatform({this.isVertical = false, this.offsetNeg = 0, this.offsetPos = 0, super.position, super.size, required Player player})
    : _player = player;

  // actual hitbox
  final hitbox = RectangleHitbox(position: Vector2(0, 0), size: Vector2(32, 8));

  // player ref
  final Player _player;

  // collision block ref
  late final CollisionBlock _block;

  // animation settings
  final double _stepTime = 0.05;
  final Vector2 _textureSize = Vector2(32, 16);
  final String _path = 'Traps/Platforms/Grey ';
  final String _pathEnd = ' (32x8).png';

  // range
  double rangeNeg = 0;
  double rangePos = 0;

  // movement
  final double _moveSpeed = 30;
  double _moveDirection = 1;

  // player on top
  bool _playerOnTop = false;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllAnimations();
    _setUpRange();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    isVertical ? _moveVertical(dt) : _moveHorizontal(dt);
    super.update(dt);
  }

  void _initialSetup() {
    // debug
    if (game.customDebug) {
      // debugMode = true;
      debugColor = AppTheme.debugColorTrap;
      hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    priority = PixelAdventure.trapLayerLevel;
    hitbox.collisionType = CollisionType.passive;
    anchor = Anchor.topCenter;
    add(hitbox);
  }

  void _loadAllAnimations() {
    final loadAnimation = spriteAnimationWrapper<MovingPlatformState>(game, _path, _pathEnd, _stepTime, _textureSize);

    // list of all animations
    animations = {for (var state in MovingPlatformState.values) state: loadAnimation(state)};

    // set current animation state
    current = MovingPlatformState.on;

    _moveDirection == -1 ? flipHorizontally() : null;
  }

  void _setUpRange() {
    if (isVertical) {
      rangeNeg = position.y - offsetNeg * game.tileSize;
      rangePos = position.y + offsetPos * game.tileSize;
    } else {
      rangeNeg = position.x - offsetNeg * game.tileSize + width / 2;
      rangePos = position.x + offsetPos * game.tileSize + width / 2;
    }
  }

  void setCollisionBlock(CollisionBlock block) {
    _block = block;
  }

  // moves the saw vertically and changes direction if the end of the range is reached
  void _moveVertical(double dt) {
    if (position.y > rangePos && _moveDirection != -1) {
      _moveDirection = -1;
      flipHorizontally();
    } else if (position.y < rangeNeg && _moveDirection != 1) {
      _moveDirection = 1;
      flipHorizontally();
    }
    final moveY = _moveDirection * _moveSpeed * dt;
    position.y += moveY;
    _block.position.y += moveY;
  }

  // moves the saw horizontally and changes direction if the end of the range is reached
  void _moveHorizontal(double dt) {
    if (position.x > rangePos && _moveDirection != -1) {
      _moveDirection = -1;
      flipHorizontally();
    } else if (position.x < rangeNeg && _moveDirection != 1) {
      _moveDirection = 1;
      flipHorizontally();
    }
    final moveX = _moveDirection * _moveSpeed * dt;
    position.x += moveX;
    _block.position.x += moveX;
    if (_playerOnTop) _player.position.x += moveX;
  }

  void collidedWithPlayer(Vector2 collisionPoint) {
    if (collisionPoint.y == position.y) {
      // once he is taken away, he no longer has to be on at least half of his hitbox
      if (_playerOnTop) return;

      // when entering the platform, at least half of the player's hitbox must be on the platform in order to be carried along
      final playerCenter = (_player.hitboxPositionLeftX + _player.hitboxPositionRightX) / 2;
      if (playerCenter >= _block.position.x && playerCenter <= _block.position.x + width) {
        _playerOnTop = true;
      }
    }
  }

  void collidedWithPlayerEnd() {
    _playerOnTop = false;
  }
}
