import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/utils/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum TrampolineState implements AnimationState {
  idle('Idle', 1),
  jump('Jump', 8, loop: false);

  @override
  final String name;
  @override
  final int amount;
  @override
  final bool loop;

  const TrampolineState(this.name, this.amount, {this.loop = true});
}

/// A spring-loaded trampoline trap that launches the [Player] upwards on contact.
///
/// The trampoline is animated with two states: [TrampolineState.idle] and
/// [TrampolineState.jump]. When the player collides with its hitbox, it triggers
/// the jump animation, applies an upward bounce force to the player, and then
/// automatically resets back to idle once the animation is complete.
/// The trampoline acts as a passive collision object and does not move by itself.
class Trampoline extends PositionComponent
    with FixedGridOriginalSizeGroupAnimation, PlayerCollision, HasGameReference<PixelAdventure>, CollisionCallbacks {
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
  final double _bounceHeight = 500;
  bool _bounced = false;

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
      debugColor = AppTheme.debugColorTrap;
      _hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    priority = PixelAdventure.trapLayerLevel;
    _hitbox.collisionType = CollisionType.passive;
    add(_hitbox);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<TrampolineState>(game, _path, _pathEnd, PixelAdventure.stepTime, _textureSize);
    final animations = {for (var state in TrampolineState.values) state: loadAnimation(state)};
    addAnimationGroupComponent(textureSize: _textureSize, animations: animations, current: TrampolineState.idle);
  }

  @override
  Future<void> onPlayerCollisionStart(Vector2 intersectionPoint) async {
    if (!_bounced) {
      _bounced = true;

      // is needed, because otherwise the ground collision may reset the y velocity directly back to 0 before the player can even jump off
      _player.position.y -= 1;

      _player.bounceUp(jumpForce: _bounceHeight);
      animationGroupComponent.current = TrampolineState.jump;
      await animationGroupComponent.animationTickers![TrampolineState.jump]!.completed;
      animationGroupComponent.current = TrampolineState.idle;
      _bounced = false;
    }
  }
}
