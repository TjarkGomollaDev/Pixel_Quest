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
  final AppLocalizations l10n;
  final void Function(Locale locale) requestLocaleChange;
  final EdgeInsets _flutterSafePadding;

  PixelQuest({required this.l10n, required this.requestLocaleChange, required EdgeInsets safeScreenPadding})
    : _flutterSafePadding = safeScreenPadding;

  // general data that is used throughout the app and is loaded once when the app is launched
  late final StaticCenter staticCenter;
  late final StorageCenter storageCenter;
  late final AudioCenter audioCenter;

  // entities can register with the manager via an emitter if they have ambient sound
  late final AmbientLoopManager ambientLoops;

  // event bus used for all global events within the game
  late final GameEventBus eventBus;

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

  bool _isObserverAttached = false;

  @override
  Future<void> onLoad() async {
    _startLoading();
    await _loadCenters();
    await _loadImagesIntoCache();
    _addStorageEventBridge();
    _setUpServices();
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
    _attachLifecycleObserver();
    super.onMount();
    add(WarmUpRunner()); // must be added after super.onMount
  }

  @override
  void onRemove() {
    _detachLifecycleObserver();
    _removeStorageEventBridge();
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
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        eventBus.emit(const GameLifecycleChanged(Lifecycle.paused));
        break;
      case AppLifecycleState.resumed:
        eventBus.emit(const GameLifecycleChanged(Lifecycle.resumed));
        break;
      default:
        break;
    }
    super.didChangeAppLifecycleState(state);
  }

  void _attachLifecycleObserver() {
    if (_isObserverAttached) return;
    WidgetsBinding.instance.addObserver(this);
    _isObserverAttached = true;
  }

  void _detachLifecycleObserver() {
    if (!_isObserverAttached) return;
    WidgetsBinding.instance.removeObserver(this);
    _isObserverAttached = false;
  }

  void _startLoading() {
    _startTime = DateTime.now();
  }

  Future<void> _completeLoading() async {
    if (GameSettings.testMode) return;
    final elapsedMs = DateTime.now().difference(_startTime).inMilliseconds;
    final delayMs = 5200;
    if (elapsedMs < delayMs) await Future.delayed(Duration(milliseconds: delayMs - elapsedMs));
  }

  Future<void> _loadCenters() async {
    staticCenter = await StaticCenter.init();
    storageCenter = await StorageCenter.init(staticCenter: staticCenter);
    audioCenter = await AudioCenter.init(storageCenter: storageCenter);
  }

  Future<void> _loadImagesIntoCache() async {
    await images.loadAllImages();
  }

  void _addStorageEventBridge() {
    _storageBridgeSub = storageCenter.onDataChanged.listen((event) {
      if (event is NewStarsStorageEvent) {
        eventBus.emit(
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

  void _setUpServices() {
    ambientLoops = AmbientLoopManager(audioCenter: audioCenter);
    eventBus = GameEventBus();
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
    router = createRouter(staticCenter: staticCenter, initialRoute: staticCenter.allLevelsInOneWorldByIndex(0).getLevelByNumber(14).uuid);
    add(router);
  }

  void _setUpLoadingOverlay() {
    loadingOverlay = LoadingOverlay(screenToWorldScale: worldToScreenScale, safePadding: safePadding, size: size);

    // important that it is explicitly added to the router
    router.add(loadingOverlay);
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
