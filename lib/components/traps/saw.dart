import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class Saw extends SpriteAnimationComponent with HasGameReference<PixelAdventure> {
  final double offsetNeg;
  final double offsetPos;
  final bool isVertical;

  Saw({this.offsetNeg = 0, this.offsetPos = 0, this.isVertical = false, super.position}) : super(size: _fixedSize);

  // size
  static final Vector2 _fixedSize = Vector2.all(32);

  // actual hitbox
  final CircleHitbox hitbox = CircleHitbox();

  // animation settings
  final double _stepTime = 0.03;
  final Vector2 _textureSize = Vector2.all(38);
  final int _amount = 8;
  final String _pathSaw = 'Traps/Saw/On (38x38).png';
  final String _pathChain = 'Traps/Platforms/Chain.png';

  // range
  double _rangeNeg = 0;
  double _rangePos = 0;

  // movement
  double _moveDirection = -1;
  final double _moveSpeed = 50;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAnimation();
    _setUpRange();
    _createChainPath();

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
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
      hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    priority = PixelAdventure.trapLayerLevel;
    hitbox.collisionType = CollisionType.passive;
    anchor = Anchor.topCenter;
    add(hitbox);
  }

  void _loadAnimation() => animation = loadSpriteAnimation(game, _pathSaw, _amount, _stepTime, _textureSize);

  void _setUpRange() {
    if (isVertical) {
      _rangeNeg = position.y - offsetNeg * game.tileSize;
      _rangePos = position.y + offsetPos * game.tileSize;
      position.x += width / 2;
    } else {
      _rangeNeg = position.x - offsetNeg * game.tileSize + width / 2;
      _rangePos = position.x + offsetPos * game.tileSize + width / 2;
    }
    _rangeNeg += game.rangeOffset;
    _rangePos -= game.rangeOffset;
  }

  void _createChainPath() {
    final chainSprite = loadSprite(game, _pathChain);
    final double chainSize = 8;

    // calculate the startpoint of the chain
    final startPoint = Vector2(
      isVertical ? position.x - chainSize / 2 : _rangeNeg - width / 2 - game.rangeOffset,
      isVertical ? _rangeNeg - game.rangeOffset : position.y + height / 2 - chainSize / 2,
    );

    // calculate the length of the chain
    final length = ((_rangePos - _rangeNeg + width + 2 * game.rangeOffset) / game.tileSize);
    double offset = chainSize * 2;

    // exactly two chain elements fit into a tile and a tile is left free at both ends
    for (var i = 0; i < length * 2 - 4; i++) {
      final chain =
          DebugSpriteComponent(
              sprite: chainSprite,
              size: Vector2.all(chainSize),
              position: isVertical ? Vector2(startPoint.x, startPoint.y + offset) : Vector2(startPoint.x + offset, startPoint.y),
              priority: PixelAdventure.trapHintsLayerLevel,
            )
            ..debugMode = game.customDebug
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
    final double newPositionX = position.y + _moveDirection * _moveSpeed * dt;
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
    final double newPositionX = position.x + _moveDirection * _moveSpeed * dt;
    position.x = newPositionX.clamp(_rangeNeg, _rangePos);
  }
}
