import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/collision/collision.dart';
import 'package:pixel_adventure/game/collision/entity_collision.dart';
import 'package:pixel_adventure/game/hud/entity_on_mini_map.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/utils/animation_state.dart';
import 'package:pixel_adventure/game/utils/grid.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_quest.dart';

enum SpikeHeadState implements AnimationState {
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

  const SpikeHeadState(this.fileName, this.amount, {this.loop = true});
}

class SpikeHead extends PositionComponent
    with FixedGridOriginalSizeGroupAnimation, EntityCollision, EntityOnMiniMap, HasGameReference<PixelQuest> {
  // constructor parameters
  final double _offsetPos;
  double _delay;
  final Player _player;

  SpikeHead({required double offsetPos, required double delay, required Player player, required super.position})
    : _offsetPos = offsetPos,
      _player = player,
      _delay = delay,
      super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2.all(64);

  // actual hitbox
  late final CompositeHitbox _hitbox;

  // animation settings
  static final Vector2 _textureSize = Vector2(54, 52);
  static const String _path = 'Traps/Spike Head/';
  static const String _pathEnd = ' (54x52).png';

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
    _setUpHitbox();
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

  void _setUpHitbox() {
    _hitbox = CompositeHitbox(
      position: Vector2(10, 10),
      size: Vector2(44, 44),
      children: [
        _makeHitbox(Vector2(8, 0), Vector2(28, 8)), // top
        _makeHitbox(Vector2(36, 8), Vector2(8, 28)), // right
        _makeHitbox(Vector2(8, 36), Vector2(28, 8)), // bottom
        _makeHitbox(Vector2(0, 8), Vector2(8, 28)), // left
      ],
    );
  }

  RectangleHitbox _makeHitbox(Vector2 position, Vector2 size) =>
      RectangleHitbox(position: position, size: size, collisionType: CollisionType.passive)..debugColor = AppTheme.debugColorTrapHitbox;

  void _initialSetup() {
    // debug
    if (GameSettings.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
      _hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    priority = GameSettings.trapLayerLevel;
    add(_hitbox);
    marker = EntityMiniMapMarker(size: _hitbox.height, type: EntityMiniMapMarkerType.square, color: AppTheme.entityMarkerSpecial);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<SpikeHeadState>(game, _path, _pathEnd, GameSettings.stepTime, _textureSize);
    final animations = {for (var state in SpikeHeadState.values) state: loadAnimation(state)};
    addAnimationGroupComponent(textureSize: _textureSize, animations: animations, current: SpikeHeadState.idle, isBottomCenter: false);
  }

  void _setUpRange() {
    _rangeNeg = position.y;
    _rangePos = position.y + height + _offsetPos * GameSettings.tileSize;
  }

  void _setUpActualBorders() {
    _topBorder = _rangeNeg - _hitbox.position.y;
    _bottomtBorder = _rangePos - _hitbox.position.y - _hitbox.height;

    // only relevant for mini map not for the actual functionality
    yMoveRange = Vector2(_topBorder + _hitbox.position.y + _hitbox.height / 2, _bottomtBorder + _hitbox.position.y + _hitbox.height / 2);
  }

  void _correctingStartPosition() {
    position.y = _topBorder;
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
      final newPositionY = position.y + _moveDirection * _moveSpeed * dt;
      position.y = newPositionY.clamp(_topBorder, _bottomtBorder);
    }
  }

  Future<void> _changeDirection(int newDirection) async {
    _directionChangePending = true;
    final SpikeHeadState hitAnimation;
    if (newDirection == 1) {
      hitAnimation = SpikeHeadState.topHit;
      _moveSpeed = _moveSpeedDown;
    } else {
      hitAnimation = SpikeHeadState.bottomHit;
      _moveSpeed = _moveSpeedUp;
    }
    _moveDirection = newDirection;
    animationGroupComponent.current = hitAnimation;
    await animationGroupComponent.animationTickers![hitAnimation]!.completed;
    animationGroupComponent.current = SpikeHeadState.idle;
    await Future.delayed((newDirection == 1 ? _delayAtTop : _delayAtBottom) - _delayBlinkBeforeMove);
    animationGroupComponent.current = SpikeHeadState.blink;
    await animationGroupComponent.animationTickers![SpikeHeadState.blink]!.completed;
    animationGroupComponent.current = SpikeHeadState.idle;
    await Future.delayed(_delayBlinkBeforeMove);
    _directionChangePending = false;
  }

  @override
  void onEntityCollision(CollisionSide collisionSide) => _player.collidedWithEnemy(collisionSide);

  @override
  ShapeHitbox get entityHitbox => RectangleHitbox(position: position + _hitbox.position, size: _hitbox.size);
}
