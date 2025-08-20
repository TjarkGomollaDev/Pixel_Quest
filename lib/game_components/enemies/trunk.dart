import 'dart:async';
import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game_components/enemies/trunk_bullet.dart';
import 'package:pixel_adventure/game_components/level/player.dart';
import 'package:pixel_adventure/game_components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum TrunkState implements AnimationState {
  idle('Idle', 18),
  run('Run', 14),
  attack('Attack', 11, loop: false),
  hit('Hit', 5, loop: false);

  @override
  final String name;
  @override
  final int amount;
  @override
  final bool loop;

  const TrunkState(this.name, this.amount, {this.loop = true});
}

class Trunk extends SpriteAnimationGroupComponent with HasGameReference<PixelAdventure>, CollisionCallbacks {
  final double offsetNeg;
  final double offsetPos;
  final double extandNegAttack;
  final double extandPosAttack;
  final bool isLeft;

  Trunk({
    required this.offsetNeg,
    required this.offsetPos,
    required this.extandNegAttack,
    required this.extandPosAttack,
    required this.isLeft,
    required super.position,
    required super.size,
    required Player player,
  }) : _player = player;

  // actual hitbox
  final RectangleHitbox hitbox = RectangleHitbox(position: Vector2(22, 7), size: Vector2(21, 26));

  // player ref
  final Player _player;

  // these are the correct x values for the trunk, one for the left side of the hitbox and one for the right side of the hitbox
  late double _hitboxPositionLeftX;
  late double _hitboxPositionRightX;

  // animation settings
  final double _stepTime = 0.05;
  final Vector2 _textureSize = Vector2(64, 32);
  final String _path = 'Enemies/Trunk/';
  final String _pathEnd = ' (64x32).png';

  // range in which the trunk moves
  late final double _rangeNeg;
  late final double _rangePos;

  // actual borders that compensate for the hitbox and flip offset, depending on the moveDirection
  late double _leftBorder;
  late double _rightBorder;

  // attack range
  late final double _attackRangeNeg;
  late final double _attackRangePos;

  // movement
  late double _moveDirection;
  double? _pendingDirection;
  final double _moveSpeed = 40; // [Adjustable]
  double _speedFactor = 1;

  // acceleration
  double _accelProgress = 1;
  final double _accelDuration = 2.5; // [Adjustable]

  // delay after direction change
  double _pauseTimer = 0;
  final double _pauseDuration = 2; // [Adjustable]

  // shooting
  bool _isShooting = false;
  bool _wasShooting = false;
  late Timer _shootTimer;
  final double _timeBetweenShots = 0.8; // [Adjustable]

  // default vertical extension in y direction when checking if the trunk should enter attack mode
  final double _extendRangeDefault = 20; // [Adjustable]

  // additional vertical range added on top of _extendRangeDefault after the trunk has attacked,
  // keeping the trunk in "combat ready" mode as long as the player stays within this extended range
  final double _extendRangeCombatReady = 80; // [Adjustable]

  // got stomped
  bool _gotStomped = false;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllSpriteAnimations();
    _setUpRange();
    _setUpAttackRange();
    _setUpMoveDirection();
    _updateHitboxEdges();
    _setUpTimer();
    return super.onLoad();
  }

  /// The Trunk can be in one of three modes:
  ///
  /// 1. **Attack Mode**: The trunk attacks when the player is within its attack range
  ///    and positioned in front of the trunk (not behind).
  /// 2. **Combat Ready Mode**: After starting an attack, the trunk remains in place as long as
  ///    the player is still within an extended range above the default attack range
  ///    and positioned in front of the trunk. The trunk does NOT shoot again while in this mode;
  ///    shooting resumes only when the player re-enters the normal attack range.
  /// 3. **Idle Mode**: If the player is out of range, the trunk moves normally, patrolling
  ///    back and forth between its set borders.
  @override
  Future<void> update(double dt) async {
    if (_gotStomped) return super.update(dt);
    if (_checkAttack()) {
      _shootTimer.update(dt);
      if (!_isShooting) {
        _startShooting();
      }
    } else if (_wasShooting && _checkCombatReady()) {
      if (_isShooting) {
        await _stopShooting();
      }
    } else {
      if (_isShooting) {
        await _stopShooting();
        _startMovement();
      } else if (_wasShooting) {
        _startMovement();
      }
      _movement(dt);
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

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<TrunkState>(game, _path, _pathEnd, _stepTime, _textureSize);

    // list of all animations
    animations = {for (var state in TrunkState.values) state: loadAnimation(state)};

    // set current animation state
    current = TrunkState.run;
  }

  void _setUpRange() {
    _rangeNeg = position.x - offsetNeg * PixelAdventure.tileSize + game.rangeOffset;
    _rangePos = position.x + offsetPos * PixelAdventure.tileSize + width - game.rangeOffset;
  }

  void _setUpAttackRange() {
    _attackRangeNeg = _rangeNeg - extandNegAttack * PixelAdventure.tileSize;
    _attackRangePos = _rangePos + extandPosAttack * PixelAdventure.tileSize;
  }

  void _setUpMoveDirection() {
    _moveDirection = isLeft ? -1 : 1;
    if (_moveDirection == 1) flipHorizontallyAroundCenter();
    _updateActualBorders();
  }

  void _updateActualBorders() {
    _leftBorder = (_moveDirection == -1) ? _rangeNeg - hitbox.position.x : _rangeNeg + hitbox.position.x + hitbox.width;
    _rightBorder = (_moveDirection == 1) ? _rangePos + hitbox.position.x : _rangePos - hitbox.position.x - hitbox.width;
  }

  void _updateHitboxEdges() {
    _hitboxPositionLeftX = (scale.x > 0) ? position.x + hitbox.position.x : position.x - hitbox.position.x - hitbox.width;
    _hitboxPositionRightX = _hitboxPositionLeftX + hitbox.width;
  }

  void _setUpTimer() => _shootTimer = Timer(_timeBetweenShots, onTick: _shoot, repeat: true, autoStart: false);

  void _startMovement() {
    _wasShooting = false;
    if (_pendingDirection == null) {
      // since the trunk is already standing during his break, the run animation must not be triggered
      current = TrunkState.run;
    } else {
      // if the trunk attacks during the break at the borders, the timer should be reset after the attack
      _pauseTimer = _pauseDuration;
    }
  }

  void _movement(double dt) {
    // short break before direction change
    if (_pauseTimer > 0) {
      _pauseTimer -= dt;
      return;
    }

    if (_pendingDirection != null) _executeDirectionChange();

    // change move direction if we reached the borders
    if (position.x >= _rightBorder && _moveDirection != -1) {
      _startDirectionChange(-1);
      return;
    } else if (position.x <= _leftBorder && _moveDirection != 1) {
      _startDirectionChange(1);
      return;
    }

    if (_accelProgress == 0) current = TrunkState.run;

    // movement
    final currentSpeed = _calculateCurrentSpeed(dt);
    final newPositionX = position.x + _moveDirection * currentSpeed * dt;
    position.x = newPositionX.clamp(_leftBorder, _rightBorder);
    _updateHitboxEdges();
  }

  void _startDirectionChange(double newDirection) {
    // change of direction recognized, but still pending
    current = TrunkState.idle;
    _pendingDirection = newDirection;

    // reset acceleration and timer
    _speedFactor = 0;
    _accelProgress = 0;
    _pauseTimer = _pauseDuration;
  }

  void _executeDirectionChange() {
    // now it's time to really change direction
    _moveDirection = _pendingDirection!;
    _pendingDirection = null;
    flipHorizontallyAroundCenter();

    // after changing the direction, we need to adjust the borders and overwrite the x position manually
    _updateActualBorders();
    _updateHitboxEdges();
    position.x = _moveDirection == 1 ? _leftBorder : _rightBorder;
  }

  double _calculateCurrentSpeed(double dt) {
    // check whether we have reached maximum speed
    if (!(_accelProgress < 1)) return _moveSpeed;

    // calculate speed factor
    _accelProgress = (_accelProgress + dt / _accelDuration).clamp(0.0, 1.0);
    _speedFactor = 1 - math.pow(1 - _accelProgress, 3).toDouble();

    // calculate current speed
    return _moveSpeed * _speedFactor;
  }

  bool _checkIsPlayerBefore() {
    // checks whether the player is positioned in front of the trunk, relative to its current move direction
    return (_moveDirection == -1 && _hitboxPositionLeftX > _player.hitboxPositionRightX) ||
        (_moveDirection == 1 && _player.hitboxPositionLeftX > _hitboxPositionRightX);
  }

  bool _checkIsPlayerInRange({double? extended}) {
    // checks whether the player is within the range in which the trunk moves, optionally with a y extension to the top
    return _player.hitboxPositionRightX >= _attackRangeNeg &&
        _player.hitboxPositionLeftX <= _attackRangePos &&
        _player.y + _player.height <= position.y + height &&
        _player.y + _player.height >= position.y + hitbox.position.y + (extended ?? 0);
  }

  bool _checkAttack() => (_checkIsPlayerBefore() && _checkIsPlayerInRange(extended: -_extendRangeDefault));

  bool _checkCombatReady() => (_checkIsPlayerBefore() && _checkIsPlayerInRange(extended: -_extendRangeDefault - _extendRangeCombatReady));

  void _startShooting() {
    _isShooting = true;
    _wasShooting = true;
    current = TrunkState.idle;
    _shoot();
    _shootTimer.start();
  }

  Future<void> _stopShooting() async {
    _isShooting = false;
    _shootTimer.stop();
    await animationTickers?[TrunkState.attack]?.completed;
  }

  Future<void> _shoot() async {
    current = TrunkState.attack;
    animationTickers![TrunkState.attack]!.completed.whenComplete(() {
      _spawnBullet();
      current = TrunkState.idle;
    });
  }

  void _spawnBullet() {
    final isLeft = _moveDirection == -1;
    final bulletOffset = Vector2(isLeft ? hitbox.position.x - TrunkBullet.fixedSize.x : -hitbox.position.x, hitbox.position.y + 3);
    final bulletPosition = position + bulletOffset;
    final bullet = TrunkBullet(position: bulletPosition, isLeft: isLeft);
    game.world.add(bullet);
  }

  void collidedWithPlayer(Vector2 collisionPoint) {
    if (_gotStomped) return;
    if (_player.velocity.y > 0 && collisionPoint.y < position.y + hitbox.position.y + game.toleranceEnemieCollision) {
      _gotStomped = true;
      _player.bounceUp();
      current = TrunkState.hit;
      animationTickers![TrunkState.hit]!.completed.whenComplete(() => removeFromParent());
    } else {
      _player.collidedWithEnemy();
    }
  }
}
