import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:pixel_adventure/data/data_center.dart';
import 'package:pixel_adventure/game/hud/pause_route.dart';
import 'package:pixel_adventure/game/level/level.dart';
import 'package:pixel_adventure/game/level/level_list.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/menu/menu_page.dart';

class PixelQuest extends FlameGame
    with HasKeyboardHandlerComponents, DragCallbacks, HasCollisionDetection, HasPerformanceTracker, SingleGameInstance {
  late final DataCenter dataCenter;

  // router
  late final RouterComponent router;

  @override
  Future<void> onLoad() async {
    final startTime = DateTime.now();
    dataCenter = await DataCenter.init();
    await _loadAllImagesIntoCache();
    _setUpCam();
    _setUpRouter();

    await Future.delayed(Duration(seconds: 3000));
    final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
    final delayMs = 5200;
    if (elapsedMs < delayMs) {
      await Future.delayed(Duration(milliseconds: delayMs - elapsedMs));
    }

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
      for (final levelMetadata in allLevels)
        levelMetadata.uuid: WorldRoute(() => Level(levelMetadata: levelMetadata), maintainState: false),
    };

    add(router = RouterComponent(routes: levelRoutes, initialRoute: RouteNames.menu));
  }
}

abstract class RouteNames {
  static const String menu = 'menu';
  static const String pause = 'pause';
}
