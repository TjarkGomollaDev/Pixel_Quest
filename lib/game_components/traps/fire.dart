import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game_components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class Fire extends PositionComponent with HasGameReference<PixelAdventure>, CollisionCallbacks {
  int side;
  Fire({required this.side, required super.position, required super.size});

  // actual hitbox
  final RectangleHitbox hitbox = RectangleHitbox();

  // count fires
  late final double _count;

  // animation settings
  final double _stepTime = 0.05;
  final Vector2 _textureSize = Vector2(16, 16);
  final String _path = 'Traps/Fire/On (16x32).png';
  final int _amount = 3;

  @override
  FutureOr<void> onLoad() {
    _normalizeDimensions();
    _initialSetup();
    _loadSpriteAnimation();
    return super.onLoad();
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

  void _initialSetup() {
    // debug
    if (game.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
      hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    priority = PixelAdventure.trapBehindLayerLevel;
    hitbox.collisionType = CollisionType.passive;
    add(hitbox);
  }

  void _loadSpriteAnimation() {
    final animation = loadSpriteAnimation(game, _path, _amount, _stepTime, _textureSize);
    addSpriteRow(game: game, side: side, count: _count, parent: this, animation: animation);
  }
}
