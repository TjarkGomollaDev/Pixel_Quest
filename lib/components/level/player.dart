import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/components/enemies/blue_bird.dart';
import 'package:pixel_adventure/components/enemies/ghost.dart';
import 'package:pixel_adventure/components/enemies/mushroom.dart';
import 'package:pixel_adventure/components/enemies/slime.dart';
import 'package:pixel_adventure/components/enemies/slime_particle.dart';
import 'package:pixel_adventure/components/enemies/snail.dart';
import 'package:pixel_adventure/components/enemies/trunk.dart';
import 'package:pixel_adventure/components/enemies/trunk_bullet.dart';
import 'package:pixel_adventure/components/enemies/turtle.dart';
import 'package:pixel_adventure/components/traps/checkpoint.dart';
import 'package:pixel_adventure/components/enemies/chicken.dart';
import 'package:pixel_adventure/components/collision_block.dart';
import 'package:pixel_adventure/components/custom_hitbox.dart';
import 'package:pixel_adventure/components/enemies/plant.dart';
import 'package:pixel_adventure/components/enemies/plant_bullet.dart';
import 'package:pixel_adventure/components/traps/fan_air_stream.dart';
import 'package:pixel_adventure/components/traps/fire_trap.dart';
import 'package:pixel_adventure/components/traps/fruit.dart';
import 'package:pixel_adventure/components/traps/moving_platform.dart';
import 'package:pixel_adventure/components/traps/saw.dart';
import 'package:pixel_adventure/components/traps/saw_circle_single_saw.dart';
import 'package:pixel_adventure/components/traps/spikes.dart';
import 'package:pixel_adventure/components/traps/trampoline.dart';
import 'package:pixel_adventure/components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum PlayerState implements AnimationState {
  idle('Idle', 11),
  run('Run', 12),
  jump('Jump', 1),
  doubleJump('Double Jump', 6, loop: false),
  fall('Fall', 1),
  hit('Hit', 7, loop: false),
  appearing('Appearing', 7, loop: false, special: true),
  disappearing('Disappearing', 7, loop: false, special: true);

  @override
  final String name;
  @override
  final int amount;
  @override
  final bool loop;
  final bool special;

  const PlayerState(this.name, this.amount, {this.loop = true, this.special = false});
}

enum PlayerCharacter {
  maskDude('Mask Dude'),
  ninjaFrog('Ninja Frog'),
  pinkMan('Pink Man'),
  virtualGuy('Virtual Guy');

  final String name;
  const PlayerCharacter(this.name);
}

class Player extends SpriteAnimationGroupComponent with HasGameReference<PixelAdventure>, KeyboardHandler, CollisionCallbacks {
  final PlayerCharacter character;
  Player({this.character = PlayerCharacter.maskDude, super.position});

  // these are the correct x values for the player, one for the left side of the hitbox and one for the right side of the hitbox
  late double hitboxPositionLeftX;
  late double hitboxPositionRightX;

  // animation settings
  final double _stepTime = 0.05;
  final Vector2 _textureSize = Vector2(32, 32);
  final Vector2 _textureSizeSpecial = Vector2(96, 96);
  final String _path = 'Main Characters/';
  final String _pathEnd = ' (32x32).png';
  final String _pathEndSpecial = ' (96x96).png';

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

  // hit by trap
  bool _gotHit = false;

  // finish checkpoint
  bool _hasReachedCheckpoint = false;

  // startposition in a level
  Vector2 _startPosition = Vector2.zero();

  // actual hitbox
  CustomHitbox hitbox = CustomHitbox(offsetX: 10, offsetY: 4, width: 14, height: 28);

  // list of all collision elements
  List<CollisionBlock> collisionBlocks = [];

  // joystick for mobile
  JoystickComponent? _joystick;
  JoystickDirection _lastJoystickDirection = JoystickDirection.idle;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _updateHitboxEdges();
    _loadAllAnimations();

    return super.onLoad();
  }

  @override
  void update(double dt) {
    accumulatedTime += dt;
    while (accumulatedTime >= fixedDT) {
      _updateHitboxEdges();
      if (!_gotHit && !_hasReachedCheckpoint) {
        _updatePlayerState();
        _updatePlayerMovement(fixedDT);
        if (_joystick != null) updateJoystick();
        _checkHorizontalCollisions();
        _applyGravity(fixedDT);
        _checkVerticalCollisions();
      }
      accumulatedTime -= fixedDT;
    }
    super.update(dt);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (_hasReachedCheckpoint || _gotHit) return super.onCollisionStart(intersectionPoints, other);
    final intersectionPoint = intersectionPoints.first;
    switch (other) {
      case Fruit():
        other.collidedWithPlayer();
        break;
      case Saw():
        _respawn();
        break;
      case SawCircleSingleSaw():
        _respawn();
        break;
      case Spikes():
        _respawn();
        break;
      case Chicken():
        other.collidedWithPlayer(intersectionPoint);
        break;
      case BlueBird():
        other.collidedWithPlayer(intersectionPoint);
        break;
      case Mushroom():
        other.collidedWithPlayer(intersectionPoint);
        break;
      case Slime():
        other.collidedWithPlayer(intersectionPoint);
        break;
      case SlimeParticle():
        _respawn();
        break;
      case Snail():
        other.collidedWithPlayer(intersectionPoint);
        break;
      case Turtle():
        other.collidedWithPlayer(intersectionPoint);
        break;
      case Trampoline():
        other.collidedWithPlayer(intersectionPoint);
        break;
      case Plant():
        other.collidedWithPlayer(intersectionPoint);
        break;
      case PlantBullet():
        other.collidedWithPlayer(intersectionPoint);
        _respawn();
        break;
      case Trunk():
        other.collidedWithPlayer(intersectionPoint);
        break;
      case TrunkBullet():
        other.collidedWithPlayer(intersectionPoint);
        _respawn();
        break;
      case Checkpoint():
        other.collidedWithPlayer();
        _reachedCheckpoint();
        break;
      case FanAirStream():
        other.collidedWithPlayer(intersectionPoint);
        break;
    }

    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (_hasReachedCheckpoint || _gotHit) super.onCollisionEnd(other);
    switch (other) {
      case MovingPlatform():
        other.collidedWithPlayerEnd();
        break;
      case FanAirStream():
        other.collidedWithPlayerEnd();
        break;
    }

    super.onCollisionEnd(other);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (_hasReachedCheckpoint || _gotHit) super.onCollision(intersectionPoints, other);
    final intersectionPoint = intersectionPoints.first;
    switch (other) {
      // Fire uses onCollision because it only triggers when the player touches its bottom edge, check in Fire
      case FireTrap():
        other.collidedWithPlayer(intersectionPoint);
        break;
      case Ghost():
        other.collidedWithPlayer(intersectionPoint);
        break;
      case MovingPlatform():
        other.collidedWithPlayer(intersectionPoint);
        break;
    }

    super.onCollision(intersectionPoints, other);
  }

  // use keyboard for input
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
    _startPosition = Vector2(position.x, position.y);
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

  void _loadAllAnimations() {
    final loadAnimation = spriteAnimationWrapper<PlayerState>(game, '$_path${character.name}/', _pathEnd, _stepTime, _textureSize);
    final loadSpecialAnimation = spriteAnimationWrapper<PlayerState>(game, _path, _pathEndSpecial, _stepTime, _textureSizeSpecial);

    // list of all animations
    animations = {for (var state in PlayerState.values) state: state.special ? loadSpecialAnimation(state) : loadAnimation(state)};

    // set current animation state
    current = PlayerState.idle;
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
          break;
        } else if (velocity.y < 0) {
          velocity.y = 0;
          position.y = block.y + block.height - hitbox.offsetY;
          // double jump not possible if the player hits their head
          canDoubleJump = false;
          break;
        }
      }
    }
  }

  void _respawn() {
    velocity.y = 0;
    _gotHit = true;
    current = PlayerState.hit;
    final hitAnimation = animationTickers![PlayerState.hit]!;
    hitAnimation.completed.whenComplete(() {
      current = PlayerState.appearing;
      scale.x = 1;
      position = _startPosition - Vector2.all(32);
      hitAnimation.reset();
      final appearingAnimation = animationTickers![PlayerState.appearing]!;
      appearingAnimation.completed.whenComplete(() {
        position = _startPosition;
        current = PlayerState.idle;
        _gotHit = false;
        appearingAnimation.reset();
      });
    });
  }

  void _reachedCheckpoint() {
    _hasReachedCheckpoint = true;
    current = PlayerState.disappearing;
    if (scale.x > 0) {
      position = position - Vector2.all(32);
    } else if (scale.x < 0) {
      position = position + Vector2(32, -32);
    }
    final disappearingAnimation = animationTickers![PlayerState.disappearing]!;
    disappearingAnimation.completed.whenComplete(() {
      position = Vector2.all(-200);
      Future.delayed(Duration(seconds: 3), () async {
        current = PlayerState.idle;
        _hasReachedCheckpoint = false;
        await game.loadNextLevel();
      });
    });
  }

  void collidedWithEnemy() {
    _respawn();
  }

  void bounceUp({double jumpForce = 260, bool resetDoubleJump = true}) {
    velocity.y = -jumpForce;
    isOnGround = false;
    if (resetDoubleJump) {
      canDoubleJump = true;
    }
  }

  void _updateHitboxEdges() {
    hitboxPositionLeftX = (scale.x > 0) ? x + hitbox.offsetX : x - hitbox.offsetX - hitbox.width;
    hitboxPositionRightX = hitboxPositionLeftX + hitbox.width;
  }
}
