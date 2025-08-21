import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game_components/enemies/ghost_particle.dart';
import 'package:pixel_adventure/game_components/enemies/slime_particle.dart';
import 'package:pixel_adventure/game_components/level/player.dart';
import 'package:pixel_adventure/game_components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum SlimeState implements AnimationState {
  idle('Idle', 10),
  hit('Hit', 5, loop: false);

  @override
  final String name;
  @override
  final int amount;
  @override
  final bool loop;

  const SlimeState(this.name, this.amount, {this.loop = true});
}

class Slime extends PositionComponent
    with FixedGridOriginalSizeGroupAnimation, PlayerCollision, HasGameReference<PixelAdventure>, CollisionCallbacks {
  // constructor parameters
  final double _offsetNeg;
  final double _offsetPos;
  final bool _isLeft;
  final Player _player;

  Slime({required double offsetNeg, required double offsetPos, required bool isLeft, required Player player, required super.position})
    : _offsetNeg = offsetNeg,
      _offsetPos = offsetPos,
      _isLeft = isLeft,
      _player = player,
      super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2(48, 32);

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(8, 8), size: Vector2(32, 24));

  // animation settings
  static const double _stepTime = 0.05;
  static final Vector2 _textureSize = Vector2(44, 30);
  static const String _path = 'Enemies/Slime/';
  static const String _pathEnd = ' (44x30).png';

  // range
  late final double _rangeNeg;
  late final double _rangePos;

  // actual borders that compensate for the hitbox and flip offset, depending on the moveDirection
  late double _leftBorder;
  late double _rightBorder;

  // movement
  late double _moveDirection;
  final double _moveSpeed = 18; // [Adjustable]

  // particles
  final double _offsetCloserToSlime = 10; // [Adjustable] higher means closer
  final double _offsetAlignToGround = 10;

  // particle timer and delay
  late Timer _particleTimer;
  final List<double> _particleIntervals = [0.6, 0.4, 0.8, 0.5, 0.5, 0.9, 0.7, 0.4]; // [Adjustable]
  int _particleIndex = 0;

  // got stomped
  bool _gotStomped = false;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllSpriteAnimations();
    _setUpRange();
    _setUpMoveDirection();
    _startParticleTimer();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (!_gotStomped) {
      _movement(dt);
      _particleTimer.update(dt);
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
    final loadAnimation = spriteAnimationWrapper<SlimeState>(game, _path, _pathEnd, _stepTime, _textureSize);
    final animations = {for (var state in SlimeState.values) state: loadAnimation(state)};
    addAnimationGroupComponent(textureSize: _textureSize, animations: animations, current: SlimeState.idle);
  }

  void _setUpRange() {
    _rangeNeg = position.x - _offsetNeg * PixelAdventure.tileSize + game.rangeOffset;
    _rangePos = position.x + _offsetPos * PixelAdventure.tileSize + width - game.rangeOffset;
  }

  void _setUpMoveDirection() {
    _moveDirection = _isLeft ? -1 : 1;
    if (_moveDirection == 1) flipHorizontallyAroundCenter();
    _updateActualBorders();
  }

  void _updateActualBorders() {
    _leftBorder = (_moveDirection == -1) ? _rangeNeg - _hitbox.position.x : _rangeNeg + _hitbox.position.x + _hitbox.width;
    _rightBorder = (_moveDirection == 1) ? _rangePos + _hitbox.position.x : _rangePos - _hitbox.position.x - _hitbox.width;
  }

  void _movement(double dt) {
    // change move direction if we reached the borders
    if (position.x >= _rightBorder && _moveDirection != -1) {
      _changeDirection(-1);
      return;
    } else if (position.x <= _leftBorder && _moveDirection != 1) {
      _changeDirection(1);
      return;
    }

    // movement
    final newPositionX = position.x + _moveDirection * _moveSpeed * dt;
    position.x = newPositionX.clamp(_leftBorder, _rightBorder);
  }

  void _changeDirection(double newDirection) {
    _moveDirection = newDirection;
    flipHorizontallyAroundCenter();

    // after changing the direction, we need to adjust the borders and overwrite the x position
    _updateActualBorders();
    position.x = _moveDirection == 1 ? _leftBorder : _rightBorder;

    // delete all remaining particles
    game.world.children.whereType<GhostParticle>().where((p) => p.owner == this).forEach((p) => p.removeFromParent());
  }

  void _startParticleTimer() {
    _particleTimer = Timer(_particleIntervals[_particleIndex], onTick: _handleParticleTick, repeat: false)..start();
  }

  void _handleParticleTick() {
    _spawnSlimeParticles();

    // set next index
    _particleIndex = (_particleIndex + 1) % _particleIntervals.length;

    // reconfigure timer
    _particleTimer
      ..stop()
      ..limit = _particleIntervals[_particleIndex]
      ..start();
  }

  void _spawnSlimeParticles() {
    final spawnOnLeftSide = _moveDirection == 1;
    final particleOffset = Vector2(
      spawnOnLeftSide
          ? -_hitbox.position.x - _hitbox.width - 16 + _offsetCloserToSlime
          : _hitbox.position.x + _hitbox.width - _offsetCloserToSlime,
      height - _offsetAlignToGround,
    );
    final particlePosition = position + particleOffset;

    final ghostParticle = SlimeParticle(spawnOnLeftSide: spawnOnLeftSide, player: _player, position: particlePosition);
    game.world.add(ghostParticle);
  }

  @override
  void onPlayerCollisionStart(Vector2 intersectionPoint) {
    if (_gotStomped) return;
    if (_player.velocity.y > 0 && intersectionPoint.y < position.y + _hitbox.position.y + game.toleranceEnemieCollision) {
      _gotStomped = true;
      _player.bounceUp();
      animationGroupComponent.current = SlimeState.hit;
      animationGroupComponent.animationTickers![SlimeState.hit]!.completed.then((_) => removeFromParent());
    } else {
      _player.collidedWithEnemy();
    }
  }
}
