import 'dart:async';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/rendering.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/app_theme.dart';
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
import 'package:pixel_adventure/game/hud/mini%20map/entity_on_mini_map.dart';
import 'package:pixel_adventure/game/hud/game_hud.dart';
import 'package:pixel_adventure/game/level/tile_id_helper.dart';
import 'package:pixel_adventure/game/utils/jump_btn.dart';
import 'package:pixel_adventure/game/level/background_colored.dart';
import 'package:pixel_adventure/game/level/background_szene.dart';
import 'package:pixel_adventure/data/static/metadata/level_metadata.dart';
import 'package:pixel_adventure/game/traps/arrow_up.dart';
import 'package:pixel_adventure/game/checkpoints/finish.dart';
import 'package:pixel_adventure/game/traps/rock_head.dart';
import 'package:pixel_adventure/game/checkpoints/checkpoint.dart';
import 'package:pixel_adventure/game/traps/fan.dart';
import 'package:pixel_adventure/game/traps/fire.dart';
import 'package:pixel_adventure/game/traps/fire_trap.dart';
import 'package:pixel_adventure/game/traps/fruit.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/traps/moving_platform.dart';
import 'package:pixel_adventure/game/traps/saw.dart';
import 'package:pixel_adventure/game/traps/saw_circle_component.dart';
import 'package:pixel_adventure/game/traps/spike_head.dart';
import 'package:pixel_adventure/game/traps/spiked_ball_component.dart';
import 'package:pixel_adventure/game/traps/spiked_ball_ball.dart';
import 'package:pixel_adventure/game/traps/spikes.dart';
import 'package:pixel_adventure/game/traps/trampoline.dart';
import 'package:pixel_adventure/game/utils/grid.dart';
import 'package:pixel_adventure/game/utils/utils.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_quest.dart';

class DecoratedWorld extends World with HasTimeScale {
  PaintDecorator? decorator;

  @override
  void renderFromCamera(Canvas canvas) {
    if (decorator == null) {
      super.renderFromCamera(canvas);
    } else {
      decorator!.applyChain(super.renderFromCamera, canvas);
    }
  }
}

class Level extends DecoratedWorld with HasGameReference<PixelQuest>, TapCallbacks {
  // constructor parameters
  final LevelMetadata levelMetadata;

  Level({required this.levelMetadata});

  // level map from Tiled file
  late final TiledComponent _levelMap;
  static const _hasBorder = GameSettings.mapBorderWidth != 0;

  // level background
  late final ParallaxComponent _levelBackground;

  // all collision blocks from background layer
  final List<WorldBlock> _collisionBlocks = [];

  // all spawning objects from spawning layer
  final List<PositionComponent> _spawningObjects = [];

  // all spawning objects which are needed in some way for the mini map
  final List<EntityOnMiniMap> _miniMapEntities = [];

  // mini map
  late final PictureRecorder _miniMapRecorder;
  late final Canvas _miniMapCanvas;
  late final Paint _miniMapPaint;
  late final Vector2 _miniMapSize;
  late final Sprite _readyMadeMiniMapForground;

  // player
  late final Player _player;

  // hud
  late final GameHud _gameHud;
  late final JoystickComponent? _joystick;
  late final JumpBtn? _jumpBtn;
  late final FpsTextComponent? _fpsText;

  // counts
  int totalFruitsCount = 0;
  int playerFruitsCount = 0;
  int deathCount = 0;
  int earnedStars = 0;

  // respawnables
  final List<Respawnable> _pendingRespawnables = [];

  // timestamp used to measure loading time and used in conjunction with the loading overlay
  late final DateTime _startTime;

  @override
  Future<void> onLoad() async {
    _startTime = DateTime.now();
    _initialSetup();
    await _loadLevelMap();
    await _startMiniMapRecording();
    await _addBackgroundLayer();
    await _addSpawningLayer();
    await _endMiniMapRecording();
    return super.onLoad();
  }

  @override
  Future<void> onMount() async {
    _setUpCamera();
    _addGameHud();
    _addMobileControls();
    await _hideLoadingOverlay();

    // delay for visual reasons only
    await Future.delayed(Duration(milliseconds: 100));

    // this method triggers the level start
    _player.spawnInLevel();
    super.onMount();
  }

  @override
  Future<void> onRemove() async {
    _removeGameHud();
    if (GameSettings.showMobileControls) _removeMobileControls();
    game.audioCenter.stopBackgroundMusic();
    return super.onRemove();
  }

  void _initialSetup() {
    // debug
    if (GameSettings.customDebug) {
      _fpsText = FpsTextComponent(
        position: Vector2(game.size.x, 0) + Vector2(-GameSettings.hudMargin, GameSettings.hudMargin / 2),
        anchor: Anchor.topRight,
      );
      game.camera.viewport.add(_fpsText!);
    } else {
      _fpsText = null;
    }

    // general
  }

  Future<void> _loadLevelMap() async {
    _levelMap = await TiledComponent.load('${levelMetadata.tmxFileName}.tmx', Vector2.all(GameSettings.tileSize))
      ..priority = GameSettings.mapLayerLevel;
    add(_levelMap);
    await yieldFrame();
  }

  Future<void> _startMiniMapRecording() async {
    _miniMapRecorder = PictureRecorder();
    _miniMapCanvas = Canvas(_miniMapRecorder);
    _miniMapPaint = Paint();
    _miniMapSize = Vector2(_levelMap.tileMap.map.width.toDouble(), _levelMap.tileMap.map.height.toDouble());
  }

  void _addTileToMiniMap(int x, int y, int tileId, bool isPlatform) {
    _miniMapPaint.color = getMiniMapColor(
      tileId: tileId,
      isPlatform: isPlatform,
      baseBlock: game.staticCenter.getWorld(levelMetadata.worldUuid).baseBlock,
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

  Future<void> _endMiniMapRecording() async {
    final picture = _miniMapRecorder.endRecording();
    final image = await picture.toImage(_miniMapSize.x.toInt(), _miniMapSize.y.toInt());

    _readyMadeMiniMapForground = Sprite(image);
  }

  Future<void> _addBackgroundLayer() async {
    final backgroundLayer = _levelMap.tileMap.getLayer<TileLayer>('Background');
    if (backgroundLayer != null) {
      _addBackground(backgroundLayer);
      await _addWorldCollisions(backgroundLayer);
    }
  }

  void _addBackground(TileLayer backgroundLayer) {
    final backgroundType = backgroundLayer.properties.getValue<String?>('BackgroundType');
    final size = Vector2(
      _levelMap.width - (GameSettings.mapBorderWidth != 0 ? GameSettings.tileSize * 2 : 0),
      _levelMap.height - (GameSettings.mapBorderWidth != 0 ? GameSettings.tileSize * 2 : 0),
    );
    final position = Vector2.all(GameSettings.mapBorderWidth != 0 ? GameSettings.tileSize : 0);
    bool isInitialized = false;
    if (backgroundType != null && backgroundType.isNotEmpty) {
      for (var szene in Szene.values) {
        if (szene.fileName == backgroundType) {
          _levelBackground = BackgroundSzene(szene: szene, position: position, size: size);
          isInitialized = true;
          break;
        }
      }
      if (!isInitialized) {
        for (var tileColor in BackgroundTileColor.values) {
          if (tileColor.name == backgroundType) {
            _levelBackground = BackgroundColored(color: tileColor, position: position, size: size);
            break;
          }
        }
      }
    } else {
      _levelBackground = BackgroundSzene(
        szene: game.staticCenter.getWorld(levelMetadata.worldUuid).backgroundSzene,
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
  Future<void> _addWorldCollisions(TileLayer backgroundLayer) async {
    _addWorldBorders();

    // y axis range of map
    final yStart = _hasBorder ? 1 : 0;
    final yEnd = _hasBorder ? _levelMap.tileMap.map.height - 1 : _levelMap.tileMap.map.height;

    // x axis range of map
    final xStart = _hasBorder ? 1 : 0;
    final xEnd = _hasBorder ? _levelMap.tileMap.map.width - 1 : _levelMap.tileMap.map.width;

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

        if ((x % 50) == 0) await yieldFrame();
      }
      await yieldFrame();
    }
    addAll(_collisionBlocks);
  }

  void _addWorldBorders() {
    const borderWidth = GameSettings.tileSize;
    final verticalSize = Vector2(borderWidth, _hasBorder ? _levelMap.height : _levelMap.height + borderWidth * 2);
    final horizontalSize = Vector2(_hasBorder ? _levelMap.width - borderWidth * 2 : _levelMap.width, borderWidth);
    final borders = [
      // top
      WorldBlock(position: Vector2(_hasBorder ? borderWidth : 0, _hasBorder ? 0 : -borderWidth), size: horizontalSize),
      // bottom
      WorldBlock(
        position: Vector2(_hasBorder ? borderWidth : 0, _hasBorder ? _levelMap.height - borderWidth : _levelMap.height),
        size: horizontalSize,
      ),
      // left
      WorldBlock(position: Vector2(_hasBorder ? 0 : -borderWidth, _hasBorder ? 0 : -borderWidth), size: verticalSize),
      // right
      WorldBlock(
        position: Vector2(_hasBorder ? _levelMap.width - borderWidth : _levelMap.width, _hasBorder ? 0 : -borderWidth),
        size: verticalSize,
      ),
    ];

    _collisionBlocks.addAll(borders);
  }

  Future<void> _addSpawningLayer() async {
    final spawnPointsLayer = _levelMap.tileMap.getLayer<ObjectGroup>('Spawning');
    if (spawnPointsLayer == null) return;

    // the start with player is always created first in the level, as many other objects require a reference to the player
    for (var spawnPoint in spawnPointsLayer.objects) {
      if (spawnPoint.class_ == 'Start') {
        final gridPosition = snapVectorToGrid(spawnPoint.position);
        final start = Start(position: gridPosition);
        add(start);
        _player = Player(character: game.storageCenter.settings.character, startPosition: start.playerPosition);
        add(_player);
        _addCheckpointToMiniMap(gridPosition);
        break;
      }
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
            totalFruitsCount++;
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
            for (var singleSaw in (spawnObject as SawCircleComponent).getSingleSaws()) {
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
              position:
                  gridPosition - Vector2(radius - GameSettings.tileSize / 2, SpikedBallBall.gridSize.x / 2 - GameSettings.tileSize / 2),
              size: Vector2(radius * 2, radius + SpikedBallBall.gridSize.x / 2),
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
            spawnObject = Turtle(isLeft: isLeft, player: _player, position: gridPosition);
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

        // add all spawn objects and, if necessary, add them to the mini map
        _spawningObjects.add(spawnObject);
        add(spawnObject);
        if (spawnObject is EntityOnMiniMap) _addEntityToMiniMap(spawnObject);

        if ((++i % 10) == 0) await yieldFrame();
      } catch (e, stack) {
        debugPrint('❌ Failed to spawn object ${spawnPoint.class_} at position (${spawnPoint.x}, ${spawnPoint.y}): $e\n$stack');
      }
    }
  }

  void _addEntityToMiniMap(EntityOnMiniMap entity) => _miniMapEntities.add(entity);

  void _setUpCamera() => game.setUpCameraForLevel(_levelMap.width, _player);

  void _addMobileControls() {
    if (!GameSettings.showMobileControls) {
      _joystick = null;
      _jumpBtn = null;
      return;
    }
    _joystick = JoystickComponent(
      knob: SpriteComponent(sprite: Sprite(game.images.fromCache('HUD/Knob.png'))),
      background: SpriteComponent(sprite: Sprite(game.images.fromCache('HUD/Joystick.png'))),
      margin: EdgeInsets.only(left: GameSettings.hudMargin, bottom: GameSettings.hudMargin),
    );
    _player.setJoystick(_joystick!);
    _jumpBtn = JumpBtn(_player);
    game.camera.viewport.addAll([_joystick, _jumpBtn!]);
  }

  void _removeMobileControls() {
    if (_joystick != null) game.camera.viewport.remove(_joystick);
    if (_jumpBtn != null) game.camera.viewport.remove(_jumpBtn);
  }

  void _addGameHud() {
    _gameHud = GameHud(
      totalFruitsCount: totalFruitsCount,
      miniMapSprite: _readyMadeMiniMapForground,
      levelWidth: _levelMap.width,
      player: _player,
      levelMetadata: levelMetadata,
      miniMapEntities: _miniMapEntities,
    );
    game.camera.viewport.add(_gameHud);
  }

  void _removeGameHud() {
    if (_gameHud.isMounted) game.camera.viewport.remove(_gameHud);
    if (_fpsText != null && _fpsText.isMounted) game.camera.viewport.remove(_fpsText);
  }

  void removeGameHudOnFinish() => _removeGameHud();

  void showGameHud() => _gameHud.show();

  void increaseFruitsCount() => _gameHud.updateFruitCount(++playerFruitsCount);

  void _increaseDeathCount() => _gameHud.updateDeathCount(++deathCount);

  Future<void> _hideLoadingOverlay() async {
    final elapsedMs = DateTime.now().difference(_startTime).inMilliseconds;
    final delayMs = 1400;
    if (elapsedMs < delayMs) await Future.delayed(Duration(milliseconds: delayMs - elapsedMs));
    await game.hideLoadingOverlay();
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

  void playerRespawn() {
    _processRespawns();
    _increaseDeathCount();
  }

  void _calculateEarnedStars() {
    if (playerFruitsCount >= totalFruitsCount) {
      earnedStars = 3;
    } else if (playerFruitsCount >= totalFruitsCount ~/ 2) {
      earnedStars = 2;
    } else {
      earnedStars = 1;
    }
  }

  Future<void> saveData() async {
    _calculateEarnedStars();
    await game.storageCenter.saveLevel(
      data: LevelEntity(
        uuid: levelMetadata.uuid,
        stars: earnedStars,
        totalFruits: totalFruitsCount,
        earnedFruits: playerFruitsCount,
        deaths: deathCount,
      ),
      worldUuid: levelMetadata.worldUuid,
    );
  }

  void pauseLevel() => _gameHud.togglePlayButton();
}
