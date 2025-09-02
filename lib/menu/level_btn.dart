import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/game/level/level.dart';
import 'package:pixel_adventure/game/utils/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class LevelBtn extends SpriteComponent with HasGameReference<PixelAdventure>, TapCallbacks {
  final MyLevel _myLevel;

  LevelBtn({required MyLevel myLevel, required super.position}) : _myLevel = myLevel;

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
    game.router.pushNamed(_myLevel.name);
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

  void _loadSprite() => sprite = loadSprite(game, '$_path${_myLevel.btnName}$_pathEnd');
}
