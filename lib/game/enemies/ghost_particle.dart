import 'package:flame/components.dart';
import 'package:pixel_quest/app_theme.dart';
import 'package:pixel_quest/game/enemies/ghost.dart';
import 'package:pixel_quest/game/utils/debug_components.dart';
import 'package:pixel_quest/game/utils/load_sprites.dart';
import 'package:pixel_quest/game/game_settings.dart';
import 'package:pixel_quest/game/game.dart';

/// A short-lived visual effect spawned by a [Ghost].
///
/// Plays a small particle animation once (optionally flipped) and removes itself
/// when the animation finishes.
class GhostParticle extends SpriteAnimationComponent with HasGameReference<PixelQuest>, DebugOutlineOnly {
  // constructor parameters
  final Ghost _owner;
  final bool _spawnOnLeftSide;

  GhostParticle({required Ghost owner, required bool spawnOnLeftSide, required super.position})
    : _owner = owner,
      _spawnOnLeftSide = spawnOnLeftSide,
      super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2.all(16);

  // animation settings
  static final Vector2 _textureSize = Vector2.all(16);
  static const int _amount = 4;
  static const String _path = 'Enemies/Ghost/Ghost Particles (16x16).png';

  // getter
  Ghost get owner => _owner;

  @override
  Future<void> onLoad() async {
    _initialSetup();
    _loadAndPlayAnimationOneTime();
    await super.onLoad();
  }

  void _initialSetup() {
    // debug
    if (GameSettings.customDebugMode) {
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
