import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Route, Image;
import 'package:pixel_adventure/data/static/metadata/level_metadata.dart';
import 'package:pixel_adventure/data/static/static_center.dart';
import 'package:pixel_adventure/data/storage/storage_center.dart';
import 'package:pixel_adventure/game/hud/pause_route.dart';
import 'package:pixel_adventure/game/level/level.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/level/tile_id_helper.dart';
import 'package:pixel_adventure/game/utils/game_safe_padding.dart';
import 'package:pixel_adventure/game/utils/position_provider.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/menu/menu_page.dart';

class PixelQuest extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection, HasPerformanceTracker, SingleGameInstance, WidgetsBindingObserver {
  final EdgeInsets _flutterSafePadding;

  PixelQuest({required EdgeInsets safeScreenPadding}) : _flutterSafePadding = safeScreenPadding;

  late final StaticCenter staticCenter;
  late final StorageCenter storageCenter;
  late final GameSafePadding safePadding;

  late final Image miniMapBackgroundPattern;

  // router
  late final RouterComponent router;

  @override
  Future<void> onLoad() async {
    final startTime = DateTime.now();
    staticCenter = await StaticCenter.init();
    storageCenter = await StorageCenter.init(staticCenter: staticCenter);
    await _loadAllImagesIntoCache();
    _setUpCameraDefault();
    _setUpSafePadding();
    _setUpRouter();
    await _createMiniMapBackgroundPattern();
    WidgetsBinding.instance.addObserver(this);

    // await Future.delayed(Duration(seconds: 3000));
    // final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
    // final delayMs = 5200;
    // if (elapsedMs < delayMs) {
    //   await Future.delayed(Duration(milliseconds: delayMs - elapsedMs));
    // }

    return super.onLoad();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final currentRoute = router.currentRoute;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (currentRoute is WorldRoute && currentRoute.world is Level) (currentRoute.world as Level).pauseLevel();
      if (currentRoute is WorldRoute && currentRoute.world is MenuPage) (currentRoute.world as MenuPage).pauseMenu();
    } else if (state == AppLifecycleState.resumed) {
      if (currentRoute is WorldRoute && currentRoute.world is MenuPage) (currentRoute.world as MenuPage).resumeMenu();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void onRemove() {
    WidgetsBinding.instance.removeObserver(this);
    super.onRemove();
  }

  @override
  void onDispose() {
    ((router.routes[RouteNames.menu] as WorldRoute?)?.world as MenuPage?)?.dispose();
    super.onDispose();
  }

  Future<void> _loadAllImagesIntoCache() async => await images.loadAllImages();

  void _setUpCameraDefault() {
    final fixedHeight = GameSettings.mapHeight - GameSettings.mapBorderWidth * 2;
    final aspectRatio = size.x / size.y;
    final dynamicWidth = fixedHeight * aspectRatio;

    // create a camera with fixed resolution that is used for both a level and the menu page
    camera = CameraComponent.withFixedResolution(width: dynamicWidth, height: fixedHeight);
    add(camera);
  }

  void setUpCameraForMenu() {
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.setBounds(Rectangle.fromLTRB(0, 0, size.x, size.y));
    camera.follow(StaticPositionProvider.topLeft);
  }

  void setUpCameraForLevel(double mapWidth, Player player) {
    // the player should not be visible on the far left of the screen, but rather at 1/4 of the screen width
    camera.viewfinder.anchor = Anchor(0.25, 0);

    // camera bounds
    final leftBound = size.x * camera.viewfinder.anchor.x + GameSettings.mapBorderWidth;
    final rightBound = size.x * (1 - camera.viewfinder.anchor.x) + GameSettings.mapBorderWidth;
    camera.setBounds(Rectangle.fromLTRB(leftBound, GameSettings.mapBorderWidth, mapWidth - rightBound, GameSettings.mapBorderWidth));

    // viewfinder follows player
    setRefollowForLevelCamera(player);
  }

  void setRefollowForLevelCamera(Player player) => camera.follow(PlayerHitboxPositionProvider(player), horizontalOnly: true);

  void _setUpSafePadding() {
    final scaleX = camera.viewport.size.x / size.x;
    final scaleY = camera.viewport.size.y / size.y;
    safePadding = GameSafePadding(
      top: _flutterSafePadding.top / scaleY,
      bottom: _flutterSafePadding.bottom / scaleY,
      left: _flutterSafePadding.left / scaleX,
      right: _flutterSafePadding.right / scaleX,
    );
  }

  void _setUpRouter() {
    final levelRoutes = {
      RouteNames.menu: WorldRoute(() => MenuPage()),
      RouteNames.pause: PauseRoute(),
      for (final levelMetadata in staticCenter.allLevelsInAllWorlds.flat())
        levelMetadata.uuid: WorldRoute(() => Level(levelMetadata: levelMetadata), maintainState: false),
    };

    add(
      router = RouterComponent(
        routes: levelRoutes,
        initialRoute: staticCenter.allLevelsInOneWorld('014809d5-8ec5-4171-a82e-df72e7839d45').getLevelByNumber(1).uuid,
      ),
    );
    // add(router = RouterComponent(routes: levelRoutes, initialRoute: RouteNames.menu));
  }

  Future<void> _createMiniMapBackgroundPattern() async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final patternSize = Vector2.all(16);
    final random = Random();
    final paint = Paint();

    // create a small pattern
    for (int y = 0; y < patternSize.y; y++) {
      for (int x = 0; x < patternSize.x; x++) {
        paint.color = miniMapBackgroundColors[random.nextInt(miniMapBackgroundColors.length)];
        canvas.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1), paint);
      }
    }

    // convert pattern to image
    final picture = recorder.endRecording();
    miniMapBackgroundPattern = await picture.toImage(patternSize.x.toInt(), patternSize.y.toInt());
  }
}

abstract class RouteNames {
  static const String menu = 'menu';
  static const String pause = 'pause';
}
