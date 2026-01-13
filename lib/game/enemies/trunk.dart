import 'dart:async';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/data/audio/audio_center.dart';
import 'package:pixel_adventure/game/collision/collision.dart';
import 'package:pixel_adventure/game/collision/entity_collision.dart';
import 'package:pixel_adventure/game/enemies/trunk_bullet.dart';
import 'package:pixel_adventure/game/hud/mini%20map/entity_on_mini_map.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/utils/animation_state.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_quest.dart';

enum TrunkState implements AnimationState {
  idle('Idle', 18),
  run('Run', 14),
  attack('Attack', 11, loop: false),
  hit('Hit', 5, loop: false);

  @override
  final String fileName;
  @override
  final int amount;
  @override
  final bool loop;

  const TrunkState(this.fileName, this.amount, {this.loop = true});
}

class Trunk extends SpriteAnimationGroupComponent with EntityCollision, EntityOnMiniMap, HasGameReference<PixelQuest> {
  // constructor parameters
  final double _offsetNeg;
  final double _offsetPos;
  final double _extandNegAttack;
  final double _extandPosAttack;
  final bool _isLeft;
  final Player _player;

  Trunk({
    required double offsetNeg,
    required double offsetPos,
    required double extandNegAttack,
    required double extandPosAttack,
    required bool isLeft,
    required Player player,
    required super.position,
  }) : _isLeft = isLeft,
       _extandPosAttack = extandPosAttack,
       _extandNegAttack = extandNegAttack,
       _offsetPos = offsetPos,
       _offsetNeg = offsetNeg,
       _player = player,
       super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2(64, 32);

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(22, 7), size: Vector2(21, 26));

  // these are the correct x values for the trunk, one for the left side of the hitbox and one for the right side of the hitbox
  late double _hitboxLeft;
  late double _hitboxRight;

  // animation settings
  static final Vector2 _textureSize = Vector2(64, 32);
  static const String _path = 'Enemies/Trunk/';
  static const String _pathEnd = ' (64x32).png';

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
  late int _moveDirection;
  int? _pendingDirection;
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
  final double _extendRangeDefault = 30; // [Adjustable]

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
        _stopShooting();
      }
    } else {
      if (_isShooting) {
        _stopShooting();
        _startMovement();
      } else if (_wasShooting) {
        _startMovement();
      }
      _movement(dt);
    }

    super.update(dt);
  }

  @override
  void onEntityCollision(CollisionSide collisionSide) {
    if (_gotStomped) return;
    if (collisionSide == CollisionSide.Top) {
      _gotStomped = true;
      _player.bounceUp();
      game.audioCenter.playSound(Sfx.enemieHit, SfxType.game);

      // play hit animation and then remove from level
      animationTickers![TrunkState.attack]?.onComplete?.call();
      current = TrunkState.hit;
      animationTickers![TrunkState.hit]!.completed.whenComplete(() => removeFromParent());
    } else {
      _player.collidedWithEnemy(collisionSide);
    }
  }

  @override
  ShapeHitbox get entityHitbox => _hitbox;

  void _initialSetup() {
    // debug
    if (GameSettings.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorEnemie;
      _hitbox.debugColor = AppTheme.debugColorEnemieHitbox;
    }

    // general
    priority = GameSettings.enemieLayerLevel;
    _hitbox.collisionType = CollisionType.passive;
    add(_hitbox);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<TrunkState>(game, _path, _pathEnd, GameSettings.stepTime, _textureSize);
    animations = {for (var state in TrunkState.values) state: loadAnimation(state)};
    current = TrunkState.run;
  }

  void _setUpRange() {
    _rangeNeg = position.x - _offsetNeg * GameSettings.tileSize;
    _rangePos = position.x + _offsetPos * GameSettings.tileSize + width;
  }

  void _setUpAttackRange() {
    _attackRangeNeg = _rangeNeg - _extandNegAttack * GameSettings.tileSize;
    _attackRangePos = _rangePos + _extandPosAttack * GameSettings.tileSize;
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

  void _updateHitboxEdges() {
    _hitboxLeft = (scale.x > 0) ? position.x + _hitbox.position.x : position.x - width + _hitbox.position.x;
    _hitboxRight = _hitboxLeft + _hitbox.width;
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

  void _startDirectionChange(int newDirection) {
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
    _speedFactor = 1 - pow(1 - _accelProgress, 3).toDouble();

    // calculate current speed
    return _moveSpeed * _speedFactor;
  }

  bool _checkIsPlayerBefore() {
    // checks whether the player is positioned in front of the trunk, relative to its current move direction
    return (_moveDirection == -1 && _hitboxLeft > _player.hitboxRight) || (_moveDirection == 1 && _player.hitboxLeft > _hitboxRight);
  }

  bool _checkIsPlayerInRange({double? extended}) {
    return _player.hitboxRight >= _attackRangeNeg &&
        _player.hitboxLeft <= _attackRangePos &&
        _player.hitboxBottom >= position.y + _hitbox.position.y + (extended ?? 0) &&
        _player.hitboxTop <= position.y + height;
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

  void _stopShooting() {
    _isShooting = false;
    _shootTimer.stop();
    animationTickers![TrunkState.attack]?.onComplete?.call();
    current = TrunkState.idle;
  }

  void _shoot() async {
    current = TrunkState.attack;
    await animationTickers![TrunkState.attack]!.completed;
    if (!_isShooting || _gotStomped) return;
    _spawnBullet();
    current = TrunkState.idle;
  }

  void _spawnBullet() {
    final isLeft = _moveDirection == -1;
    final bulletOffset = Vector2(isLeft ? _hitbox.position.x - TrunkBullet.gridSize.x : -_hitbox.position.x, _hitbox.position.y + 3);
    final bulletPosition = position + bulletOffset;
    final bullet = TrunkBullet(isLeft: isLeft, player: _player, position: bulletPosition);
    game.world.add(bullet);
  }
}
