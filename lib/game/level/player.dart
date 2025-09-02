import 'dart:async';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/image_composition.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/animations/spotlight.dart';
import 'package:pixel_adventure/game/animations/star.dart';
import 'package:pixel_adventure/game/checkpoints/finish.dart';
import 'package:pixel_adventure/game/checkpoints/start.dart';
import 'package:pixel_adventure/game/collision_block.dart';
import 'package:pixel_adventure/game/level/level.dart';
import 'package:pixel_adventure/game/level/player_special_effect.dart';
import 'package:pixel_adventure/game/traps/moving_platform.dart';
import 'package:pixel_adventure/game/traps/rock_head.dart';
import 'package:pixel_adventure/game/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum PlayerState implements AnimationState {
  idle('Idle', 11),
  run('Run', 12),
  jump('Jump', 1),
  doubleJump('Double Jump', 6, loop: false),
  fall('Fall', 1),
  hit('Hit', 7, loop: false);

  @override
  final String name;
  @override
  final int amount;
  @override
  final bool loop;

  const PlayerState(this.name, this.amount, {this.loop = true});
}

enum PlayerCharacter {
  maskDude('Mask Dude'),
  ninjaFrog('Ninja Frog'),
  pinkMan('Pink Man'),
  virtualGuy('Virtual Guy');

  final String name;

  const PlayerCharacter(this.name);
}

class Player extends SpriteAnimationGroupComponent
    with HasGameReference<PixelAdventure>, HasWorldReference<Level>, KeyboardHandler, CollisionCallbacks, HasVisibility {
  // constructor parameters
  final PlayerCharacter _character;
  Vector2 _startPosition;

  Player({PlayerCharacter character = PlayerCharacter.maskDude, required Vector2 startPosition})
    : _character = character,
      _startPosition = startPosition,
      super(position: startPosition, size: gridSize);

  // size
  static final Vector2 gridSize = Vector2.all(32);

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(9, 4), size: Vector2(14, 28));

  // these are the correct x and y values for the player hitbox, the x values are cleaned up from the horizontal flip
  late double hitboxLeft;
  late double hitboxRight;
  late double hitboxTop;
  late double hitboxBottom;

  // animation settings
  static final Vector2 _textureSize = Vector2(32, 32);
  static const String _path = 'Main Characters/';
  static const String _pathEnd = ' (32x32).png';

  // gravity
  final double _gravity = 9.8;
  final double _jumpForce = 310;
  final double _doubleJumpForce = 250;
  final double _terminalVelocity = 300;

  // movement
  double _horizontalMovement = 0;
  final double _moveSpeed = 100;
  Vector2 velocity = Vector2.zero();

  // jump
  bool isOnGround = false;
  bool hasJumped = false;

  // double jump
  bool canDoubleJump = true;
  bool hasDoubleJumped = false;

  // if true all collisions are deactivated, only the world collision is always on
  bool _spawnProtection = true;

  // if true the world collision is deactivated (special case, e.g. for the spawn sequence at the start of the level)
  bool isWorldCollisionInactive = true;

  // if the true the player state is not automatically updated
  bool _isPlayerStateActive = false;

  // if true gravity is active
  bool _isGravityActive = false;

  // special effect
  late final PlayerSpecialEffect _effect;

  // spawn position
  late final Vector2 _spawnPosition;
  final double _spawnDropFall = 120;

  // joystick for mobile
  JoystickComponent? _joystick;
  JoystickDirection _lastJoystickDirection = JoystickDirection.idle;

  // respawn notifier
  final PlayerRespawnNotifier respawnNotifier = PlayerRespawnNotifier();

  // completer to detect when the player is back on the ground
  Completer<void>? _isOnGroundCompleter;

  // completer to detect when the player has reached a target x position
  Completer<void>? _isAtXCompleter;
  double? _targetX;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllSpriteAnimations();
    _updateHitboxEdges();
    _setUpSpawnPosition();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    _updateHitboxEdges(); // must be done before updatePlayerMovement, important for world collision
    _updatePlayerMovement(dt);
    if (_isGravityActive) _applyGravity(dt);
    if (_isPlayerStateActive) _updatePlayerState();
    if (!_spawnProtection && _joystick != null) updateJoystick();
    if (_isOnGroundCompleter != null && !_isOnGroundCompleter!.isCompleted && isOnGround) _isOnGroundCompleter!.complete();
    if (_isAtXCompleter != null && !_isAtXCompleter!.isCompleted && _targetX == null) _isAtXCompleter!.complete();

    super.update(dt);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (_spawnProtection) return false;

    _horizontalMovement = 0;
    final isLeftKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyA) || keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final isRightKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyD) || keysPressed.contains(LogicalKeyboardKey.arrowRight);
    _horizontalMovement += isLeftKeyPressed ? -1 : 0;
    _horizontalMovement += isRightKeyPressed ? 1 : 0;

    // only set to true once when the space bar is actually pressed again
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space && isOnGround) {
      hasJumped = true;
    } else if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space && !hasDoubleJumped && canDoubleJump) {
      hasDoubleJumped = true;
      canDoubleJump = false;
    }

    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (_spawnProtection) return super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerCollision) other.onPlayerCollisionStart(intersectionPoints.first);
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (_spawnProtection) return super.onCollisionEnd(other);
    if (other is PlayerCollision) other.onPlayerCollisionEnd();
    super.onCollisionEnd(other);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (isWorldCollisionInactive && other is Start) {
      isWorldCollisionInactive = false;
      _spawnProtection = false;
      onWorldCollision(other as CollisionBlock);
    } else if (!isWorldCollisionInactive) {
      if (other is CollisionBlock) onWorldCollision(other as CollisionBlock);
      if (_spawnProtection) return super.onCollision(intersectionPoints, other);
      if (other is PlayerCollision) other.onPlayerCollision(intersectionPoints.first);
    }

    super.onCollision(intersectionPoints, other);
  }

  void onWorldCollision(CollisionBlock other) {
    // positions of the two hitboxes
    final rect = other.solidHitbox.toAbsoluteRect();
    final playerRect = hitbox;

    // overlap calculation
    final overlapX = (playerRect.center.dx < rect.center.dx) ? (playerRect.right - rect.left) : (rect.right - playerRect.left);
    final overlapY = (playerRect.center.dy < rect.center.dy) ? (playerRect.bottom - rect.top) : (rect.bottom - playerRect.top);

    // check whether the y ranges overlap → otherwise no horizontal collision
    final hasVerticalIntersection = playerRect.top < rect.bottom && playerRect.bottom > rect.top;

    // check whether the x ranges overlap → otherwise no vertical collision
    final hasHorizontalIntersection = playerRect.left < rect.right && playerRect.right > rect.left;

    // special cases
    bool forceVertical = false;
    if (other is WorldBlock && other.isPlattform) {
      // plattform collision
      _resolveOneWayTopCollision(playerRect.bottom, rect.top, hasHorizontalIntersection, other);
      return;
    } else if (other is RockHead) {
      // the rapid movement of the rockhead can cause the collision direction to be misinterpreted
      forceVertical = _verticalSweptCheck(other, playerRect, hasHorizontalIntersection);
    }

    if (overlapX < overlapY && hasVerticalIntersection && !forceVertical) {
      // horizontal collision
      if (playerRect.center.dx < rect.center.dx) {
        _resolveLeftCollision(rect.left);
      } else {
        _resolveRightCollision(rect.right);
      }
    } else if (hasHorizontalIntersection) {
      // vertical collision
      if (playerRect.center.dy < rect.center.dy) {
        _resolveTopCollision(rect.top, other);
      } else {
        _resolveBottomCollision(rect.bottom, other);
      }
    }
  }

  bool _verticalSweptCheck(RockHead rect, Rect playerRect, bool hasHorizontalIntersection) {
    final oldTop = rect.previousY;
    final newBottom = rect.position.y + rect.height;

    // check whether the block intersected the player hitbox in the last frame, only the y values are checked
    return hasHorizontalIntersection && playerRect.bottom > oldTop && playerRect.top < newBottom;
  }

  void _resolveOneWayTopCollision(double playerBottom, double top, bool hasHorizontalIntersection, CollisionBlock other) {
    if ((velocity.y > 0 && playerBottom <= top && hasHorizontalIntersection)) _resolveTopCollision(top, other);
  }

  void _resolveTopCollision(double blockTop, CollisionBlock other) {
    position.y = blockTop - _hitbox.position.y - _hitbox.height;
    velocity.y = 0;
    isOnGround = true;
    canDoubleJump = true;
    if (other is MovingPlatform && other.moveDirection == 1) other.onPlayerCollision(Vector2.zero());
    if (other is Finish) other.reachedFinish();
  }

  void _resolveBottomCollision(double blockBottom, CollisionBlock other) {
    if (isOnGround) {
      _respawn();
    } else {
      position.y = blockBottom - _hitbox.position.y;
      velocity.y = 0;
      // reset can double jump if the player hits their head
      canDoubleJump = false;
      if (other is MovingPlatform && other.isVertical && other.moveDirection == 1) position.y += 1;
    }
  }

  void _resolveLeftCollision(double blockLeft) {
    position.x = (scale.x < 0) ? blockLeft + _hitbox.position.x : blockLeft - _hitbox.position.x - _hitbox.width;
    velocity.x = 0;
  }

  void _resolveRightCollision(double blockRight) {
    position.x = (scale.x < 0) ? blockRight + _hitbox.position.x + _hitbox.width : blockRight - _hitbox.position.x;
    velocity.x = 0;
  }

  void _initialSetup() {
    // debug
    if (game.customDebug) {
      _hitbox.debugMode = true;
      _hitbox.debugColor = AppTheme.debugColorPlayerHitbox;
    }

    // general
    priority = PixelAdventure.playerLayerLevel;
    add(_hitbox);
  }

  void setJoystick(JoystickComponent joystick) => _joystick = joystick;

  void updateJoystick() {
    if (_joystick!.direction == _lastJoystickDirection) return;
    _lastJoystickDirection = _joystick!.direction;
    switch (_joystick!.direction) {
      case JoystickDirection.left:
      case JoystickDirection.upLeft:
      case JoystickDirection.downLeft:
        _horizontalMovement = -1;
        break;
      case JoystickDirection.right:
      case JoystickDirection.upRight:
      case JoystickDirection.downRight:
        _horizontalMovement = 1;
        break;
      case JoystickDirection.idle:
        _horizontalMovement = 0;
      default:
    }
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<PlayerState>(
      game,
      '$_path${_character.name}/',
      _pathEnd,
      PixelAdventure.stepTime,
      _textureSize,
    );
    animations = {for (var state in PlayerState.values) state: loadAnimation(state)};
    current = PlayerState.idle;
  }

  void _setUpSpawnPosition() {
    isVisible = false;
    _spawnPosition = _startPosition - Vector2(0, _spawnDropFall);
    position = _spawnPosition;
    _effect = PlayerSpecialEffect();
    world.add(_effect);
  }

  Future<void> _updatePlayerState() async {
    if (current == PlayerState.doubleJump) {
      await animationTickers![PlayerState.doubleJump]!.completed;
    }
    PlayerState playerState = PlayerState.idle;
    if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }

    if (velocity.x > 0 || velocity.x < 0) playerState = PlayerState.run;
    if (velocity.y > 0 && !isOnGround) playerState = PlayerState.fall;
    if (velocity.y < 0 && !isOnGround) playerState = PlayerState.jump;

    current = playerState;
  }

  void _updatePlayerMovement(double dt) {
    if (hasJumped && isOnGround) {
      _playerJump(dt);
    } else if (hasDoubleJumped && !hasJumped) {
      _playerDoubleJump(dt);
    }
    if (velocity.y > _gravity) isOnGround = false;

    velocity.x = _horizontalMovement * _moveSpeed;
    if (_isAtXCompleter != null && _targetX != null) {
      if (_horizontalMovement == 1) {
        position.x = (position.x + velocity.x * dt).clamp(double.negativeInfinity, _targetX!);
      } else if (_horizontalMovement == -1) {
        position.x = (position.x + velocity.x * dt).clamp(_targetX!, double.infinity);
      }
      if (position.x == _targetX) {
        _horizontalMovement = 0;
        _targetX = null;
      }
    } else {
      position.x += velocity.x * dt;
    }
  }

  void _playerJump(double dt) {
    velocity.y = -_jumpForce;
    position.y += velocity.y * dt;
    isOnGround = false;
    hasJumped = false;
  }

  void _playerDoubleJump(double dt) {
    velocity.y = -_doubleJumpForce;
    position.y += velocity.y * dt;
    isOnGround = false;
    hasDoubleJumped = false;
    current = PlayerState.doubleJump;
  }

  void _applyGravity(double dt) {
    velocity.y += _gravity;
    velocity.y = velocity.y.clamp(double.negativeInfinity, _terminalVelocity);
    position.y += velocity.y * dt;
  }

  Future<void> spawnInLevel() async {
    // play appearing animation
    await _effect.playAppearing(_spawnPosition);
    _isPlayerStateActive = true;
    _isGravityActive = true;
    isVisible = true;

    // spawn protection is deactivated as soon as the player lands on the starting platform, take a look at onCollision
  }

  Future<void> _waitUntilPlayerIsOnGround() {
    _isOnGroundCompleter = Completer<void>();
    return _isOnGroundCompleter!.future;
  }

  Future<void> _waitUntilPlayerIsAtFinishCenter(double newTargetX) {
    if (hitbox.center.dx < newTargetX) {
      if (scale.x < 0) flipHorizontallyAroundCenter();
      _horizontalMovement = 1;
      _targetX = newTargetX - _hitbox.position.x - _hitbox.width / 2;
    } else if (hitbox.center.dx > newTargetX) {
      if (scale.x > 0) flipHorizontallyAroundCenter();
      _horizontalMovement = -1;
      _targetX = newTargetX + width - _hitbox.position.x - _hitbox.width / 2;
    } else {
      return Future.value();
    }
    _isAtXCompleter = Completer<void>();
    return _isAtXCompleter!.future;
  }

  void reachedCheckpoint(Vector2 checkpointPosition) {
    if (checkpointPosition.x > _startPosition.x + PixelAdventure.checkpointBufferZone) _startPosition = checkpointPosition;
  }

  Future<void> _delayAnimation(int milliseconds) => Future.delayed(Duration(milliseconds: milliseconds));

  int _earnedStars() {
    final collected = world.playerFruitsCount;
    final total = world.totalFruitsCount;

    if (collected >= total) return 3;
    if (collected >= total ~/ 2) return 2;
    return 1;
  }

  Future<void> reachedFinish(ShapeHitbox finish) async {
    _horizontalMovement = 0;
    _spawnProtection = true;

    // delays are not functional, but purely for a more visually appealing result
    final delays = [200, 800, 80, 620, 120, 600, 400, 200];
    int delayIndex = 0;

    // player moves to the horizontal center of the finish
    await _waitUntilPlayerIsAtFinishCenter(finish.toAbsoluteRect().center.dx);

    // spotlight animation
    world.removeGameHudOnFinish();
    final playerCenter = hitbox.center.toVector2();
    final spotlight = Spotlight(targetCenter: playerCenter, targetRadius: PixelAdventure.finishSpotlightAnimationRadius);
    world.add(spotlight);
    await spotlight.startAnimation(2.0);
    await _delayAnimation(delays[delayIndex]).whenComplete(() => delayIndex++);

    // star positions
    final starRadius = PixelAdventure.finishSpotlightAnimationRadius * 1.5;
    final starPositions = calculateStarPositions(playerCenter, starRadius);
    final List<OutlineStar> outlineStars = [];
    final stars = [];

    // outline stars
    for (final position in starPositions) {
      final outlineStar = OutlineStar(position: position);
      outlineStars.add(outlineStar);
    }
    world.addAll(outlineStars);
    await _delayAnimation(delays[delayIndex]).whenComplete(() => delayIndex++);

    // earned stars
    for (var i = 0; i < _earnedStars(); i++) {
      final star = Star(position: playerCenter);
      world.add(star);
      stars.add(star);

      // flies to the outline star position
      await star.flyTo(starPositions[i]);
      await _delayAnimation(delays[delayIndex]);
    }
    delayIndex++;

    // delete all outline stars that are behind the earned stars
    for (var i = 0; i < stars.length; i++) {
      world.remove(outlineStars[0]);
      outlineStars.removeAt(0);
    }
    await _delayAnimation(delays[delayIndex]).whenComplete(() => delayIndex++);

    // jump animation
    bounceUp(jumpForce: 320);
    await _delayAnimation(delays[delayIndex]).whenComplete(() => delayIndex++);
    current = PlayerState.doubleJump;
    await animationTickers![PlayerState.doubleJump]!.completed;
    await _waitUntilPlayerIsOnGround();
    await _delayAnimation(delays[delayIndex]).whenComplete(() => delayIndex++);

    // player disapperaing animation
    isVisible = false;
    await _effect.playDisappearing(scale.x > 0 ? position : position - Vector2(width, 0));
    await _delayAnimation(delays[delayIndex]).whenComplete(() => delayIndex++);

    // fade stars out and shrink light circle to zero
    for (var e in outlineStars) {
      e.fadeOut();
    }
    for (var e in stars) {
      e.fadeOut();
    }
    await spotlight.shrinkToBlack(0.4);
    await _delayAnimation(delays[delayIndex]).whenComplete(() => delayIndex++);

    // level official finished, go back to menu
    game.router.pushReplacementNamed(RouteNames.menu);
  }

  Future<void> _respawn() async {
    // hit
    _spawnProtection = true;
    _isPlayerStateActive = false;
    _isGravityActive = false;
    _horizontalMovement = 0;
    respawnNotifier.notifyRespawn();
    current = PlayerState.hit;
    await animationTickers![PlayerState.hit]!.completed;
    isVisible = false;

    // respawn
    scale.x = 1;
    velocity = Vector2.zero();
    position = _startPosition;
    _isPlayerStateActive = true;
    _isGravityActive = true;

    // a frame must be maintained, otherwise flickering will occur
    SchedulerBinding.instance.addPostFrameCallback((_) {
      isVisible = true;
      _spawnProtection = false;
    });
  }

  void collidedWithEnemy() => _respawn();

  void bounceUp({double jumpForce = 260, bool resetDoubleJump = true}) {
    velocity.y = -jumpForce;
    isOnGround = false;
    if (resetDoubleJump) canDoubleJump = true;
  }

  void _updateHitboxEdges() {
    hitboxLeft = (scale.x > 0) ? position.x + _hitbox.position.x : position.x - width + _hitbox.position.x;
    hitboxRight = hitboxLeft + _hitbox.width;
    hitboxTop = position.y + _hitbox.position.y;
    hitboxBottom = hitboxTop + _hitbox.height;
  }

  Rect get hitbox => Rect.fromLTRB(hitboxLeft, hitboxTop, hitboxRight, hitboxBottom);
  Vector2 get hitboxPosition => _hitbox.position;
}

class PlayerHitboxPositionProvider extends PositionProvider {
  final Player player;

  PlayerHitboxPositionProvider(this.player);

  @override
  Vector2 get position {
    return Vector2(player.hitboxLeft, player.position.y);
  }

  @override
  set position(Vector2 value) {}
}

class PlayerRespawnNotifier extends ChangeNotifier {
  void notifyRespawn() => notifyListeners();
}
