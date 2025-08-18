import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/components/enemies/blue_bird.dart';
import 'package:pixel_adventure/components/enemies/chicken.dart';
import 'package:pixel_adventure/components/enemies/ghost.dart';
import 'package:pixel_adventure/components/enemies/mushroom.dart';
import 'package:pixel_adventure/components/enemies/plant.dart';
import 'package:pixel_adventure/components/enemies/slime.dart';
import 'package:pixel_adventure/components/enemies/snail.dart';
import 'package:pixel_adventure/components/enemies/trunk.dart';
import 'package:pixel_adventure/components/enemies/turtle.dart';
import 'package:pixel_adventure/components/jump_btn.dart';
import 'package:pixel_adventure/components/level/level_background.dart';
import 'package:pixel_adventure/components/traps/checkpoint.dart';
import 'package:pixel_adventure/components/collision_block.dart';
import 'package:pixel_adventure/components/traps/fan.dart';
import 'package:pixel_adventure/components/traps/fire.dart';
import 'package:pixel_adventure/components/traps/fire_trap.dart';
import 'package:pixel_adventure/components/traps/fruit.dart';
import 'package:pixel_adventure/components/level/player.dart';
import 'package:pixel_adventure/components/traps/moving_platform.dart';
import 'package:pixel_adventure/components/traps/saw.dart';
import 'package:pixel_adventure/components/traps/saw_circle.dart';
import 'package:pixel_adventure/components/traps/spikes.dart';
import 'package:pixel_adventure/components/traps/trampoline.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum LevelName {
  firstLevel('Level_01'),
  secondLevel('Level_02'),
  thirdLevel('Level_03');

  final String name;
  const LevelName(this.name);
}

class Level extends World with HasGameReference<PixelAdventure>, TapCallbacks {
  final LevelName levelName;
  Level({required this.levelName});

  // level map from Tiled file
  late final TiledComponent _levelMap;

  late final LevelBackground _levelBackground;

  // all collision blocks
  final List<CollisionBlock> _collisionBlocks = [];

  // player
  late final Player _player;

  // mobile controls
  late final JoystickComponent? _joystick;
  late final JumpBtn? _jumpBtn;

  @override
  Future<void> onLoad() async {
    await _addLevelMap();
    _addLevelBackground();
    _addSpawningObjects();
    _addCollisions();
    if (game.showMobileControls) _addMobileControls();

    return super.onLoad();
  }

  @override
  Future<void> onRemove() async {
    // remove mobile controls from game
    if (_joystick != null && _jumpBtn != null) {
      game.remove(_joystick);
      game.remove(_jumpBtn);
    }

    return super.onRemove();
  }

  Future<void> _addLevelMap() async {
    _levelMap = await TiledComponent.load('${levelName.name}.tmx', Vector2.all(16))
      ..priority = PixelAdventure.mapLayerLevel;
    add(_levelMap);
  }

  void _addLevelBackground() {
    final backgroundLayer = _levelMap.tileMap.getLayer('Background');
    if (backgroundLayer != null) {
      final backgroundColor = backgroundLayer.properties.getValue('BackgroundColor');
      const allowedColors = ['Blue', 'Brown', 'Gray', 'Green', 'Pink', 'Purple', 'Yellow'];
      final safeColor = allowedColors.contains(backgroundColor) ? backgroundColor : 'Gray';
      _levelBackground = LevelBackground(color: safeColor, position: Vector2.zero())..priority = PixelAdventure.backgroundLayerLevel;
      add(_levelBackground);
    }
  }

  void _addSpawningObjects() {
    final spawnPointsLayer = _levelMap.tileMap.getLayer<ObjectGroup>('Spawnpoints');
    if (spawnPointsLayer != null) {
      // the player is always created first in the level, as many other objects require a reference to the player
      for (var spawnPoint in spawnPointsLayer.objects) {
        if (spawnPoint.class_ == 'Player') {
          _player = Player(character: game.characters[game.yourCharacterIndex]);
          _player.position = Vector2(spawnPoint.x, spawnPoint.y);
          _player.scale.x = 1;
          add(_player);
          break;
        }
      }

      // all other objects are created
      for (var spawnPoint in spawnPointsLayer.objects) {
        switch (spawnPoint.class_) {
          case 'Fruit':
            final fruit = Fruit(
              name: spawnPoint.name,
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
            );
            add(fruit);
            break;
          case 'Saw':
            final bool isVertical = spawnPoint.properties.getValue('isVertical');
            final double offsetNeg = spawnPoint.properties.getValue('offsetNeg');
            final double offsetPos = spawnPoint.properties.getValue('offsetPos');
            final saw = Saw(
              offsetNeg: offsetNeg,
              offsetPos: offsetPos,
              isVertical: isVertical,
              position: Vector2(spawnPoint.x, spawnPoint.y),
            );
            add(saw);
            break;
          case 'SawCircle':
            final double circleWidth = spawnPoint.properties.getValue('circleWidth');
            final double circleHeight = spawnPoint.properties.getValue('circleHeight');
            final bool doubleSaw = spawnPoint.properties.getValue('doubleSaw');
            final bool clockwise = spawnPoint.properties.getValue('clockwise');
            final sawCircle = SawCircle(
              doubleSaw: doubleSaw,
              clockwise: clockwise,
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(circleWidth * game.tileSize, circleHeight * game.tileSize),
            );
            add(sawCircle);
            break;
          case 'Chicken':
            final double offsetNeg = spawnPoint.properties.getValue('offsetNeg');
            final double offsetPos = spawnPoint.properties.getValue('offsetPos');
            final bool isLeft = spawnPoint.properties.getValue('isLeft');
            final chicken = Chicken(
              offsetNeg: offsetNeg,
              offsetPos: offsetPos,
              isLeft: isLeft,
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
              player: _player,
            );
            add(chicken);
            break;
          case 'Trampoline':
            final trampoline = Trampoline(
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
              player: _player,
            );
            add(trampoline);
            break;
          case 'Fan':
            final fan = Fan(position: Vector2(spawnPoint.x, spawnPoint.y), player: _player);
            add(fan);
            break;
          case 'FireTrap':
            final fireTrap = FireTrap(
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
              player: _player,
            );
            add(fireTrap);
            final block = CollisionBlock(
              position: Vector2(spawnPoint.x, spawnPoint.y + game.tileSize),
              size: Vector2(spawnPoint.width, game.tileSize),
            );
            _collisionBlocks.add(block);
            break;
          case 'Fire':
            final fire = Fire(position: Vector2(spawnPoint.x, spawnPoint.y), size: Vector2(spawnPoint.width, spawnPoint.height));
            add(fire);
            break;
          case 'Moving Platform':
            final bool isVertical = spawnPoint.properties.getValue('isVertical');
            final double offsetNeg = spawnPoint.properties.getValue('offsetNeg');
            final double offsetPos = spawnPoint.properties.getValue('offsetPos');
            final movingPlatform = MovingPlatform(
              isVertical: isVertical,
              offsetNeg: offsetNeg,
              offsetPos: offsetPos,
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
              player: _player,
            );
            final block = CollisionBlock(
              position: Vector2(spawnPoint.x - spawnPoint.width / 2, spawnPoint.y + 2),
              size: Vector2(spawnPoint.width, 5),
            );
            _collisionBlocks.add(block);
            movingPlatform.setCollisionBlock(block);
            add(movingPlatform);
            break;
          case 'Plant':
            final bool isLeft = spawnPoint.properties.getValue('isLeft');
            final bool doubleShot = spawnPoint.properties.getValue('doubleShot');
            final plant = Plant(
              isLeft: isLeft,
              doubleShot: doubleShot,
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
              player: _player,
            );
            add(plant);
            break;
          case 'Blue Bird':
            final double offsetNeg = spawnPoint.properties.getValue('offsetNeg');
            final double offsetPos = spawnPoint.properties.getValue('offsetPos');
            final bool isLeft = spawnPoint.properties.getValue('isLeft');
            final bird = BlueBird(
              offsetNeg: offsetNeg,
              offsetPos: offsetPos,
              isLeft: isLeft,
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
              player: _player,
            );
            add(bird);
            break;
          case 'Snail':
            final double offsetNeg = spawnPoint.properties.getValue('offsetNeg');
            final double offsetPos = spawnPoint.properties.getValue('offsetPos');
            final bool isLeft = spawnPoint.properties.getValue('isLeft');
            final snail = Snail(
              offsetNeg: offsetNeg,
              offsetPos: offsetPos,
              isLeft: isLeft,
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
              player: _player,
            );
            add(snail);
            break;
          case 'Ghost':
            final double offsetNeg = spawnPoint.properties.getValue('offsetNeg');
            final double offsetPos = spawnPoint.properties.getValue('offsetPos');
            final bool isLeft = spawnPoint.properties.getValue('isLeft');
            final ghost = Ghost(
              offsetNeg: offsetNeg,
              offsetPos: offsetPos,
              isLeft: isLeft,
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
              player: _player,
            );
            add(ghost);
            break;
          case 'Mushroom':
            final double offsetNeg = spawnPoint.properties.getValue('offsetNeg');
            final double offsetPos = spawnPoint.properties.getValue('offsetPos');
            final bool isLeft = spawnPoint.properties.getValue('isLeft');
            final mushroom = Mushroom(
              offsetNeg: offsetNeg,
              offsetPos: offsetPos,
              isLeft: isLeft,
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
              player: _player,
            );
            add(mushroom);
            break;
          case 'Trunk':
            final double offsetNeg = spawnPoint.properties.getValue('offsetNeg');
            final double offsetPos = spawnPoint.properties.getValue('offsetPos');
            final double extandNegAttack = spawnPoint.properties.getValue('extandNegAttack');
            final double extandPosAttack = spawnPoint.properties.getValue('extandPosAttack');
            final bool isLeft = spawnPoint.properties.getValue('isLeft');
            final trunk = Trunk(
              offsetNeg: offsetNeg,
              offsetPos: offsetPos,
              extandNegAttack: extandNegAttack,
              extandPosAttack: extandPosAttack,
              isLeft: isLeft,
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
              player: _player,
            );
            add(trunk);
            break;
          case 'Slime':
            final double offsetNeg = spawnPoint.properties.getValue('offsetNeg');
            final double offsetPos = spawnPoint.properties.getValue('offsetPos');
            final bool isLeft = spawnPoint.properties.getValue('isLeft');
            final slime = Slime(
              offsetNeg: offsetNeg,
              offsetPos: offsetPos,
              isLeft: isLeft,
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
              player: _player,
            );
            add(slime);
            break;
          case 'Turtle':
            final bool isLeft = spawnPoint.properties.getValue('isLeft');
            final turtle = Turtle(
              isLeft: isLeft,
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
              player: _player,
            );
            add(turtle);
            break;
          case 'Spikes':
            final int side = spawnPoint.properties.getValue('side');
            final spikes = Spikes(
              side: side,
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
            );
            add(spikes);
            break;
          case 'Checkpoint':
            final checkpoint = Checkpoint(
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
            );
            add(checkpoint);
            break;
        }
      }
    }
  }

  void _addCollisions() {
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

  void _addMobileControls() {
    _joystick = JoystickComponent(
      knob: SpriteComponent(sprite: Sprite(game.images.fromCache('HUD/Knob.png'))),
      background: SpriteComponent(sprite: Sprite(game.images.fromCache('HUD/Joystick.png'))),
      margin: const EdgeInsets.only(left: 32, bottom: 32),
      knobRadius: 64,
    );
    _player.setJoystick(_joystick!);
    _jumpBtn = JumpBtn(_player);
    game.add(_joystick);
    game.add(_jumpBtn!);
  }
}
