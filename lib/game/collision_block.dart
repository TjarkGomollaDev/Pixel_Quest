import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class WorldBlock extends PositionComponent with HasGameReference<PixelAdventure>, CollisionCallbacks, CollisionBlock {
  final bool isPlattform;

  WorldBlock({this.isPlattform = false, super.position, super.size});

  // actual hitbox
  late final RectangleHitbox _hitbox;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    return super.onLoad();
  }

  void _initialSetup() {
    // debug
    if (game.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorWorldBlock;
    }

    // general
    _hitbox = RectangleHitbox(size: size)..collisionType = CollisionType.passive;
    add(_hitbox);
  }

  @override
  ShapeHitbox get solidHitbox => _hitbox;
}

mixin CollisionBlock {
  ShapeHitbox get solidHitbox;
}
