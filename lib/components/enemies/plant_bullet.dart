import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/components/collision_block.dart';
import 'package:pixel_adventure/components/enemies/turtle.dart';
import 'package:pixel_adventure/components/traps/saw.dart';
import 'package:pixel_adventure/components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class PlantBullet extends SpriteComponent with HasGameReference<PixelAdventure>, CollisionCallbacks {
  final bool isLeft;

  PlantBullet({required this.isLeft, required super.position}) : super(size: fixedSize);

  // size
  static final Vector2 fixedSize = Vector2.all(16);
  static final Vector2 hitboxOffset = Vector2(4, 4);
  static const double hitboxRadius = 4;

  // actual hitbox
  final CircleHitbox hitbox = CircleHitbox(position: hitboxOffset, radius: hitboxRadius);

  // animation settings
  final String _path = 'Enemies/Plant/Bullet.png';

  // movement
  final double _moveSpeed = 100; // [Adjustable]
  late double _moveDirection;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAnimation();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    _move(dt);
    super.update(dt);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is CollisionBlock && !other.isPlattform) _despawn();
    if (other is Saw) _despawn();
    if (other is Turtle) _despawn();
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
    add(hitbox);
    _moveDirection = isLeft ? -1 : 1;
  }

  void _loadAnimation() => sprite = loadSprite(game, _path);

  void _move(double dt) => position.x += _moveDirection * _moveSpeed * dt;

  void _despawn() => removeFromParent();

  void collidedWithPlayer(Vector2 collisionPoint) => _despawn();
}
