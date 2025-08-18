import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/components/collision_block.dart';
import 'package:pixel_adventure/components/traps/saw.dart';
import 'package:pixel_adventure/components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class TrunkBullet extends SpriteComponent with HasGameReference<PixelAdventure>, CollisionCallbacks {
  final bool isLeft;

  TrunkBullet({required this.isLeft, required super.position}) : super(size: fixedSize);

  // size
  static final Vector2 fixedSize = Vector2.all(16);

  // actual hitbox
  final CircleHitbox hitbox = CircleHitbox(position: Vector2(4, 4), radius: 4);

  // animation settings
  final String _path = 'Enemies/Trunk/Bullet.png';

  // movement
  final double _moveSpeed = 260; // [Adjustable]
  late double _moveDirection;

  // spawn protection to prevent flickering if the bullet is spawned in a collision block
  int _spawnProtectionFrames = 2;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAnimation();
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
    if (other is CollisionBlock && !other.isPlattform) _despawn();
    if (other is Saw) _despawn();
    super.onCollisionStart(intersectionPoints, other);
  }

  void _initialSetup() {
    // debug
    if (game.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorEnemie;
      hitbox.debugColor = AppTheme.debugColorEnemieHitbox;
    }

    // general
    priority = PixelAdventure.enemieBulletLayerLevel;
    opacity = 0;
    add(hitbox);
  }

  void _loadAnimation() {
    sprite = loadSprite(game, _path);
    _moveDirection = isLeft ? -1 : 1;
    if (_moveDirection == 1) flipHorizontallyAroundCenter();
  }

  void _move(double dt) => position.x += _moveDirection * _moveSpeed * dt;

  void _despawn() => removeFromParent();

  void collidedWithPlayer(Vector2 collisionPoint) => _despawn();
}
