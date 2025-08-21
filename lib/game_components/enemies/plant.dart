import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game_components/enemies/plant_bullet.dart';
import 'package:pixel_adventure/game_components/level/player.dart';
import 'package:pixel_adventure/game_components/utils.dart';
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

class Plant extends PositionComponent
    with FixedGridOriginalSizeGroupAnimation, PlayerCollision, HasGameReference<PixelAdventure>, CollisionCallbacks {
  // constructor parameters
  final bool _isLeft;
  final bool _doubleShot;
  final Player _player;

  Plant({required bool isLeft, required bool doubleShot, required Player player, required super.position})
    : _isLeft = isLeft,
      _doubleShot = doubleShot,
      _player = player,
      super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2.all(48);

  // actual hitbox
  final _hitbox = RectangleHitbox(position: Vector2(18, 18), size: Vector2(20, 30));

  // animation settings
  static const double _stepTime = 0.05;
  static final Vector2 _textureSize = Vector2(44, 42);
  static const String _path = 'Enemies/Plant/';
  static const String _pathEnd = ' (44x42).png';

  // attack
  double _timeSinceLastAttack = 0.0;
  bool _isAttacking = false;
  final _timeUntilNextAttack = 5; // [Adjustable]
  final _delayBetweenDoubleShot = Duration(milliseconds: 500); // [Adjustable]

  // got stomped
  bool _gotStomped = false;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllSpriteAnimations();
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
      _hitbox.debugColor = AppTheme.debugColorEnemieHitbox;
    }

    // general
    priority = PixelAdventure.enemieLayerLevel;
    _hitbox.collisionType = CollisionType.passive;
    add(_hitbox);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<PlantState>(game, _path, _pathEnd, _stepTime, _textureSize);
    final animations = {for (var state in PlantState.values) state: loadAnimation(state)};
    addAnimationGroupComponent(textureSize: _textureSize, animations: animations, current: PlantState.idle);
    if (!_isLeft) flipHorizontallyAroundCenter();
  }

  void _startAttack() {
    animationGroupComponent.current = PlantState.attack;
    _isAttacking = true;
    animationGroupComponent.animationTickers![PlantState.attack]!.completed.whenComplete(() async {
      _spawnBullet();
      animationGroupComponent.current = PlantState.idle;
      if (_doubleShot) {
        await Future.delayed(_delayBetweenDoubleShot);
        animationGroupComponent.current = PlantState.attack;
        await animationGroupComponent.animationTickers![PlantState.attack]!.completed;
        _spawnBullet();
        animationGroupComponent.current = PlantState.idle;
      }
      _isAttacking = false;
      _timeSinceLastAttack = 0;
    });
  }

  void _spawnBullet() {
    final bulletOffset = Vector2(
      _isLeft
          ? _hitbox.position.x - PlantBullet.hitboxOffset.x - PlantBullet.hitboxRadius * 2
          : -_hitbox.position.x - PlantBullet.hitboxOffset.x,
      _hitbox.position.y - PlantBullet.hitboxOffset.y,
    );
    final bulletPosition = position + bulletOffset;
    final bullet = PlantBullet(isLeft: _isLeft, player: _player, position: bulletPosition);
    game.world.add(bullet);
  }

  @override
  void onPlayerCollisionStart(Vector2 intersectionPoint) {
    if (_gotStomped) return;
    if (_player.velocity.y > 0 && intersectionPoint.y < position.y + _hitbox.position.y + game.toleranceEnemieCollision) {
      _gotStomped = true;
      _player.bounceUp();
      animationGroupComponent.current = PlantState.hit;
      animationGroupComponent.animationTickers![PlantState.hit]!.completed.whenComplete(() => removeFromParent());
    }
  }
}
