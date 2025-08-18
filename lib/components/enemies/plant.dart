import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/components/enemies/plant_bullet.dart';
import 'package:pixel_adventure/components/level/player.dart';
import 'package:pixel_adventure/components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum PlantState implements AnimationState {
  idle('Idle', 11),
  attack('Attack', 8, loop: false),
  hit('Hit', 5, loop: false);

  @override
  final String name;
  @override
  final int amount;
  @override
  final bool loop;

  const PlantState(this.name, this.amount, {this.loop = true});
}

class Plant extends SpriteAnimationGroupComponent with HasGameReference<PixelAdventure>, CollisionCallbacks {
  final bool isLeft;
  final bool doubleShot;

  Plant({this.isLeft = true, this.doubleShot = false, super.position, super.size, required Player player}) : _player = player;

  // actual hitbox
  final hitbox = RectangleHitbox(position: Vector2(10, 8), size: Vector2(17, 24));

  // player ref
  final Player _player;

  // animation settings
  final double _stepTime = 0.05;
  final Vector2 _textureSize = Vector2(44, 42);
  final String _path = 'Enemies/Plant/';
  final String _pathEnd = ' (44x42).png';

  // attack
  double _timeSinceLastAttack = 0.0;
  bool _isAttacking = false;
  final double _timeUntilNextAttack = 5; // [Adjustable]
  final Duration _delayBetweenDoubleShot = Duration(milliseconds: 500); // [Adjustable]

  // got stomped
  bool _gotStomped = false;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllAnimations();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (_gotStomped) return super.update(dt);
    if (!_isAttacking) {
      _timeSinceLastAttack += dt;
      if (_timeSinceLastAttack >= _timeUntilNextAttack) _startAttack();
    }
    super.update(dt);
  }

  void _initialSetup() {
    // debug
    if (game.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorEnemie;
      hitbox.debugColor = AppTheme.debugColorEnemieHitbox;
    }

    // general
    priority = PixelAdventure.enemieLayerLevel;
    hitbox.collisionType = CollisionType.passive;
    add(hitbox);
  }

  void _loadAllAnimations() {
    final loadAnimation = spriteAnimationWrapper<PlantState>(game, _path, _pathEnd, _stepTime, _textureSize);

    // list of all animations
    animations = {for (var state in PlantState.values) state: loadAnimation(state)};

    // set current animation state
    current = PlantState.idle;

    if (!isLeft) flipHorizontallyAroundCenter();
  }

  void _startAttack() {
    current = PlantState.attack;
    _isAttacking = true;
    animationTickers![PlantState.attack]!.completed.whenComplete(() async {
      _spawnBullet();
      current = PlantState.idle;
      if (doubleShot) {
        await Future.delayed(_delayBetweenDoubleShot);
        current = PlantState.attack;
        await animationTickers![PlantState.attack]!.completed;
        _spawnBullet();
        current = PlantState.idle;
      }
      _isAttacking = false;
      _timeSinceLastAttack = 0;
    });
  }

  void _spawnBullet() {
    final bulletOffset = Vector2(
      isLeft
          ? hitbox.position.x - PlantBullet.hitboxOffset.x - PlantBullet.hitboxRadius * 2
          : -hitbox.position.x - PlantBullet.hitboxOffset.x,
      hitbox.position.y - PlantBullet.hitboxOffset.y,
    );
    final bulletPosition = position + bulletOffset;
    final bullet = PlantBullet(position: bulletPosition, isLeft: isLeft);
    game.world.add(bullet);
  }

  void collidedWithPlayer(Vector2 collisionPoint) {
    if (_gotStomped) return;
    if (_player.velocity.y > 0 && collisionPoint.y < position.y + hitbox.position.y + game.toleranceEnemieCollision) {
      _gotStomped = true;
      _player.bounceUp();
      current = PlantState.hit;
      animationTickers![PlantState.hit]!.completed.whenComplete(() => removeFromParent());
    }
  }
}
