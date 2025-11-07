import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/collision/world_collision.dart';
import 'package:pixel_adventure/game/hud/entity_on_mini_map.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/utils/animation_state.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_quest.dart';

enum MovingPlatformState implements AnimationState {
  off('Off', 1),
  on('On', 8);

  @override
  final String fileName;
  @override
  final int amount;
  @override
  final bool loop = true;

  const MovingPlatformState(this.fileName, this.amount);
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
    with HasGameReference<PixelQuest>, WorldCollision, WorldCollisionEnd, EntityOnMiniMap {
  final double _offsetNeg;
  final double _offsetPos;
  final bool _isVertical;
  final bool _isLeft;
  final Player _player;

  MovingPlatform({
    required double offsetNeg,
    required double offsetPos,
    required bool isVertical,
    required bool isLeft,
    required Player player,
    required super.position,
  }) : _offsetNeg = offsetNeg,
       _offsetPos = offsetPos,
       _isVertical = isVertical,
       _isLeft = isLeft,
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

  // actual borders that compensate for the hitbox and flip offset, depending on the moveDirection
  late double _leftBorder;
  late double _rightBorder;

  // movement
  int _moveDirection = 1;
  final double _moveSpeed = 24;

  // player on top
  bool _playerOnTop = false;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllSpriteAnimations();
    _correctingPosition();
    _setUpRange();
    _setUpMoveDirection();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    _isVertical ? _moveVertical(dt) : _moveHorizontal(dt);
    super.update(dt);
  }

  @override
  void onRemove() {
    _player.respawnNotifier.removeListener(onWorldCollisionEnd);
    super.onRemove();
  }

  // we return top left instead of bottom center, and we have to take _correctingPosition() into account
  @override
  Vector2 get markerPosition => Vector2(_hitbox.toAbsoluteRect().left, position.y + _hitbox.position.y);

  void _initialSetup() {
    // debug
    if (GameSettings.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
      _hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    priority = GameSettings.trapLayerLevel;
    _player.respawnNotifier.addListener(onWorldCollisionEnd);
    _hitbox.collisionType = CollisionType.passive;
    add(_hitbox);
    marker = EntityMiniMapMarker(type: EntityMiniMapMarkerType.platform, color: AppTheme.entityMarkerSpecial);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<MovingPlatformState>(game, _path, _pathEnd, GameSettings.stepTime, _textureSize);
    animations = {for (var state in MovingPlatformState.values) state: loadAnimation(state)};
    current = MovingPlatformState.on;
  }

  void _correctingPosition() => position.y -= _hitbox.position.y;

  void _setUpRange() {
    if (_isVertical) {
      _rangeNeg = position.y - _offsetNeg * GameSettings.tileSize;
      _rangePos = position.y + _offsetPos * GameSettings.tileSize;
    } else {
      _rangeNeg = position.x - _offsetNeg * GameSettings.tileSize + width;
      _rangePos = position.x + _offsetPos * GameSettings.tileSize;
    }
  }

  void _setUpMoveDirection() {
    _moveDirection = _isLeft ? -1 : 1;
    if (_moveDirection == -1) flipHorizontallyAroundCenter();
    if (!_isVertical) _updateActualBorders();
  }

  void _updateActualBorders() {
    _leftBorder = (_moveDirection == -1) ? _rangeNeg : _rangeNeg - width;
    _rightBorder = (_moveDirection == 1) ? _rangePos : _rangePos + width;
  }

  // moves the saw vertically and changes direction if the end of the range is reached
  void _moveVertical(double dt) {
    if (position.y >= _rangePos && _moveDirection != -1) {
      _changeDirection(-1);
      return;
    } else if (position.y <= _rangeNeg && _moveDirection != 1) {
      _changeDirection(1);
      return;
    }

    // movement
    final moveY = (position.y + _moveDirection * _moveSpeed * dt).clamp(_rangeNeg, _rangePos) - position.y;
    position.y += moveY;
    if (_playerOnTop) _player.position.y += moveY;
  }

  // moves the saw horizontally and changes direction if the end of the range is reached
  void _moveHorizontal(double dt) {
    if (position.x >= _rightBorder && _moveDirection != -1) {
      _changeDirection(-1);
      return;
    } else if (position.x <= _leftBorder && _moveDirection != 1) {
      _changeDirection(1);
      return;
    }

    // movement
    final moveX = (position.x + _moveDirection * _moveSpeed * dt).clamp(_leftBorder, _rightBorder) - position.x;
    position.x += moveX;
    if (_playerOnTop) _player.position.x += moveX;
  }

  void _changeDirection(int newDirection) {
    _moveDirection = newDirection;
    if (!_isVertical) {
      flipHorizontallyAroundCenter();
      _updateActualBorders();
      position.x = _moveDirection == 1 ? _leftBorder : _rightBorder;
    }
  }

  void playerOnTop() {
    if (_playerOnTop) return;
    _playerOnTop = true;
  }

  @override
  void onWorldCollisionEnd() => _playerOnTop = false;

  @override
  ShapeHitbox get worldHitbox => _hitbox;

  int get moveDirection => _moveDirection;

  bool get isVertical => _isVertical;
}
