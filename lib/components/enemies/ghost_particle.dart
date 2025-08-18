import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/components/enemies/ghost.dart';
import 'package:pixel_adventure/components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class GhostParticle extends SpriteAnimationComponent with HasGameReference<PixelAdventure> {
  final Ghost owner;
  final bool spawnOnLeftSide;

  GhostParticle({required this.owner, required this.spawnOnLeftSide, super.position}) : super(size: Vector2(16, 16));

  // animation settings
  final double _stepTime = 0.07;
  final Vector2 _textureSize = Vector2(16, 16);
  final int _amount = 4;
  final String _path = 'Enemies/Ghost/Ghost Particles (16x16).png';

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
    }

    // general
    priority = PixelAdventure.enemieParticleLayerLevel;
  }

  void _loadAndPlayAnimationOneTime() {
    animation = loadSpriteAnimation(game, _path, _amount, _stepTime, _textureSize, loop: false);
    if (spawnOnLeftSide) flipHorizontallyAroundCenter();
    animationTicker!.completed.then((_) => removeFromParent());
  }
}
