import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game_components/level/player.dart';
import 'package:pixel_adventure/game_components/collision_block.dart';
import 'package:pixel_adventure/game_components/utils.dart';
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

/// A moving platform that can travel horizontally or vertically
/// within a predefined range.
///
/// The player can stand on top of the platform
/// and be carried along as it moves.
///
/// The platform automatically reverses direction when reaching the end
/// of its movement range.
class MovingPlatform extends SpriteAnimationGroupComponent with PlayerCollision, HasGameReference<PixelAdventure>, CollisionCallbacks {
  final double _offsetNeg;
  final double _offsetPos;
  final bool _isVertical;
  final Player _player;
  final CollisionBlock _block;

  MovingPlatform({
    required bool isVertical,
    required double offsetNeg,
    required double offsetPos,
    required Player player,
    required CollisionBlock block,
    required super.position,
  }) : _isVertical = isVertical,
       _offsetPos = offsetPos,
       _offsetNeg = offsetNeg,
       _player = player,
       _block = block,
       super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2(32, 16);

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(0, 0), size: Vector2(32, 8));

  // animation settings
  static const double _stepTime = 0.05;
  static final Vector2 _textureSize = Vector2(32, 16);
  static const String _path = 'Traps/Platforms/Grey ';
  static const String _pathEnd = ' (32x8).png';

  // range
  late final double _rangeNeg;
  late final double _rangePos;

  // movement
  final double _moveSpeed = 30;
  double _moveDirection = 1;

  // player on top
  bool _playerOnTop = false;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllSpriteAnimations();
    _setUpRange();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    _isVertical ? _moveVertical(dt) : _moveHorizontal(dt);
    super.update(dt);
  }

  @override
  void onRemove() {
    _player.respawnNotifier.removeListener(onPlayerCollisionEnd);
    super.onRemove();
  }

  void _initialSetup() {
    // debug
    if (game.customDebug) {
      // debugMode = true;
      debugColor = AppTheme.debugColorTrap;
      _hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    priority = PixelAdventure.trapLayerLevel;
    _player.respawnNotifier.addListener(onPlayerCollisionEnd);
    _hitbox.collisionType = CollisionType.passive;
    anchor = Anchor.topCenter;
    add(_hitbox);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<MovingPlatformState>(game, _path, _pathEnd, _stepTime, _textureSize);
    animations = {for (var state in MovingPlatformState.values) state: loadAnimation(state)};
    current = MovingPlatformState.on;
    if (_moveDirection == -1) flipHorizontally();
  }

  void _setUpRange() {
    if (_isVertical) {
      _rangeNeg = position.y - _offsetNeg * PixelAdventure.tileSize;
      _rangePos = position.y + _offsetPos * PixelAdventure.tileSize;
    } else {
      _rangeNeg = position.x - _offsetNeg * PixelAdventure.tileSize + width / 2;
      _rangePos = position.x + _offsetPos * PixelAdventure.tileSize + width / 2;
    }
  }

  // moves the saw vertically and changes direction if the end of the range is reached
  void _moveVertical(double dt) {
    if (position.y > _rangePos && _moveDirection != -1) {
      _moveDirection = -1;
      flipHorizontally();
    } else if (position.y < _rangeNeg && _moveDirection != 1) {
      _moveDirection = 1;
      flipHorizontally();
    }
    final moveY = _moveDirection * _moveSpeed * dt;
    position.y += moveY;
    _block.position.y += moveY;
  }

  // moves the saw horizontally and changes direction if the end of the range is reached
  void _moveHorizontal(double dt) {
    if (position.x > _rangePos && _moveDirection != -1) {
      _moveDirection = -1;
      flipHorizontally();
    } else if (position.x < _rangeNeg && _moveDirection != 1) {
      _moveDirection = 1;
      flipHorizontally();
    }
    final moveX = _moveDirection * _moveSpeed * dt;
    position.x += moveX;
    _block.position.x += moveX;
    if (_playerOnTop) _player.position.x += moveX;
  }

  @override
  void onPlayerCollision(Vector2 intersectionPoint) {
    if (intersectionPoint.y == position.y) {
      // once he is taken away, he no longer has to be on at least half of his hitbox
      if (_playerOnTop) return;

      // when entering the platform, at least half of the player's hitbox must be on the platform in order to be carried along
      final playerCenter = (_player.hitboxPositionLeftX + _player.hitboxPositionRightX) / 2;
      if (playerCenter >= _block.position.x && playerCenter <= _block.position.x + width) {
        _playerOnTop = true;
      }
    }
  }

  @override
  void onPlayerCollisionEnd() => _playerOnTop = false;
}
