import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/collision/collision.dart';
import 'package:pixel_adventure/game/collision/entity_collision.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

/// A single saw unit used inside a [SawCircle].
///
/// The saw is rendered as a rotating sprite animation with a circular hitbox,
/// anchored at its center. Depending on configuration, it can be mirrored
/// to represent clockwise or counterclockwise motion within the circular trap.
///
/// This component does not move by itself, but is positioned and updated
/// by its parent [SawCircle]. It acts as a passive collision area
/// that can interact with the [Player].
class SawCircleSingleSaw extends SpriteAnimationComponent with EntityCollision, HasGameReference<PixelAdventure> {
  // constructor parameters
  final bool _clockwise;
  final Player _player;

  SawCircleSingleSaw({required bool clockwise, required Player player, required super.position})
    : _clockwise = clockwise,
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
  static const String _path = 'Traps/Saw/On (38x38).png';

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadSpriteAnimation();
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
    _hitbox.collisionType = CollisionType.passive;
    anchor = Anchor.center;
    add(_hitbox);
  }

  void _loadSpriteAnimation() {
    animation = loadSpriteAnimation(game, _path, _amount, _stepTime, _textureSize);
    if (_clockwise) flipHorizontally();
  }

  @override
  void onEntityCollision(CollisionSide collisionSide) => _player.collidedWithEnemy(collisionSide);

  @override
  ShapeHitbox get entityHitbox => _hitbox;
}
