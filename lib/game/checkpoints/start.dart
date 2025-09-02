import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/level/collision_block.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/utils/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum StartState implements AnimationState {
  idle('Idle', 1),
  moving('Moving', 8, loop: false);

  @override
  final String name;
  @override
  final int amount;
  @override
  final bool loop;

  const StartState(this.name, this.amount, {this.loop = true});
}

class Start extends SpriteAnimationGroupComponent with HasGameReference<PixelAdventure>, CollisionCallbacks, CollisionBlock {
  Start({required super.position}) : super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2.all(64);

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(26, 56), size: Vector2(34, 8));

  // animation settings
  static final Vector2 _textureSize = Vector2.all(64);
  static const String _path = 'Items/Checkpoints/Start/';
  static const String _pathEnd = ' (64x64).png';

  // reached
  bool reached = false;

  // player start point
  late final Vector2 playerPosition;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllSpriteAnimations();
    _setUpPlayerPosition();
    return super.onLoad();
  }

  void _initialSetup() {
    // debug
    if (game.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
      _hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    priority = PixelAdventure.trapLayerLevel;
    _hitbox.collisionType = CollisionType.passive;
    add(_hitbox);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<StartState>(game, _path, _pathEnd, PixelAdventure.stepTime, _textureSize);
    animations = {for (var state in StartState.values) state: loadAnimation(state)};
    current = StartState.idle;
  }

  void _setUpPlayerPosition() {
    playerPosition = Vector2(
      position.x + _hitbox.x + (_hitbox.width - Player.gridSize.x) / 2,
      position.y + height - _hitbox.height - Player.gridSize.y,
    );
  }

  @override
  ShapeHitbox get solidHitbox => _hitbox;
}
