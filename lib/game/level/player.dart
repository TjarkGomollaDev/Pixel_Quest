import 'dart:async';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/animations/spotlight.dart';
import 'package:pixel_adventure/game/animations/star.dart';
import 'package:pixel_adventure/game/collision_block.dart';
import 'package:pixel_adventure/game/level/level.dart';
import 'package:pixel_adventure/game/level/player_special_effect.dart';
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
  final RectangleHitbox hitbox = RectangleHitbox(position: Vector2(10, 4), size: Vector2(14, 28));

  // these are the correct x values for the player, one for the left side of the hitbox and one for the right side of the hitbox
  late double hitboxLeft;
  late double hitboxRight;
  late double hitboxTop;
  late double hitboxBottom;

  // animation settings
  final double _stepTime = 0.05;
  final Vector2 _textureSize = Vector2(32, 32);
  final String _path = 'Main Characters/';
  final String _pathEnd = ' (32x32).png';

  // gravity
  final double _gravity = 9.8;
  final double _jumpForce = 310;
  final double _doubleJumpForce = 250;
  final double _terminalVelocity = 400;

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

  // when activated, all collisions and movement (in update) are deactivated
  // this is used when the level starts and when the player dies and respawns
  bool _spawnProtection = false;

  // finish level
  bool _hasReachedFinish = false;

  // counterpart to spawn protection, when activated, certain things should still be active in the update method
  bool _isCinematic = true;

  // special effect
  late final PlayerSpecialEffect _effect;

  // spawn position
  late final Vector2 _spawnPosition;
  final double _spawnDropFall = 80;

  // list of all collision elements
  List<WorldBlock> collisionBlocks = [];

  // joystick for mobile
  JoystickComponent? _joystick;
  JoystickDirection _lastJoystickDirection = JoystickDirection.idle;

  // respawn notifier
  final PlayerRespawnNotifier respawnNotifier = PlayerRespawnNotifier();

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _updateHitboxEdges();
    _loadAllSpriteAnimations();
    _setUpSpawnPosition();
    return super.onLoad();
  }

  Completer<void>? _isOnGroundCompleter;

  bool start = true;

  @override
  void update(double dt) {
    _updateHitboxEdges();
    if (!_spawnProtection && !_hasReachedFinish) {
      _updatePlayerState();
      _updatePlayerMovement(dt);
      _applyGravity(dt);
      if (_joystick != null) updateJoystick();
    } else if (_isCinematic) {
      _updateHitboxEdges();
      _updatePlayerState();
      _applyGravity(dt);
    }
    if (_isOnGroundCompleter != null && !_isOnGroundCompleter!.isCompleted && isOnGround) {
      _isOnGroundCompleter!.complete();
    }
    super.update(dt);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (_checkIsCollisionInactive()) return super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerCollision) other.onPlayerCollisionStart(intersectionPoints.first);
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (_checkIsCollisionInactive()) return super.onCollisionEnd(other);
    if (other is PlayerCollision) other.onPlayerCollisionEnd();
    super.onCollisionEnd(other);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    // if (_checkIsCollisionInactive()) return super.onCollision(intersectionPoints, other);

    _updateHitboxEdges();
    if (other is CollisionBlock) {
      final rect = (other as CollisionBlock).solidHitbox.toAbsoluteRect();
      final blockTop = rect.top;
      final blockBottom = rect.bottom;
      final blockLeft = rect.left;
      final blockRight = rect.right;

      const double epsilon = 0.5;

      if (hitboxRight >= blockLeft && absoluteCenter.x < blockLeft && (hitboxBottom - blockTop).abs() > epsilon) {
        debugPrint('right');
        velocity.x = 0;
        position.x = (scale.x < 0) ? blockLeft + hitbox.position.x : blockLeft - hitbox.position.x - hitbox.width;
      } else if (hitboxLeft <= blockRight && absoluteCenter.x > blockRight && (hitboxBottom - blockTop).abs() > epsilon) {
        debugPrint('left');
        velocity.x = 0;
        position.x = (scale.x < 0) ? blockRight + hitbox.position.x + hitbox.width : blockRight - hitbox.position.x;
      } else if (hitboxBottom >= blockTop && absoluteCenter.y < blockTop && !(velocity.y < 0)) {
        debugPrint('up');
        position.y = blockTop - hitbox.position.y - hitbox.height;
        velocity.y = 0;
        isOnGround = true;
        canDoubleJump = true;
      } else if (hitboxTop <= blockBottom && absoluteCenter.y > blockBottom) {
        debugPrint('down');
        if (isOnGround) {
          debugPrint('dead');
          _respawn();
          return;
        }
        position.y = blockBottom - hitbox.position.y;
        velocity.y = 0;
        // reset can double jump if the player hits their head
        canDoubleJump = false;
      } else {
        debugPrint('WTF');
        // debugPrint(hitboxLeft.toString());
      }
    }

    if (other is PlayerCollision) other.onPlayerCollision(intersectionPoints.first);
    super.onCollision(intersectionPoints, other);
  }

  bool _checkIsCollisionInactive() => _hasReachedFinish || _spawnProtection;

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
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

  void _initialSetup() {
    // debug
    if (game.customDebug) {
      hitbox.debugMode = true;
      hitbox.debugColor = AppTheme.debugColorPlayerHitbox;
    }

    // general
    priority = PixelAdventure.playerLayerLevel;
    add(hitbox);
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
    final loadAnimation = spriteAnimationWrapper<PlayerState>(game, '$_path${_character.name}/', _pathEnd, _stepTime, _textureSize);
    animations = {for (var state in PlayerState.values) state: loadAnimation(state)};
    current = PlayerState.idle;
  }

  void _setUpSpawnPosition() {
    isVisible = false;
    _spawnPosition = _startPosition - Vector2(0, _spawnDropFall);
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
    position.x += velocity.x * dt;
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

    // spawn modus
    isVisible = true;
    position = _spawnPosition;

    // deactivate spawn modus when player is on ground
    await waitUntilPlayerIsOnGround();
    _isCinematic = false;
    _spawnProtection = false;
  }

  Future<void> waitUntilPlayerIsOnGround() {
    _isOnGroundCompleter = Completer<void>();
    return _isOnGroundCompleter!.future;
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

  Future<void> reachedFinish() async {
    velocity = Vector2.zero();
    _hasReachedFinish = true;
    _isCinematic = true;

    // delays are not functional, but purely for a more visually appealing result
    final delays = [200, 800, 80, 620, 120, 600, 400, 200];
    int delayIndex = 0;

    // spotlight animation
    world.removeGameHudOnFinish();
    final playerCenter = Vector2((hitboxLeft + hitboxRight) / 2, position.y + height / 2);
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

    // delete all outline stars that are behind
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
    await waitUntilPlayerIsOnGround();
    await _delayAnimation(delays[delayIndex]).whenComplete(() => delayIndex++);

    // player disapperaing animation
    isVisible = false;
    await _effect.playDisappearing(position, scale.x);
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
    respawnNotifier.notifyRespawn();
    current = PlayerState.hit;
    await animationTickers![PlayerState.hit]!.completed;
    isVisible = false;

    // respawn
    scale.x = 1;
    velocity = Vector2.zero();
    position = _startPosition;
    _isCinematic = true;

    // a frame must be maintained, otherwise flickering will occur
    SchedulerBinding.instance.addPostFrameCallback((_) {
      isVisible = true;
      _spawnProtection = false;
      _isCinematic = false;
    });
  }

  void collidedWithEnemy() => _respawn();

  void bounceUp({double jumpForce = 260, bool resetDoubleJump = true}) {
    velocity.y = -jumpForce;
    isOnGround = false;
    if (resetDoubleJump) canDoubleJump = true;
  }

  void _updateHitboxEdges() {
    hitboxLeft = (scale.x > 0) ? x + hitbox.position.x : x - hitbox.position.x - hitbox.width;
    hitboxRight = hitboxLeft + hitbox.width;
    hitboxTop = position.y + hitbox.position.y;
    hitboxBottom = hitboxTop + hitbox.height;
  }
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
