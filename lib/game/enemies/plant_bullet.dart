import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/level/collision_block.dart';
import 'package:pixel_adventure/game/enemies/turtle.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/traps/fire.dart';
import 'package:pixel_adventure/game/traps/saw.dart';
import 'package:pixel_adventure/game/traps/spikes.dart';
import 'package:pixel_adventure/game/utils/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class PlantBullet extends SpriteComponent with PlayerCollision, HasGameReference<PixelAdventure>, CollisionCallbacks {
  // constructor parameters
  final bool _isLeft;
  final Player _player;

  PlantBullet({required bool isLeft, required Player player, required super.position})
    : _isLeft = isLeft,
      _player = player,
      super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2.all(16);
  static final Vector2 hitboxOffset = Vector2(4, 4);
  static const double hitboxRadius = 4;

  // actual hitbox
  final CircleHitbox _hitbox = CircleHitbox(position: hitboxOffset, radius: hitboxRadius);

  // animation settings
  static const String _path = 'Enemies/Plant/Bullet (16x16).png';

  // movement
  final double _moveSpeed = 100; // [Adjustable]
  late int _moveDirection;

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
    _move(dt);
    super.update(dt);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (despawnTypes.any((type) => other.runtimeType == type)) _despawn();
    super.onCollisionStart(intersectionPoints, other);
  }

  void _initialSetup() {
    // debug
    if (PixelAdventure.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorParticle;
      _hitbox.debugColor = AppTheme.debugColorParticleHitbox;
    }

    // general
    priority = PixelAdventure.enemieBulletLayerLevel;
    add(_hitbox);
    _moveDirection = _isLeft ? -1 : 1;
  }

  void _loadSprite() => sprite = loadSprite(game, _path);

  void _move(double dt) => position.x += _moveDirection * _moveSpeed * dt;

  void _despawn() => removeFromParent();

  @override
  void onPlayerCollisionStart(Vector2 intersectionPoint) {
    _despawn();
    _player.collidedWithEnemy();
  }
}
