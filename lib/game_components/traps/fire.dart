import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game_components/level/player.dart';
import 'package:pixel_adventure/game_components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

/// A fire that renders a row of animated flames along one side of a tile area.
///
/// The fire can be placed on the top, right, bottom, or left side of its bounding box,
/// and automatically normalizes its dimensions to align with the game's tile grid.
/// Each flame is drawn as part of a continuous row using [addSpriteRow],
/// creating a seamless trap surface.
///
/// The fire itself does not move, but acts as a passive collision area
/// that can interact with the [Player].
class Fire extends PositionComponent with HasGameReference<PixelAdventure>, CollisionCallbacks {
  // constructor parameters
  int _side;
  final Player _player;

  Fire({required int side, required Player player, required super.position, required super.size}) : _side = side, _player = player;

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox();

  // count fires
  late final double _count;

  // animation settings
  static const double _stepTime = 0.05;
  static final Vector2 _textureSize = Vector2(16, 16);
  static const String _path = 'Traps/Fire/On (16x32).png';
  static const int _amount = 3;

  @override
  FutureOr<void> onLoad() {
    _normalizeDimensions();
    _initialSetup();
    _loadSpriteAnimation();
    return super.onLoad();
  }

  void _normalizeDimensions() {
    if (_side > 4 || _side < 1) _side = 1;
    // intercept any errors from the tiled world editor, set the height to the tile size and the width to a multiple of the tile size
    if (_side.isOdd) {
      height = PixelAdventure.tileSize;
      width = ((width / PixelAdventure.tileSize).round()) * PixelAdventure.tileSize;
    } else {
      width = PixelAdventure.tileSize;
      height = ((height / PixelAdventure.tileSize).round()) * PixelAdventure.tileSize;
    }
    _count = (_side.isOdd ? width : height) / PixelAdventure.tileSize;
  }

  void _initialSetup() {
    // debug
    if (game.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
      _hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    priority = PixelAdventure.trapBehindLayerLevel;
    _hitbox.collisionType = CollisionType.passive;
    add(_hitbox);
  }

  void _loadSpriteAnimation() {
    final animation = loadSpriteAnimation(game, _path, _amount, _stepTime, _textureSize);
    addSpriteRow(game: game, side: _side, count: _count, parent: this, animation: animation);
  }

  void collidedWithPlayer() => _player.collidedWithEnemy();
}
