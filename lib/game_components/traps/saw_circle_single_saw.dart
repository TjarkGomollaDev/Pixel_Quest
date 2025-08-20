import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game_components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class SawCircleSingleSaw extends SpriteAnimationComponent with HasGameReference<PixelAdventure> {
  final bool clockwise;

  SawCircleSingleSaw({required this.clockwise, required super.position}) : super(size: fixedSize);

  // size
  static Vector2 fixedSize = Vector2.all(32);

  // actual hitbox
  final CircleHitbox hitbox = CircleHitbox();

  // animation settings
  final double _stepTime = 0.03;
  final Vector2 _textureSize = Vector2.all(38);
  final int _amount = 8;
  final String _path = 'Traps/Saw/On (38x38).png';

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadSpriteAnimation();

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
    hitbox.collisionType = CollisionType.passive;
    anchor = Anchor.center;
    add(hitbox);
    if (clockwise) flipHorizontally();
  }

  void _loadSpriteAnimation() => animation = loadSpriteAnimation(game, _path, _amount, _stepTime, _textureSize);
}
