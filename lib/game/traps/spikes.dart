import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/collision/collision.dart';
import 'package:pixel_adventure/game/collision/entity_collision.dart';
import 'package:pixel_adventure/game/level/player/player.dart';
import 'package:pixel_adventure/game/utils/grid.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game/utils/utils.dart';
import 'package:pixel_adventure/game/game_settings.dart';
import 'package:pixel_adventure/game/game.dart';

/// A spike trap that renders a row of spikes along one side of a tile area.
///
/// The spikes can be placed on the top, right, bottom, or left side of their bounding box,
/// and automatically normalize their dimensions to align with the game's tile grid.
/// Each spike is drawn as part of a continuous row using [addSpriteRow],
/// creating a seamless trap surface.
///
/// The spikes themselves do not move, but act as a passive collision area
/// that can interact with the [Player].
class Spikes extends PositionComponent with EntityCollision, HasGameReference<PixelQuest> {
  // constructor parameters
  int _side;
  final Player _player;

  Spikes({required int side, required Player player, required super.position, required super.size}) : _side = side, _player = player;

  // actual hitbox
  late final RectangleHitbox _hitbox;

  // count spikes
  late final double _count;

  // animation settings
  static const String _path = 'Traps/Spikes/Idle.png';

  @override
  FutureOr<void> onLoad() {
    _normalizeDimensions();
    _setupHitbox();
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
    if (GameSettings.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
      _hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    priority = GameSettings.trapLayerLevel;
    _hitbox.collisionType = CollisionType.passive;
    add(_hitbox);
  }

  void _normalizeDimensions() {
    if (_side > 4 || _side < 1) _side = 1;
    // intercept any errors from the tiled world editor, set the height to the tile size and the width to a multiple of the tile size
    if (_side.isOdd) {
      height = GameSettings.tileSize;
      width = snapValueToGrid(width);
    } else {
      width = GameSettings.tileSize;
      height = snapValueToGrid(height);
    }
    _count = (_side.isOdd ? width : height) / GameSettings.tileSize;
  }

  void _setupHitbox() {
    _hitbox = switch (_side) {
      // right, bottom, left and default top
      2 => RectangleHitbox(position: Vector2.zero(), size: Vector2(8, height)),
      3 => RectangleHitbox(position: Vector2.zero(), size: Vector2(width, 8)),
      4 => RectangleHitbox(position: Vector2(8, 0), size: Vector2(8, height)),
      _ => RectangleHitbox(position: Vector2(0, 8), size: Vector2(width, 8)),
    };
  }

  void _loadSprite() {
    final sprite = loadSprite(game, _path);
    addSpriteRow(game: game, side: _side, count: _count, parent: this, sprite: sprite);
  }
}
