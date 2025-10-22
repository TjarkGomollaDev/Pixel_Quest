import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/rendering.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/data/border_tiles_config.dart';
import 'package:pixel_adventure/storage/entities/level_entity.dart';
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
import 'package:pixel_adventure/game/hud/game_hud.dart';
import 'package:pixel_adventure/game/hud/jump_btn.dart';
import 'package:pixel_adventure/game/level/background_colored.dart';
import 'package:pixel_adventure/game/level/background_szene.dart';
import 'package:pixel_adventure/data/level_data.dart';
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
import 'package:pixel_adventure/game/traps/saw_circle.dart';
import 'package:pixel_adventure/game/traps/spike_head.dart';
import 'package:pixel_adventure/game/traps/spiked_ball.dart';
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
  final LevelMetadata levelMetadata;

  Level({required this.levelMetadata});

  // level map from Tiled file
  late final TiledComponent _levelMap;

  // level background
  late final ParallaxComponent _levelBackground;

  // all collision blocks
  final List<WorldBlock> _collisionBlocks = [];

  // player
  late final Player _player;

  // HUD
  late final GameHud _gameHud;
  late final JoystickComponent? _joystick;
  late final JumpBtn? _jumpBtn;
  late final FpsTextComponent? _fpsText;

  // fruits count
  int totalFruitsCount = 0;
  int playerFruitsCount = 0;

  // death count
  int deathCount = 0;

  // stars
  int earnedStars = 0;

  // respawnables
  final List<Respawnable> _pendingRespawnables = [];

  @override
  Future<void> onLoad() async {
    _initialSetup();
    await _loadLevelMap();
    _addBackgroundLayer();
    _addSpawningLayer();
    return super.onLoad();
  }

  @override
  void onMount() {
    _setUpCamera();
    _addGameHud();
    _addMobileControls();
    _player.spawnInLevel();
    super.onMount();
  }

  @override
  Future<void> onRemove() async {
    _removeGameHud();
    if (GameSettings.showMobileControls) _removeMobileControls();
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
  }

  Future<void> _addBackgroundLayer() async {
    final backgroundLayer = _levelMap.tileMap.getLayer<TileLayer>('Background');
    if (backgroundLayer != null) {
      await _changeBorderTiles(backgroundLayer);
      _addBackground(backgroundLayer);
      _addWorldCollisions(backgroundLayer);
    }
  }

  Future<void> _changeBorderTiles(TileLayer backgroundLayer) async {
    final config = await BorderTileConfig.load('assets/json/border_tiles.json');

    final layerId = backgroundLayer.id!;
    final width = _levelMap.tileMap.map.width;
    final height = _levelMap.tileMap.map.height;

    Gid getNewGid(int x, int y, int newTile) {
      final oldGid = _levelMap.tileMap.getTileData(layerId: layerId, x: x, y: y);
      return Gid(newTile, oldGid!.flips);
    }

    // 🔸 Top border
    for (int x = 1; x < width - 1; x++) {
      final index = (x - 1) % config.top.length;
      _levelMap.tileMap.setTileData(layerId: layerId, x: x, y: 0, gid: getNewGid(x, 0, config.top[index]));
    }

    // 🔸 Bottom border
    for (int x = 1; x < width - 1; x++) {
      final index = (x - 1) % config.bottom.length;
      _levelMap.tileMap.setTileData(layerId: layerId, x: x, y: height - 1, gid: getNewGid(x, height - 1, config.bottom[index]));
    }

    // 🔸 Left border
    for (int y = 1; y < height - 1; y++) {
      final index = (y - 1) % config.left.length;
      _levelMap.tileMap.setTileData(layerId: layerId, x: 0, y: y, gid: getNewGid(0, y, config.left[index]));
    }

    // 🔸 Right border
    for (int y = 1; y < height - 1; y++) {
      final index = (y - 1) % config.right.length;
      _levelMap.tileMap.setTileData(layerId: layerId, x: width - 1, y: y, gid: getNewGid(width - 1, y, config.right[index]));
    }

    // 🔸 Corners
    _levelMap.tileMap.setTileData(layerId: layerId, x: 0, y: 0, gid: getNewGid(0, 0, config.corners[0])); // top-left
    _levelMap.tileMap.setTileData(layerId: layerId, x: width - 1, y: 0, gid: getNewGid(width - 1, 0, config.corners[1])); // top-right
    _levelMap.tileMap.setTileData(
      layerId: layerId,
      x: width - 1,
      y: height - 1,
      gid: getNewGid(width - 1, height - 1, config.corners[2]),
    ); // bottom-right
    _levelMap.tileMap.setTileData(layerId: layerId, x: 0, y: height - 1, gid: getNewGid(0, height - 1, config.corners[3])); // bottom-left
  }

  void _addBackground(TileLayer backgroundLayer) {
    final backgroundType = backgroundLayer.properties.getValue<String?>('BackgroundType');
    final size = Vector2(
      _levelMap.width - (GameSettings.mapBorderWidth != 0 ? GameSettings.tileSize * 2 : 0),
      _levelMap.height - (GameSettings.mapBorderWidth != 0 ? GameSettings.tileSize * 2 : 0),
    );
    final position = Vector2.all(GameSettings.mapBorderWidth != 0 ? GameSettings.tileSize : 0);
    bool isInitialized = false;
    BackgroundTileColor? color;
    if (backgroundType != null) {
      for (var szene in Szene.values) {
        if (szene.name == backgroundType) {
          _levelBackground = BackgroundSzene(szene: szene, position: position, size: size);
          isInitialized = true;
          break;
        }
      }
      if (!isInitialized) {
        for (var tileColor in BackgroundTileColor.values) {
          if (tileColor.name == backgroundType) {
            color = tileColor;
            break;
          }
        }
      }
    }
    if (!isInitialized) {
      _levelBackground = BackgroundColored(color: color ?? BackgroundTileColor.Gray, position: position, size: size);
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
  void _addWorldCollisions(TileLayer backgroundLayer) {
    _addWorldBorders();
    final hasBorder = GameSettings.mapBorderWidth != 0;

    // y axis range of map
    final yStart = hasBorder ? 1 : 0;
    final yEnd = hasBorder ? _levelMap.tileMap.map.height - 1 : _levelMap.tileMap.map.height;

    // x axis range of map
    final xStart = hasBorder ? 1 : 0;
    final xEnd = hasBorder ? _levelMap.tileMap.map.width - 1 : _levelMap.tileMap.map.width;

    // platform ids
    final platformValues = {18, 19, 20, 40, 41, 42, 62, 63, 64};

    final visited = List.generate(_levelMap.tileMap.map.height, (_) => List.filled(_levelMap.tileMap.map.width, false));

    for (var y = yStart; y < yEnd; y++) {
      for (var x = xStart; x < xEnd; x++) {
        // skip already processed tiles
        if (visited[y][x]) continue;

        // skip empty tiles
        final tile = backgroundLayer.tileData![y][x].tile;
        if (tile == 0) continue;

        // check if current tile is a platform
        final isPlatform = platformValues.contains(tile);

        // find width to the right
        int w = 1;
        while (x + w < xEnd &&
            !visited[y][x + w] &&
            backgroundLayer.tileData![y][x + w].tile != 0 &&
            (isPlatform
                ? platformValues.contains(backgroundLayer.tileData![y][x + w].tile)
                : !platformValues.contains(backgroundLayer.tileData![y][x + w].tile))) {
          w++;
        }

        // find height downwards
        int h = 1;
        if (!isPlatform) {
          bool done = false;
          while (y + h < yEnd && !done) {
            for (var dx = 0; dx < w; dx++) {
              final t = backgroundLayer.tileData![y + h][x + dx].tile;
              if (t == 0 || platformValues.contains(t) || visited[y + h][x + dx]) {
                done = true;
                break;
              }
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
      }
    }
    addAll(_collisionBlocks);
  }

  void _addWorldBorders() {
    const borderWidth = GameSettings.tileSize;
    final hasBorder = GameSettings.mapBorderWidth != 0;
    final verticalSize = Vector2(borderWidth, hasBorder ? _levelMap.height : _levelMap.height + borderWidth * 2);
    final horizontalSize = Vector2(hasBorder ? _levelMap.width - borderWidth * 2 : _levelMap.width, borderWidth);
    final borders = <WorldBlock>[
      // left
      WorldBlock(position: Vector2(hasBorder ? 0 : -borderWidth, hasBorder ? 0 : -borderWidth), size: verticalSize),
      // top
      WorldBlock(position: Vector2(hasBorder ? borderWidth : 0, hasBorder ? 0 : -borderWidth), size: horizontalSize),
      // right
      WorldBlock(
        position: Vector2(hasBorder ? _levelMap.width - borderWidth : _levelMap.width, hasBorder ? 0 : -borderWidth),
        size: verticalSize,
      ),
      // bottom
      WorldBlock(
        position: Vector2(hasBorder ? borderWidth : 0, hasBorder ? _levelMap.height - borderWidth : _levelMap.height),
        size: horizontalSize,
      ),
    ];

    _collisionBlocks.addAll(borders);
  }

  void _addSpawningLayer() {
    final spawnPointsLayer = _levelMap.tileMap.getLayer<ObjectGroup>('Spawning');
    if (spawnPointsLayer == null) return;

    // the start with player is always created first in the level, as many other objects require a reference to the player
    for (var spawnPoint in spawnPointsLayer.objects) {
      if (spawnPoint.class_ == 'Start') {
        final gridPosition = snapVectorToGrid(Vector2(spawnPoint.x, spawnPoint.y));
        final start = Start(position: gridPosition);
        add(start);
        _player = Player(character: game.storageCenter.settings.character, startPosition: start.playerPosition);
        add(_player);
        break;
      }
    }

    // all other objects are created
    for (var spawnPoint in spawnPointsLayer.objects) {
      try {
        final gridPosition = snapVectorToGrid(Vector2(spawnPoint.x, spawnPoint.y));
        switch (spawnPoint.class_) {
          case 'Fruit':
            final fruitName = spawnPoint.name;
            final safeName = FruitName.values.map((e) => e.name).contains(fruitName) ? fruitName : FruitName.Apple.name;
            final fruit = Fruit(name: safeName, position: gridPosition);
            totalFruitsCount++;
            add(fruit);
            break;
          case 'ArrowUp':
            final arrowUp = ArrowUp(player: _player, position: gridPosition);
            add(arrowUp);
            break;
          case 'Saw':
            final offsetNeg = spawnPoint.properties.getValue<double?>('offsetNeg') ?? GameSettings.offsetNegDefault;
            final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? GameSettings.offsetPosDefault;
            final isVertical = spawnPoint.properties.getValue<bool?>('isVertical') ?? GameSettings.isVerticalDefault;
            final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? GameSettings.isLeftDefault;
            final showPath = spawnPoint.properties.getValue<bool?>('showPath') ?? GameSettings.showPath;
            final saw = Saw(
              offsetNeg: offsetNeg,
              offsetPos: offsetPos,
              isVertical: isVertical,
              isLeft: isLeft,
              showPath: showPath,
              player: _player,
              position: gridPosition,
            );
            add(saw);
            break;
          case 'SawCircle':
            final doubleSaw = spawnPoint.properties.getValue<bool?>('doubleSaw') ?? GameSettings.doubleSawDefault;
            final clockwise = spawnPoint.properties.getValue<bool?>('clockwise') ?? GameSettings.clockwiseDefault;
            final sawCircle = SawCircle(
              doubleSaw: doubleSaw,
              clockwise: clockwise,
              player: _player,
              position: gridPosition,
              size: spawnPoint.size,
            );
            add(sawCircle);
            break;
          case 'Spiked Ball':
            final radius =
                (spawnPoint.properties.getValue<int?>('radius') ?? GameSettings.spikedBallRadiusDefault) * GameSettings.tileSize +
                GameSettings.tileSize / 2;
            final startLeft = spawnPoint.properties.getValue<bool?>('startLeft') ?? GameSettings.clockwiseDefault;
            final swingArcDec = spawnPoint.properties.getValue<int?>('swingArcDec') ?? GameSettings.spikedBallSwingArcDec;
            final swingSpeed = spawnPoint.properties.getValue<int?>('swingSpeed') ?? GameSettings.spikedBallSwingSpeed;
            final spikedBall = SpikedBall(
              radius: radius,
              player: _player,
              swingArcDeg: swingArcDec,
              swingSpeed: swingSpeed,
              startLeft: startLeft,
              position:
                  gridPosition - Vector2(radius - GameSettings.tileSize / 2, SpikedBallBall.gridSize.x / 2 - GameSettings.tileSize / 2),
              size: Vector2(radius * 2, radius + SpikedBallBall.gridSize.x / 2),
            );
            add(spikedBall);
            break;
          case 'Chicken':
            final offsetNeg = spawnPoint.properties.getValue<double?>('offsetNeg') ?? GameSettings.offsetNegDefault;
            final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? GameSettings.offsetPosDefault;
            final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? GameSettings.isLeftDefault;
            final chicken = Chicken(offsetNeg: offsetNeg, offsetPos: offsetPos, isLeft: isLeft, player: _player, position: gridPosition);
            add(chicken);
            break;
          case 'Trampoline':
            final trampoline = Trampoline(player: _player, position: gridPosition);
            add(trampoline);
            break;
          case 'Fan':
            final alwaysOn = spawnPoint.properties.getValue<bool?>('alwaysOn') ?? GameSettings.fanAlwaysOnDefault;
            final fan = Fan(alwaysOn: alwaysOn, player: _player, position: gridPosition);
            add(fan);
            break;
          case 'FireTrap':
            final fireTrap = FireTrap(player: _player, position: gridPosition);
            add(fireTrap);
            break;
          case 'Fire':
            final side = spawnPoint.properties.getValue<int?>('side') ?? GameSettings.sideDefault;
            final fire = Fire(side: side, player: _player, position: gridPosition, size: spawnPoint.size);
            add(fire);
            break;
          case 'Moving Platform':
            final offsetNeg = spawnPoint.properties.getValue<double?>('offsetNeg') ?? GameSettings.offsetNegDefault;
            final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? GameSettings.offsetPosDefault;
            final isVertical = spawnPoint.properties.getValue<bool?>('isVertical') ?? GameSettings.isVerticalDefault;
            final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? GameSettings.isLeftDefault;
            final movingPlatform = MovingPlatform(
              offsetNeg: offsetNeg,
              offsetPos: offsetPos,
              isVertical: isVertical,
              isLeft: isLeft,
              player: _player,
              position: gridPosition,
            );
            add(movingPlatform);
            break;
          case 'Rock Head':
            final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? GameSettings.offsetPosDefault;
            final delay = spawnPoint.properties.getValue<double?>('delay') ?? GameSettings.delay;
            final rockHead = RockHead(offsetPos: offsetPos, delay: delay, position: gridPosition);
            add(rockHead);
            break;
          case 'Spike Head':
            final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? GameSettings.offsetPosDefault;
            final delay = spawnPoint.properties.getValue<double?>('delay') ?? GameSettings.delay;
            final spikeHead = SpikeHead(offsetPos: offsetPos, delay: delay, player: _player, position: gridPosition);
            add(spikeHead);
            break;
          case 'Plant':
            final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? GameSettings.isLeftDefault;
            final doubleShot = spawnPoint.properties.getValue<bool?>('doubleShot') ?? GameSettings.doubleShotDefault;
            final plant = Plant(isLeft: isLeft, doubleShot: doubleShot, player: _player, position: gridPosition);
            add(plant);
            break;
          case 'Blue Bird':
            final offsetNeg = spawnPoint.properties.getValue<double?>('offsetNeg') ?? GameSettings.offsetNegDefault;
            final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? GameSettings.offsetPosDefault;
            final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? GameSettings.isLeftDefault;
            final bird = BlueBird(offsetNeg: offsetNeg, offsetPos: offsetPos, isLeft: isLeft, player: _player, position: gridPosition);
            add(bird);
            break;
          case 'Snail':
            final offsetNeg = spawnPoint.properties.getValue<double?>('offsetNeg') ?? GameSettings.offsetNegDefault;
            final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? GameSettings.offsetPosDefault;
            final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? GameSettings.isLeftDefault;
            final snail = Snail(offsetNeg: offsetNeg, offsetPos: offsetPos, isLeft: isLeft, player: _player, position: gridPosition);
            add(snail);
            break;
          case 'Ghost':
            final offsetNeg = spawnPoint.properties.getValue<double?>('offsetNeg') ?? GameSettings.offsetNegDefault;
            final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? GameSettings.offsetPosDefault;
            final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? GameSettings.isLeftDefault;
            final delay = spawnPoint.properties.getValue<double?>('delay') ?? GameSettings.delay;
            final ghost = Ghost(
              offsetNeg: offsetNeg,
              offsetPos: offsetPos,
              isLeft: isLeft,
              delay: delay,
              player: _player,
              position: gridPosition,
            );
            add(ghost);
            break;
          case 'Mushroom':
            final offsetNeg = spawnPoint.properties.getValue<double?>('offsetNeg') ?? GameSettings.offsetNegDefault;
            final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? GameSettings.offsetPosDefault;
            final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? GameSettings.isLeftDefault;
            final mushroom = Mushroom(offsetNeg: offsetNeg, offsetPos: offsetPos, isLeft: isLeft, player: _player, position: gridPosition);
            add(mushroom);
            break;
          case 'Trunk':
            final offsetNeg = spawnPoint.properties.getValue<double?>('offsetNeg') ?? GameSettings.offsetNegDefault;
            final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? GameSettings.offsetPosDefault;
            final extandNegAttack = spawnPoint.properties.getValue<double?>('extandNegAttack') ?? GameSettings.extandNegAttackDefault;
            final extandPosAttack = spawnPoint.properties.getValue<double?>('extandPosAttack') ?? GameSettings.extandPosAttackDefault;
            final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? GameSettings.isLeftDefault;
            final trunk = Trunk(
              offsetNeg: offsetNeg,
              offsetPos: offsetPos,
              extandNegAttack: extandNegAttack,
              extandPosAttack: extandPosAttack,
              isLeft: isLeft,
              player: _player,
              position: gridPosition,
            );
            add(trunk);
            break;
          case 'Slime':
            final offsetNeg = spawnPoint.properties.getValue<double?>('offsetNeg') ?? GameSettings.offsetNegDefault;
            final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? GameSettings.offsetPosDefault;
            final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? GameSettings.isLeftDefault;
            final slime = Slime(offsetNeg: offsetNeg, offsetPos: offsetPos, isLeft: isLeft, player: _player, position: gridPosition);
            add(slime);
            break;
          case 'Turtle':
            final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? GameSettings.isLeftDefault;
            final turtle = Turtle(isLeft: isLeft, player: _player, position: gridPosition);
            add(turtle);
            break;
          case 'Spikes':
            final side = spawnPoint.properties.getValue<int?>('side') ?? GameSettings.sideDefault;
            final spikes = Spikes(side: side, player: _player, position: gridPosition, size: spawnPoint.size);
            add(spikes);
            break;
          case 'Checkpoint':
            final checkpoint = Checkpoint(player: _player, position: gridPosition);
            add(checkpoint);
            break;
          case 'Finish':
            final finish = Finish(player: _player, position: gridPosition);
            add(finish);
            break;
        }
      } catch (e, stack) {
        debugPrint('❌ Failed to spawn object ${spawnPoint.class_} at position (${spawnPoint.x}, ${spawnPoint.y}): $e\n$stack');
      }
    }
  }

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
    _gameHud = GameHud(totalFruitsCount: totalFruitsCount);
    game.camera.viewport.add(_gameHud);
  }

  void _removeGameHud() {
    if (_gameHud.isMounted) game.camera.viewport.remove(_gameHud);
    if (_fpsText != null && _fpsText.isMounted) game.camera.viewport.remove(_fpsText);
  }

  void removeGameHudOnFinish() => _removeGameHud();

  void increaseFruitsCount() => _gameHud.updateFruitCount(++playerFruitsCount);

  void _increaseDeathCount() => _gameHud.updateDeathCount(++deathCount);

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
      LevelEntity(
        uuid: levelMetadata.uuid,
        stars: earnedStars,
        totalFruits: totalFruitsCount,
        earnedFruits: playerFruitsCount,
        deaths: deathCount,
      ),
    );
  }

  void pauseLevel() => _gameHud.togglePlayButton();
}
