import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/data/data_center.dart';
import 'package:pixel_adventure/game/hud/pause_route.dart';
import 'package:pixel_adventure/game/level/level.dart';
import 'package:pixel_adventure/game/level/level_list.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/menu/menu_page.dart';

class PixelAdventure extends FlameGame
    with HasKeyboardHandlerComponents, DragCallbacks, HasCollisionDetection, HasPerformanceTracker, SingleGameInstance {
  final DataCenter dataCenter;

  PixelAdventure({required this.dataCenter});

  @override
  Color backgroundColor() => AppTheme.backgroundColor;

  // character
  final List<PlayerCharacter> characters = PlayerCharacter.values;
  int yourCharacterIndex = 0;

  // router
  late final RouterComponent router;

  @override
  Future<void> onLoad() async {
    await _loadAllImagesIntoCache();
    _setUpCam();
    _setUpRouter();
    return super.onLoad();
  }

  Future<void> _loadAllImagesIntoCache() async => await images.loadAllImages();

  void _setUpCam() {
    final fixedHeight = GameSettings.mapHeight - GameSettings.mapBorderWidth * 2;
    final aspectRatio = size.x / size.y;
    final dynamicWidth = fixedHeight * aspectRatio;

    camera = CameraComponent.withFixedResolution(width: dynamicWidth, height: fixedHeight);
    camera.viewfinder.anchor = Anchor(0.25, 0);
    add(camera);
  }

  void setUpCameraForLevel(double mapWidth, Player player) {
    // camera bounds
    final leftBound = size.x * camera.viewfinder.anchor.x + GameSettings.mapBorderWidth;
    final rightBound = size.x * (1 - camera.viewfinder.anchor.x) + GameSettings.mapBorderWidth;
    camera.setBounds(Rectangle.fromLTRB(leftBound, GameSettings.mapBorderWidth, mapWidth - rightBound, GameSettings.mapBorderWidth));

    // viewfinder follows player
    setRefollowForCam(player);
  }

  void setRefollowForCam(Player player) => camera.follow(PlayerHitboxPositionProvider(player), horizontalOnly: true);

  void _setUpRouter() {
    final levelRoutes = {
      RouteNames.menu: Route(MenuPage.new),
      RouteNames.pause: PauseRoute(),
      for (final level in MyLevel.values) level.name: WorldRoute(() => Level(myLvel: level), maintainState: false),
    };

    add(router = RouterComponent(routes: levelRoutes, initialRoute: MyLevel.level_2.name));
  }
}

abstract class RouteNames {
  static const String menu = 'menu';
  static const String pause = 'pause';
}
