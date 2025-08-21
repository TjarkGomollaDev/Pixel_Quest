import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game_components/enemies/ghost_particle.dart';
import 'package:pixel_adventure/game_components/level/player.dart';
import 'package:pixel_adventure/game_components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum GhostState implements AnimationState {
  idle('Idle', 10),
  appear('Appear', 4, loop: false),
  disappear('Disappear', 4, loop: false),
  hit('Hit', 5, loop: false);

  @override
  final String name;
  @override
  final int amount;
  @override
  final bool loop;

  const GhostState(this.name, this.amount, {this.loop = true});
}

class Ghost extends PositionComponent
    with FixedGridOriginalSizeGroupAnimation, PlayerCollision, HasGameReference<PixelAdventure>, CollisionCallbacks {
  // constructor parameters
  final double _offsetNeg;
  final double _offsetPos;
  final bool _isLeft;
  final Player _player;

  Ghost({required double offsetNeg, required double offsetPos, required bool isLeft, required Player player, required super.position})
    : _offsetNeg = offsetNeg,
      _offsetPos = offsetPos,
      _isLeft = isLeft,
      _player = player,
      super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2(48, 32);

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(13, 7), size: Vector2(21, 25));

  // animation settings
  static const double _stepTime = 0.05;
  static final Vector2 _textureSize = Vector2(44, 30);
  static const String _path = 'Enemies/Ghost/';
  static const String _pathEnd = ' (44x30).png';

  // range
  late final double _rangeNeg;
  late final double _rangePos;

  // actual borders that compensate for the hitbox and flip offset, depending on the moveDirection
  late double _leftBorder;
  late double _rightBorder;

  // movement
  late double _moveDirection;
  final double _moveSpeed = 24; // [Adjustable]

  // ghost timer
  late Timer _ghostTimer;
  bool _isVisible = true;
  final double _durationVisible = 2; // [Adjustable]
  final double _durationInVisible = 3; // [Adjustable]

  // particle timer
  late Timer _particleTimer;
  final double _particleDelayBetweenBurst = 0.8; // [Adjustable]

  // particle burst
  final List<Vector2> _particleOffsets = [Vector2(1, 4), Vector2(4, 16), Vector2(8, 9), Vector2(13, 15)]; // [Adjustable]
  final List<int> _particleDelays = [0, 100, 80, 120]; // [Adjustable]
  final double _offsetCloserToGhost = 8; // [Adjustable] higher means closer

  // got stomped
  bool _gotStomped = false;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllSpriteAnimations();
    _setUpRange();
    _setUpMoveDirection();
    _startGhostTimer();
    _startParticleTimer();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (!_gotStomped) {
      _movement(dt);
      _ghostTimer.update(dt);
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
    final loadAnimation = spriteAnimationWrapper<GhostState>(game, _path, _pathEnd, _stepTime, _textureSize);
    final animations = {for (var state in GhostState.values) state: loadAnimation(state)};
    addAnimationGroupComponent(textureSize: _textureSize, animations: animations, current: GhostState.idle);
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

  void _startParticleTimer() => _particleTimer = Timer(_particleDelayBetweenBurst, repeat: true, onTick: _spawnGhostParticles);

  void _startGhostTimer() => _ghostTimer = Timer(_durationVisible, onTick: _triggerDisappear);

  Future<void> _triggerDisappear() async {
    animationGroupComponent.current = GhostState.disappear;
    _particleTimer.stop();
    _ghostTimer.stop();
    await animationGroupComponent.animationTickers![GhostState.disappear]!.completed;
    animationGroupComponent.opacity = 0;
    _isVisible = false;
    _ghostTimer
      ..limit = _durationInVisible
      ..onTick = _triggerAppear
      ..start();
  }

  Future<void> _triggerAppear() async {
    animationGroupComponent.current = GhostState.appear;
    _ghostTimer.stop();
    animationGroupComponent.opacity = 1;
    await animationGroupComponent.animationTickers![GhostState.appear]!.completed;
    animationGroupComponent.current = GhostState.idle;
    _isVisible = true;
    _spawnGhostParticles();
    _ghostTimer
      ..limit = _durationVisible
      ..onTick = _triggerDisappear
      ..start();
    _particleTimer.start();
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

  Future<void> _spawnGhostParticles() async {
    // calculate base position
    final spawnOnLeftSide = _moveDirection == 1;
    final particleBaseOffset = Vector2(
      spawnOnLeftSide
          ? -_hitbox.position.x - _hitbox.width - 16 + _offsetCloserToGhost
          : _hitbox.position.x + _hitbox.width - _offsetCloserToGhost,
      _hitbox.position.y,
    );
    final particleBasePosition = position + particleBaseOffset;

    // spawn particles from a list with a small delay between
    for (var i = 0; i < _particleOffsets.length; i++) {
      if (_particleDelays[i] > 0) {
        await Future.delayed(Duration(milliseconds: _particleDelays[i]));
      }
      final particleOffset = Vector2(spawnOnLeftSide ? _particleOffsets[i].x * -1 : _particleOffsets[i].x, _particleOffsets[i].y);
      final ghostParticle = GhostParticle(owner: this, spawnOnLeftSide: spawnOnLeftSide, position: particleBasePosition + particleOffset);
      game.world.add(ghostParticle);
    }
  }

  @override
  void onPlayerCollision(Vector2 intersectionPoint) {
    if (_gotStomped || !_isVisible) return;
    if (_player.velocity.y > 0 && intersectionPoint.y < position.y + _hitbox.position.y + game.toleranceEnemieCollision) {
      _gotStomped = true;
      _player.bounceUp();
      animationGroupComponent.current = GhostState.hit;
      animationGroupComponent.animationTickers![GhostState.hit]!.completed.then((_) => removeFromParent());
    } else {
      _player.collidedWithEnemy();
    }
  }
}
