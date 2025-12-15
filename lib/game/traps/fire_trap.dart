import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/data/audio/audio_center.dart';
import 'package:pixel_adventure/game/collision/collision.dart';
import 'package:pixel_adventure/game/collision/entity_collision.dart';
import 'package:pixel_adventure/game/collision/world_collision.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/utils/animation_state.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_quest.dart';

enum FireTrapState implements AnimationState {
  off('Off', 1),
  on('On', 3),
  hit('Hit', 4, loop: false);

  @override
  final String fileName;
  @override
  final int amount;
  @override
  final bool loop;

  const FireTrapState(this.fileName, this.amount, {this.loop = true});
}

/// A flame trap that activates when the player steps on its trigger area.
///
/// Initially idle in the [FireTrapState.off] state, it switches to [FireTrapState.hit]
/// when triggered from above. After a short delay, the fire ignites into the
/// [FireTrapState.on] state, dealing continuous damage while active. Once the
/// burn duration ends, the trap returns to its idle state and can be triggered again.
///
/// Damage is only applied while the fire is burning. Triggering and timing
/// are fully animation-driven, allowing the trap to synchronize visuals with
/// its collision behavior for fair player feedback.
class FireTrap extends SpriteAnimationGroupComponent with WorldCollision, HasGameReference<PixelQuest> {
  // constructor parameters
  final Player _player;

  FireTrap({required Player player, required super.position}) : _player = player, super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2(16, 32);

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(0, 16), size: Vector2.all(16));

  // animation settings
  static final Vector2 _textureSize = Vector2(16, 32);
  static const String _path = 'Traps/Fire/';
  static const String _pathEnd = ' (16x32).png';

  // fire
  bool _isFireActivated = false;
  bool _isDamageOn = false;

  // fire settings
  final _fireDelayAfterHit = Duration(milliseconds: 250); // [Adjustable]
  final _fireDuration = Duration(seconds: 2); // [Adjustable]

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllSpriteAnimations();
    return super.onLoad();
  }

  void _initialSetup() {
    // debug
    if (GameSettings.customDebug) {
      _hitbox.debugMode = true;
      _hitbox.debugColor = AppTheme.debugColorWorldBlock;
    }

    // general
    priority = GameSettings.trapBehindLayerLevel;
    _hitbox.collisionType = CollisionType.passive;
    add(_hitbox);

    // entity collider
    add(
      _FireTrapEntityCollider(
        onCollide: (collisonSide) {
          if (!_isDamageOn) return;
          _player.collidedWithEnemy(collisonSide);
        },
      ),
    );
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<FireTrapState>(game, _path, _pathEnd, GameSettings.stepTime, _textureSize);
    animations = {for (var state in FireTrapState.values) state: loadAnimation(state)};
    current = FireTrapState.off;
  }

  Future<void> hitTrap() async {
    if (_isFireActivated) return;
    _isFireActivated = true;
    game.audioCenter.playSound(SoundEffect.pressurePlate);
    current = FireTrapState.hit;
    await animationTickers![FireTrapState.hit]!.completed;
    await Future.delayed(_fireDelayAfterHit);
    _isDamageOn = true;
    current = FireTrapState.on;
    await Future.delayed(_fireDuration);
    current = FireTrapState.off;
    _isDamageOn = false;
    _isFireActivated = false;
  }

  @override
  ShapeHitbox get worldHitbox => _hitbox;
}

class _FireTrapEntityCollider extends PositionComponent with EntityCollision, CollisionCallbacks {
  // constructor parameters
  final void Function(CollisionSide collisonSide) onCollide;

  _FireTrapEntityCollider({required this.onCollide}) : super(position: Vector2.zero(), size: Vector2.all(16));

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(0, 0), size: Vector2.all(16));

  @override
  FutureOr<void> onLoad() {
    // debug
    if (GameSettings.customDebug) {
      _hitbox.debugMode = true;
      _hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }
    _hitbox.collisionType = CollisionType.passive;
    add(_hitbox);
    return super.onLoad();
  }

  @override
  ShapeHitbox get entityHitbox => _hitbox;

  @override
  void onEntityCollision(CollisionSide collisionSide) => onCollide(collisionSide);
}
