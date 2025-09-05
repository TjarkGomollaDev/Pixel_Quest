import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/collision/collision.dart';
import 'package:pixel_adventure/game/collision/entity_collision.dart';
import 'package:pixel_adventure/game/level/level.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/utils/utils.dart';
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

/// A collectible fruit item that animates and can be picked up by the [Player].
///
/// This fruit remains idle until collected, then plays a short "collected"
/// animation before disappearing from the level. Once collected, it increments
/// the player's fruit counter and is no longer visible in the game world.
/// Each fruit type is defined by its name and has its own idle animation.
class Fruit extends SpriteAnimationGroupComponent
    with EntityCollision, HasGameReference<PixelAdventure>, HasWorldReference<Level>, CollisionCallbacks {
  // constructor parameters
  final String _name;
  final bool _collectible;

  Fruit({required String name, required super.position, bool collectible = true})
    : _name = name,
      _collectible = collectible,
      super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2.all(32);

  // hitbox
  late final RectangleHitbox _hitbox;

  // animation settings
  static final Vector2 _textureSize = Vector2.all(32);
  static const String _path = 'Items/Fruits/';
  static const String _pathEnd = '.png';

  // once the item has been collected, it is no longer displayed in the UI
  bool _isCollected = false;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllSpriteAnimations();
    return super.onLoad();
  }

  void _initialSetup() {
    // hitbox
    if (_collectible) _hitbox = RectangleHitbox(position: Vector2(10, 10), size: Vector2(12, 12));

    // debug
    if (PixelAdventure.customDebug && _collectible) {
      debugMode = true;
      debugColor = AppTheme.debugColorCollectibles;
      if (_collectible) _hitbox.debugColor = AppTheme.debugColorCollectiblesHitbox;
    }

    // general
    priority = PixelAdventure.collectiblesLayerLevel;
    if (_collectible) {
      _hitbox.collisionType = CollisionType.passive;
      add(_hitbox);
    } else {
      anchor = Anchor.centerLeft;
    }
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<FruitState>(game, _path, _pathEnd, PixelAdventure.stepTime, _textureSize);
    animations = {
      for (var state in FruitState.values)
        // small adjustment here, as we are not using the enum name for the fruit but the name from the class
        state: state == FruitState.idle
            ? loadSpriteAnimation(game, '$_path$_name$_pathEnd', state.amount, PixelAdventure.stepTime, _textureSize)
            : loadAnimation(state),
    };
    current = FruitState.idle;
    if (!_collectible) {
      animationTicker?.currentIndex = 0;
      animationTicker?.paused = true;
    }
  }

  @override
  void onEntityCollision(CollisionSide collisionSide) {
    if (!_isCollected) {
      _isCollected = true;
      world.increaseFruitsCount();
      current = FruitState.collected;
      animationTickers![FruitState.collected]!.completed.whenComplete(() => removeFromParent());
    }
  }

  @override
  EntityCollisionType get collisionType => EntityCollisionType.Any;

  @override
  ShapeHitbox get entityHitbox => _hitbox;
}
