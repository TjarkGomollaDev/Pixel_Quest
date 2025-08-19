import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game_components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum CheckpointState implements AnimationState {
  flagIdle('Flag Idle', 10),
  flagOut('Flag Out', 26, loop: false),
  noFlag('No Flag', 1);

  @override
  final String name;
  @override
  final int amount;
  @override
  final bool loop;

  const CheckpointState(this.name, this.amount, {this.loop = true});
}

class Checkpoint extends SpriteAnimationGroupComponent with HasGameReference<PixelAdventure>, CollisionCallbacks {
  Checkpoint({required super.position, required super.size});

  // actual hitbox
  final RectangleHitbox hitbox = RectangleHitbox(position: Vector2(18, 18), size: Vector2(12, 46));

  // animation settings
  final double _stepTime = 0.05;
  final Vector2 _textureSize = Vector2.all(64);
  final String _path = 'Items/Checkpoints/Checkpoint/Checkpoint (';
  final String _pathEnd = ').png';

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllAnimations();
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
    priority = PixelAdventure.trapLayerLevel;
    hitbox.collisionType = CollisionType.passive;
    add(hitbox);
  }

  void _loadAllAnimations() {
    final loadAnimation = spriteAnimationWrapper<CheckpointState>(game, _path, _pathEnd, _stepTime, _textureSize);

    // list of all animations
    animations = {for (var state in CheckpointState.values) state: loadAnimation(state)};

    // set current animation state
    current = CheckpointState.noFlag;
  }

  Future<void> collidedWithPlayer() async {
    current = CheckpointState.flagOut;
    await animationTickers![CheckpointState.flagOut]!.completed;
    current = CheckpointState.flagIdle;
  }
}
