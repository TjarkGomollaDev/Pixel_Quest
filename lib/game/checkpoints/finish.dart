import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_quest/app_theme.dart';
import 'package:pixel_quest/game/collision/world_collision.dart';
import 'package:pixel_quest/game/level/player/player.dart';
import 'package:pixel_quest/game/utils/animation_state.dart';
import 'package:pixel_quest/game/utils/load_sprites.dart';
import 'package:pixel_quest/game/game_settings.dart';
import 'package:pixel_quest/game/game.dart';

enum _FinishState implements AnimationState {
  idle('Idle', 1),
  pressed('Pressed', 8, loop: false);

  @override
  final String fileName;
  @override
  final int amount;
  @override
  final bool loop;

  const _FinishState(this.fileName, this.amount, {this.loop = true});
}

/// Level end checkpoint that triggers when the player reaches it.
///
/// Provides a passive world hitbox for collision detection and plays a short
/// activation animation + finish sound exactly once per level run.
class Finish extends SpriteAnimationGroupComponent with HasGameReference<PixelQuest>, CollisionCallbacks, WorldCollision {
  // constructor parameters
  final Player _player;

  Finish({required Player player, required super.position}) : _player = player, super(size: gridSize);

  // size
  static final Vector2 gridSize = .all(64);

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(15, 20), size: Vector2(34, 44));

  // animation settings
  static final Vector2 _textureSize = .all(64);
  static const String _path = 'Items/Checkpoints/End/';
  static const String _pathEnd = ' (64x64).png';

  // reached
  bool _reached = false;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllSpriteAnimations();
    return super.onLoad();
  }

  @override
  ShapeHitbox get worldHitbox => _hitbox;

  void _initialSetup() {
    // debug
    if (GameSettings.showDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
      _hitbox.debugColor = _hitbox.debugColor = AppTheme.debugColorWorldBlock;
    }

    // general
    priority = GameSettings.trapLayerLevel;
    _hitbox.collisionType = .passive;
    add(_hitbox);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<_FinishState>(game, _path, _pathEnd, GameSettings.stepTime, _textureSize);
    animations = {for (final state in _FinishState.values) state: loadAnimation(state)};
    current = _FinishState.idle;
  }

  Future<void> reachedFinish() async {
    if (_reached) return;
    _reached = true;
    _player.reachedFinish(_hitbox);

    // finish sound
    game.audioCenter.stopBackgroundMusic();
    game.audioCenter.playSound(.finish, .level);

    // play reached finish animation
    current = _FinishState.pressed;
    await animationTickers![_FinishState.pressed]!.completed;
    current = _FinishState.idle;
  }
}
