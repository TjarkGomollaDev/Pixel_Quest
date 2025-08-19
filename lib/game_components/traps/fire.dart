import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game_components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class Fire extends SpriteAnimationComponent with HasGameReference<PixelAdventure>, CollisionCallbacks {
  Fire({required super.position, required super.size});

  // actual hitbox
  final RectangleHitbox hitbox = RectangleHitbox();

  // animation settings
  final double _stepTime = 0.05;
  final Vector2 _textureSize = Vector2(16, 16);
  final String _path = 'Traps/Fire/On (16x32).png';
  final int _amount = 3;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAnimation();
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
    priority = PixelAdventure.trapBehindLayerLevel;
    hitbox.collisionType = CollisionType.passive;
    add(hitbox);
  }

  void _loadAnimation() => animation = loadSpriteAnimation(game, _path, _amount, _stepTime, _textureSize);
}
