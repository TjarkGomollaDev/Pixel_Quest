import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/utils/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

/// A moving saw trap that travels back and forth along a defined path.
///
/// The saw can move either horizontally or vertically between two offsets,
/// automatically calculating its movement range in tile units.
/// A chain of sprites is rendered along the travel path for visual clarity,
/// creating the appearance of the saw being suspended.
///
/// The saw continuously animates while moving and flips direction
/// once reaching the end of its range. It acts as a passive collision area
/// that can interact with the [Player].
class Saw extends SpriteAnimationComponent with PlayerCollision, HasGameReference<PixelAdventure> {
  // constructor parameters
  final double _offsetNeg;
  final double _offsetPos;
  final bool _isVertical;
  final Player _player;

  Saw({required double offsetNeg, required double offsetPos, required bool isVertical, required Player player, required super.position})
    : _isVertical = isVertical,
      _offsetPos = offsetPos,
      _offsetNeg = offsetNeg,
      _player = player,
      super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2.all(32);

  // actual hitbox
  final CircleHitbox _hitbox = CircleHitbox();

  // animation settings
  static const double _stepTime = 0.03;
  static final Vector2 _textureSize = Vector2.all(38);
  static const int _amount = 8;
  static const String _pathSaw = 'Traps/Saw/On (38x38).png';
  static const String _pathChain = 'Traps/Platforms/Chain.png';

  // range
  late final double _rangeNeg;
  late final double _rangePos;

  // movement
  int _moveDirection = -1;
  final double _moveSpeed = 50; // [Adjustable]

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadSpriteAnimation();
    _setUpRange();
    _createChainPath();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    _isVertical ? _moveVertical(dt) : _moveHorizontal(dt);
    super.update(dt);
  }

  void _initialSetup() {
    // debug
    if (PixelAdventure.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
      _hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    priority = PixelAdventure.trapLayerLevel;
    anchor = Anchor.topCenter;
    _hitbox.collisionType = CollisionType.passive;
    add(_hitbox);
  }

  void _loadSpriteAnimation() => animation = loadSpriteAnimation(game, _pathSaw, _amount, _stepTime, _textureSize);

  void _setUpRange() {
    if (_isVertical) {
      _rangeNeg = position.y - _offsetNeg * PixelAdventure.tileSize;
      _rangePos = position.y + _offsetPos * PixelAdventure.tileSize;
      position.x += width / 2;
    } else {
      _rangeNeg = position.x - _offsetNeg * PixelAdventure.tileSize + width / 2;
      _rangePos = position.x + _offsetPos * PixelAdventure.tileSize + width / 2;
    }
  }

  void _createChainPath() {
    final chainSprite = loadSprite(game, _pathChain);
    final chainSize = 8.0;

    // calculate the startpoint of the chain
    final startPoint = Vector2(
      _isVertical ? position.x - chainSize / 2 : _rangeNeg - width / 2,
      _isVertical ? _rangeNeg : position.y + height / 2 - chainSize / 2,
    );

    // calculate the length of the chain
    final length = ((_rangePos - _rangeNeg + width) / PixelAdventure.tileSize);
    double offset = chainSize * 2;

    // exactly two chain elements fit into a tile and a tile is left free at both ends
    for (var i = 0; i < length * 2 - 4; i++) {
      final chain =
          DebugSpriteComponent(
              sprite: chainSprite,
              size: Vector2.all(chainSize),
              position: _isVertical ? Vector2(startPoint.x, startPoint.y + offset) : Vector2(startPoint.x + offset, startPoint.y),
              priority: PixelAdventure.trapParticlesLayerLevel,
            )
            ..debugMode = PixelAdventure.customDebug
            ..debugColor = AppTheme.debugColorTrapHitbox;
      game.world.add(chain);
      offset += chainSize;
    }
  }

  void _moveVertical(double dt) {
    // moves the saw vertically and changes direction if the end of the range is reached
    if (position.y >= _rangePos && _moveDirection != -1) {
      _moveDirection = -1;
      flipHorizontally();
    } else if (position.y <= _rangeNeg && _moveDirection != 1) {
      _moveDirection = 1;
      flipHorizontally();
    }

    // movement
    final newPositionX = position.y + _moveDirection * _moveSpeed * dt;
    position.y = newPositionX.clamp(_rangeNeg, _rangePos);
  }

  void _moveHorizontal(double dt) {
    // moves the saw horizontally and changes direction if the end of the range is reached
    if (position.x >= _rangePos && _moveDirection != -1) {
      _moveDirection = -1;
      flipHorizontally();
    } else if (position.x <= _rangeNeg && _moveDirection != 1) {
      _moveDirection = 1;
      flipHorizontally();
    }

    // movement
    final newPositionX = position.x + _moveDirection * _moveSpeed * dt;
    position.x = newPositionX.clamp(_rangeNeg, _rangePos);
  }

  @override
  void onPlayerCollisionStart(Vector2 intersectionPoint) => _player.collidedWithEnemy();
}
