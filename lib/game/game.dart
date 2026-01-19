import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Route, Image;
import 'package:pixel_adventure/data/audio/ambient_loop_manager.dart';
import 'package:pixel_adventure/data/static/metadata/level_metadata.dart';
import 'package:pixel_adventure/data/static/static_center.dart';
import 'package:pixel_adventure/data/storage/storage_center.dart';
import 'package:pixel_adventure/game/events/game_event_bus.dart';
import 'package:pixel_adventure/game/level/level.dart';
import 'package:pixel_adventure/game/level/loading/loading_overlay.dart';
import 'package:pixel_adventure/game/level/player/player.dart';
import 'package:pixel_adventure/game/utils/tile_id_helper.dart';
import 'package:pixel_adventure/game/utils/game_safe_padding.dart';
import 'package:pixel_adventure/game/level/player/player_hitbox_position_provider.dart.dart';
import 'package:pixel_adventure/data/audio/audio_center.dart';
import 'package:pixel_adventure/game/utils/warm_up.dart';
import 'package:pixel_adventure/game/game_settings.dart';
import 'package:pixel_adventure/l10n/app_localizations.dart';
import 'package:pixel_adventure/game/menu/menu_page.dart';
import 'package:pixel_adventure/game/game_router.dart';

class PixelQuest extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection, HasPerformanceTracker, SingleGameInstance, WidgetsBindingObserver {
  // constructor parameters
  final AppLocalizations _l10n;
  final void Function(Locale locale) _requestLocaleChange;
  final EdgeInsets _flutterSafePadding;

  PixelQuest({
    required AppLocalizations l10n,
    required void Function(Locale locale) requestLocaleChange,
    required EdgeInsets safeScreenPadding,
  }) : _l10n = l10n,
       _requestLocaleChange = requestLocaleChange,
       _flutterSafePadding = safeScreenPadding;

  // general data that is used throughout the app and is loaded once when the app is launched
  late final StaticCenter staticCenter;
  late final StorageCenter storageCenter;

  // handles everything related to audio in the game
  late final AudioCenter audioCenter;
  late final AmbientLoopManager ambientLoops;

  // in context with the camera
  final ({double top, double bottom}) cameraWorldYBounds = (top: GameSettings.mapBorderWidth, bottom: GameSettings.mapBorderWidth);

  // factor to convert Flutter pixels in world units
  late final double worldToScreenScale;

  // padding that depends on the device and is converted to the pixel size of the game
  late final GameSafePadding safePadding;

  // mini map background image
  late final Image miniMapBackgroundPattern;

  // router
  late final RouterComponent router;

  // overlay for level while loading
  late final LoadingOverlay loadingOverlay;

  // timestamp used to measure loading time and used in conjunction with the splash screen
  late final DateTime _startTime;

  static const double _maxDt = 1 / 60;

  // bridge to convert events from storage layer into game events
  StreamSubscription? _storageBridgeSub;

  // getter
  AppLocalizations get l10n => _l10n;
  void Function(Locale locale) get requestLocale => _requestLocaleChange;

  @override
  Future<void> onLoad() async {
    _startLoading();
    await _loadAllCenters();
    await _loadAllImagesIntoCache();
    _addStorageEventBridge();
    _setUpCameraDefault();
    _setUpSafePadding();
    _setUpRouter();
    _setUpLoadingOverlay();
    await _createMiniMapBackgroundPattern();
    await _completeLoading();
    return super.onLoad();
  }

  @override
  Future<void> onMount() async {
    WidgetsBinding.instance.addObserver(this);
    super.onMount();
    add(WarmUpRunner()); // must be added after super.onMount
  }

  @override
  void onRemove() {
    _removeStorageEventBridge();
    WidgetsBinding.instance.removeObserver(this);
    super.onRemove();
  }

  @override
  void onDispose() {
    ((router.routes[RouteNames.menu] as WorldRoute?)?.world as MenuPage?)?.dispose();
    storageCenter.dispose();
    ambientLoops.dispose();
    super.onDispose();
  }

  @override
  void update(double dt) {
    super.update(dt > _maxDt ? _maxDt : dt);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final currentRoute = router.currentRoute;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (currentRoute is WorldRoute && currentRoute.world is Level) return GameEventBus.instance.emit(PausePageTriggered());
      if (currentRoute is WorldRoute && currentRoute.world is MenuPage) (currentRoute.world as MenuPage).pauseMenu();
    } else if (state == AppLifecycleState.resumed) {
      if (currentRoute is WorldRoute && currentRoute.world is MenuPage) (currentRoute.world as MenuPage).resumeMenu();
    }
    super.didChangeAppLifecycleState(state);
  }

  void _startLoading() {
    _startTime = DateTime.now();
  }

  Future<void> _completeLoading() async {
    // await Future.delayed(Duration(seconds: 3000));
    // final elapsedMs = DateTime.now().difference(_startTime).inMilliseconds;
    // final delayMs = 5200;
    // if (elapsedMs < delayMs) await Future.delayed(Duration(milliseconds: delayMs - elapsedMs));
  }

  Future<void> _loadAllCenters() async {
    staticCenter = await StaticCenter.init();
    storageCenter = await StorageCenter.init(staticCenter: staticCenter);
    audioCenter = await AudioCenter.init(storageCenter: storageCenter);
    ambientLoops = AmbientLoopManager(audioCenter: audioCenter);
  }

  Future<void> _loadAllImagesIntoCache() async {
    await images.loadAllImages();
  }

  void _addStorageEventBridge() {
    _storageBridgeSub = storageCenter.onDataChanged.listen((event) {
      if (event is NewStarsStorageEvent) {
        GameEventBus.instance.emit(
          NewStarsEarned(
            worldUuid: event.worldUuid,
            levelUuid: event.levelUuid,
            totalStars: event.totalStars,
            newStars: event.newStars,
            levelStars: event.levelStars,
          ),
        );
      }
    });
  }

  void _removeStorageEventBridge() {
    _storageBridgeSub?.cancel();
    _storageBridgeSub = null;
  }

  void _setUpCameraDefault() {
    final fixedHeight = GameSettings.mapHeight - GameSettings.mapBorderWidth * 2;
    final aspectRatio = size.x / size.y;
    final dynamicWidth = fixedHeight * aspectRatio;

    // create a camera with fixed resolution that is used for both a level and the menu page
    camera = CameraComponent.withFixedResolution(width: dynamicWidth, height: fixedHeight);
    add(camera);

    // calculate scale factor
    worldToScreenScale = camera.viewport.size.y / size.y;
  }

  void setUpCameraForMenu() {
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.setBounds(Rectangle.fromLTRB(0, 0, size.x, size.y));
    camera.follow(PositionComponent());
  }

  void setUpCameraForLevel(double mapWidth, Player player) {
    // the player should not be visible on the far left of the screen, but rather at 1/4 of the screen width
    camera.viewfinder.anchor = Anchor(0.25, 0);

    // camera bounds
    final leftBound = size.x * camera.viewfinder.anchor.x + GameSettings.mapBorderWidth;
    final rightBound = size.x * (1 - camera.viewfinder.anchor.x) + GameSettings.mapBorderWidth;
    camera.setBounds(Rectangle.fromLTRB(leftBound, cameraWorldYBounds.top, mapWidth - rightBound, cameraWorldYBounds.bottom));

    // viewfinder follows player
    setRefollowForLevelCamera(player);
  }

  void setRefollowForLevelCamera(Player player) {
    camera.follow(PlayerHitboxPositionProvider(player), horizontalOnly: true);
  }

  void _setUpSafePadding() {
    safePadding = GameSafePadding(
      top: _flutterSafePadding.top / worldToScreenScale,
      bottom: _flutterSafePadding.bottom / worldToScreenScale,
      left: _flutterSafePadding.left / worldToScreenScale,
      right: _flutterSafePadding.right / worldToScreenScale,
    );
  }

  void _setUpRouter() {
    // router = createRouter(staticCenter: staticCenter);
    router = createRouter(staticCenter: staticCenter, initialRoute: staticCenter.allLevelsInOneWorldByIndex(0).getLevelByNumber(9).uuid);
    add(router);
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

  void _setUpLoadingOverlay() {
    loadingOverlay = LoadingOverlay(screenToWorldScale: worldToScreenScale, safePadding: safePadding, size: size);

    // important that it is explicitly added to the router
    router.add(loadingOverlay);
  }

  Future<void> showLoadingOverlay(LevelMetadata levelMetadata) async {
    await loadingOverlay.showOverlay(levelMetadata);
  }

  Future<void> hideLoadingOverlay({VoidCallback? onAfterDummyFallOut}) async {
    await loadingOverlay.hideOverlay(onAfterDummyFallOut: onAfterDummyFallOut);
  }
}
