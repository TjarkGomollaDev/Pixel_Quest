import 'dart:async';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/image_composition.dart';
import 'package:flutter/scheduler.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/collision/collision.dart';
import 'package:pixel_adventure/game/collision/entity_collision.dart';
import 'package:pixel_adventure/game/collision/world_collision.dart';
import 'package:pixel_adventure/game/animations/spotlight.dart';
import 'package:pixel_adventure/game/animations/star.dart';
import 'package:pixel_adventure/game/checkpoints/finish.dart';
import 'package:pixel_adventure/game/checkpoints/start.dart';
import 'package:pixel_adventure/game/events/game_event_bus.dart';
import 'package:pixel_adventure/game/level/level.dart';
import 'package:pixel_adventure/game/level/player/player_effects.dart';
import 'package:pixel_adventure/game/traps/fire_trap.dart';
import 'package:pixel_adventure/game/traps/moving_platform.dart';
import 'package:pixel_adventure/game/utils/animation_state.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/data/audio/audio_center.dart';
import 'package:pixel_adventure/game/utils/utils.dart';
import 'package:pixel_adventure/game/game_settings.dart';
import 'package:pixel_adventure/game/game.dart';
import 'package:pixel_adventure/game/game_router.dart';

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
    with HasGameReference<PixelQuest>, HasWorldReference<Level>, CollisionCallbacks, HasVisibility {
  // constructor parameters
  final PlayerCharacter _character;

  Player({PlayerCharacter character = PlayerCharacter.defaultCharacter, required Vector2 startPosition})
    : _character = character,
      _respawnPosition = startPosition,
      super(position: startPosition, size: gridSize);

  // size
  static final Vector2 gridSize = Vector2.all(32);

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(9, 4), size: Vector2(14, 28));

  // these are the correct x and y values for the player hitbox in absolute space, the x values are cleaned up from the horizontal flip
  late double _hitboxLeft;
  late double _hitboxRight;
  late double _hitboxTop;
  late double _hitboxBottom;

  // animation settings
  static final Vector2 _textureSize = Vector2(32, 32);
  static const String _path = 'Main Characters/';
  static const String _pathEnd = ' (32x32).png';

  // special effects object for the player
  late final PlayerEffects _effect;

  // gravity
  final double _gravity = 570; // [Adjustable]
  final double _jumpForce = 310; // [Adjustable]
  final double _doubleJumpForce = 250; // [Adjustable]
  final double _terminalVelocity = 300; // [Adjustable]
  bool _isOnGround = false;

  // movement
  double _moveX = 0; // -1, 0, or 1
  final double _moveSpeed = 100; // [Adjustable]
  Vector2 _velocity = Vector2.zero();

  // jump
  bool _hasJumped = false;
  bool _hasDoubleJumped = false;
  bool _canDoubleJump = true;

  // if true all collisions are deactivated, only the world collision is always on
  bool _isSpawnProtectionActive = true;

  // if true the world collision is also deactivated
  bool _isWorldCollisionActive = false;

  // if true the player state is not automatically updated
  bool _isAnimationStateActive = false;

  // if true gravity is active
  bool _isGravityActive = false;

  // true until the player lands on the start platform and the level officially begins
  bool _isLevelStarting = true;

  // the player is reset to this position when he dies, changes when a new checkpoint is reached
  Vector2 _respawnPosition;

  // spawn position when the player appears in level and falls down onto the start platform
  late final Vector2 _spawnInLevelPosition;
  final double _spawnInLevelFallHeight = 60; // [Adjustable]

  // completer to detect when the player is back on the ground
  Completer<void>? _isOnGroundCompleter;

  // completer to detect when the player has reached a target x position
  Completer<void>? _isAtXCompleter;
  double? _targetX;

  // getter hitbox related
  Vector2 get respawnPosition => _respawnPosition;
  Vector2 get hitboxLocalPosition => _hitbox.position;
  Vector2 get hitboxLocalSize => _hitbox.size;
  Vector2 get hitboxAbsolutePosition => Vector2(_hitboxLeft, _hitboxTop);
  Rect get hitboxAbsoluteRect => Rect.fromLTRB(_hitboxLeft, _hitboxTop, _hitboxRight, _hitboxBottom);
  double get hitboxAbsoluteLeft => _hitboxLeft;
  double get hitboxAbsoluteRight => _hitboxRight;
  double get hitboxAbsoluteTop => _hitboxTop;
  double get hitboxAbsoluteBottom => _hitboxBottom;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllSpriteAnimations();
    _setUpSpecialEffects();
    _setUpSpawnPosition();
    _updateHitboxEdges();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    _updateHitboxEdges(); // must be done before updatePlayerMovement, important for world collision
    _applyInput();
    _updateMovement(dt);
    _updateGravity(dt);
    unawaited(_updateAnimationState());
    _checkCompleter();
    super.update(dt);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (_isWorldCollisionActive) {
      if (other is WorldCollision) onWorldCollision(other);
      if (_isSpawnProtectionActive) return super.onCollision(intersectionPoints, other);
      if (other is EntityCollision) onEntityCollision(other);
    } else if (_isLevelStarting && other is Start) {
      _landedOnStartPlatform(other);
    }
    super.onCollision(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (_isSpawnProtectionActive) return super.onCollisionEnd(other);
    if (other is WorldCollisionEnd) other.onWorldCollisionEnd();
    if (other is EntityCollisionEnd) other.onEntityCollisionEnd();
    super.onCollisionEnd(other);
  }

  void onEntityCollision(EntityCollision other) {
    // two rects
    final otherRect = other.entityHitbox.toAbsoluteRect();
    final playerRect = hitboxAbsoluteRect;

    // intersection check
    final hasVerticalIntersection = checkVerticalIntersection(playerRect, otherRect);
    final hasHorizontalIntersection = checkHorizontalIntersection(playerRect, otherRect);

    // different from world collision, there must always be a horizontal and a vertical intersection
    if (!(hasVerticalIntersection && hasHorizontalIntersection)) return;

    // if the exact side is not required, we can simply pass "Any" as the collision side and save ourselves computing costs
    if (other.collisionType == EntityCollisionType.any) return other.onEntityCollision(CollisionSide.Any);

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
    final playerRect = hitboxAbsoluteRect;

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
    _velocity.y = 0;
    _isOnGround = true;
    _canDoubleJump = true;
    if (other is MovingPlatform) other.playerOnTop();
    if (other is Finish) other.reachedFinish();
    if (other is FireTrap) other.hitTrap();
  }

  void _resolveBottomWorldCollision(double blockBottom, WorldCollision other) {
    if (_isOnGround) {
      _respawn(CollisionSide.Bottom);
    } else {
      position.y = blockBottom - _hitbox.position.y;
      _velocity.y = 0;

      // reset can double jump if the player hits their head
      _canDoubleJump = false;
      if (other is MovingPlatform && other.isVertical && other.moveDirection == 1) position.y += 1;
    }
  }

  void _resolveLeftWorldCollision(double blockLeft) {
    position.x = (scale.x < 0) ? blockLeft + _hitbox.position.x : blockLeft - _hitbox.position.x - _hitbox.width;
    _velocity.x = 0;
  }

  void _resolveRightWorldCollision(double blockRight) {
    position.x = (scale.x < 0) ? blockRight + _hitbox.position.x + _hitbox.width : blockRight - _hitbox.position.x;
    _velocity.x = 0;
  }

  void _resolveOneWayTopCollision(double playerBottom, double top, bool hasHorizontalIntersection, WorldCollision other) {
    if ((_velocity.y > 0 && playerBottom <= top && hasHorizontalIntersection)) _resolveTopWorldCollision(top, other);
  }

  void _landedOnStartPlatform(WorldCollision other) {
    _isLevelStarting = false;
    _isWorldCollisionActive = true;
    _isSpawnProtectionActive = false;
    game.audioCenter.playBackgroundMusic(BackgroundMusic.game);
    game.audioCenter.unmuteGameSfx();
    world.showOverlayOnStart();
    onWorldCollision(other);
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

  void _setUpSpecialEffects() {
    _effect = PlayerEffects(player: this);
    world.add(_effect);
  }

  void _setUpSpawnPosition() {
    isVisible = false;
    _spawnInLevelPosition = _respawnPosition - Vector2(0, _spawnInLevelFallHeight);
    position = _spawnInLevelPosition;
  }

  void _updateHitboxEdges() {
    _hitboxLeft = (scale.x > 0) ? position.x + _hitbox.position.x : position.x - width + _hitbox.position.x;
    _hitboxRight = _hitboxLeft + _hitbox.width;
    _hitboxTop = position.y + _hitbox.position.y;
    _hitboxBottom = _hitboxTop + _hitbox.height;
  }

  void _applyInput() {
    if (_isSpawnProtectionActive || (game.world as DecoratedWorld).timeScale == 0) return;

    // horizontal movement handling
    _moveX = world.playerInput.moveX;

    // jump handling
    if (world.playerInput.jumped && _isOnGround) {
      _hasJumped = true;
    } else if (world.playerInput.jumped && !_hasDoubleJumped && _canDoubleJump) {
      _hasDoubleJumped = true;
      _canDoubleJump = false;
    }

    world.playerInput.clearInput();
  }

  void _updateMovement(double dt) {
    // update vertical movement, meaning jump and gravity
    if (_hasJumped && _isOnGround) {
      _playerJump(dt);
    } else if (_hasDoubleJumped && !_hasJumped) {
      _playerDoubleJump(dt);
    }
    if (_velocity.y > _gravity) _isOnGround = false;

    // update horizontal movement
    _velocity.x = _moveX * _moveSpeed;
    if (_isAtXCompleter != null && _targetX != null) {
      if (_moveX == 1) {
        position.x = (position.x + _velocity.x * dt).clamp(double.negativeInfinity, _targetX!);
      } else if (_moveX == -1) {
        position.x = (position.x + _velocity.x * dt).clamp(_targetX!, double.infinity);
      }
      if (position.x == _targetX) {
        _moveX = 0;
        _targetX = null;
      }
    } else {
      position.x += _velocity.x * dt;
    }
  }

  void _playerJump(double dt) {
    _velocity.y = -_jumpForce;
    _isOnGround = false;
    _hasJumped = false;
    game.audioCenter.playSound(Sfx.jump, SfxType.player);
  }

  void _playerDoubleJump(double dt) {
    _velocity.y = -_doubleJumpForce;
    _isOnGround = false;
    _hasDoubleJumped = false;
    current = PlayerState.doubleJump;
    game.audioCenter.playSound(Sfx.doubleJump, SfxType.player);
  }

  void _updateGravity(double dt) {
    if (!_isGravityActive) return;
    _velocity.y += _gravity * dt;
    _velocity.y = _velocity.y.clamp(double.negativeInfinity, _terminalVelocity);
    position.y += _velocity.y * dt;
  }

  Future<void> _updateAnimationState() async {
    if (!_isAnimationStateActive) return;

    // wait if double jump animation is currently running
    if (current == PlayerState.doubleJump) {
      await animationTickers![PlayerState.doubleJump]!.completed;

      // prevents race condition during respawn
      if (!_isAnimationStateActive) return;
    }

    // flip when facing another direction
    if (_velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (_velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }

    // update state
    PlayerState playerState = PlayerState.idle;
    if (_velocity.x > 0 || _velocity.x < 0 && _isOnGround) playerState = PlayerState.run;
    if (_velocity.y > 0 && !_isOnGround) playerState = PlayerState.fall;
    if (_velocity.y < 0 && !_isOnGround) playerState = PlayerState.jump;
    current = playerState;
  }

  void _checkCompleter() {
    if (_isOnGroundCompleter != null && !_isOnGroundCompleter!.isCompleted && _isOnGround) _isOnGroundCompleter!.complete();
    if (_isAtXCompleter != null && !_isAtXCompleter!.isCompleted && _targetX == null) _isAtXCompleter!.complete();
  }

  Future<void> spawnInLevel() async {
    // play appearing animation
    game.audioCenter.playSound(Sfx.appearing, SfxType.level);
    await _effect.playAppearing(_spawnInLevelPosition);
    _isAnimationStateActive = true;
    _isGravityActive = true;
    isVisible = true;

    // spawn protection is deactivated as soon as the player lands on the start platform, take a look at onCollision
  }

  Future<void> _waitUntilPlayerIsOnGround() {
    _isOnGroundCompleter = Completer<void>();
    return _isOnGroundCompleter!.future.whenComplete(() => _updateHitboxEdges());
  }

  Future<void> _waitUntilPlayerIsAtX(double newTargetX) {
    if (hitboxAbsoluteRect.center.dx < newTargetX) {
      if (scale.x < 0) flipHorizontallyAroundCenter();
      _moveX = 1;
      _targetX = newTargetX - _hitbox.position.x - _hitbox.width / 2;
    } else if (hitboxAbsoluteRect.center.dx > newTargetX) {
      if (scale.x > 0) flipHorizontallyAroundCenter();
      _moveX = -1;
      _targetX = newTargetX + width - _hitbox.position.x - _hitbox.width / 2;
    } else {
      return Future.value();
    }
    _isAtXCompleter = Completer<void>();
    return _isAtXCompleter!.future.whenComplete(() => _updateHitboxEdges());
  }

  void reachedCheckpoint(Vector2 checkpointPosition) => _respawnPosition = checkpointPosition;

  Future<void> _delayAnimation(int milliseconds) => Future.delayed(Duration(milliseconds: milliseconds));

  Future<void> reachedFinish(ShapeHitbox finish) async {
    _moveX = 0;
    _isSpawnProtectionActive = true;
    unawaited(world.saveData());

    // delays are not functional, but purely for a more visually appealing result
    final delays = [200, 800, 80, 620, 120, 600, 400, 320];
    int delayIndex = 0;

    // player moves to the horizontal center of the finish
    await _waitUntilPlayerIsAtX(finish.toAbsoluteRect().center.dx);

    // spotlight animation
    world.removeOverlaysOnFinish();
    unawaited(game.audioCenter.muteGameSfx());
    final playerCenter = hitboxAbsoluteRect.center.toVector2();
    final spotlight = Spotlight(targetCenter: playerCenter, targetRadius: GameSettings.finishSpotlightAnimationRadius);
    world.add(spotlight);
    await spotlight.focusOnTarget();
    game.audioCenter.playBackgroundMusic(BackgroundMusic.win);
    await _delayAnimation(delays[delayIndex]).whenComplete(() => delayIndex++);

    // star positions
    final starRadius = GameSettings.finishSpotlightAnimationRadius * 1.5;
    final starPositions = calculateStarPositions(playerCenter, starRadius);
    final outlineStars = [];
    final stars = [];

    // outline stars
    for (var position in starPositions) {
      final outlineStar = Star(variant: StarVariant.outline, position: position, spawnSizeZero: true);
      world.add(outlineStar);
      outlineStars.add(outlineStar);
      unawaited(outlineStar.scaleIn());
    }
    await _delayAnimation(delays[delayIndex]).whenComplete(() => delayIndex++);

    // earned stars
    for (var i = 0; i < world.earnedStars; i++) {
      final star = Star(variant: StarVariant.filled, position: playerCenter, spawnSizeZero: true);
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
    game.audioCenter.playSound(Sfx.jump, SfxType.player);
    bounceUp(jumpForce: 320);
    await _delayAnimation(delays[delayIndex]).whenComplete(() => delayIndex++);
    current = PlayerState.doubleJump;
    await animationTickers![PlayerState.doubleJump]!.completed;
    await _waitUntilPlayerIsOnGround();
    await _delayAnimation(delays[delayIndex]).whenComplete(() => delayIndex++);

    // player disapperaing animation
    isVisible = false;
    game.audioCenter.playSound(Sfx.disappearing, SfxType.level);
    await _effect.playDisappearing(scale.x > 0 ? position : position - Vector2(width, 0));
    await _delayAnimation(delays[delayIndex]).whenComplete(() => delayIndex++);

    // fade stars out and shrink light circle to zero
    for (var e in outlineStars) {
      unawaited(e.fadeOut());
    }
    for (var e in stars) {
      unawaited(e.fadeOut());
    }
    game.audioCenter.stopBackgroundMusic();
    await spotlight.shrinkToBlack();
    await _delayAnimation(delays[delayIndex]);

    // level official finished, go back to menu
    game.router.pushReplacementNamed(RouteNames.menu);
  }

  void _respawn(CollisionSide collisionSide) async {
    // hit
    _isSpawnProtectionActive = true;
    _isGravityActive = false;
    _isAnimationStateActive = false;
    _isWorldCollisionActive = false;
    _moveX = 0;
    _velocity = Vector2.zero();
    animationTickers![PlayerState.doubleJump]?.onComplete?.call(); // prevents race condition during respawn
    GameEventBus.instance.emit(PlayerRespawned());

    // play death effects
    game.audioCenter.playSound(Sfx.playerHit, SfxType.player);
    game.audioCenter.playSound(Sfx.playerDeath, SfxType.player);
    _effect.playFlashScreen();
    _effect.shakeCamera();
    current = PlayerState.hit;
    await _effect.playDeathTrajectory(collisionSide);
    game.setRefollowForLevelCamera(this);
    isVisible = false;

    // respawn
    position = _respawnPosition;
    scale.x = 1;
    world.playerRespawn();

    // a frame must be maintained before visible again, otherwise flickering will occur
    SchedulerBinding.instance.addPostFrameCallback((_) {
      world.playerInput.clearInput();
      isVisible = true;
      _isSpawnProtectionActive = false;
      _isAnimationStateActive = true;
      _isGravityActive = true;
      _isWorldCollisionActive = true;
    });
  }

  void collidedWithEnemy(CollisionSide collisionSide) => _respawn(collisionSide);

  void bounceUp({double jumpForce = 260, bool resetDoubleJump = true}) {
    _velocity.y = -jumpForce;
    _isOnGround = false;
    if (resetDoubleJump) _canDoubleJump = true;
  }

  void activateDoubleJump() => _canDoubleJump = true;

  void adjustPostion({double? x, double? y}) => position += Vector2(x ?? 0, y ?? 0);
}
