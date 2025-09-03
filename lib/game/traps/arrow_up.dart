import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/utils/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum ArrowUpState implements AnimationState {
  idle('Idle', 10),
  hit('Hit', 4, loop: false);

  @override
  final String name;
  @override
  final int amount;
  @override
  final bool loop;

  const ArrowUpState(this.name, this.amount, {this.loop = true});
}

/// A collectible arrow boost item that animates and can be picked up by the [Player].
///
/// When the player collides with it, the arrow boosts the player vertically
/// with increased jump force, switches into its hit animation, and disappears
/// from the world once the animation has finished. Before being collected,
/// the arrow remains in its idle state and passively waits for interaction.
class ArrowUp extends PositionComponent
    with FixedGridOriginalSizeGroupAnimation, PlayerCollision, HasGameReference<PixelAdventure>, CollisionCallbacks {
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

  void _initialSetup() {
    // debug
    if (PixelAdventure.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorCollectibles;
      _hitbox.debugColor = AppTheme.debugColorCollectiblesHitbox;
    }

    // general
    priority = PixelAdventure.collectiblesLayerLevel;
    _hitbox.collisionType = CollisionType.passive;
    add(_hitbox);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<ArrowUpState>(game, _path, _pathEnd, PixelAdventure.stepTime, _textureSize);
    final animations = {for (var state in ArrowUpState.values) state: loadAnimation(state)};
    addAnimationGroupComponent(textureSize: _textureSize, animations: animations, current: ArrowUpState.idle, isBottomCenter: false);
  }

  @override
  void onPlayerCollisionStart(Vector2 intersectionPoint) {
    if (!_isCollected) {
      _isCollected = true;
      animationGroupComponent.current = ArrowUpState.hit;
      _player.bounceUp(jumpForce: _bounceHeight);
      animationGroupComponent.animationTickers![ArrowUpState.hit]!.completed.whenComplete(() => removeFromParent());
    }
  }
}
