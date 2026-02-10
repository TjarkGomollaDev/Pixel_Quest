import 'dart:async';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_quest/app_theme.dart';
import 'package:pixel_quest/game/collision/collision.dart';
import 'package:pixel_quest/game/collision/entity_collision.dart';
import 'package:pixel_quest/game/hud/mini%20map/entity_on_mini_map.dart';
import 'package:pixel_quest/game/level/player/player.dart';
import 'package:pixel_quest/game/utils/grid.dart';
import 'package:pixel_quest/game/utils/load_sprites.dart';
import 'package:pixel_quest/game/game_settings.dart';
import 'package:pixel_quest/game/game.dart';

/// The actual damaging spiked-ball entity used by [SpikedBallComponent]:
/// a circular hitbox with a sprite that can be positioned by its parent component.
class SpikedBall extends PositionComponent
    with FixedGridOriginalSizeSprite, EntityCollision, EntityOnMiniMap, HasGameReference<PixelQuest> {
  // constructor parameters
  final Player _player;

  SpikedBall({required Player player}) : _player = player, super(position: .zero(), size: gridSize) {
    // marker is set here because the ball is not added directly to the level,
    // but via the parent SpikedBallComponent, and we need direct access before onLoad()
    _setUpMarker();
  }

  // size
  static final Vector2 gridSize = .all(32);

  // actual hitbox
  final CircleHitbox _hitbox = CircleHitbox(position: (gridSize - _textureSize) / 2, radius: _textureSize.x / 2);

  // animation settings
  static final Vector2 _textureSize = .all(28);
  static const String _path = 'Traps/Spiked Ball/Spiked Ball (28x28).png';

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadSprite();
    return super.onLoad();
  }

  @override
  void onEntityCollision(CollisionSide collisionSide) => _player.collidedWithEnemy(collisionSide);

  @override
  ShapeHitbox get entityHitbox => _hitbox;

  void _initialSetup() {
    // debug
    if (GameSettings.showDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
      _hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    anchor = Anchor.center;
    _hitbox.collisionType = .passive;
    add(_hitbox);
  }

  void _setUpMarker() {
    marker = EntityMiniMapMarker(size: _hitbox.height, color: AppTheme.entityMarkerSpecial);
  }

  void _loadSprite() {
    addSpriteComponent(textureSize: _textureSize, sprite: loadSprite(game, _path), isBottomCenter: false);

    // rotate so that there is no spike at the top
    spriteComponent.angle += pi / 8;
  }
}
