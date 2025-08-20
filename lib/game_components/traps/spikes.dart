import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game_components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class Spikes extends PositionComponent with HasGameReference<PixelAdventure>, CollisionCallbacks {
  int side;

  Spikes({required this.side, required super.position, required super.size});

  // actual hitbox
  late final RectangleHitbox hitbox;

  // count spikes
  late final double _count;

  // animation settings
  final String _path = 'Traps/Spikes/Idle.png';

  @override
  FutureOr<void> onLoad() {
    _normalizeDimensions();
    _setupHitbox();
    _initialSetup();
    _loadSprite();
    return super.onLoad();
  }

  void _initialSetup() {
    // debug
    if (game.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
      hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    priority = PixelAdventure.trapLayerLevel;
    hitbox.collisionType = CollisionType.passive;
    add(hitbox);
  }

  void _normalizeDimensions() {
    if (side > 4 || side < 1) side = 1;
    // intercept any errors from the tiled world editor, set the height to the tile size and the width to a multiple of the tile size
    if (side.isOdd) {
      height = game.tileSize;
      width = ((width / game.tileSize).round()) * game.tileSize;
    } else {
      width = game.tileSize;
      height = ((height / game.tileSize).round()) * game.tileSize;
    }
    _count = (side.isOdd ? width : height) / game.tileSize;
  }

  void _setupHitbox() {
    hitbox = switch (side) {
      // right, bottom, left and default top
      2 => RectangleHitbox(position: Vector2.zero(), size: Vector2(8, height)),
      3 => RectangleHitbox(position: Vector2.zero(), size: Vector2(width, 8)),
      4 => RectangleHitbox(position: Vector2(8, 0), size: Vector2(8, height)),
      _ => RectangleHitbox(position: Vector2(0, 8), size: Vector2(width, 8)),
    };
  }

  void _loadSprite() {
    final sprite = loadSprite(game, _path);
    addSpriteRow(game: game, side: side, count: _count, parent: this, sprite: sprite);
  }
}
