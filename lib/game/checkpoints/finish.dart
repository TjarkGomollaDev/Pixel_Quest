import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/data/audio/audio_center.dart';
import 'package:pixel_adventure/game/collision/world_collision.dart';
import 'package:pixel_adventure/game/level/player/player.dart';
import 'package:pixel_adventure/game/utils/animation_state.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game/game_settings.dart';
import 'package:pixel_adventure/game/game.dart';

enum FinishState implements AnimationState {
  idle('Idle', 1),
  pressed('Pressed', 8, loop: false);

  @override
  final String fileName;
  @override
  final int amount;
  @override
  final bool loop;

  const FinishState(this.fileName, this.amount, {this.loop = true});
}

class Finish extends SpriteAnimationGroupComponent with HasGameReference<PixelQuest>, CollisionCallbacks, WorldCollision {
  // constructor parameters
  final Player _player;

  Finish({required Player player, required super.position}) : _player = player, super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2.all(64);

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(15, 20), size: Vector2(34, 44));

  // animation settings
  static final Vector2 _textureSize = Vector2.all(64);
  static const String _path = 'Items/Checkpoints/End/';
  static const String _pathEnd = ' (64x64).png';

  // reached
  bool reached = false;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllSpriteAnimations();
    return super.onLoad();
  }

  void _initialSetup() {
    // debug
    if (GameSettings.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
      _hitbox.debugColor = _hitbox.debugColor = AppTheme.debugColorWorldBlock;
    }

    // general
    priority = GameSettings.trapLayerLevel;
    _hitbox.collisionType = CollisionType.passive;
    add(_hitbox);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<FinishState>(game, _path, _pathEnd, GameSettings.stepTime, _textureSize);
    animations = {for (var state in FinishState.values) state: loadAnimation(state)};
    current = FinishState.idle;
  }

  Future<void> reachedFinish() async {
    if (reached) return;
    reached = true;
    current = FinishState.pressed;
    _player.reachedFinish(_hitbox);
    game.audioCenter.stopBackgroundMusic();
    game.audioCenter.playSound(Sfx.finish, SfxType.level);

    await animationTickers![FinishState.pressed]!.completed;
    current = FinishState.idle;
  }

  @override
  ShapeHitbox get worldHitbox => _hitbox;
}
