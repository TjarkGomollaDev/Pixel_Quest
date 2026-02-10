import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_quest/app_theme.dart';
import 'package:pixel_quest/game/collision/collision.dart';
import 'package:pixel_quest/game/collision/entity_collision.dart';
import 'package:pixel_quest/game/hud/mini%20map/entity_on_mini_map.dart';
import 'package:pixel_quest/game/level/level.dart';
import 'package:pixel_quest/game/level/player/player.dart';
import 'package:pixel_quest/game/utils/animation_state.dart';
import 'package:pixel_quest/game/utils/load_sprites.dart';
import 'package:pixel_quest/game/game_settings.dart';
import 'package:pixel_quest/game/game.dart';

enum _FruitState implements AnimationState {
  idle('Idle', 17),
  collected('Collected', 6, loop: false);

  @override
  final String fileName;
  @override
  final int amount;
  @override
  final bool loop;

  const _FruitState(this.fileName, this.amount, {this.loop = true});
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
    with HasGameReference<PixelQuest>, HasWorldReference<Level>, EntityCollision, EntityOnMiniMap {
  // constructor parameters
  final String _name;

  Fruit({required String name, required super.position}) : _name = name, super(size: gridSize);

  // size
  static final Vector2 gridSize = .all(32);

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(10, 10), size: Vector2(12, 12));

  // animation settings
  static final Vector2 _textureSize = .all(32);
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

  @override
  void onEntityCollision(CollisionSide collisionSide) {
    if (!_isCollected) {
      _isCollected = true;
      world.increaseFruitsCount();

      // play collected animation and then remove from level
      game.audioCenter.playSound(.collected, .game);
      current = _FruitState.collected;
      animationTickers![_FruitState.collected]!.completed.whenComplete(() => removeFromParent());
    }
  }

  @override
  EntityCollisionType get collisionType => .any;

  @override
  ShapeHitbox get entityHitbox => _hitbox;

  void _initialSetup() {
    // debug
    if (GameSettings.showDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorCollectibles;
      _hitbox.debugColor = AppTheme.debugColorCollectiblesHitbox;
    }

    // general
    priority = GameSettings.collectiblesLayerLevel;
    _hitbox.collisionType = .passive;
    add(_hitbox);
    marker = EntityMiniMapMarker(layer: .none);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<_FruitState>(game, _path, _pathEnd, GameSettings.stepTime, _textureSize);
    animations = {
      for (final state in _FruitState.values)
        // small adjustment here, as we are not using the enum name for the fruit but the name from the class
        state: state == .idle
            ? loadSpriteAnimation(game, '$_path$_name$_pathEnd', state.amount, GameSettings.stepTime, _textureSize)
            : loadAnimation(state),
    };
    current = _FruitState.idle;
  }
}
