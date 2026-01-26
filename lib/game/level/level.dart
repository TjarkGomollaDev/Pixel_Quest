import 'dart:async';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/rendering.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/data/audio/audio_center.dart';
import 'package:pixel_adventure/data/storage/entities/level_entity.dart';
import 'package:pixel_adventure/game/collision/world_collision.dart';
import 'package:pixel_adventure/game/checkpoints/start.dart';
import 'package:pixel_adventure/game/enemies/blue_bird.dart';
import 'package:pixel_adventure/game/enemies/chicken.dart';
import 'package:pixel_adventure/game/enemies/ghost.dart';
import 'package:pixel_adventure/game/enemies/mushroom.dart';
import 'package:pixel_adventure/game/enemies/plant.dart';
import 'package:pixel_adventure/game/enemies/slime.dart';
import 'package:pixel_adventure/game/enemies/snail.dart';
import 'package:pixel_adventure/game/enemies/trunk.dart';
import 'package:pixel_adventure/game/enemies/turtle.dart';
import 'package:pixel_adventure/game/events/game_event_bus.dart';
import 'package:pixel_adventure/game/game_router.dart';
import 'package:pixel_adventure/game/hud/mini%20map/entity_on_mini_map.dart';
import 'package:pixel_adventure/game/hud/game_hud.dart';
import 'package:pixel_adventure/game/level/player/player_input.dart';
import 'package:pixel_adventure/game/level/mobile%20controls/mobile_controls.dart';
import 'package:pixel_adventure/game/utils/tile_id_helper.dart';
import 'package:pixel_adventure/game/utils/background_parallax.dart';
import 'package:pixel_adventure/data/static/metadata/level_metadata.dart';
import 'package:pixel_adventure/game/traps/arrow_up.dart';
import 'package:pixel_adventure/game/checkpoints/finish.dart';
import 'package:pixel_adventure/game/traps/rock_head.dart';
import 'package:pixel_adventure/game/checkpoints/checkpoint.dart';
import 'package:pixel_adventure/game/traps/fan.dart';
import 'package:pixel_adventure/game/traps/fire.dart';
import 'package:pixel_adventure/game/traps/fire_trap.dart';
import 'package:pixel_adventure/game/traps/fruit.dart';
import 'package:pixel_adventure/game/level/player/player.dart';
import 'package:pixel_adventure/game/traps/moving_platform.dart';
import 'package:pixel_adventure/game/traps/saw.dart';
import 'package:pixel_adventure/game/traps/saw_circle_component.dart';
import 'package:pixel_adventure/game/traps/spike_head.dart';
import 'package:pixel_adventure/game/traps/spiked_ball_component.dart';
import 'package:pixel_adventure/game/traps/spiked_ball.dart';
import 'package:pixel_adventure/game/traps/spikes.dart';
import 'package:pixel_adventure/game/traps/trampoline.dart';
import 'package:pixel_adventure/game/utils/grid.dart';
import 'package:pixel_adventure/game/utils/misc_utils.dart';
import 'package:pixel_adventure/game/game_settings.dart';
import 'package:pixel_adventure/game/game.dart';
import 'package:pixel_adventure/game/utils/visible_components.dart';

/// Internal control-flow exception used to abort the level loading pipeline.
///
/// This is thrown by the loading guard methods (e.g. `_guard`, `_guardYield`,
/// `_guardDelay`) when loading has been canceled or a newer loading token is
/// active. It is intentionally caught in `onLoad` / `onMount` to exit early
/// without treating the cancellation as an actual error.
final class _LoadingCanceled implements Exception {
  const _LoadingCanceled();
}

/// A complete, self-contained world instance for one playable level.
///
/// The level loads its Tiled map, builds optimized world collisions, spawns all entities (player, enemies, traps, checkpoints),
/// records a mini map, wires up pause/resume via the event bus, and manages HUD/mobile overlays plus basic count stats.
class Level extends World with HasGameReference<PixelQuest>, HasTimeScale, TapCallbacks {
  // constructor parameters
  final LevelMetadata _levelMetadata;

  Level({required LevelMetadata levelMetadata}) : _levelMetadata = levelMetadata;

  // level map from Tiled file
  late final TiledComponent _levelMap;

  // parallax background
  late final BackgroundParallax _levelBackground;

  // all collision blocks from background layer
  final List<WorldBlock> _collisionBlocks = [];

  // all spawning objects from spawning layer which are needed in some way for the mini map
  final List<EntityOnMiniMap> _miniMapEntities = [];

  // mini map
  late final PictureRecorder _miniMapRecorder;
  late final Canvas _miniMapCanvas;
  late final Paint _miniMapPaint;
  late final Vector2 _miniMapSize;
  late final Sprite _readyMadeMiniMapForground;

  // player
  late final Player _player;
  late final PlayerInput _playerInput;

  // overlays
  late final GameHud _gameHud;
  late final MobileControls? _mobileControls;
  late final VisibleFpsTextComponent? _fpsDisplay;

  // counts
  int _totalFruitsCount = 0;
  int _playerFruitsCount = 0;
  int _deathCount = 0;
  int _earnedStars = 0;

  // there are objects that can be collected by the player, but should reappear when the player respawns
  final List<Respawnable> _pendingRespawnables = [];

  // when the level is paused, it should be rendered with a blur
  bool _levelPaused = false;
  PaintDecorator decorator = PaintDecorator.tint(AppTheme.screenBlur)..addBlur(6.0);

  // timestamp used to measure loading time and used in conjunction with the loading overlay
  late final DateTime _startTime;

  // flag we need if we want to load a level directly for testing purposes without going through the menu
  static bool _testModeStartInLevel = false;

  // subscription for game events
  GameSubscription? _sub;

  // if the loading process is to be canceled
  int _loadingToken = 0;
  bool _loadingCanceled = false;

  // getter
  PlayerInput get playerInput => _playerInput;
  int get earnedStars => _earnedStars;

  @override
  Future<void> onLoad() async {
    final token = _bumpLoadingToken();
    try {
      _startLoading();
      await _loadLevelMap(token);
      _startMiniMapRecording();
      await _addBackgroundLayer(token);
      await _addSpawningLayer(token);
      await _endMiniMapRecording(token);
      _setUpCamera();
      return super.onLoad();
    } on _LoadingCanceled {
      return;
    }
  }

  @override
  Future<void> onMount() async {
    final token = _loadingToken;
    try {
      _addSubscription();
      _addAllOverlays();
      await _completeLoading(token);
      super.onMount();
    } on _LoadingCanceled {
      return;
    }
  }

  @override
  Future<void> onRemove() async {
    _removeSubscription();
    _removeGameHud();
    _removeMobileControls();
    _removeFpsDisplay();
    _cleanUpLevel();
    return super.onRemove();
  }

  @override
  void renderFromCamera(Canvas canvas) {
    if (_levelPaused) return decorator.applyChain(super.renderFromCamera, canvas);
    super.renderFromCamera(canvas);
  }

  int _bumpLoadingToken() => ++_loadingToken;

  void _guard(int token) {
    if (_loadingCanceled || token != _loadingToken) throw const _LoadingCanceled();
  }

  Future<void> _guardYield(int token) async {
    await yieldFrame();
    _guard(token);
  }

  Future<void> _guardDelay(int token, Duration d) async {
    await Future.delayed(d);
    _guard(token);
  }

  void _cancelLoading() {
    _loadingCanceled = true;
    _bumpLoadingToken();
  }

  void _addSubscription() {
    _sub = game.eventBus.listenMany((on) {
      on<GameLifecycleChanged>((event) {
        // if the level is still loading, cancel and return to the menu
        if (game.loadingOverlay.isShown) {
          _cancelLoading();
          game.router.pushReplacementNamed(RouteNames.menu);

          // wait until the menu is mounted and then pass on the event that the menu is paused
          game.router.currentRoute.mounted.whenComplete(() => game.eventBus.emit(event));

          // cancel loading overlay
          game.loadingOverlay.cancelAnimations();
          return;
        }
        if (event.lifecycle == Lifecycle.paused && !_levelPaused) return _gameHud.triggerPause();
      });
      on<LevelLifecycleChanged>((event) {
        if (event.lifecycle == Lifecycle.paused) return _pause();
        if (event.lifecycle == Lifecycle.resumed) return _resume();
      });
    });
  }

  void _removeSubscription() {
    _sub?.cancel();
    _sub = null;
  }

  void _startLoading() {
    _startTime = DateTime.now();
    timeScale = 0;
  }

  Future<void> _completeLoading(int token) async {
    if (game.router.initialRoute == RouteNames.menu || _testModeStartInLevel) {
      // the overlay should be displayed for a minimum amount of time
      final elapsedMs = DateTime.now().difference(_startTime).inMilliseconds;
      final delayMs = 1400;
      if (elapsedMs < delayMs) await _guardDelay(token, Duration(milliseconds: delayMs - elapsedMs));
      await game.loadingOverlay.hide(onAfterDummyFallOut: () => timeScale = 1);
      _guard(token);
    } else {
      // when we start testing directly in a level, we don't want any delays and we don't need to hide any overlays
      _testModeStartInLevel = true;
      timeScale = 1;
    }

    // delay for visual reasons only
    await _guardDelay(token, Duration(milliseconds: 100));

    // this method spawns the player and initiates the level start
    _player.appearInLevel();
  }

  Future<void> _loadLevelMap(int token) async {
    _levelMap = await TiledComponent.load('${_levelMetadata.tmxFileName}.tmx', Vector2.all(GameSettings.tileSize))
      ..priority = GameSettings.mapLayerLevel;
    add(_levelMap);
    await _guardYield(token);
  }

  void _startMiniMapRecording() {
    _miniMapRecorder = PictureRecorder();
    _miniMapCanvas = Canvas(_miniMapRecorder);
    _miniMapPaint = Paint();
    _miniMapSize = Vector2(_levelMap.tileMap.map.width.toDouble(), _levelMap.tileMap.map.height.toDouble());
  }

  Future<void> _endMiniMapRecording(int token) async {
    final picture = _miniMapRecorder.endRecording();
    final image = await picture.toImage(_miniMapSize.x.toInt(), _miniMapSize.y.toInt());
    _readyMadeMiniMapForground = Sprite(image);
    _guard(token);
  }

  void _addTileToMiniMap(int x, int y, int tileId, bool isPlatform) {
    _miniMapPaint.color = getMiniMapColor(
      tileId: tileId,
      isPlatform: isPlatform,
      baseBlock: game.staticCenter.getWorld(_levelMetadata.worldUuid).baseBlock,
    );
    _miniMapCanvas.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1), _miniMapPaint);
  }

  void _addSpecialTileToMiniMap(Vector2 position, Vector2 mapOffset, Color color) {
    final mapPosition = position / GameSettings.tileSize + mapOffset;
    _miniMapPaint.color = color;
    _miniMapCanvas.drawRect(Rect.fromLTWH(mapPosition.x, mapPosition.y, 1, 1), _miniMapPaint);
  }

  void _addPatternToMiniMap(Vector2 position, List<List<Color?>> pattern) {
    for (int y = 0; y < pattern.length; y++) {
      for (int x = 0; x < pattern[y].length; x++) {
        final color = pattern[y][x];
        if (color == null) continue;
        _miniMapPaint.color = color;
        _miniMapCanvas.drawRect(Rect.fromLTWH(position.x + x, position.y + y, 1, 1), _miniMapPaint);
      }
    }
  }

  void _addCheckpointToMiniMap(Vector2 position) {
    final mapPosition = position / GameSettings.tileSize + Vector2(1, 0);
    _addPatternToMiniMap(mapPosition, miniMapCheckpointPattern);
  }

  void _addEntityToMiniMap(EntityOnMiniMap entity) {
    _miniMapEntities.add(entity);
  }

  Future<void> _addBackgroundLayer(int token) async {
    final backgroundLayer = _levelMap.tileMap.getLayer<TileLayer>('Background');
    if (backgroundLayer != null) {
      _addBackground(backgroundLayer);
      await _addWorldCollisions(backgroundLayer, token);
      _guard(token);
    }
  }

  void _addBackground(TileLayer backgroundLayer) {
    final type = backgroundLayer.properties.getValue<String?>('BackgroundType');
    final position = Vector2.all(GameSettings.hasBorder ? GameSettings.tileSize : 0);
    final size = Vector2(
      _levelMap.width - (GameSettings.hasBorder ? GameSettings.tileSize * 2 : 0),
      _levelMap.height - (GameSettings.hasBorder ? GameSettings.tileSize * 2 : 0),
    );
    bool isInitialized = false;

    // if desired, you can assign an individual background to each level, which is particularly useful for testing purposes
    if (type != null && type.isNotEmpty) {
      for (final szene in BackgroundSzene.values) {
        if (szene.fileName == type) {
          _levelBackground = BackgroundParallax.szene(szene: szene, position: position, size: size);
          isInitialized = true;
          break;
        }
      }
      if (!isInitialized) {
        for (final tileColor in BackgroundColor.values) {
          if (tileColor.fileName == type) {
            _levelBackground = BackgroundParallax.colored(color: tileColor, position: position, size: size);
            isInitialized = true;
            break;
          }
        }
      }
    }

    // the background from the world is the default
    if (!isInitialized) {
      _levelBackground = BackgroundParallax.szene(
        szene: game.staticCenter.getWorld(_levelMetadata.worldUuid).backgroundSzene,
        position: position,
        size: size,
      );
    }

    _levelBackground.priority = GameSettings.backgroundLayerLevel;
    add(_levelBackground);
  }

  /// Builds collision blocks from a tile layer by merging adjacent tiles.
  ///
  /// Algorithm:
  /// - Iterates over every tile in the given [backgroundLayer].
  /// - Skips empty tiles (id == 0) and already processed tiles.
  /// - Distinguishes between "platform" tiles (IDs in [platformValues]) and solid tiles.
  /// - For platforms:
  ///   - Merges horizontally as long as consecutive tiles are valid platforms.
  ///   - Creates a thin horizontal [WorldBlock] with fixed height.
  /// - For solid tiles:
  ///   - First merges horizontally to find maximum width.
  ///   - Then attempts to expand vertically downwards while every row of that width
  ///     is filled with solid tiles.
  ///   - Creates one larger rectangular [WorldBlock].
  /// - Marks all merged tiles as visited so they are not processed again.
  ///
  /// This reduces the number of collision blocks significantly:
  /// instead of creating one 16x16 block per tile, larger rectangles
  /// are created, improving performance in collision checks.
  ///
  /// Example (16x16 tiles → merged WorldBlocks):
  ///
  /// Input tile map (S = solid, P = platform, . = empty):
  ///
  ///   S S S S . . P P P
  ///   S S S S . . . . .
  ///   S S S S . . . . .
  ///
  /// Naive collision blocks (one per tile):
  ///   {S}{S}{S}{S} .. {P}{P}{P}
  ///   {S}{S}{S}{S} .. ...
  ///   {S}{S}{S}{S} .. ...
  ///
  /// Optimized merged blocks:
  ///   {████████} .. {PPP}
  ///   {████████} .. ...
  ///   {████████} .. ...
  ///
  /// Result:
  /// - 12 small solid blocks → 1 big rectangle (64x48).
  /// - 3 platform tiles → 1 merged platform (48x5).
  ///
  /// This reduces the number of collision checks
  /// and improves runtime performance significantly.
  Future<void> _addWorldCollisions(TileLayer backgroundLayer, int token) async {
    _addWorldBorders();

    // y axis range of map
    final yStart = GameSettings.hasBorder ? 1 : 0;
    final yEnd = GameSettings.hasBorder ? _levelMap.tileMap.map.height - 1 : _levelMap.tileMap.map.height;

    // x axis range of map
    final xStart = GameSettings.hasBorder ? 1 : 0;
    final xEnd = GameSettings.hasBorder ? _levelMap.tileMap.map.width - 1 : _levelMap.tileMap.map.width;

    // visited tiles
    final visited = List.generate(_levelMap.tileMap.map.height, (_) => List.filled(_levelMap.tileMap.map.width, false));

    for (int y = yStart; y < yEnd; y++) {
      for (int x = xStart; x < xEnd; x++) {
        // skip already processed tiles
        if (visited[y][x]) continue;

        // skip empty tiles
        final tileId = backgroundLayer.tileData![y][x].tile;
        if (tileId == 0) continue;

        // check if current tile is a platform
        final isPlatform = platformBlockIds.contains(tileId);

        _addTileToMiniMap(x, y, tileId, isPlatform);

        // find width to the right
        int w = 1;
        int nextTileId = backgroundLayer.tileData![y][x + w].tile;
        bool isNextPlatform = platformBlockIds.contains(nextTileId);
        while (x + w < xEnd && !visited[y][x + w] && nextTileId != 0 && (isPlatform ? isNextPlatform : !isNextPlatform)) {
          _addTileToMiniMap(x + w, y, nextTileId, isNextPlatform);
          nextTileId = backgroundLayer.tileData![y][x + ++w].tile;
          isNextPlatform = platformBlockIds.contains(nextTileId);
        }

        // find height downwards
        int h = 1;
        if (!isPlatform) {
          bool done = false;
          while (y + h < yEnd && !done) {
            for (var dx = 0; dx < w; dx++) {
              final tileBelowId = backgroundLayer.tileData![y + h][x + dx].tile;
              final isBelowPlatform = platformBlockIds.contains(tileBelowId);
              if (tileBelowId == 0 || isBelowPlatform || visited[y + h][x + dx]) {
                done = true;
                break;
              }
              _addTileToMiniMap(x + dx, y + h, tileBelowId, isBelowPlatform);
            }
            if (!done) h++;
          }
        }

        // mark all merged tiles as visited
        for (var dy = 0; dy < h; dy++) {
          for (var dx = 0; dx < w; dx++) {
            visited[y + dy][x + dx] = true;
          }
        }

        // create merged WorldBlock
        _collisionBlocks.add(
          WorldBlock(
            isPlatform: isPlatform,
            position: Vector2(x * GameSettings.tileSize, y * GameSettings.tileSize),
            size: isPlatform ? Vector2(w * GameSettings.tileSize, 5) : Vector2(w * GameSettings.tileSize, h * GameSettings.tileSize),
          ),
        );

        if ((x % 50) == 0) await _guardYield(token);
      }
      await _guardYield(token);
    }
    addAll(_collisionBlocks);
    await _guardYield(token);
  }

  void _addWorldBorders() {
    final hasBorder = GameSettings.hasBorder;
    final borderWidth = GameSettings.tileSize;
    final verticalSize = Vector2(borderWidth, hasBorder ? _levelMap.height : _levelMap.height + borderWidth * 2);
    final horizontalSize = Vector2(hasBorder ? _levelMap.width - borderWidth * 2 : _levelMap.width, borderWidth);

    // top, bottom, left, right
    final borders = [
      WorldBlock(position: Vector2(hasBorder ? borderWidth : 0, hasBorder ? 0 : -borderWidth), size: horizontalSize),
      WorldBlock(
        position: Vector2(hasBorder ? borderWidth : 0, hasBorder ? _levelMap.height - borderWidth : _levelMap.height),
        size: horizontalSize,
      ),
      WorldBlock(position: Vector2(hasBorder ? 0 : -borderWidth, hasBorder ? 0 : -borderWidth), size: verticalSize),

      WorldBlock(
        position: Vector2(hasBorder ? _levelMap.width - borderWidth : _levelMap.width, hasBorder ? 0 : -borderWidth),
        size: verticalSize,
      ),
    ];

    _collisionBlocks.addAll(borders);
  }

  Future<void> _addSpawningLayer(int token) async {
    final spawnPointsLayer = _levelMap.tileMap.getLayer<ObjectGroup>('Spawning');
    if (spawnPointsLayer == null) return;

    // the start with player is always created first in the level, as many other objects require a reference to the player
    bool foundStart = false;
    for (var spawnPoint in spawnPointsLayer.objects) {
      if (spawnPoint.class_ == 'Start') {
        // first create start
        foundStart = true;
        final gridPosition = snapVectorToGrid(spawnPoint.position);
        final start = Start(position: gridPosition);

        // then player and player input
        _player = Player(character: game.storageCenter.settings.character, startPosition: start.playerPosition);
        _playerInput = PlayerInput();
        addAll([start, _player, _playerInput]);
        _addCheckpointToMiniMap(gridPosition);
        break;
      }
    }

    // cancel if no start was found
    if (!foundStart) {
      return debugPrint(
        '❌ Failed to spawn player: No Start object found in Spawning layer '
        '(level=${_levelMetadata.tmxFileName}.tmx, layer=Spawning).',
      );
    }

    // all other objects are created
    int i = 0;
    for (var spawnPoint in spawnPointsLayer.objects) {
      try {
        final gridPosition = snapVectorToGrid(spawnPoint.position);
        PositionComponent? spawnObject;
        switch (spawnPoint.class_) {
          case 'Fruit':
            final fruitName = spawnPoint.name;
            final safeName = FruitName.values.map((e) => e.name).contains(fruitName) ? fruitName : FruitName.Apple.name;
            spawnObject = Fruit(name: safeName, position: gridPosition);
            _totalFruitsCount++;
            break;
          case 'ArrowUp':
            spawnObject = ArrowUp(player: _player, position: gridPosition);
            break;
          case 'Saw':
            final offsetNeg = spawnPoint.properties.getValue<double?>('offsetNeg') ?? GameSettings.offsetNegDefault;
            final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? GameSettings.offsetPosDefault;
            final isVertical = spawnPoint.properties.getValue<bool?>('isVertical') ?? GameSettings.isVerticalDefault;
            final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? GameSettings.isLeftDefault;
            final showPath = spawnPoint.properties.getValue<bool?>('showPath') ?? GameSettings.showPath;
            spawnObject = Saw(
              offsetNeg: offsetNeg,
              offsetPos: offsetPos,
              isVertical: isVertical,
              isLeft: isLeft,
              showPath: showPath,
              player: _player,
              position: gridPosition,
            );
            break;
          case 'SawCircle':
            final doubleSaw = spawnPoint.properties.getValue<bool?>('doubleSaw') ?? GameSettings.doubleSawDefault;
            final clockwise = spawnPoint.properties.getValue<bool?>('clockwise') ?? GameSettings.clockwiseDefault;
            spawnObject = SawCircleComponent(
              doubleSaw: doubleSaw,
              clockwise: clockwise,
              player: _player,
              position: gridPosition,
              size: spawnPoint.size,
            );

            // add the single saws from the saw circle component to the mini map entities
            for (var singleSaw in (spawnObject as SawCircleComponent).singleSaws) {
              if (singleSaw != null) _addEntityToMiniMap(singleSaw);
            }
            break;
          case 'Spiked Ball':
            final radius =
                (spawnPoint.properties.getValue<int?>('radius') ?? GameSettings.spikedBallRadiusDefault) * GameSettings.tileSize +
                GameSettings.tileSize / 2;
            final startLeft = spawnPoint.properties.getValue<bool?>('startLeft') ?? GameSettings.clockwiseDefault;
            final swingArcDec = spawnPoint.properties.getValue<int?>('swingArcDec') ?? GameSettings.spikedBallSwingArcDec;
            final swingSpeed = spawnPoint.properties.getValue<int?>('swingSpeed') ?? GameSettings.spikedBallSwingSpeed;
            spawnObject = SpikedBallComponent(
              radius: radius,
              player: _player,
              swingArcDeg: swingArcDec,
              swingSpeed: swingSpeed,
              startLeft: startLeft,
              position: gridPosition - Vector2(radius - GameSettings.tileSize / 2, SpikedBall.gridSize.x / 2 - GameSettings.tileSize / 2),
              size: Vector2(radius * 2, radius + SpikedBall.gridSize.x / 2),
            );

            // add the ball from the spiked ball component to the mini map entities
            _addEntityToMiniMap((spawnObject as SpikedBallComponent).ball);
            break;
          case 'Chicken':
            final offsetNeg = spawnPoint.properties.getValue<double?>('offsetNeg') ?? GameSettings.offsetNegDefault;
            final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? GameSettings.offsetPosDefault;
            final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? GameSettings.isLeftDefault;
            spawnObject = Chicken(offsetNeg: offsetNeg, offsetPos: offsetPos, isLeft: isLeft, player: _player, position: gridPosition);
            break;
          case 'Trampoline':
            spawnObject = Trampoline(player: _player, position: gridPosition);
            break;
          case 'Fan':
            final alwaysOn = spawnPoint.properties.getValue<bool?>('alwaysOn') ?? GameSettings.fanAlwaysOnDefault;
            spawnObject = Fan(alwaysOn: alwaysOn, player: _player, position: gridPosition);
            break;
          case 'FireTrap':
            spawnObject = FireTrap(player: _player, position: gridPosition);
            _addSpecialTileToMiniMap(gridPosition, Vector2(0, 1), AppTheme.woodBlock);
            break;
          case 'Fire':
            final side = spawnPoint.properties.getValue<int?>('side') ?? GameSettings.sideDefault;
            spawnObject = Fire(side: side, player: _player, position: gridPosition, size: spawnPoint.size);
            break;
          case 'Moving Platform':
            final offsetNeg = spawnPoint.properties.getValue<double?>('offsetNeg') ?? GameSettings.offsetNegDefault;
            final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? GameSettings.offsetPosDefault;
            final isVertical = spawnPoint.properties.getValue<bool?>('isVertical') ?? GameSettings.isVerticalDefault;
            final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? GameSettings.isLeftDefault;
            spawnObject = MovingPlatform(
              offsetNeg: offsetNeg,
              offsetPos: offsetPos,
              isVertical: isVertical,
              isLeft: isLeft,
              player: _player,
              position: gridPosition,
            );
            break;
          case 'Rock Head':
            final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? GameSettings.offsetPosDefault;
            final delay = spawnPoint.properties.getValue<double?>('delay') ?? GameSettings.delay;
            spawnObject = RockHead(offsetPos: offsetPos, delay: delay, position: gridPosition);
            break;
          case 'Spike Head':
            final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? GameSettings.offsetPosDefault;
            final delay = spawnPoint.properties.getValue<double?>('delay') ?? GameSettings.delay;
            spawnObject = SpikeHead(offsetPos: offsetPos, delay: delay, player: _player, position: gridPosition);
            break;
          case 'Plant':
            final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? GameSettings.isLeftDefault;
            final doubleShot = spawnPoint.properties.getValue<bool?>('doubleShot') ?? GameSettings.doubleShotDefault;
            spawnObject = Plant(isLeft: isLeft, doubleShot: doubleShot, player: _player, position: gridPosition);
            break;
          case 'Blue Bird':
            final offsetNeg = spawnPoint.properties.getValue<double?>('offsetNeg') ?? GameSettings.offsetNegDefault;
            final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? GameSettings.offsetPosDefault;
            final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? GameSettings.isLeftDefault;
            spawnObject = BlueBird(offsetNeg: offsetNeg, offsetPos: offsetPos, isLeft: isLeft, player: _player, position: gridPosition);
            break;
          case 'Snail':
            final offsetNeg = spawnPoint.properties.getValue<double?>('offsetNeg') ?? GameSettings.offsetNegDefault;
            final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? GameSettings.offsetPosDefault;
            final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? GameSettings.isLeftDefault;
            spawnObject = Snail(offsetNeg: offsetNeg, offsetPos: offsetPos, isLeft: isLeft, player: _player, position: gridPosition);
            break;
          case 'Ghost':
            final offsetNeg = spawnPoint.properties.getValue<double?>('offsetNeg') ?? GameSettings.offsetNegDefault;
            final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? GameSettings.offsetPosDefault;
            final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? GameSettings.isLeftDefault;
            final delay = spawnPoint.properties.getValue<double?>('delay') ?? GameSettings.delay;
            spawnObject = Ghost(
              offsetNeg: offsetNeg,
              offsetPos: offsetPos,
              isLeft: isLeft,
              delay: delay,
              player: _player,
              position: gridPosition,
            );
            break;
          case 'Mushroom':
            final offsetNeg = spawnPoint.properties.getValue<double?>('offsetNeg') ?? GameSettings.offsetNegDefault;
            final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? GameSettings.offsetPosDefault;
            final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? GameSettings.isLeftDefault;
            spawnObject = Mushroom(offsetNeg: offsetNeg, offsetPos: offsetPos, isLeft: isLeft, player: _player, position: gridPosition);
            break;
          case 'Trunk':
            final offsetNeg = spawnPoint.properties.getValue<double?>('offsetNeg') ?? GameSettings.offsetNegDefault;
            final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? GameSettings.offsetPosDefault;
            final extandNegAttack = spawnPoint.properties.getValue<double?>('extandNegAttack') ?? GameSettings.extandNegAttackDefault;
            final extandPosAttack = spawnPoint.properties.getValue<double?>('extandPosAttack') ?? GameSettings.extandPosAttackDefault;
            final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? GameSettings.isLeftDefault;
            spawnObject = Trunk(
              offsetNeg: offsetNeg,
              offsetPos: offsetPos,
              extandNegAttack: extandNegAttack,
              extandPosAttack: extandPosAttack,
              isLeft: isLeft,
              player: _player,
              position: gridPosition,
            );
            break;
          case 'Slime':
            final offsetNeg = spawnPoint.properties.getValue<double?>('offsetNeg') ?? GameSettings.offsetNegDefault;
            final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? GameSettings.offsetPosDefault;
            final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? GameSettings.isLeftDefault;
            spawnObject = Slime(offsetNeg: offsetNeg, offsetPos: offsetPos, isLeft: isLeft, player: _player, position: gridPosition);
            break;
          case 'Turtle':
            final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? GameSettings.isLeftDefault;
            final delay = spawnPoint.properties.getValue<double?>('delay') ?? GameSettings.delay;
            spawnObject = Turtle(isLeft: isLeft, delay: delay, player: _player, position: gridPosition);
            break;
          case 'Spikes':
            final side = spawnPoint.properties.getValue<int?>('side') ?? GameSettings.sideDefault;
            spawnObject = Spikes(side: side, player: _player, position: gridPosition, size: spawnPoint.size);
            break;
          case 'Checkpoint':
            spawnObject = Checkpoint(player: _player, position: gridPosition);
            _addCheckpointToMiniMap(gridPosition);
            break;
          case 'Finish':
            spawnObject = Finish(player: _player, position: gridPosition);
            _addCheckpointToMiniMap(gridPosition);
            break;
        }
        if (spawnObject == null) continue;

        // add spawn objects to level and, if necessary, add them to the mini map
        add(spawnObject);
        if (spawnObject is EntityOnMiniMap) _addEntityToMiniMap(spawnObject);

        if ((++i % 10) == 0) await _guardYield(token);
      } catch (e, stack) {
        debugPrint('❌ Failed to spawn object ${spawnPoint.class_} at position (${spawnPoint.x}, ${spawnPoint.y}): $e\n$stack');
      }
    }
    await _guardYield(token);
  }

  void _setUpCamera() {
    game.setUpCameraForLevel(_levelMap.width, _player);
  }

  void _addGameHud() {
    _gameHud = GameHud(
      totalFruitsCount: _totalFruitsCount,
      miniMapSprite: _readyMadeMiniMapForground,
      levelWidth: _levelMap.width,
      player: _player,
      levelMetadata: _levelMetadata,
      miniMapEntities: _miniMapEntities,
    );
    game.camera.viewport.add(_gameHud);
  }

  void _removeGameHud() {
    if (_gameHud.isMounted) game.camera.viewport.remove(_gameHud);
  }

  void _addMobileControls() {
    if (!GameSettings.showMobileControls) return _mobileControls = null;
    _mobileControls = MobileControls(playerInput: _playerInput);
    game.camera.viewport.add(_mobileControls!);
  }

  void _removeMobileControls() {
    if (_mobileControls != null && _mobileControls.isMounted) game.camera.viewport.remove(_mobileControls);
  }

  void _addFpsDisplay() {
    if (!GameSettings.customDebugMode) return _fpsDisplay = null;
    _fpsDisplay = VisibleFpsTextComponent(position: _gameHud.position + Vector2(0, _gameHud.size.y), show: false);
    game.camera.viewport.add(_fpsDisplay!);
  }

  void _removeFpsDisplay() {
    if (_fpsDisplay != null && _fpsDisplay.isMounted) game.camera.viewport.remove(_fpsDisplay);
  }

  void _addAllOverlays() {
    _addGameHud();
    _addMobileControls();
    _addFpsDisplay();
  }

  void _removeAllOverlays() {
    _removeGameHud();
    _removeMobileControls();
    _removeFpsDisplay();
  }

  void _showAllOverlays() {
    _gameHud.show();
    _mobileControls?.show();
    _fpsDisplay?.show();
  }

  void beginGameplay() {
    _showAllOverlays();
    game.audioCenter.playBackgroundMusic(BackgroundMusic.game);
    game.audioCenter.unmuteGameSfx();
  }

  void endGameplay() {
    _removeAllOverlays();
    game.audioCenter.stopBackgroundMusic();
    unawaited(game.audioCenter.muteGameSfx());
  }

  void _pause() {
    if (_levelPaused) return;
    _levelPaused = true;
    timeScale = 0;
    _mobileControls?.hide();
    _fpsDisplay?.hide();
    unawaited(game.audioCenter.pauseAllLoops());
  }

  void _resume() {
    if (!_levelPaused) return;
    _levelPaused = false;
    timeScale = 1;
    _mobileControls?.show();
    _fpsDisplay?.show();
    unawaited(game.audioCenter.resumeAllLoops());
  }

  void increaseFruitsCount() {
    _gameHud.updateFruitCount(++_playerFruitsCount);
  }

  void queueForRespawn(Respawnable item) {
    _pendingRespawnables.add(item);
  }

  void _processRespawns() {
    for (var item in _pendingRespawnables) {
      if (!item.isMounted) {
        item.onRespawn();
        add(item);
      }
    }
    _pendingRespawnables.clear();
  }

  void playerRespawned() {
    _processRespawns();
    _gameHud.updateDeathCount(++_deathCount);
  }

  Future<void> saveData() async {
    _calculateEarnedStars();
    await game.storageCenter.saveLevel(
      data: LevelEntity(
        uuid: _levelMetadata.uuid,
        stars: _earnedStars,
        totalFruits: _totalFruitsCount,
        earnedFruits: _playerFruitsCount,
        deaths: _deathCount,
      ),
      worldUuid: _levelMetadata.worldUuid,
    );
  }

  void _calculateEarnedStars() {
    if (_playerFruitsCount >= _totalFruitsCount) {
      _earnedStars = 3;
    } else if (_playerFruitsCount >= _totalFruitsCount ~/ 2) {
      _earnedStars = 2;
    } else {
      _earnedStars = 1;
    }
  }

  void _cleanUpLevel() {
    game.audioCenter.stopBackgroundMusic();
    game.audioCenter.muteGameSfx();
    _playerInput.clearInput();
  }
}
