import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/enemies/ghost.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class GhostParticle extends SpriteAnimationComponent with HasGameReference<PixelAdventure> {
  // constructor parameters
  final Ghost owner; // has to be public
  final bool _spawnOnLeftSide;

  GhostParticle({required this.owner, required bool spawnOnLeftSide, required super.position})
    : _spawnOnLeftSide = spawnOnLeftSide,
      super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2.all(16);

  // animation settings
  static final Vector2 _textureSize = Vector2.all(16);
  static const int _amount = 4;
  static const String _path = 'Enemies/Ghost/Ghost Particles (16x16).png';

  @override
  Future<void> onLoad() async {
    _initialSetup();
    _loadAndPlayAnimationOneTime();
    await super.onLoad();
  }

  void _initialSetup() {
    // debug
    if (GameSettings.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorParticle;
    }

    // general
    priority = GameSettings.enemieParticleLayerLevel;
  }

  void _loadAndPlayAnimationOneTime() {
    animation = loadSpriteAnimation(game, _path, _amount, GameSettings.stepTime, _textureSize, loop: false);
    if (_spawnOnLeftSide) flipHorizontallyAroundCenter();
    animationTicker!.completed.then((_) => removeFromParent());
  }
}
