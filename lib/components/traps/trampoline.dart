import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/components/level/player.dart';
import 'package:pixel_adventure/components/utils.dart';
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

class Trampoline extends SpriteAnimationGroupComponent with HasGameReference<PixelAdventure>, CollisionCallbacks {
  Trampoline({super.position, super.size, required Player player}) : _player = player;

  // actual hitbox
  final hitbox = RectangleHitbox(position: Vector2(2, 20), size: Vector2(28, 12));

  // player ref
  final Player _player;

  // animation settings
  final double _stepTime = 0.05;
  final Vector2 _textureSize = Vector2(28, 28);
  final String _path = 'Traps/Trampoline/';
  final String _pathEnd = '.png';

  // bounce
  final double _bounceHeight = 500;
  bool _bounced = false;

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
    final loadAnimation = spriteAnimationWrapper<TrampolineState>(game, _path, _pathEnd, _stepTime, _textureSize);

    // list of all animations
    animations = {for (var state in TrampolineState.values) state: loadAnimation(state)};

    // set current animation state
    current = TrampolineState.idle;
  }

  Future<void> collidedWithPlayer(Vector2 collisionPoint) async {
    if (!_bounced) {
      _bounced = true;
      _player.bounceUp(jumpForce: _bounceHeight);
      current = TrampolineState.jump;
      await animationTickers![TrampolineState.jump]!.completed;
      current = TrampolineState.idle;
      _bounced = false;
    }
  }
}
