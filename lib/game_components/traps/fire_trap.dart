import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game_components/level/player.dart';
import 'package:pixel_adventure/game_components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum FireTrapState implements AnimationState {
  off('Off', 1),
  on('On', 3),
  hit('Hit', 4, loop: false);

  @override
  final String name;
  @override
  final int amount;
  @override
  final bool loop;

  const FireTrapState(this.name, this.amount, {this.loop = true});
}

class FireTrap extends SpriteAnimationGroupComponent with HasGameReference<PixelAdventure>, CollisionCallbacks {
  FireTrap({required super.position, required super.size, required Player player}) : _player = player;

  // actual hitbox
  final RectangleHitbox hitbox = RectangleHitbox(position: Vector2(0, 0), size: Vector2(16, 16));

  // player ref
  final Player _player;

  // animation settings
  final double _stepTime = 0.05;
  final Vector2 _textureSize = Vector2(16, 32);
  final String _path = 'Traps/Fire/';
  final String _pathEnd = ' (16x32).png';

  // fire
  bool _isFireActivated = false;
  bool _isDamageOn = false;

  // fire settings
  final _fireDelayAfterHit = Duration(milliseconds: 250); // [Adjustable]
  final _fireDuration = Duration(seconds: 2); // [Adjustable]

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
    priority = PixelAdventure.trapBehindLayerLevel;
    hitbox.collisionType = CollisionType.passive;
    add(hitbox);
  }

  void _loadAllAnimations() {
    final loadAnimation = spriteAnimationWrapper<FireTrapState>(game, _path, _pathEnd, _stepTime, _textureSize);

    // list of all animations
    animations = {for (var state in FireTrapState.values) state: loadAnimation(state)};
    // set current animation state
    current = FireTrapState.off;
  }

  Future<void> collidedWithPlayer(Vector2 collisionPoint) async {
    if (!_isFireActivated && collisionPoint.y == position.y + hitbox.height) {
      current = FireTrapState.hit;
      _isFireActivated = true;
      await animationTickers![FireTrapState.hit]!.completed;
      await Future.delayed(_fireDelayAfterHit);
      current = FireTrapState.on;
      _isDamageOn = true;
      await Future.delayed(_fireDuration);
      current = FireTrapState.off;
      _isFireActivated = false;
      _isDamageOn = false;
    } else if (_isDamageOn) {
      _player.collidedWithEnemy();
    }
  }
}
