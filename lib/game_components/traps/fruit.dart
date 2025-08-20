import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game_components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum FruitState implements AnimationState {
  idle('Idle', 17),
  collected('Collected', 6, loop: false);

  @override
  final String name;
  @override
  final int amount;
  @override
  final bool loop;

  const FruitState(this.name, this.amount, {this.loop = true});
}

// ignore: constant_identifier_names
enum FruitName { Apple, Bananas, Cherries, Kiwi, Melon, Orange, Pineapple, Strawberry }

class Fruit extends SpriteAnimationGroupComponent with HasGameReference<PixelAdventure>, CollisionCallbacks {
  final String name;

  Fruit({required this.name, required super.position, required super.size});

  // hitbox
  final RectangleHitbox hitbox = RectangleHitbox(position: Vector2(10, 10), size: Vector2(12, 12));

  // animation settings
  final double _stepTime = 0.05;
  final Vector2 _textureSize = Vector2.all(32);
  final String _path = 'Items/Fruits/';
  final String _pathEnd = '.png';

  // once the item has been collected, it is no longer displayed in the UI
  bool _isCollected = false;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllSpriteAnimations();

    return super.onLoad();
  }

  void _initialSetup() {
    // debug
    if (game.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorCollectibles;
      hitbox.debugColor = AppTheme.debugColorcollectiblesHitbox;
    }

    // general
    priority = PixelAdventure.collectiblesLayerLevel;
    hitbox.collisionType = CollisionType.passive;
    add(hitbox);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<FruitState>(game, _path, _pathEnd, _stepTime, _textureSize);

    // list of all animations
    animations = {
      for (var state in FruitState.values)
        // small adjustment here, as we are not using the enum name but the name from the class
        state: state == FruitState.idle
            ? loadSpriteAnimation(game, '$_path$name$_pathEnd', state.amount, _stepTime, _textureSize)
            : loadAnimation(state),
    };

    // set current animation state
    current = FruitState.idle;
  }

  void collidedWithPlayer() {
    if (!_isCollected) {
      _isCollected = true;
      current = FruitState.collected;
      animationTickers![FruitState.collected]!.completed.whenComplete(() => removeFromParent());
    }
  }
}
