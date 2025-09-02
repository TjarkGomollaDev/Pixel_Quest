import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/game/utils/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum InGameActionBtnName {
  achievements('Achievements'),
  back('Back'),
  close('Close'),
  leaderboard('Leaderboard'),
  levels('Levels'),
  next('Next'),
  play('Play'),
  pause('Pause'),
  previous('Previous'),
  restart('Restart'),
  settings('Settings'),
  volume('Volume');

  final String name;

  const InGameActionBtnName(this.name);
}

class InGameActionBtn extends SpriteComponent with HasGameReference<PixelAdventure>, TapCallbacks {
  final InGameActionBtnName _name;
  final void Function() _action;

  InGameActionBtn({required InGameActionBtnName name, required void Function() action, required super.position})
    : _name = name,
      _action = action;

  // size
  static final Vector2 btnSize = Vector2(21, 22);

  // animation settings
  static const String _path = 'Menu/Buttons/';
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
    _action();
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

  void _loadSprite() => sprite = loadSprite(game, '$_path${_name.name}$_pathEnd');

  void setSpriteByName(InGameActionBtnName name) {
    sprite = loadSprite(game, '$_path${name.name}$_pathEnd');
  }
}

class InGameActionToggleBtn extends InGameActionBtn {
  final InGameActionBtnName _name_2;
  final void Function() _action_2;
  bool toggle = true;

  InGameActionToggleBtn({
    required super.name,
    required InGameActionBtnName name_2,
    required super.action,
    required void Function() action_2,
    required super.position,
  }) : _name_2 = name_2,
       _action_2 = action_2;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    setSpriteByName(toggle ? _name : _name_2);
  }

  @override
  void onTapUp(TapUpEvent event) {
    scale = Vector2.all(1.0);
    if (toggle) {
      setSpriteByName(_name_2);
      _action();
    } else {
      setSpriteByName(_name);
      _action_2();
    }
    toggle = !toggle;
  }
}
