import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_quest/app_theme.dart';
import 'package:pixel_quest/game/collision/world_collision.dart';
import 'package:pixel_quest/game/level/player/player.dart';
import 'package:pixel_quest/game/utils/animation_state.dart';
import 'package:pixel_quest/game/utils/load_sprites.dart';
import 'package:pixel_quest/game/game_settings.dart';
import 'package:pixel_quest/game/game.dart';

enum _StartState implements AnimationState {
  idle('Idle', 1),
  moving('Moving', 8, loop: false);

  @override
  final String fileName;
  @override
  final int amount;
  @override
  final bool loop;

  const _StartState(this.fileName, this.amount, {this.loop = true});
}

/// Level start checkpoint that defines the player spawn point.
///
/// Exposes a computed `playerPosition` so the level can spawn the player in a
/// consistent spot relative to the start marker’s hitbox.
class Start extends SpriteAnimationGroupComponent with HasGameReference<PixelQuest>, CollisionCallbacks, WorldCollision {
  Start({required super.position}) : super(size: gridSize) {
    // is already called her so that we have immediate access to the player position from outside
    _setUpPlayerPosition();
  }

  // size
  static final Vector2 gridSize = .all(64);

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(26, 56), size: Vector2(34, 8));

  // animation settings
  static final Vector2 _textureSize = .all(64);
  static const String _path = 'Items/Checkpoints/Start/';
  static const String _pathEnd = ' (64x64).png';

  // player start point
  late final Vector2 _playerPosition;

  // getter
  Vector2 get playerPosition => _playerPosition;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllSpriteAnimations();
    return super.onLoad();
  }

  @override
  ShapeHitbox get worldHitbox => _hitbox;

  void _initialSetup() {
    // debug
    if (GameSettings.showDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
      _hitbox.debugColor = AppTheme.debugColorWorldBlock;
    }

    // general
    priority = GameSettings.trapLayerLevel;
    _hitbox.collisionType = .passive;
    add(_hitbox);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<_StartState>(game, _path, _pathEnd, GameSettings.stepTime, _textureSize);
    animations = {for (final state in _StartState.values) state: loadAnimation(state)};
    current = _StartState.idle;
  }

  void _setUpPlayerPosition() {
    _playerPosition = Vector2(
      position.x + _hitbox.x + (_hitbox.width - Player.gridSize.x) / 2,
      position.y + height - _hitbox.height - Player.gridSize.y,
    );
  }
}
