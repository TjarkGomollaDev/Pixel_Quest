import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game_components/level/level.dart';
import 'package:pixel_adventure/game_components/level/player.dart';
import 'package:pixel_adventure/menu/menu_screen.dart';

class PixelAdventure extends FlameGame
    with HasKeyboardHandlerComponents, DragCallbacks, HasCollisionDetection, HasPerformanceTracker, SingleGameInstance {
  @override
  Color backgroundColor() => AppTheme.backgroundColor;

  // character
  final List<PlayerCharacter> characters = PlayerCharacter.values;
  int yourCharacterIndex = 0;

  // router
  late final RouterComponent router;

  // mobile
  final bool showMobileControls = false;

  // custom debug mode
  final bool customDebug = true;

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

  // default spawn values
  static const bool isLeftDefault = true;
  static const bool isVerticalDefault = false;
  static const bool doubleShotDefault = false;
  static const bool doubleSawDefault = false;
  static const bool clockwiseDefault = false;
  static const int sideDefault = 1;
  static const double offsetNegDefault = 1.0;
  static const double offsetPosDefault = 1.0;
  static const double extandNegAttackDefault = 0.0;
  static const double extandPosAttackDefault = 0.0;
  static const int circleWidthDefault = 6;
  static const int circleHeightDefault = 4;

  // tile size
  static const double tileSize = 16;

  // margin HUD elements
  final double hudMargin = 32;
  final double hudMobileControlsSize = 64;

  // collision
  final double toleranceEnemieCollision = 5;

  // offset for all objects with a range, allowing the player to stand at the exact border of the range without causing a collision
  // that's a matter of taste and can of course simply be set to 0
  final double rangeOffset = 1;

  @override
  Future<void> onLoad() async {
    await _loadAllImagesIntoCache();
    _setUpCam();
    _setUpRouter();
    return super.onLoad();
  }

  Future<void> _loadAllImagesIntoCache() async => await images.loadAllImages();

  void _setUpCam() {
    final fixedHeight = 368.0;
    final aspectRatio = size.x / size.y;
    final dynamicWidth = fixedHeight * aspectRatio;

    camera = CameraComponent.withFixedResolution(width: dynamicWidth, height: fixedHeight, world: world);
    camera.viewfinder.anchor = Anchor(0.25, 0);
    add(camera);
  }

  void setCameraBounds(double mapWidth) {
    final leftBound = size.x * camera.viewfinder.anchor.x;
    final rightBound = size.x * (1 - camera.viewfinder.anchor.x);
    camera.setBounds(Rectangle.fromLTRB(leftBound, 0, mapWidth - rightBound, 0));
  }

  void _setUpRouter() {
    final levelRoutes = {
      'menu': Route(MenuScreen.new),
      for (final level in MyLevels.values) level.levelIndex.toString(): WorldRoute(() => Level(name: level), maintainState: false),
    };

    add(router = RouterComponent(routes: levelRoutes, initialRoute: '3'));
  }

  void nextLevel() {
    final index = int.parse(router.currentRoute.name!);
    if (index < MyLevels.values.length) {
      router.pushReplacementNamed((index + 1).toString());
    } else {
      debugPrint('no more level');
    }
  }
}
