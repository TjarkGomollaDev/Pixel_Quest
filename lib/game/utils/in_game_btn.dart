import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/pixel_quest.dart';

enum InGameBtnType {
  // normal size
  achievements('Achievements'),
  leaderboard('Leaderboard'),
  levels('Levels'),
  next('Next'),
  play('Play'),
  pause('Pause'),
  previous('Previous'),
  restart('Restart'),
  settings('Settings'),
  volumeOn('Volume On'),
  volumeOff('Volume Off'),

  // small size
  closeSmall('Close Small'),
  backSmall('Back Small'),
  editSmall('Edit Small'),
  previousSmall('Previous Small'),
  nexStSmall('Next Small');

  final String fileName;

  const InGameBtnType(this.fileName);
}

class InGameBtn extends SpriteComponent with HasGameReference<PixelQuest>, TapCallbacks, HasVisibility {
  final InGameBtnType _type;
  final void Function() _action;

  InGameBtn({required InGameBtnType type, required void Function() action, required super.position, bool show = true})
    : _type = type,
      _action = action {
    if (!show) hide();
  }

  // size
  static final Vector2 btnSize = Vector2(21, 22);
  static final Vector2 btnSizeSmall = Vector2(15, 16);

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

  void setSpriteByName(InGameBtnType name) => sprite = loadSprite(game, '$_path${name.fileName}$_pathEnd');

  void show() => isVisible = true;

  void hide() => isVisible = false;

  Future<void> animatedShow({double duration = 0.25}) async {
    if (isVisible) return;
    scale = Vector2.all(0);
    isVisible = true;

    final completer = Completer<void>();
    final controller = EffectController(duration: duration, curve: Curves.easeOutBack);

    add(ScaleEffect.to(Vector2.all(1.0), controller, onComplete: () => completer.complete()));

    return completer.future;
  }
}

class InGameToggleBtn extends InGameBtn {
  final InGameBtnType _type_2;
  final void Function() _action_2;
  bool toggle = true;

  InGameToggleBtn({
    required super.type,
    required InGameBtnType type_2,
    required super.action,
    required void Function() action_2,
    required super.position,
    bool show = true,
    bool initialState = true,
  }) : _type_2 = type_2,
       _action_2 = action_2 {
    if (!show) hide();
    if (!initialState) toggle = false;
  }

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
