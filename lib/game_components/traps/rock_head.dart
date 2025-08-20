import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game_components/level/player.dart';
import 'package:pixel_adventure/game_components/collision_block.dart';
import 'package:pixel_adventure/game_components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum RockHeadState implements AnimationState {
  idle('Idle', 1),
  topHit('Top Hit', 4, loop: false),
  bottomHit('Bottom Hit', 4, loop: false);

  @override
  final String name;
  @override
  final int amount;
  @override
  final bool loop;

  const RockHeadState(this.name, this.amount, {this.loop = true});
}

class RockHead extends SpriteAnimationGroupComponent with HasGameReference<PixelAdventure>, CollisionCallbacks {
  final double offsetPos;

  RockHead({required this.offsetPos, required super.position, required super.size, required Player player, required CollisionBlock block})
    : _player = player,
      _block = block;

  // actual hitbox
  final RectangleHitbox hitbox = RectangleHitbox(position: Vector2(6, 6), size: Vector2(36, 36));

  // player ref
  final Player _player;

  // collision block ref
  final CollisionBlock _block;

  // animation settings
  final double _stepTime = 0.05;
  final Vector2 _textureSize = Vector2(42, 42);
  final String _path = 'Traps/Rock Head/';
  final String _pathEnd = ' (42x42).png';

  // range
  late final double _rangeNeg;
  late final double _rangePos;

  // actual borders that compensate for the hitbox
  late final double _topBorder;
  late final double _bottomtBorder;

  // movement
  double _moveDirection = 1;
  final double _moveSpeedUp = 100; // [Adjustable]
  final double _moveSpeedDown = 850; // [Adjustable]
  late double _moveSpeed;

  // direction change
  bool _directionChangePending = false;
  final Duration _delayAtBottom = Duration(seconds: 1); // [Adjustable]
  final Duration _delayAtTop = Duration(seconds: 2); // [Adjustable]

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllSpriteAnimations();
    _setUpRange();
    _setUpActualBorders();
    _correctingStartPosition();
    _setUpCollisionBlock();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (!_directionChangePending) _movement(dt);
    super.update(dt);
  }

  void _initialSetup() {
    // debug
    if (game.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
      hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    priority = PixelAdventure.trapLayerLevel;
    hitbox.collisionType = CollisionType.passive;
    add(hitbox);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<RockHeadState>(game, _path, _pathEnd, _stepTime, _textureSize);

    // list of all animations
    animations = {for (var state in RockHeadState.values) state: loadAnimation(state)};

    // set current animation state
    current = RockHeadState.idle;
  }

  void _setUpRange() {
    _rangeNeg = position.y;
    _rangePos = position.y + height + offsetPos * game.tileSize;
  }

  void _setUpActualBorders() {
    _topBorder = _rangeNeg - hitbox.position.y;
    _bottomtBorder = _rangePos - height + hitbox.position.y;
  }

  void _correctingStartPosition() {
    position.y = _topBorder;
    _moveSpeed = _moveSpeedDown;
  }

  void _setUpCollisionBlock() {
    _block.size = hitbox.size;
    _block.position = position + hitbox.position;
  }

  void _movement(double dt) {
    // change move direction if we reached the borders
    if (position.y >= _bottomtBorder && _moveDirection != -1) {
      _changeDirection(-1);
    } else if (position.y <= _topBorder && _moveDirection != 1) {
      _changeDirection(1);
    } else {
      // movement
      final newPositionY = position.y + _moveDirection * _moveSpeed * dt;
      position.y = newPositionY.clamp(_topBorder, _bottomtBorder);
      _block.y = position.y + hitbox.position.y;
    }
  }

  Future<void> _changeDirection(double newDirection) async {
    _directionChangePending = true;
    final RockHeadState hitAnimation;
    if (newDirection == 1) {
      hitAnimation = RockHeadState.topHit;
      _moveSpeed = _moveSpeedDown;
    } else {
      hitAnimation = RockHeadState.bottomHit;
      _moveSpeed = _moveSpeedUp;
    }
    _moveDirection = newDirection;
    current = hitAnimation;
    await animationTickers![hitAnimation]!.completed;
    current = RockHeadState.idle;
    await Future.delayed(newDirection == 1 ? _delayAtTop : _delayAtBottom);
    _directionChangePending = false;
  }
}
