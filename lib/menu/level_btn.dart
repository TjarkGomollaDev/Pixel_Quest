import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/game/level/level_list.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class LevelBtn extends SpriteComponent with HasGameReference<PixelAdventure>, TapCallbacks {
  final LevelMetadata _levelMetadata;

  LevelBtn({required LevelMetadata levelMetadata, required super.position}) : _levelMetadata = levelMetadata;

  // size
  static final Vector2 btnSize = Vector2(19, 17);

  // animation settings
  static const String _path = 'Menu/Levels/';
  static const String _pathEnd = '.png';

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadSprite();
    return super.onLoad();
  }

  @override
  void onTapDown(TapDownEvent event) {
    scale = Vector2.all(1.05);
    super.onTapDown(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    scale = Vector2.all(1.0);
    game.router.pushNamed(_levelMetadata.uuid);
    super.onTapUp(event);
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    scale = Vector2.all(1.0);
    super.onTapCancel(event);
  }

  void _initialSetup() {
    // debug
    debugColor = Colors.transparent;

    // general
    anchor = Anchor.center;
  }

  void _loadSprite() => sprite = loadSprite(game, '$_path${_levelMetadata.btnFileName}$_pathEnd');
}
