import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game_components/level/player.dart';
import 'package:pixel_adventure/game_components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class SlimeParticle extends SpriteAnimationComponent with PlayerCollision, HasGameReference<PixelAdventure> {
  // constructor parameters
  final bool spawnOnLeftSide;
  final Player player;

  SlimeParticle({required this.spawnOnLeftSide, required this.player, required super.position}) : super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2.all(16);

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(5, 7), size: Vector2(6, 3));

  // animation settings
  static const double _stepTime = 0.07;
  static final Vector2 _textureSize = Vector2.all(16);
  static const int _amount = 4;
  static const String _path = 'Enemies/Slime/Particles (16x16).png';

  @override
  Future<void> onLoad() async {
    _initialSetup();
    _loadAndPlayAnimationOneTime();
    await super.onLoad();
  }

  void _initialSetup() {
    // debug
    if (game.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorEnemie;
      _hitbox.debugColor = AppTheme.debugColorEnemieHitbox;
    }

    // general
    priority = PixelAdventure.enemieParticleLayerLevel;
    _hitbox.collisionType = CollisionType.passive;
    add(_hitbox);
  }

  Future<void> _loadAndPlayAnimationOneTime() async {
    animation = loadSpriteAnimation(game, _path, _amount, _stepTime, _textureSize, loop: false);
    if (!spawnOnLeftSide) flipHorizontallyAroundCenter();

    // stop animation at first frame
    animationTicker?.currentIndex = 0;
    animationTicker?.paused = true;
    await Future.delayed(const Duration(seconds: 4));

    // then let the animation continue running
    animationTicker?.paused = false;
    animationTicker!.completed.then((_) => removeFromParent());
  }

  @override
  void onPlayerCollisionStart(Vector2 intersectionPoint) => player.collidedWithEnemy();
}
