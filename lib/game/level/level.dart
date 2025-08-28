import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/rendering.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
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
import 'package:pixel_adventure/game/level/level_background.dart';
import 'package:pixel_adventure/game/traps/arrow_up.dart';
import 'package:pixel_adventure/game/checkpoints/finish.dart';
import 'package:pixel_adventure/game/traps/rock_head.dart';
import 'package:pixel_adventure/game/checkpoints/checkpoint.dart';
import 'package:pixel_adventure/game/collision_block.dart';
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
import 'package:pixel_adventure/game/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum MyLevel {
  level_1('Level_01', '01', 1),
  level_2('Level_02', '02', 2),
  level_3('Level_03', '03', 3);

  final String name;
  final String btnName;
  final int levelIndex;

  const MyLevel(this.name, this.btnName, this.levelIndex);
}

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

class Level extends DecoratedWorld with HasGameReference<PixelAdventure>, TapCallbacks {
  final MyLevel myLvel;

  Level({required this.myLvel});

  // level map from Tiled file
  late final TiledComponent _levelMap;

  // level background
  late final LevelBackground _levelBackground;

  // all collision blocks
  final List<CollisionBlock> _collisionBlocks = [];

  // player
  late final Player _player;

  // HUD
  late final GameHud _gameHud;
  late final JoystickComponent? _joystick;
  late final JumpBtn? _jumpBtn;
  late final FpsTextComponent? _fpsText;

  // count fruits
  int totalFruitsCount = 0;
  int playerFruitsCount = 0;

  @override
  Future<void> onLoad() async {
    _initialSetup();
    await _addLevelMap();
    _addLevelBackground();
    _addSpawningObjects();
    _addCollisions();
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
    if (game.showMobileControls) _removeMobileControls();
    return super.onRemove();
  }

  void _initialSetup() {
    // debug
    if (game.customDebug) {
      _fpsText = FpsTextComponent(
        position: Vector2(game.size.x, 0) + Vector2(-game.hudMargin, game.hudMargin / 2),
        anchor: Anchor.topRight,
      );
      game.camera.viewport.add(_fpsText!);
    } else {
      _fpsText = null;
    }

    // general
  }

  Future<void> _addLevelMap() async {
    _levelMap = await TiledComponent.load('${myLvel.name}.tmx', Vector2.all(PixelAdventure.tileSize))
      ..priority = PixelAdventure.mapLayerLevel;
    add(_levelMap);
  }

  void _addLevelBackground() {
    final backgroundLayer = _levelMap.tileMap.getLayer<TileLayer>('Background');
    if (backgroundLayer != null) {
      final backgroundColor = backgroundLayer.properties.getValue<String?>('BackgroundColor');
      final safeColor = BackgroundTileColor.values.map((e) => e.name).contains(backgroundColor)
          ? backgroundColor
          : BackgroundTileColor.Gray.name;
      _levelBackground = LevelBackground(color: safeColor!, position: Vector2.zero(), size: Vector2(_levelMap.width, _levelMap.height))
        ..priority = PixelAdventure.backgroundLayerLevel;
      add(_levelBackground);
    }
  }

  void _addSpawningObjects() {
    final spawnPointsLayer = _levelMap.tileMap.getLayer<ObjectGroup>('Spawnpoints');
    if (spawnPointsLayer != null) {
      // the start with player is always created first in the level, as many other objects require a reference to the player
      for (var spawnPoint in spawnPointsLayer.objects) {
        if (spawnPoint.class_ == 'Start') {
          final gridPosition = snapVectorToGrid(Vector2(spawnPoint.x, spawnPoint.y));
          final start = Start(position: gridPosition);
          add(start);
          _player = Player(character: game.characters[game.yourCharacterIndex], startPosition: start.playerPosition);
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
              final offsetNeg = spawnPoint.properties.getValue<double?>('offsetNeg') ?? PixelAdventure.offsetNegDefault;
              final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? PixelAdventure.offsetPosDefault;
              final isVertical = spawnPoint.properties.getValue<bool?>('isVertical') ?? PixelAdventure.isVerticalDefault;
              final saw = Saw(offsetNeg: offsetNeg, offsetPos: offsetPos, isVertical: isVertical, player: _player, position: gridPosition);
              add(saw);
              break;
            case 'SawCircle':
              final circleWidth = spawnPoint.properties.getValue<int?>('circleWidth') ?? PixelAdventure.circleWidthDefault;
              final circleHeight = spawnPoint.properties.getValue<int?>('circleHeight') ?? PixelAdventure.circleHeightDefault;
              final doubleSaw = spawnPoint.properties.getValue<bool?>('doubleSaw') ?? PixelAdventure.doubleSawDefault;
              final clockwise = spawnPoint.properties.getValue<bool?>('clockwise') ?? PixelAdventure.clockwiseDefault;
              final sawCircle = SawCircle(
                doubleSaw: doubleSaw,
                clockwise: clockwise,
                player: _player,
                position: gridPosition,
                size: Vector2(circleWidth * PixelAdventure.tileSize, circleHeight * PixelAdventure.tileSize),
              );
              add(sawCircle);
              break;
            case 'Spiked Ball':
              final radius =
                  (spawnPoint.properties.getValue<int?>('radius') ?? PixelAdventure.spikedBallRadiusDefault) * PixelAdventure.tileSize +
                  PixelAdventure.tileSize / 2;
              final startLeft = spawnPoint.properties.getValue<bool?>('startLeft') ?? PixelAdventure.clockwiseDefault;
              final swingArcDec = spawnPoint.properties.getValue<int?>('swingArcDec') ?? PixelAdventure.spikedBallSwingArcDec;
              final swingSpeed = spawnPoint.properties.getValue<int?>('swingSpeed') ?? PixelAdventure.spikedBallSwingSpeed;
              final spikedBall = SpikedBall(
                radius: radius,
                player: _player,
                swingArcDeg: swingArcDec,
                swingSpeed: swingSpeed,
                startLeft: startLeft,
                position:
                    gridPosition -
                    Vector2(radius - PixelAdventure.tileSize / 2, SpikedBallBall.gridSize.x / 2 - PixelAdventure.tileSize / 2),
                size: Vector2(radius * 2, radius + SpikedBallBall.gridSize.x / 2),
              );
              add(spikedBall);
              break;
            case 'Chicken':
              final offsetNeg = spawnPoint.properties.getValue<double?>('offsetNeg') ?? PixelAdventure.offsetNegDefault;
              final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? PixelAdventure.offsetPosDefault;
              final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? PixelAdventure.isLeftDefault;
              final chicken = Chicken(offsetNeg: offsetNeg, offsetPos: offsetPos, isLeft: isLeft, player: _player, position: gridPosition);
              add(chicken);
              break;
            case 'Trampoline':
              final trampoline = Trampoline(player: _player, position: gridPosition);
              add(trampoline);
              break;
            case 'Fan':
              final alwaysOn = spawnPoint.properties.getValue<bool?>('alwaysOn') ?? PixelAdventure.fanAlwaysOnDefault;
              final fan = Fan(alwaysOn: alwaysOn, player: _player, position: gridPosition);
              add(fan);
              break;
            case 'FireTrap':
              final fireTrap = FireTrap(player: _player, position: gridPosition);
              add(fireTrap);
              final block = CollisionBlock(
                position: Vector2(spawnPoint.x, spawnPoint.y + PixelAdventure.tileSize),
                size: Vector2(spawnPoint.width, PixelAdventure.tileSize),
              );
              _collisionBlocks.add(block);
              break;
            case 'Fire':
              final side = spawnPoint.properties.getValue<int?>('side') ?? PixelAdventure.sideDefault;
              final fire = Fire(side: side, player: _player, position: gridPosition, size: spawnPoint.size);
              add(fire);
              break;
            case 'Moving Platform':
              final offsetNeg = spawnPoint.properties.getValue<double?>('offsetNeg') ?? PixelAdventure.offsetNegDefault;
              final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? PixelAdventure.offsetPosDefault;
              final isVertical = spawnPoint.properties.getValue<bool?>('isVertical') ?? PixelAdventure.isVerticalDefault;
              final block = CollisionBlock(
                position: Vector2(spawnPoint.x - spawnPoint.width / 2, spawnPoint.y + 2),
                size: Vector2(spawnPoint.width, 5),
              );
              final movingPlatform = MovingPlatform(
                isVertical: isVertical,
                offsetNeg: offsetNeg,
                offsetPos: offsetPos,
                player: _player,
                block: block,
                position: gridPosition,
              );
              _collisionBlocks.add(block);
              add(movingPlatform);
              break;
            case 'Rock Head':
              final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? PixelAdventure.offsetPosDefault;
              final block = CollisionBlock(
                position: Vector2(spawnPoint.x, spawnPoint.y),
                size: Vector2(spawnPoint.width, spawnPoint.height),
              );
              final rockHead = RockHead(offsetPos: offsetPos, position: gridPosition, block: block);
              _collisionBlocks.add(block);
              add(rockHead);
              break;
            case 'Spike Head':
              final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? PixelAdventure.offsetPosDefault;
              final spikeHead = SpikeHead(offsetPos: offsetPos, player: _player, position: gridPosition);
              add(spikeHead);
              break;
            case 'Plant':
              final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? PixelAdventure.isLeftDefault;
              final doubleShot = spawnPoint.properties.getValue<bool?>('doubleShot') ?? PixelAdventure.doubleShotDefault;
              final plant = Plant(isLeft: isLeft, doubleShot: doubleShot, player: _player, position: gridPosition);
              add(plant);
              break;
            case 'Blue Bird':
              final offsetNeg = spawnPoint.properties.getValue<double?>('offsetNeg') ?? PixelAdventure.offsetNegDefault;
              final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? PixelAdventure.offsetPosDefault;
              final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? PixelAdventure.isLeftDefault;
              final bird = BlueBird(offsetNeg: offsetNeg, offsetPos: offsetPos, isLeft: isLeft, player: _player, position: gridPosition);
              add(bird);
              break;
            case 'Snail':
              final offsetNeg = spawnPoint.properties.getValue<double?>('offsetNeg') ?? PixelAdventure.offsetNegDefault;
              final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? PixelAdventure.offsetPosDefault;
              final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? PixelAdventure.isLeftDefault;
              final snail = Snail(offsetNeg: offsetNeg, offsetPos: offsetPos, isLeft: isLeft, player: _player, position: gridPosition);
              add(snail);
              break;
            case 'Ghost':
              final offsetNeg = spawnPoint.properties.getValue<double?>('offsetNeg') ?? PixelAdventure.offsetNegDefault;
              final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? PixelAdventure.offsetPosDefault;
              final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? PixelAdventure.isLeftDefault;
              final ghost = Ghost(offsetNeg: offsetNeg, offsetPos: offsetPos, isLeft: isLeft, player: _player, position: gridPosition);
              add(ghost);
              break;
            case 'Mushroom':
              final offsetNeg = spawnPoint.properties.getValue<double?>('offsetNeg') ?? PixelAdventure.offsetNegDefault;
              final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? PixelAdventure.offsetPosDefault;
              final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? PixelAdventure.isLeftDefault;
              final mushroom = Mushroom(
                offsetNeg: offsetNeg,
                offsetPos: offsetPos,
                isLeft: isLeft,
                player: _player,
                position: gridPosition,
              );
              add(mushroom);
              break;
            case 'Trunk':
              final offsetNeg = spawnPoint.properties.getValue<double?>('offsetNeg') ?? PixelAdventure.offsetNegDefault;
              final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? PixelAdventure.offsetPosDefault;
              final extandNegAttack = spawnPoint.properties.getValue<double?>('extandNegAttack') ?? PixelAdventure.extandNegAttackDefault;
              final extandPosAttack = spawnPoint.properties.getValue<double?>('extandPosAttack') ?? PixelAdventure.extandPosAttackDefault;
              final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? PixelAdventure.isLeftDefault;
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
              final offsetNeg = spawnPoint.properties.getValue<double?>('offsetNeg') ?? PixelAdventure.offsetNegDefault;
              final offsetPos = spawnPoint.properties.getValue<double?>('offsetPos') ?? PixelAdventure.offsetPosDefault;
              final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? PixelAdventure.isLeftDefault;
              final slime = Slime(offsetNeg: offsetNeg, offsetPos: offsetPos, isLeft: isLeft, player: _player, position: gridPosition);
              add(slime);
              break;
            case 'Turtle':
              final isLeft = spawnPoint.properties.getValue<bool?>('isLeft') ?? PixelAdventure.isLeftDefault;
              final turtle = Turtle(isLeft: isLeft, player: _player, position: gridPosition);
              add(turtle);
              break;
            case 'Spikes':
              final side = spawnPoint.properties.getValue<int?>('side') ?? PixelAdventure.sideDefault;
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
  }

  void _addCollisions() {
    _addWorldBorders();
    final collisionsLayer = _levelMap.tileMap.getLayer<ObjectGroup>('Collisions');
    if (collisionsLayer != null) {
      for (var collision in collisionsLayer.objects) {
        switch (collision.class_) {
          case 'Plattform':
            final platform = CollisionBlock(
              isPlattform: true,
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
            );
            _collisionBlocks.add(platform);
            break;
          default:
            final block = CollisionBlock(position: Vector2(collision.x, collision.y), size: Vector2(collision.width, collision.height));
            _collisionBlocks.add(block);
        }
      }

      addAll(_collisionBlocks);
    }
    _player.collisionBlocks = _collisionBlocks;
  }

  void _addWorldBorders() {
    const borderWidth = 16.0;
    final borders = [
      // position, size
      [Vector2(-borderWidth, -borderWidth), Vector2(borderWidth, _levelMap.height + borderWidth * 2)], // left
      [Vector2(_levelMap.width, -borderWidth), Vector2(borderWidth, _levelMap.height + borderWidth * 2)], // right
      [Vector2(0, -borderWidth), Vector2(_levelMap.width, borderWidth)], // top
      [Vector2(0, _levelMap.height), Vector2(_levelMap.width, borderWidth)], // bottom
    ];

    _collisionBlocks.addAll(borders.map((b) => CollisionBlock(position: b[0], size: b[1])));
  }

  void _setUpCamera() => game.setUpCameraForLevel(_levelMap.width, _player);

  void _addMobileControls() {
    if (!game.showMobileControls) {
      _joystick = null;
      _jumpBtn = null;
      return;
    }
    _joystick = JoystickComponent(
      knob: SpriteComponent(sprite: Sprite(game.images.fromCache('HUD/Knob.png'))),
      background: SpriteComponent(sprite: Sprite(game.images.fromCache('HUD/Joystick.png'))),
      margin: EdgeInsets.only(left: game.hudMargin, bottom: game.hudMargin),
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

  void increaseFruitsCount() {
    playerFruitsCount++;
    _gameHud.updateFruitCounter(playerFruitsCount);
  }
}
