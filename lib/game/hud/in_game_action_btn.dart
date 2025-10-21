import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/pixel_quest.dart';

enum InGameActionBtnType {
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

  final String fileName;

  const InGameActionBtnType(this.fileName);
}

class InGameActionBtn extends SpriteComponent with HasGameReference<PixelQuest>, TapCallbacks {
  final InGameActionBtnType _type;
  final void Function() _action;

  InGameActionBtn({required InGameActionBtnType type, required void Function() action, required super.position})
    : _type = type,
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

  void _loadSprite() => sprite = loadSprite(game, '$_path${_type.fileName}$_pathEnd');

  void setSpriteByName(InGameActionBtnType name) {
    sprite = loadSprite(game, '$_path${name.fileName}$_pathEnd');
  }
}

class InGameActionToggleBtn extends InGameActionBtn {
  final InGameActionBtnType _type_2;
  final void Function() _action_2;
  bool toggle = true;

  InGameActionToggleBtn({
    required super.type,
    required InGameActionBtnType type_2,
    required super.action,
    required void Function() action_2,
    required super.position,
  }) : _type_2 = type_2,
       _action_2 = action_2;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    setSpriteByName(toggle ? _type : _type_2);
  }

  @override
  void onTapUp(TapUpEvent event) {
    scale = Vector2.all(1.0);
    if (toggle) {
      setSpriteByName(_type_2);
      _action();
    } else {
      setSpriteByName(_type);
      _action_2();
    }
    toggle = !toggle;
  }

  void triggerToggle() {
    if (toggle) {
      setSpriteByName(_type_2);
      _action();
    } else {
      setSpriteByName(_type);
      _action_2();
    }
    toggle = !toggle;
  }
}
