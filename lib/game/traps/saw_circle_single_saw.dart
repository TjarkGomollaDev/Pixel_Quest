import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_quest/app_theme.dart';
import 'package:pixel_quest/data/audio/ambient_loop_emitter.dart';
import 'package:pixel_quest/data/audio/audio_center.dart';
import 'package:pixel_quest/game/collision/collision.dart';
import 'package:pixel_quest/game/collision/entity_collision.dart';
import 'package:pixel_quest/game/hud/mini%20map/entity_on_mini_map.dart';
import 'package:pixel_quest/game/level/player/player.dart';
import 'package:pixel_quest/game/utils/load_sprites.dart';
import 'package:pixel_quest/game/game_settings.dart';
import 'package:pixel_quest/game/game.dart';

/// A single saw unit used inside a [SawCircleComponent].
///
/// The saw is rendered as a rotating sprite animation with a circular hitbox,
/// anchored at its center. Depending on configuration, it can be mirrored
/// to represent clockwise or counterclockwise motion within the circular trap.
///
/// This component does not move by itself, but is positioned and updated
/// by its parent [SawCircleComponent]. It acts as a passive collision area
/// that can interact with the [Player].
class SawCircleSingleSaw extends SpriteAnimationComponent
    with EntityCollision, EntityOnMiniMap, HasGameReference<PixelQuest>, AmbientLoopEmitter {
  // constructor parameters
  final bool _clockwise;
  final Player _player;

  SawCircleSingleSaw({required bool clockwise, required Player player, required super.position})
    : _clockwise = clockwise,
      _player = player,
      super(size: gridSize) {
    // marker is set here because the single saw is not added directly to the level,
    // but via the parent SawCircleComponent, and we need direct access before onLoad()
    _setUpMarker();
  }

  // size
  static final Vector2 gridSize = Vector2.all(32);

  // actual hitbox
  final CircleHitbox _hitbox = CircleHitbox(radius: gridSize.x / 2);

  // animation settings
  static const double _stepTime = 0.03;
  static final Vector2 _textureSize = Vector2.all(38);
  static const int _amount = 8;
  static const String _path = 'Traps/Saw/On (38x38).png';

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadSpriteAnimation();
    return super.onLoad();
  }

  @override
  void onEntityCollision(CollisionSide collisionSide) => _player.collidedWithEnemy(collisionSide);

  @override
  ShapeHitbox get entityHitbox => _hitbox;

  void _initialSetup() {
    // debug
    if (GameSettings.customDebugMode) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
      _hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    _hitbox.collisionType = CollisionType.passive;
    anchor = Anchor.center;
    add(_hitbox);
    configureAmbientLoop(loop: LoopSfx.saw, hitbox: _hitbox);
  }

  void _setUpMarker() => marker = EntityMiniMapMarker(
    size: _hitbox.height,
    color: AppTheme.entityMarkerSpecial,
    layer: EntityMiniMapMarkerLayer.behindForeground,
  );

  void _loadSpriteAnimation() {
    animation = loadSpriteAnimation(game, _path, _amount, _stepTime, _textureSize);
    if (_clockwise) flipHorizontally();
  }
}
