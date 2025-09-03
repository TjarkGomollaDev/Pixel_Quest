import 'dart:async';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/utils/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class SpikedBallBall extends PositionComponent
    with FixedGridOriginalSizeSprite, PlayerCollision, HasGameReference<PixelAdventure>, CollisionCallbacks {
  // constructor parameters
  final Player _player;

  SpikedBallBall({required Player player}) : _player = player, super(position: Vector2.zero(), size: gridSize);

  // actual hitbox
  final CircleHitbox _hitbox = CircleHitbox(position: (gridSize - _textureSize) / 2, radius: _textureSize.x / 2);

  // size
  static final Vector2 gridSize = Vector2.all(32);

  // animation settings
  static final Vector2 _textureSize = Vector2.all(28);
  static const String _path = 'Traps/Spiked Ball/Spiked Ball (28x28).png';

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadSprite();
    return super.onLoad();
  }

  void _initialSetup() {
    // debug
    if (PixelAdventure.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
      _hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    anchor = Anchor.center;
    _hitbox.collisionType = CollisionType.passive;
    add(_hitbox);
  }

  void _loadSprite() {
    addSpriteComponent(textureSize: _textureSize, sprite: loadSprite(game, _path), isBottomCenter: false);

    // rotate so that there is no spike at the top
    spriteComponent.angle += pi / 8;
  }

  @override
  void onPlayerCollisionStart(Vector2 intersectionPoint) => _player.collidedWithEnemy();
}
