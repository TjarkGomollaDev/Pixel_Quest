import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/components/level/level.dart';
import 'package:pixel_adventure/components/level/player.dart';

class PixelAdventure extends FlameGame with HasKeyboardHandlerComponents, DragCallbacks, HasCollisionDetection {
  @override
  Color backgroundColor() => const Color(0xFF211F30);

  // levels
  late Level level;
  late CameraComponent cam;
  final List<LevelName> levels = LevelName.values;
  int currentLevelIndex = 2;

  // character
  final List<PlayerCharacter> characters = PlayerCharacter.values;
  int yourCharacterIndex = 0;

  // mobile
  bool showMobileControls = false;

  // custom debug mode
  bool customDebug = true;

  // in which layers the various objects are rendered
  static const int mapLayerLevel = 0;
  static const int backgroundLayerLevel = -5;
  static const int enemieLayerLevel = 10;
  static const int enemieBulletLayerLevel = 9;
  static const int enemieParticleLayerLevel = 8;
  static const int trapLayerLevel = 2;
  static const int trapHintsLayerLevel = 1;
  static const int trapBehindLayerLevel = -1;
  static const int collectiblesLayerLevel = 5;
  static const int playerLayerLevel = 20;

  // tile size
  final double tileSize = 16;

  // collision
  final double toleranceEnemieCollision = 5;

  // offset for all objects with a range, allowing the player to stand at the exact border of the range without causing a collision
  // that's a matter of taste and can of course simply be set to 0
  final double rangeOffset = 1;

  @override
  Future<void> onLoad() async {
    // load all images into cache
    await images.loadAllImages();
    _loadLevel();

    return super.onLoad();
  }

  Future<void> loadNextLevel() async {
    if (currentLevelIndex < levels.length - 1) {
      currentLevelIndex++;
      await _removeLevel();
      _loadLevel();
    } else {
      // no more levels
    }
  }

  Future<void> _removeLevel() async {
    remove(level);
    await level.removed;
    remove(cam);
    await cam.removed;
  }

  void _loadLevel() {
    level = Level(levelName: levels[currentLevelIndex]);

    cam = CameraComponent.withFixedResolution(width: 640, height: 368, world: level);
    cam.viewfinder.anchor = Anchor.topLeft;
    cam.priority = 0;

    addAll([cam, level]);
  }
}
