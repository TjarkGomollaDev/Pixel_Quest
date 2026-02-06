import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_quest/app_theme.dart';
import 'package:pixel_quest/game/collision/collision.dart';
import 'package:pixel_quest/game/collision/entity_collision.dart';
import 'package:pixel_quest/game/collision/world_collision.dart';
import 'package:pixel_quest/game/enemies/turtle.dart';
import 'package:pixel_quest/game/hud/mini%20map/entity_on_mini_map.dart';
import 'package:pixel_quest/game/level/player/player.dart';
import 'package:pixel_quest/game/traps/fire.dart';
import 'package:pixel_quest/game/traps/saw.dart';
import 'package:pixel_quest/game/traps/saw_circle_single_saw.dart';
import 'package:pixel_quest/game/traps/spikes.dart';
import 'package:pixel_quest/game/utils/debug_components.dart';
import 'package:pixel_quest/game/utils/load_sprites.dart';
import 'package:pixel_quest/game/game_settings.dart';
import 'package:pixel_quest/game/game.dart';

/// A simple projectile fired by the Plant.
///
/// The bullet moves straight left/right, damages the player on hit,
/// and disappears when colliding with solid world/trap/enemy objects.
class PlantBullet extends SpriteComponent
    with EntityCollision, HasGameReference<PixelQuest>, CollisionCallbacks, EntityOnMiniMap, DebugOutlineOnly {
  // constructor parameters
  final bool _isLeft;
  final Player _player;

  PlantBullet({required bool isLeft, required Player player, required super.position})
    : _isLeft = isLeft,
      _player = player,
      super(size: gridSize);

  // size
  static final Vector2 gridSize = .all(16);
  static final Vector2 hitboxOffset = Vector2(4, 4);
  static const double hitboxRadius = 4;

  // actual hitbox
  final DebugCircleHitbox _hitbox = DebugCircleHitbox(position: hitboxOffset, radius: hitboxRadius);

  // animation settings
  static const String _path = 'Enemies/Plant/Bullet (16x16).png';

  // movement
  final double _moveSpeed = 100; // [Adjustable]
  late int _moveDirection;

  // list of objects that will destroy the projectile upon collision
  static const List<Type> _despawnTypes = [WorldBlock, Saw, SawCircleSingleSaw, Turtle, Spikes, Fire]; // [Adjustable]

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadSprite();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    _movement(dt);
    super.update(dt);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (_despawnTypes.any((type) => other.runtimeType == type)) _despawn();
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onEntityCollision(CollisionSide collisionSide) {
    _despawn();
    _player.collidedWithEnemy(collisionSide);
  }

  @override
  ShapeHitbox get entityHitbox => _hitbox;

  void _initialSetup() {
    // debug
    if (GameSettings.customDebugMode) {
      debugMode = true;
      debugColor = AppTheme.debugColorParticle;
      _hitbox.debugColor = AppTheme.debugColorParticleHitbox;
    }

    // general
    priority = GameSettings.enemieBulletLayerLevel;
    add(_hitbox);
    _moveDirection = _isLeft ? -1 : 1;
    marker = EntityMiniMapMarker(layer: .none);
  }

  void _loadSprite() {
    sprite = loadSprite(game, _path);
  }

  void _movement(double dt) {
    position.x += _moveDirection * _moveSpeed * dt;
  }

  void _despawn() => removeFromParent();
}
