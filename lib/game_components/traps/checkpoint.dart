import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game_components/level/player.dart';
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
  // constructor parameters
  final Player _player;

  Checkpoint({required Player player, required super.position}) : _player = player, super(size: _fixedSize);

  // size
  static final Vector2 _fixedSize = Vector2.all(64);

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(18, 18), size: Vector2(12, 46));

  // animation settings
  static const double _stepTime = 0.05;
  static final Vector2 _textureSize = Vector2.all(64);
  static const String _path = 'Items/Checkpoints/Checkpoint/Checkpoint (';
  static const String _pathEnd = ').png';

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
      debugColor = AppTheme.debugColorTrap;
      _hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    priority = PixelAdventure.trapLayerLevel;
    _hitbox.collisionType = CollisionType.passive;
    add(_hitbox);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<CheckpointState>(game, _path, _pathEnd, _stepTime, _textureSize);
    animations = {for (var state in CheckpointState.values) state: loadAnimation(state)};

    // set current animation state
    current = CheckpointState.noFlag;
  }

  Future<void> collidedWithPlayer() async {
    current = CheckpointState.flagOut;
    _player.reachedCheckpoint();
    await animationTickers![CheckpointState.flagOut]!.completed;
    current = CheckpointState.flagIdle;
  }
}
