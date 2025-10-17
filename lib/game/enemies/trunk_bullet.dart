import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/collision/collision.dart';
import 'package:pixel_adventure/game/collision/entity_collision.dart';
import 'package:pixel_adventure/game/collision/world_collision.dart';
import 'package:pixel_adventure/game/enemies/turtle.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/traps/fire.dart';
import 'package:pixel_adventure/game/traps/saw.dart';
import 'package:pixel_adventure/game/traps/spikes.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_quest.dart';

class TrunkBullet extends SpriteComponent with EntityCollision, HasGameReference<PixelQuest>, CollisionCallbacks {
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
  late int _moveDirection;

  // spawn protection to prevent flickering if the bullet is spawned in a collision block
  int _spawnProtectionFrames = 2;

  // list of objects that will destroy the projectile upon collision
  static const List<Type> despawnTypes = [WorldBlock, Saw, Turtle, Spikes, Fire]; // [Adjustable]

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
    if (GameSettings.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorEnemie;
      _hitbox.debugColor = AppTheme.debugColorEnemieHitbox;
    }

    // general
    priority = GameSettings.enemieBulletLayerLevel;
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
  void onEntityCollision(CollisionSide collisionSide) {
    _despawn();
    _player.collidedWithEnemy(collisionSide);
  }

  @override
  ShapeHitbox get entityHitbox => _hitbox;
}
