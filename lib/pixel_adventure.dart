import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/hud/pause_route.dart';
import 'package:pixel_adventure/game/level/level.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/menu/menu_page.dart';

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
  final bool customDebug = false;

  // in which layers the various objects are rendered
  static const int mapLayerLevel = 0;
  static const int backgroundLayerLevel = -5;
  static const int enemieLayerLevel = 10;
  static const int enemieBulletLayerLevel = 9;
  static const int enemieParticleLayerLevel = 8;
  static const int trapLayerLevel = 2;
  static const int trapParticlesLayerLevel = 1;
  static const int trapBehindLayerLevel = -1;
  static const int collectiblesLayerLevel = 5;
  static const int spotlightAnimationLayer = 18;
  static const int spotlightAnimationStarsLayer = 18;
  static const int playerLayerLevel = 20;
  static const int hudElementsLayer = 30;

  // default spawn values
  static const bool isLeftDefault = true;
  static const bool isVerticalDefault = false;
  static const bool doubleShotDefault = false;
  static const bool doubleSawDefault = false;
  static const bool clockwiseDefault = false;
  static const bool fanAlwaysOnDefault = true;
  static const int sideDefault = 1;
  static const double offsetNegDefault = 1.0;
  static const double offsetPosDefault = 1.0;
  static const double extandNegAttackDefault = 0.0;
  static const double extandPosAttackDefault = 0.0;
  static const int circleWidthDefault = 6;
  static const int circleHeightDefault = 4;

  static const int spikedBallRadiusDefault = 3;
  static const bool spikedBallStartLeft = false;
  static const int spikedBallSwingArcDec = 170;
  static const int spikedBallSwingSpeed = 320;

  // tiled map dimensions
  static const double tileSize = 16;
  static const double mapHeight = 320;
  static const double mapBorder = tileSize / 2;

  // animation settings
  static const double stepTime = 0.05;
  static const double finishSpotlightAnimationRadius = 60;

  // the next checkpoint is only activated if it is further to the right in the level than the current one plus a buffer
  static const double checkpointBufferZone = 40;

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
    final fixedHeight = mapHeight - mapBorder * 2;
    final aspectRatio = size.x / size.y;
    final dynamicWidth = fixedHeight * aspectRatio;

    camera = CameraComponent.withFixedResolution(width: dynamicWidth, height: fixedHeight);
    camera.viewfinder.anchor = Anchor(0.25, 0);
    add(camera);
  }

  void setUpCameraForLevel(double mapWidth, Player player) {
    // camera bounds
    final leftBound = size.x * camera.viewfinder.anchor.x + mapBorder;
    final rightBound = size.x * (1 - camera.viewfinder.anchor.x) + mapBorder;
    camera.setBounds(Rectangle.fromLTRB(leftBound, mapBorder, mapWidth - rightBound, mapBorder));

    // viewfinder follows player
    camera.follow(PlayerHitboxPositionProvider(player), horizontalOnly: true);
  }

  void _setUpRouter() {
    final levelRoutes = {
      RouteNames.menu: Route(MenuPage.new),
      RouteNames.pause: PauseRoute(),
      for (final level in MyLevel.values) level.name: WorldRoute(() => Level(myLvel: level), maintainState: false),
    };

    add(router = RouterComponent(routes: levelRoutes, initialRoute: MyLevel.level_4.name));
  }
}

abstract class RouteNames {
  static const String menu = 'menu';
  static const String pause = 'pause';
}
