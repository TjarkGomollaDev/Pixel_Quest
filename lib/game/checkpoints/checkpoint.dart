import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/data/audio/audio_center.dart';
import 'package:pixel_adventure/game/collision/collision.dart';
import 'package:pixel_adventure/game/collision/entity_collision.dart';
import 'package:pixel_adventure/game/level/player/player.dart';
import 'package:pixel_adventure/game/utils/animation_state.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game/game_settings.dart';
import 'package:pixel_adventure/game/game.dart';

enum CheckpointState implements AnimationState {
  flagIdle('Flag Idle', 10),
  flagOut('Flag Out', 26, loop: false),
  noFlag('No Flag', 1);

  @override
  final String fileName;
  @override
  final int amount;
  @override
  final bool loop;

  const CheckpointState(this.fileName, this.amount, {this.loop = true});
}

/// Represents a checkpoint in the level where the player can respawn.
///
/// The checkpoint has three animation states:
/// - [CheckpointState.noFlag]: Default inactive state.
/// - [CheckpointState.flagOut]: Flag is raised when the player reaches the checkpoint.
/// - [CheckpointState.flagIdle]: Flag stays up after activation.
///
/// When the player collides with the checkpoint, the flag animation
/// plays, and the player is registered as having reached the checkpoint.
class Checkpoint extends SpriteAnimationGroupComponent with EntityCollision, HasGameReference<PixelQuest>, CollisionCallbacks {
  // constructor parameters
  final Player _player;

  Checkpoint({required Player player, required super.position}) : _player = player, super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2.all(64);

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(19, 18), size: Vector2(9, 46));

  // animation settings
  static final Vector2 _textureSize = Vector2.all(64);
  static const String _path = 'Items/Checkpoints/Checkpoint/Checkpoint (';
  static const String _pathEnd = ').png';

  // reached
  bool reached = false;

  // player respawn point
  late final Vector2 _playerRespawn;

  // with this offset, the player respawn point can be moved horizontally, at 0, it is exactly to the right of the checkpoint hitbox
  static const double _offset = 4; // [Adjustable]

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllSpriteAnimations();
    _setUpRespawn();
    return super.onLoad();
  }

  void _initialSetup() {
    // debug
    if (GameSettings.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
      _hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    priority = GameSettings.trapLayerLevel;
    _hitbox.collisionType = CollisionType.passive;
    add(_hitbox);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<CheckpointState>(game, _path, _pathEnd, GameSettings.stepTime, _textureSize);
    animations = {for (var state in CheckpointState.values) state: loadAnimation(state)};
    current = CheckpointState.noFlag;
  }

  void _setUpRespawn() => _playerRespawn = Vector2(
    position.x + _hitbox.position.x + _hitbox.width - _player.hitboxLocalPosition.x + _offset,
    position.y + height - _player.height,
  );

  @override
  Future<void> onEntityCollision(CollisionSide collisionSide) async {
    if (reached || _playerRespawn.x < _player.respawnPosition.x) return;
    reached = true;
    current = CheckpointState.flagOut;
    _player.reachedCheckpoint(_playerRespawn);
    game.audioCenter.playSound(Sfx.checkpoint, SfxType.level);

    await animationTickers![CheckpointState.flagOut]!.completed;
    current = CheckpointState.flagIdle;
  }

  @override
  EntityCollisionType get collisionType => EntityCollisionType.any;

  @override
  ShapeHitbox get entityHitbox => _hitbox;
}
