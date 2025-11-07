import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/collision/collision.dart';
import 'package:pixel_adventure/game/collision/world_collision.dart';
import 'package:pixel_adventure/game/hud/entity_on_mini_map.dart';
import 'package:pixel_adventure/game/utils/animation_state.dart';
import 'package:pixel_adventure/game/utils/grid.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_quest.dart';

enum RockHeadState implements AnimationState {
  idle('Idle', 1),
  blink('Blink', 4, loop: false),
  topHit('Top Hit', 4, loop: false),
  bottomHit('Bottom Hit', 4, loop: false);

  @override
  final String fileName;
  @override
  final int amount;
  @override
  final bool loop;

  const RockHeadState(this.fileName, this.amount, {this.loop = true});
}

/// A heavy stone trap that repeatedly slams down and retracts vertically
/// within a defined range.
///
/// The RockHead starts at the top of its range and drops quickly with high
/// downward speed, then retracts upward more slowly. At both the top and
/// bottom borders it plays a hit animation before pausing for a short delay,
/// creating a rhythmic crushing pattern.
class RockHead extends PositionComponent
    with FixedGridOriginalSizeGroupAnimation, HasGameReference<PixelQuest>, WorldCollision, FastCollision, EntityOnMiniMap {
  // constructor parameters
  final double _offsetPos;
  double _delay;

  RockHead({required double offsetPos, required double delay, required super.position})
    : _offsetPos = offsetPos,
      _delay = delay,
      super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2.all(48);

  // only relevant for world collision in the player
  late double _previousY;

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(8, 8), size: Vector2(32, 32));

  // animation settings
  static final Vector2 _textureSize = Vector2(42, 42);
  static const String _path = 'Traps/Rock Head/';
  static const String _pathEnd = ' (42x42).png';

  // range
  late final double _rangeNeg;
  late final double _rangePos;

  // actual borders that compensate for the hitbox
  late final double _topBorder;
  late final double _bottomtBorder;

  // movement
  int _moveDirection = 1;
  late double _moveSpeed;
  final double _moveSpeedUp = 100; // [Adjustable]
  final double _moveSpeedDown = 850; // [Adjustable]

  // direction change
  bool _directionChangePending = false;
  final Duration _delayAtBottom = Duration(milliseconds: 1200); // [Adjustable]
  final Duration _delayAtTop = Duration(milliseconds: 2000); // [Adjustable]
  final Duration _delayBlinkBeforeMove = Duration(milliseconds: 400); // [Adjustable]

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllSpriteAnimations();
    _setUpRange();
    _setUpActualBorders();
    _correctingStartPosition();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (_delay > 0) {
      _delay -= dt;
      return super.update(dt);
    }
    if (!_directionChangePending) _movement(dt);
    super.update(dt);
  }

  void _initialSetup() {
    // debug
    if (GameSettings.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
      _hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    priority = GameSettings.trapLayerLevel;
    _hitbox.collisionType = CollisionType.passive;
    add(_hitbox);
    marker = EntityMiniMapMarker(size: _hitbox.height, type: EntityMiniMapMarkerType.square, color: AppTheme.entityMarkerSpecial);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<RockHeadState>(game, _path, _pathEnd, GameSettings.stepTime, _textureSize);
    final animations = {for (var state in RockHeadState.values) state: loadAnimation(state)};
    addAnimationGroupComponent(textureSize: _textureSize, animations: animations, current: RockHeadState.idle, isBottomCenter: false);
  }

  void _setUpRange() {
    _rangeNeg = position.y;
    _rangePos = position.y + height + _offsetPos * GameSettings.tileSize;
  }

  void _setUpActualBorders() {
    _topBorder = _rangeNeg - _hitbox.position.y;
    _bottomtBorder = _rangePos - height + _hitbox.position.y;
  }

  void _correctingStartPosition() {
    position.y = _topBorder;
    _previousY = position.y;
    _moveSpeed = _moveSpeedDown;
  }

  void _movement(double dt) {
    // change move direction if we reached the borders
    if (position.y >= _bottomtBorder && _moveDirection != -1) {
      _changeDirection(-1);
    } else if (position.y <= _topBorder && _moveDirection != 1) {
      _changeDirection(1);
    } else {
      // movement
      _previousY = position.y;
      final newPositionY = position.y + _moveDirection * _moveSpeed * dt;
      position.y = newPositionY.clamp(_topBorder, _bottomtBorder);
    }
  }

  Future<void> _changeDirection(int newDirection) async {
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
    animationGroupComponent.current = hitAnimation;
    await animationGroupComponent.animationTickers![hitAnimation]!.completed;
    animationGroupComponent.current = RockHeadState.idle;
    await Future.delayed((newDirection == 1 ? _delayAtTop : _delayAtBottom) - _delayBlinkBeforeMove);
    animationGroupComponent.current = RockHeadState.blink;
    await animationGroupComponent.animationTickers![RockHeadState.blink]!.completed;
    animationGroupComponent.current = RockHeadState.idle;
    await Future.delayed(_delayBlinkBeforeMove);
    _directionChangePending = false;
  }

  @override
  ShapeHitbox get worldHitbox => _hitbox;

  @override
  double get previousY => _previousY;
}
