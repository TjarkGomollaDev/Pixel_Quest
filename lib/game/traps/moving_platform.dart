import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/collision_block.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/utils.dart';
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
class MovingPlatform extends SpriteAnimationGroupComponent
    with PlayerCollision, HasGameReference<PixelAdventure>, CollisionCallbacks, CollisionBlock {
  final double _offsetNeg;
  final double _offsetPos;
  final bool _isVertical;
  final Player _player;

  MovingPlatform({
    required double offsetNeg,
    required double offsetPos,
    required bool isVertical,
    required Player player,
    required super.position,
  }) : _offsetNeg = offsetNeg,
       _offsetPos = offsetPos,
       _isVertical = isVertical,
       _player = player,
       super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2(32, 16);

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(0, 2), size: Vector2(32, 5));

  // animation settings
  static final Vector2 _textureSize = Vector2(32, 16);
  static const String _path = 'Traps/Platforms/Grey ';
  static const String _pathEnd = ' (32x8).png';

  // range
  late final double _rangeNeg;
  late final double _rangePos;

  // movement
  final double _moveSpeed = 30;
  int _moveDirection = 1;

  // player on top
  bool _playerOnTop = false;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllSpriteAnimations();
    _correctingPosition();
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
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
      _hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    priority = PixelAdventure.trapLayerLevel;
    _player.respawnNotifier.addListener(onPlayerCollisionEnd);
    _hitbox.collisionType = CollisionType.passive;
    add(_hitbox);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<MovingPlatformState>(game, _path, _pathEnd, PixelAdventure.stepTime, _textureSize);
    animations = {for (var state in MovingPlatformState.values) state: loadAnimation(state)};
    current = MovingPlatformState.on;
    if (_moveDirection == -1) flipHorizontally();
  }

  void _correctingPosition() => position.y -= _hitbox.position.y;

  void _setUpRange() {
    if (_isVertical) {
      _rangeNeg = position.y - _offsetNeg * PixelAdventure.tileSize;
      _rangePos = position.y + _offsetPos * PixelAdventure.tileSize;
    } else {
      _rangeNeg = position.x - _offsetNeg * PixelAdventure.tileSize + width;
      _rangePos = position.x + _offsetPos * PixelAdventure.tileSize;
    }
  }

  // moves the saw vertically and changes direction if the end of the range is reached
  void _moveVertical(double dt) {
    if (position.y >= _rangePos && _moveDirection != -1) {
      _moveDirection = -1;
      flipHorizontallyAroundCenter();
    } else if (position.y <= _rangeNeg && _moveDirection != 1) {
      _moveDirection = 1;
      flipHorizontallyAroundCenter();
    }
    final moveY = _moveDirection * _moveSpeed * dt;
    position.y += moveY;
    if (_playerOnTop) _player.position.y += moveY;
  }

  // moves the saw horizontally and changes direction if the end of the range is reached
  void _moveHorizontal(double dt) {
    if (position.x >= _rangePos && _moveDirection != -1) {
      _moveDirection = -1;
      flipHorizontallyAroundCenter();
    } else if (position.x <= _rangeNeg && _moveDirection != 1) {
      _moveDirection = 1;
      flipHorizontallyAroundCenter();
    }
    final moveX = _moveDirection * _moveSpeed * dt;
    position.x += moveX;
    if (_playerOnTop) _player.position.x += moveX;
  }

  @override
  void onPlayerCollision(Vector2 intersectionPoint) => _playerOnTop = true;

  @override
  void onPlayerCollisionEnd() => _playerOnTop = false;

  @override
  ShapeHitbox get solidHitbox => _hitbox;

  int get moveDirection => _moveDirection;

  bool get isVertical => _isVertical;
}
