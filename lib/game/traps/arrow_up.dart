import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_quest/app_theme.dart';
import 'package:pixel_quest/data/audio/audio_center.dart';
import 'package:pixel_quest/game/collision/collision.dart';
import 'package:pixel_quest/game/collision/entity_collision.dart';
import 'package:pixel_quest/game/hud/mini%20map/entity_on_mini_map.dart';
import 'package:pixel_quest/game/level/level.dart';
import 'package:pixel_quest/game/level/player/player.dart';
import 'package:pixel_quest/game/utils/animation_state.dart';
import 'package:pixel_quest/game/utils/grid.dart';
import 'package:pixel_quest/game/utils/load_sprites.dart';
import 'package:pixel_quest/game/game_settings.dart';
import 'package:pixel_quest/game/game.dart';
import 'package:pixel_quest/game/utils/misc_utils.dart';

enum ArrowUpState implements AnimationState {
  idle('Idle', 10),
  hit('Hit', 4, loop: false);

  @override
  final String fileName;
  @override
  final int amount;
  @override
  final bool loop;

  const ArrowUpState(this.fileName, this.amount, {this.loop = true});
}

/// A collectible arrow boost item that animates and can be picked up by the [Player].
///
/// When the player collides with it, the arrow boosts the player vertically
/// with increased jump force, switches into its hit animation, and disappears
/// from the world once the animation has finished. Before being collected,
/// the arrow remains in its idle state and passively waits for interaction.
class ArrowUp extends PositionComponent
    with
        FixedGridOriginalSizeGroupAnimation,
        HasGameReference<PixelQuest>,
        HasWorldReference<Level>,
        Respawnable,
        EntityCollision,
        EntityOnMiniMap {
  // constructor parameters
  final Player _player;

  ArrowUp({required Player player, required super.position}) : _player = player, super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2.all(32);

  // hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(11, 11), size: Vector2(10, 10));

  // animation settings
  static final Vector2 _textureSize = Vector2.all(18);
  static const String _path = 'Traps/Arrow/';
  static const String _pathEnd = ' (18x18).png';

  // once the item has been collected, it is no longer displayed in the UI
  bool _isCollected = false;
  final double _bounceHeight = 400; // [Adjustable]

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllSpriteAnimations();
    return super.onLoad();
  }

  @override
  void onRespawn() {
    animationGroupComponent.current = ArrowUpState.idle;
    _isCollected = false;
  }

  @override
  void onEntityCollision(CollisionSide collisionSide) {
    if (!_isCollected) {
      _isCollected = true;
      _player.bounceUp(jumpForce: _bounceHeight);

      // play hit animation and then remove from level
      game.audioCenter.playSound(Sfx.jumpBoost, SfxType.game);
      animationGroupComponent.current = ArrowUpState.hit;
      animationGroupComponent.animationTickers![ArrowUpState.hit]!.completed.whenComplete(() {
        world.queueForRespawn(this);
        removeFromParent();
      });
    }
  }

  @override
  EntityCollisionType get collisionType => EntityCollisionType.any;

  @override
  ShapeHitbox get entityHitbox => _hitbox;

  void _initialSetup() {
    // debug
    if (GameSettings.customDebugMode) {
      debugMode = true;
      debugColor = AppTheme.debugColorCollectibles;
      _hitbox.debugColor = AppTheme.debugColorCollectiblesHitbox;
    }

    // general
    priority = GameSettings.collectiblesLayerLevel;
    _hitbox.collisionType = CollisionType.passive;
    add(_hitbox);
    marker = EntityMiniMapMarker(layer: EntityMiniMapMarkerLayer.none);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<ArrowUpState>(game, _path, _pathEnd, GameSettings.stepTime, _textureSize);
    final animations = {for (final state in ArrowUpState.values) state: loadAnimation(state)};
    addAnimationGroupComponent(textureSize: _textureSize, animations: animations, current: ArrowUpState.idle, isBottomCenter: false);
  }
}
