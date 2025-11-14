import 'dart:async';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/collision/collision.dart';
import 'package:pixel_adventure/game/collision/entity_collision.dart';
import 'package:pixel_adventure/game/hud/entity_on_mini_map.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/utils/grid.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_quest.dart';

class SpikedBallBall extends PositionComponent
    with FixedGridOriginalSizeSprite, EntityCollision, EntityOnMiniMap, HasGameReference<PixelQuest> {
  // constructor parameters
  final Player _player;

  SpikedBallBall({required Player player}) : _player = player, super(position: Vector2.zero(), size: gridSize) {
    // marker is set here because the ball is not added directly to the level,
    // but via the parent SpikedBallComponent, and we need direct access before onLoad()
    _setUpMarker();
  }

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
    if (GameSettings.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
      _hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    anchor = Anchor.center;
    _hitbox.collisionType = CollisionType.passive;
    add(_hitbox);
  }

  void _setUpMarker() => marker = EntityMiniMapMarker(size: _hitbox.height, color: AppTheme.entityMarkerSpecial);

  void _loadSprite() {
    addSpriteComponent(textureSize: _textureSize, sprite: loadSprite(game, _path), isBottomCenter: false);

    // rotate so that there is no spike at the top
    spriteComponent.angle += pi / 8;
  }

  @override
  void onEntityCollision(CollisionSide collisionSide) => _player.collidedWithEnemy(collisionSide);

  @override
  ShapeHitbox get entityHitbox => _hitbox;
}
