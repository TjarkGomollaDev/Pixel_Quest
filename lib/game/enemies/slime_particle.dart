import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_quest/app_theme.dart';
import 'package:pixel_quest/game/collision/collision.dart';
import 'package:pixel_quest/game/collision/entity_collision.dart';
import 'package:pixel_quest/game/enemies/slime.dart';
import 'package:pixel_quest/game/level/player/player.dart';
import 'package:pixel_quest/game/utils/debug_components.dart';
import 'package:pixel_quest/game/utils/load_sprites.dart';
import 'package:pixel_quest/game/game_settings.dart';
import 'package:pixel_quest/game/game.dart';

/// A short-lived particle spawned by a Slime.
///
/// It plays a small one-shot animation (with an optional delayed start),
/// can hurt the player on contact, and removes itself when finished.
class SlimeParticle extends SpriteAnimationComponent with EntityCollision, HasGameReference<PixelQuest>, DebugOutlineOnly {
  // constructor parameters
  final Slime _owner;
  final Player _player;
  final bool _spawnOnLeftSide;

  SlimeParticle({required Slime owner, required bool spawnOnLeftSide, required Player player, required super.position})
    : _owner = owner,
      _spawnOnLeftSide = spawnOnLeftSide,
      _player = player,
      super(size: gridSize);

  // size
  static final Vector2 gridSize = .all(16);

  // actual hitbox
  final DebugRectangleHitbox _hitbox = DebugRectangleHitbox(position: Vector2(5, 7), size: Vector2(6, 3));

  // animation settings
  static final Vector2 _textureSize = .all(16);
  static const int _amount = 4;
  static const String _path = 'Enemies/Slime/Particles (16x16).png';

  // getter
  Slime get owner => _owner;

  @override
  Future<void> onLoad() async {
    _initialSetup();
    _loadAndPlayAnimationOneTime();
    await super.onLoad();
  }

  @override
  void onEntityCollision(CollisionSide collisionSide) => _player.collidedWithEnemy(collisionSide);

  @override
  ShapeHitbox get entityHitbox => _hitbox;

  void _initialSetup() {
    // debug
    if (GameSettings.customDebugMode) {
      debugMode = true;
      debugColor = AppTheme.debugColorParticle;
      _hitbox.debugColor = AppTheme.debugColorParticleHitbox;
    }

    // general
    priority = GameSettings.enemieParticleLayerLevel;
    _hitbox.collisionType = .passive;
    add(_hitbox);
  }

  Future<void> _loadAndPlayAnimationOneTime() async {
    animation = loadSpriteAnimation(game, _path, _amount, GameSettings.stepTime, _textureSize, loop: false);
    if (!_spawnOnLeftSide) flipHorizontallyAroundCenter();

    // stop animation at first frame
    animationTicker?.currentIndex = 0;
    animationTicker?.paused = true;
    await Future.delayed(const Duration(seconds: 4));

    // then let the animation continue running
    animationTicker?.paused = false;
    animationTicker!.completed.then((_) => removeFromParent());
  }
}
