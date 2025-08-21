import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game_components/level/player.dart';
import 'package:pixel_adventure/game_components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum FinishState implements AnimationState {
  idle('Idle', 1),
  pressed('Pressed', 8, loop: false);

  @override
  final String name;
  @override
  final int amount;
  @override
  final bool loop;

  const FinishState(this.name, this.amount, {this.loop = true});
}

class Finish extends SpriteAnimationGroupComponent with PlayerCollision, HasGameReference<PixelAdventure>, CollisionCallbacks {
  // constructor parameters
  final Player _player;

  Finish({required Player player, required super.position}) : _player = player, super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2.all(64);

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(15, 20), size: Vector2(34, 44));

  // animation settings
  static const double _stepTime = 0.05;
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
    final loadAnimation = spriteAnimationWrapper<FinishState>(game, _path, _pathEnd, _stepTime, _textureSize);
    animations = {for (var state in FinishState.values) state: loadAnimation(state)};
    current = FinishState.idle;
  }

  @override
  Future<void> onPlayerCollisionStart(Vector2 intersectionPoint) async {
    if (reached) return;
    if (_player.velocity.y > 0 && intersectionPoint.y < position.y + _hitbox.position.y + game.toleranceEnemieCollision) {
      reached = true;
      current = FinishState.pressed;
      _player.reachedFinish();
      await animationTickers![FinishState.pressed]!.completed;
      current = FinishState.idle;
    }
  }
}
