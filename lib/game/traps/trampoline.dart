import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/data/audio/audio_center.dart';
import 'package:pixel_adventure/game/collision/collision.dart';
import 'package:pixel_adventure/game/collision/entity_collision.dart';
import 'package:pixel_adventure/game/level/player/player.dart';
import 'package:pixel_adventure/game/utils/animation_state.dart';
import 'package:pixel_adventure/game/utils/grid.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game/game_settings.dart';
import 'package:pixel_adventure/game/game.dart';

enum _TrampolineState implements AnimationState {
  idle('Idle', 1),
  jump('Jump', 8, loop: false);

  @override
  final String fileName;
  @override
  final int amount;
  @override
  final bool loop;

  const _TrampolineState(this.fileName, this.amount, {this.loop = true});
}

/// A spring-loaded trampoline trap that launches the [Player] upwards on contact.
///
/// The trampoline is animated with two states: [_TrampolineState.idle] and
/// [_TrampolineState.jump]. When the player collides with its hitbox, it triggers
/// the jump animation, applies an upward bounce force to the player, and then
/// automatically resets back to idle once the animation is complete.
/// The trampoline acts as a passive collision object and does not move by itself.
class Trampoline extends PositionComponent with FixedGridOriginalSizeGroupAnimation, EntityCollision, HasGameReference<PixelQuest> {
  // constructor parameters
  final Player _player;

  Trampoline({required Player player, required super.position}) : _player = player, super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2.all(32);

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(4, 21), size: Vector2(23, 11));

  // animation settings
  static final Vector2 _textureSize = Vector2(28, 28);
  static const String _path = 'Traps/Trampoline/';
  static const String _pathEnd = '.png';

  // bounce
  final double _bounceHeight = 500; // [Adjustable]
  bool _isBouncing = false;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllSpriteAnimations();
    return super.onLoad();
  }

  @override
  Future<void> onEntityCollision(CollisionSide collisionSide) async {
    if (!_isBouncing) {
      _isBouncing = true;

      // is needed, because otherwise the ground collision may reset the y velocity directly back to 0 before the player can even jump off
      _player.adjustPostion(y: -1);

      // bounce player
      _player.bounceUp(jumpForce: _bounceHeight);
      game.audioCenter.playSound(Sfx.jumpBoost, SfxType.game);

      // play animation
      animationGroupComponent.current = _TrampolineState.jump;
      await animationGroupComponent.animationTickers![_TrampolineState.jump]!.completed;
      animationGroupComponent.current = _TrampolineState.idle;

      // unblocking the trampoline
      _isBouncing = false;
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
      debugColor = AppTheme.debugColorTrap;
      _hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    priority = GameSettings.trapLayerLevel;
    _hitbox.collisionType = CollisionType.passive;
    add(_hitbox);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<_TrampolineState>(game, _path, _pathEnd, GameSettings.stepTime, _textureSize);
    final animations = {for (final state in _TrampolineState.values) state: loadAnimation(state)};
    addAnimationGroupComponent(textureSize: _textureSize, animations: animations, current: _TrampolineState.idle);
  }
}
