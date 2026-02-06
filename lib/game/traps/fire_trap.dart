import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_quest/app_theme.dart';
import 'package:pixel_quest/game/collision/collision.dart';
import 'package:pixel_quest/game/collision/entity_collision.dart';
import 'package:pixel_quest/game/collision/world_collision.dart';
import 'package:pixel_quest/game/level/player/player.dart';
import 'package:pixel_quest/game/utils/animation_state.dart';
import 'package:pixel_quest/game/utils/load_sprites.dart';
import 'package:pixel_quest/game/game_settings.dart';
import 'package:pixel_quest/game/game.dart';

enum _FireTrapState implements AnimationState {
  off('Off', 1),
  on('On', 3),
  hit('Hit', 4, loop: false);

  @override
  final String fileName;
  @override
  final int amount;
  @override
  final bool loop;

  const _FireTrapState(this.fileName, this.amount, {this.loop = true});
}

/// A flame trap that activates when the player steps on its trigger area.
///
/// Initially idle in the [_FireTrapState.off] state, it switches to [_FireTrapState.hit]
/// when triggered from above. After a short delay, the fire ignites into the
/// [_FireTrapState.on] state, dealing continuous damage while active. Once the
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
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(0, 16), size: .all(16));

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

  @override
  ShapeHitbox get worldHitbox => _hitbox;

  void _initialSetup() {
    // debug
    if (GameSettings.customDebugMode) {
      _hitbox.debugMode = true;
      _hitbox.debugColor = AppTheme.debugColorWorldBlock;
    }

    // general
    priority = GameSettings.trapBehindLayerLevel;
    _hitbox.collisionType = .passive;
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
    final loadAnimation = spriteAnimationWrapper<_FireTrapState>(game, _path, _pathEnd, GameSettings.stepTime, _textureSize);
    animations = {for (final state in _FireTrapState.values) state: loadAnimation(state)};
    current = _FireTrapState.off;
  }

  Future<void> hitTrap() async {
    if (_isFireActivated) return;
    _isFireActivated = true;

    // hit pressure plate
    game.audioCenter.playSound(.pressurePlate, .game);
    current = _FireTrapState.hit;
    await animationTickers![_FireTrapState.hit]!.completed;

    // fire on
    await Future.delayed(_fireDelayAfterHit);
    _isDamageOn = true;
    game.audioCenter.playSound(.jetFlame, .game);
    current = _FireTrapState.on;

    // fire off
    await Future.delayed(_fireDuration);
    current = _FireTrapState.off;
    _isDamageOn = false;
    _isFireActivated = false;
  }
}

/// Small helper component that provides a dedicated entity-collision hitbox for [FireTrap].
///
/// This keeps the trap's world-collision/trigger logic separate from the damage collider,
/// and simply forwards collision sides to the provided callback.
class _FireTrapEntityCollider extends PositionComponent with EntityCollision, CollisionCallbacks {
  // constructor parameters
  final void Function(CollisionSide collisonSide) _onCollide;

  _FireTrapEntityCollider({required void Function(CollisionSide) onCollide})
    : _onCollide = onCollide,
      super(position: .zero(), size: .all(16));

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(0, 0), size: .all(16));

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    return super.onLoad();
  }

  @override
  void onEntityCollision(CollisionSide collisionSide) => _onCollide(collisionSide);

  @override
  ShapeHitbox get entityHitbox => _hitbox;

  void _initialSetup() {
    // debug
    if (GameSettings.customDebugMode) {
      _hitbox.debugMode = true;
      _hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    _hitbox.collisionType = .passive;
    add(_hitbox);
  }
}
