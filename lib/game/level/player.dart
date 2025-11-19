import 'dart:async';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/image_composition.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/collision/collision.dart';
import 'package:pixel_adventure/game/collision/entity_collision.dart';
import 'package:pixel_adventure/game/collision/world_collision.dart';
import 'package:pixel_adventure/game/animations/spotlight.dart';
import 'package:pixel_adventure/game/animations/star.dart';
import 'package:pixel_adventure/game/checkpoints/finish.dart';
import 'package:pixel_adventure/game/checkpoints/start.dart';
import 'package:pixel_adventure/game/level/level.dart';
import 'package:pixel_adventure/game/level/player_special_effect.dart';
import 'package:pixel_adventure/game/traps/fire_trap.dart';
import 'package:pixel_adventure/game/traps/moving_platform.dart';
import 'package:pixel_adventure/game/utils/animation_state.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_quest.dart';

enum PlayerState implements AnimationState {
  idle('Idle', 11),
  run('Run', 12),
  jump('Jump', 1),
  doubleJump('Double Jump', 6, loop: false),
  fall('Fall', 1),
  hit('Hit', 7, loop: false);

  @override
  final String fileName;
  @override
  final int amount;
  @override
  final bool loop;

  const PlayerState(this.fileName, this.amount, {this.loop = true});
}

enum PlayerCharacter {
  maskDude('Mask Dude'),
  ninjaFrog('Ninja Frog'),
  pinkMan('Pink Man'),
  virtualGuy('Virtual Guy');

  final String fileName;

  const PlayerCharacter(this.fileName);

  static const PlayerCharacter defaultCharacter = PlayerCharacter.maskDude;

  static PlayerCharacter fromName(String name) => PlayerCharacter.values.firstWhere((c) => c.name == name, orElse: () => defaultCharacter);
}

class Player extends SpriteAnimationGroupComponent
    with HasGameReference<PixelQuest>, HasWorldReference<Level>, KeyboardHandler, CollisionCallbacks, HasVisibility {
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
  bool isOnGround = false;

  // movement
  double _horizontalMovement = 0;
  final double _moveSpeed = 100;
  Vector2 velocity = Vector2.zero();

  // jump
  bool hasJumped = false;

  // double jump
  bool canDoubleJump = true;
  bool hasDoubleJumped = false;

  // if true all collisions are deactivated, only the world collision is always on
  bool _spawnProtection = true;

  // if true the world collision is also deactivated
  bool isWorldCollisionActive = false;

  // if the true the player state is not automatically updated
  bool _isPlayerStateActive = false;

  // if true gravity is active
  bool _isGravityActive = false;

  // special effect
  late final PlayerSpecialEffect _effect;

  // spawn position
  late final Vector2 _spawnPosition;
  final double _spawnDropFall = 60;

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

  bool _levelStart = true;

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
    if (_spawnProtection || (game.world as DecoratedWorld).timeScale == 0) return false;

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
  void onCollisionEnd(PositionComponent other) {
    if (_spawnProtection) return super.onCollisionEnd(other);
    if (other is WorldCollisionEnd) other.onWorldCollisionEnd();
    if (other is EntityCollisionEnd) other.onEntityCollisionEnd();
    super.onCollisionEnd(other);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (isWorldCollisionActive) {
      if (other is WorldCollision) onWorldCollision(other);
      if (_spawnProtection) return super.onCollision(intersectionPoints, other);
      if (other is EntityCollision) onEntityCollision(other);
    } else if (_levelStart && other is Start) {
      _levelStart = false;
      isWorldCollisionActive = true;
      _spawnProtection = false;
      onWorldCollision(other);
    }
    super.onCollision(intersectionPoints, other);
  }

  void onEntityCollision(EntityCollision other) {
    // two rects
    final otherRect = other.entityHitbox.toAbsoluteRect();
    final playerRect = hitbox;

    // intersection check
    final hasVerticalIntersection = checkVerticalIntersection(playerRect, otherRect);
    final hasHorizontalIntersection = checkHorizontalIntersection(playerRect, otherRect);

    // different from world collision, there must always be a horizontal and a vertical intersection
    if (!(hasVerticalIntersection && hasHorizontalIntersection)) return;

    // if the exact side is not required, we can simply pass "Any" as the collision side and save ourselves computing costs
    if (other.collisionType == EntityCollisionType.Any) return other.onEntityCollision(CollisionSide.Any);

    // overlap calculation
    final overlapX = calculateOverlapX(playerRect, otherRect);
    final overlapY = calculateOverlapY(playerRect, otherRect);

    // resolve AABB collsion
    final result = resolveAABBCollision(
      playerRect,
      otherRect,
      overlapX,
      overlapY,
      hasVerticalIntersection,
      hasHorizontalIntersection,
      false,
    );
    if (result == CollisionSide.None) return;
    other.onEntityCollision(result);
  }

  void onWorldCollision(WorldCollision other) {
    // two rects
    final worldBlockRect = other.worldHitbox.toAbsoluteRect();
    final playerRect = hitbox;

    // intersection check
    final hasVerticalIntersection = checkVerticalIntersection(playerRect, worldBlockRect);
    final hasHorizontalIntersection = checkHorizontalIntersection(playerRect, worldBlockRect);

    // overlap calculation
    final overlapX = calculateOverlapX(playerRect, worldBlockRect);
    final overlapY = calculateOverlapY(playerRect, worldBlockRect);

    // special cases
    bool forceVertical = false;
    if (other is WorldBlock && other.isPlatform) {
      // plattform collision
      return _resolveOneWayTopCollision(playerRect.bottom, worldBlockRect.top, hasHorizontalIntersection, other);
    } else if (other is FastCollision) {
      // the rapid movement of the rockhead can cause the collision direction to be misinterpreted
      forceVertical = verticalSweptCheck(playerRect, other as FastCollision, hasHorizontalIntersection);
    }

    // resolve AABB collsion
    switch (resolveAABBCollision(
      playerRect,
      worldBlockRect,
      overlapX,
      overlapY,
      hasVerticalIntersection,
      hasHorizontalIntersection,
      forceVertical,
    )) {
      case CollisionSide.Top:
        _resolveTopWorldCollision(worldBlockRect.top, other);
        break;
      case CollisionSide.Bottom:
        _resolveBottomWorldCollision(worldBlockRect.bottom, other);
        break;
      case CollisionSide.Left:
        _resolveLeftWorldCollision(worldBlockRect.left);
        break;
      case CollisionSide.Right:
        _resolveRightWorldCollision(worldBlockRect.right);
        break;
      default:
        break;
    }
  }

  void _resolveTopWorldCollision(double blockTop, WorldCollision other) {
    position.y = blockTop - _hitbox.position.y - _hitbox.height;
    velocity.y = 0;
    isOnGround = true;
    canDoubleJump = true;
    if (other is MovingPlatform) other.playerOnTop();
    if (other is Finish) other.reachedFinish();
    if (other is FireTrap) other.hitTrap();
  }

  void _resolveBottomWorldCollision(double blockBottom, WorldCollision other) {
    if (isOnGround) {
      _respawn(CollisionSide.Bottom);
    } else {
      position.y = blockBottom - _hitbox.position.y;
      velocity.y = 0;
      // reset can double jump if the player hits their head
      canDoubleJump = false;
      if (other is MovingPlatform && other.isVertical && other.moveDirection == 1) position.y += 1;
    }
  }

  void _resolveLeftWorldCollision(double blockLeft) {
    position.x = (scale.x < 0) ? blockLeft + _hitbox.position.x : blockLeft - _hitbox.position.x - _hitbox.width;
    velocity.x = 0;
  }

  void _resolveRightWorldCollision(double blockRight) {
    position.x = (scale.x < 0) ? blockRight + _hitbox.position.x + _hitbox.width : blockRight - _hitbox.position.x;
    velocity.x = 0;
  }

  void _resolveOneWayTopCollision(double playerBottom, double top, bool hasHorizontalIntersection, WorldCollision other) {
    if ((velocity.y > 0 && playerBottom <= top && hasHorizontalIntersection)) _resolveTopWorldCollision(top, other);
  }

  void _initialSetup() {
    // debug
    if (GameSettings.customDebug) {
      _hitbox.debugMode = true;
      _hitbox.debugColor = AppTheme.debugColorPlayerHitbox;
    }

    // general
    priority = GameSettings.playerLayerLevel;
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
      '$_path${_character.fileName}/',
      _pathEnd,
      GameSettings.stepTime,
      _textureSize,
    );
    animations = {for (var state in PlayerState.values) state: loadAnimation(state)};
    current = PlayerState.idle;
  }

  void _setUpSpawnPosition() {
    isVisible = false;
    _spawnPosition = _startPosition - Vector2(0, _spawnDropFall);
    position = _spawnPosition;
    _effect = PlayerSpecialEffect(player: this);
    world.add(_effect);
  }

  Future<void> _updatePlayerState() async {
    // wait if double jump animation is currently running
    if (current == PlayerState.doubleJump) {
      await animationTickers![PlayerState.doubleJump]!.completed;

      // prevents race condition during respawn
      if (!_isPlayerStateActive) return;
    }

    // flip when facing another direction
    if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }

    // update state
    PlayerState playerState = PlayerState.idle;
    if (velocity.x > 0 || velocity.x < 0 && isOnGround) playerState = PlayerState.run;
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

  void reachedCheckpoint(Vector2 checkpointPosition) => _startPosition = checkpointPosition;

  Future<void> _delayAnimation(int milliseconds) => Future.delayed(Duration(milliseconds: milliseconds));

  Future<void> reachedFinish(ShapeHitbox finish) async {
    _horizontalMovement = 0;
    _spawnProtection = true;
    world.saveData();

    // delays are not functional, but purely for a more visually appealing result
    final delays = [200, 800, 80, 620, 120, 600, 400, 200];
    int delayIndex = 0;

    // player moves to the horizontal center of the finish
    await _waitUntilPlayerIsAtFinishCenter(finish.toAbsoluteRect().center.dx);

    // spotlight animation
    world.removeGameHudOnFinish();
    final playerCenter = hitbox.center.toVector2();
    final spotlight = Spotlight(targetCenter: playerCenter, targetRadius: GameSettings.finishSpotlightAnimationRadius);
    world.add(spotlight);
    await spotlight.focusOnTarget();
    await _delayAnimation(delays[delayIndex]).whenComplete(() => delayIndex++);

    // star positions
    final starRadius = GameSettings.finishSpotlightAnimationRadius * 1.5;
    final starPositions = calculateStarPositions(playerCenter, starRadius);
    final List<OutlineStar> outlineStars = [];
    final stars = [];

    // outline stars
    for (var position in starPositions) {
      final outlineStar = OutlineStar(position: position, spawnSizeZero: true);
      outlineStars.add(outlineStar);
    }
    world.addAll(outlineStars);
    await _delayAnimation(delays[delayIndex]).whenComplete(() => delayIndex++);

    // earned stars
    for (var i = 0; i < world.earnedStars; i++) {
      final star = Star(position: playerCenter, spawnSizeZero: true);
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
    await spotlight.shrinkToBlack();
    await _delayAnimation(delays[delayIndex]).whenComplete(() => delayIndex++);

    // level official finished, go back to menu
    game.router.pushReplacementNamed(RouteNames.menu);
  }

  void _respawn(CollisionSide collisionSide) async {
    // hit
    _spawnProtection = true;
    _isGravityActive = false;
    _isPlayerStateActive = false;
    isWorldCollisionActive = false;
    _horizontalMovement = 0;
    velocity = Vector2.zero();
    animationTickers![PlayerState.doubleJump]?.onComplete?.call(); // prevents race condition during respawn
    respawnNotifier.notifyRespawn();

    // play death effects
    _effect.playFlashScreen();
    _effect.shakeCamera();
    current = PlayerState.hit;
    await _effect.playDeathTrajectory(collisionSide);
    game.setRefollowForLevelCamera(this);
    isVisible = false;

    // respawn
    position = _startPosition;
    scale.x = 1;
    world.playerRespawn();

    // a frame must be maintained before visible again, otherwise flickering will occur
    SchedulerBinding.instance.addPostFrameCallback((_) {
      isVisible = true;
      _spawnProtection = false;
      _isPlayerStateActive = true;
      _isGravityActive = true;
      isWorldCollisionActive = true;
    });
  }

  void collidedWithEnemy(CollisionSide collisionSide) => _respawn(collisionSide);

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
  Vector2 get startPosition => _startPosition;
  Vector2 get hitboxSize => _hitbox.size;
}

class PlayerRespawnNotifier extends ChangeNotifier {
  void notifyRespawn() => notifyListeners();
}
