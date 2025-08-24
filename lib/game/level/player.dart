import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/animations/spotlight.dart';
import 'package:pixel_adventure/game/collision_block.dart';
import 'package:pixel_adventure/game/custom_hitbox.dart';
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

  // these are the correct x values for the player, one for the left side of the hitbox and one for the right side of the hitbox
  late double hitboxPositionLeftX;
  late double hitboxPositionRightX;

  // animation settings
  final double _stepTime = 0.05;
  final Vector2 _textureSize = Vector2(32, 32);
  final String _path = 'Main Characters/';
  final String _pathEnd = ' (32x32).png';

  // gravity
  final double _gravity = 9.8;
  final double _jumpForce = 310;
  final double _doubleJumpForce = 250;
  final double _terminalVelocity = 300;

  // delta time
  double fixedDT = 1 / 60;
  double accumulatedTime = 0;

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
  bool _spawnProtection = true;

  // finish level
  bool _hasReachedFinish = false;

  // counterpart to spawn protection, when activated, certain things should still be active in the update method
  bool _isCinematic = true;

  // special effect
  late final PlayerSpecialEffect _effect;

  // spawn protection
  late final Vector2 _spawnPosition;
  final double _spawnDropFall = 80;

  // actual hitbox
  CustomHitbox hitbox = CustomHitbox(offsetX: 10, offsetY: 4, width: 14, height: 28);

  // list of all collision elements
  List<CollisionBlock> collisionBlocks = [];

  // joystick for mobile
  JoystickComponent? _joystick;
  JoystickDirection _lastJoystickDirection = JoystickDirection.idle;

  // count fruits
  int _fruitCounter = 0;

  // notifier
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

  @override
  void update(double dt) {
    accumulatedTime += dt;
    while (accumulatedTime >= fixedDT) {
      if (!_spawnProtection && !_hasReachedFinish) {
        _updateHitboxEdges();
        _updatePlayerState();
        _updatePlayerMovement(fixedDT);
        _checkHorizontalCollisions();
        _applyGravity(fixedDT);
        _checkVerticalCollisions();
        if (_joystick != null) updateJoystick();
      } else if (_isCinematic) {
        _updateHitboxEdges();
        _updatePlayerState();
        _applyGravity(fixedDT);
        _checkVerticalCollisions();
      }
      if (_isOnGroundCompleter != null && !_isOnGroundCompleter!.isCompleted && isOnGround) {
        _isOnGroundCompleter!.complete();
      }
      accumulatedTime -= fixedDT;
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
    if (_checkIsCollisionInactive()) return super.onCollision(intersectionPoints, other);
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
    final hitbox2 = RectangleHitbox(position: Vector2(hitbox.offsetX, hitbox.offsetY), size: Vector2(hitbox.width, hitbox.height));

    // debug
    if (game.customDebug) {
      hitbox2.debugMode = true;
      hitbox2.debugColor = AppTheme.debugColorPlayerHitbox;
    }

    // general
    priority = PixelAdventure.playerLayerLevel;
    add(hitbox2);
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
    game.world.add(_effect);
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
    // check running
    if (velocity.x > 0 || velocity.x < 0) playerState = PlayerState.run;
    // check falling
    if (velocity.y > 0) playerState = PlayerState.fall;
    // check jumping
    if (velocity.y < 0) playerState = PlayerState.jump;

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

  void _checkHorizontalCollisions() {
    for (var block in collisionBlocks) {
      if (!block.isPlattform && checkCollision(this, block)) {
        if (velocity.x > 0) {
          velocity.x = 0;
          position.x = block.x - hitbox.offsetX - hitbox.width;
          break;
        } else if (velocity.x < 0) {
          velocity.x = 0;
          position.x = block.x + block.width + hitbox.offsetX + hitbox.width;
          break;
        }
      }
    }
  }

  void _applyGravity(double dt) {
    velocity.y += _gravity;
    velocity.y = velocity.y.clamp(double.negativeInfinity, _terminalVelocity);
    position.y += velocity.y * dt;
  }

  void _checkVerticalCollisions() {
    bool collidedTop = false;
    bool collidedBottom = false;
    for (var block in collisionBlocks) {
      if (block.isPlattform && checkCollision(this, block)) {
        if (velocity.y > 0 && position.y + hitbox.height < block.y) {
          velocity.y = 0;
          position.y = block.y - hitbox.offsetY - hitbox.height;
          isOnGround = true;
          canDoubleJump = true;

          break;
        }
      } else if (checkCollision(this, block)) {
        if (velocity.y > 0) {
          velocity.y = 0;
          position.y = block.y - hitbox.offsetY - hitbox.height;
          isOnGround = true;
          canDoubleJump = true;
          collidedBottom = true;
          break;
        } else if (velocity.y < 0) {
          velocity.y = 0;
          position.y = block.y + block.height - hitbox.offsetY;
          // double jump not possible if the player hits their head
          canDoubleJump = false;
          collidedTop = true;
          break;
        }
      }
    }
    if (collidedTop && collidedBottom) {
      _respawn();
    }
  }

  Future<void> spawnInLevel() async {
    // play appearing animation
    await _effect.playAppearing(_spawnPosition);
    position = _spawnPosition;

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

  Future<void> reachedFinish() async {
    velocity = Vector2.zero();
    _hasReachedFinish = true;
    _isCinematic = true;

    // delays are not functional, but purely for a more visually appealing result
    final delays = [200, 120, 600, 400];

    // spotlight animation
    world.removeGameHudOnFinish();
    final playerCenter = Vector2((hitboxPositionLeftX + hitboxPositionRightX) / 2, position.y + height / 2);
    final spotlight = Spotlight(targetCenter: playerCenter, targetRadius: 60)..priority = PixelAdventure.spotlightAnimationLayer;
    game.world.add(spotlight);
    await spotlight.startAnimation(2.0);
    await Future.delayed(Duration(milliseconds: delays[0]));

    // jump animation
    bounceUp(jumpForce: 320);
    await Future.delayed(Duration(milliseconds: delays[1]));
    current = PlayerState.doubleJump;
    await animationTickers![PlayerState.doubleJump]!.completed;
    await waitUntilPlayerIsOnGround();
    await Future.delayed(Duration(milliseconds: delays[2]));

    // player disapperaing animation
    isVisible = false;
    await _effect.playDisappearing(position, scale.x);

    // shrink light circle to zero
    await Future.delayed(Duration(milliseconds: delays[3]));
    await spotlight.shrinkToBlack(0.4);

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

  void increaseFruitCounter() => _fruitCounter++;

  void _updateHitboxEdges() {
    hitboxPositionLeftX = (scale.x > 0) ? x + hitbox.offsetX : x - hitbox.offsetX - hitbox.width;
    hitboxPositionRightX = hitboxPositionLeftX + hitbox.width;
  }
}

class PlayerHitboxPositionProvider extends PositionProvider {
  final Player player;

  PlayerHitboxPositionProvider(this.player);

  @override
  Vector2 get position {
    return Vector2(player.hitboxPositionLeftX, player.position.y);
  }

  @override
  set position(Vector2 value) {}
}

class PlayerRespawnNotifier extends ChangeNotifier {
  void notifyRespawn() => notifyListeners();
}
