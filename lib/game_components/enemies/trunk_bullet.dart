import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game_components/collision_block.dart';
import 'package:pixel_adventure/game_components/enemies/turtle.dart';
import 'package:pixel_adventure/game_components/level/player.dart';
import 'package:pixel_adventure/game_components/traps/fire.dart';
import 'package:pixel_adventure/game_components/traps/saw.dart';
import 'package:pixel_adventure/game_components/traps/spikes.dart';
import 'package:pixel_adventure/game_components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class TrunkBullet extends SpriteComponent with PlayerCollision, HasGameReference<PixelAdventure>, CollisionCallbacks {
  // constructor parameters
  final bool _isLeft;
  final Player _player;

  TrunkBullet({required bool isLeft, required Player player, required super.position})
    : _isLeft = isLeft,
      _player = player,
      super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2.all(16);

  // actual hitbox
  final CircleHitbox _hitbox = CircleHitbox(position: Vector2(4, 4), radius: 4);

  // animation settings
  static const String _path = 'Enemies/Trunk/Bullet.png';

  // movement
  final double _moveSpeed = 260; // [Adjustable]
  late double _moveDirection;

  // spawn protection to prevent flickering if the bullet is spawned in a collision block
  int _spawnProtectionFrames = 2;

  // list of objects that will destroy the projectile upon collision
  static const List<Type> despawnTypes = [CollisionBlock, Saw, Turtle, Spikes, Fire]; // [Adjustable]

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadSprite();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (_spawnProtectionFrames > 0) {
      _spawnProtectionFrames--;
      if (_spawnProtectionFrames == 0) {
        opacity = 1;
      }
    } else {
      _move(dt);
    }
    super.update(dt);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (despawnTypes.any((type) => other.runtimeType == type)) _despawn();
    super.onCollisionStart(intersectionPoints, other);
  }

  void _initialSetup() {
    // debug
    if (game.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorEnemie;
      _hitbox.debugColor = AppTheme.debugColorEnemieHitbox;
    }

    // general
    priority = PixelAdventure.enemieBulletLayerLevel;
    opacity = 0;
    add(_hitbox);
  }

  void _loadSprite() {
    sprite = loadSprite(game, _path);
    _moveDirection = _isLeft ? -1 : 1;
    if (_moveDirection == 1) flipHorizontallyAroundCenter();
  }

  void _move(double dt) => position.x += _moveDirection * _moveSpeed * dt;

  void _despawn() => removeFromParent();

  @override
  void onPlayerCollisionStart(Vector2 intersectionPoint) {
    _despawn();
    _player.collidedWithEnemy();
  }
}
