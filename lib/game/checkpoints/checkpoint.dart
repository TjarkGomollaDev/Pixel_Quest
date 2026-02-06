import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_quest/app_theme.dart';
import 'package:pixel_quest/game/collision/collision.dart';
import 'package:pixel_quest/game/collision/entity_collision.dart';
import 'package:pixel_quest/game/level/player/player.dart';
import 'package:pixel_quest/game/utils/animation_state.dart';
import 'package:pixel_quest/game/utils/load_sprites.dart';
import 'package:pixel_quest/game/game_settings.dart';
import 'package:pixel_quest/game/game.dart';

enum _CheckpointState implements AnimationState {
  flagIdle('Flag Idle', 10),
  flagOut('Flag Out', 26, loop: false),
  noFlag('No Flag', 1);

  @override
  final String fileName;
  @override
  final int amount;
  @override
  final bool loop;

  const _CheckpointState(this.fileName, this.amount, {this.loop = true});
}

/// Represents a checkpoint in the level where the player can respawn.
///
/// The checkpoint has three animation states:
/// - [_CheckpointState.noFlag]: Default inactive state.
/// - [_CheckpointState.flagOut]: Flag is raised when the player reaches the checkpoint.
/// - [_CheckpointState.flagIdle]: Flag stays up after activation.
///
/// When the player collides with the checkpoint, the flag animation
/// plays, and the player is registered as having reached the checkpoint.
class Checkpoint extends SpriteAnimationGroupComponent with EntityCollision, HasGameReference<PixelQuest>, CollisionCallbacks {
  // constructor parameters
  final Player _player;

  Checkpoint({required Player player, required super.position}) : _player = player, super(size: gridSize);

  // size
  static final Vector2 gridSize = .all(64);

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(19, 18), size: Vector2(9, 46));

  // animation settings
  static final Vector2 _textureSize = .all(64);
  static const String _path = 'Items/Checkpoints/Checkpoint/Checkpoint (';
  static const String _pathEnd = ').png';

  // reached
  bool _reached = false;

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

  @override
  Future<void> onEntityCollision(CollisionSide collisionSide) async {
    // the checkpoint should only be set if it is further along in the level than the previous respawn point
    if (_reached || _playerRespawn.x < _player.respawnPosition.x) return;
    _reached = true;
    _player.reachedCheckpoint(_playerRespawn);
    game.audioCenter.playSound(.checkpoint, .level);

    // play reached checkpoint animation
    current = _CheckpointState.flagOut;
    await animationTickers![_CheckpointState.flagOut]!.completed;
    current = _CheckpointState.flagIdle;
  }

  @override
  EntityCollisionType get collisionType => .any;

  @override
  ShapeHitbox get entityHitbox => _hitbox;

  void _initialSetup() {
    // debug
    if (GameSettings.customDebugMode) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
      _hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    priority = GameSettings.trapLayerLevel;
    _hitbox.collisionType = .passive;
    add(_hitbox);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<_CheckpointState>(game, _path, _pathEnd, GameSettings.stepTime, _textureSize);
    animations = {for (final state in _CheckpointState.values) state: loadAnimation(state)};
    current = _CheckpointState.noFlag;
  }

  void _setUpRespawn() => _playerRespawn = Vector2(
    position.x + _hitbox.position.x + _hitbox.width - _player.hitboxLocalPosition.x + _offset,
    position.y + height - _player.height,
  );
}
