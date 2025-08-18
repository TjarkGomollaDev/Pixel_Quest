import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class SlimeParticle extends SpriteAnimationComponent with HasGameReference<PixelAdventure> {
  final bool spawnOnLeftSide;

  SlimeParticle({required this.spawnOnLeftSide, required super.position}) : super(size: fixedSize);

  // size
  static final Vector2 fixedSize = Vector2.all(16);

  // actual hitbox
  final RectangleHitbox hitbox = RectangleHitbox(position: Vector2(5, 7), size: Vector2(6, 3));

  // animation settings
  final double _stepTime = 0.07;
  final Vector2 _textureSize = Vector2(16, 16);
  final int _amount = 4;
  final String _path = 'Enemies/Slime/Particles (16x16).png';

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
      hitbox.debugColor = AppTheme.debugColorEnemieHitbox;
    }

    // general
    priority = PixelAdventure.enemieParticleLayerLevel;
    hitbox.collisionType = CollisionType.passive;
    add(hitbox);
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
}
