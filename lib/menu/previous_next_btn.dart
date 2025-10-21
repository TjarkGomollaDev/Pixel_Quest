import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/pixel_quest.dart';

enum PreviousNextBtnType { previous, next }

class PreviousNextBtn extends SpriteComponent with HasGameReference<PixelQuest>, TapCallbacks {
  final PreviousNextBtnType _type;
  final void Function() _action;

  PreviousNextBtn({required PreviousNextBtnType type, required void Function() action, required super.position})
    : _type = type,
      _action = action;

  // size
  static final Vector2 btnSize = Vector2(15, 16);

  // animation settings
  static const String _path = 'Menu/Buttons/Back.png';

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadSprite();
    return super.onLoad();
  }

  @override
  void onTapDown(TapDownEvent event) {
    // at this point, it is not sufficient to simply set the scale to 1.0 or 1.05 because of the flip
    scale.setValues(scale.x * 1.05, scale.y * 1.05);
    super.onTapDown(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    // at this point, it is not sufficient to simply set the scale to 1.0 or 1.05 because of the flip
    scale.setValues(scale.x / 1.05, scale.y / 1.05);
    _action();
    super.onTapUp(event);
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    // at this point, it is not sufficient to simply set the scale to 1.0 or 1.05 because of the flip
    scale.setValues(scale.x / 1.05, scale.y / 1.05);
    super.onTapCancel(event);
  }

  void _initialSetup() {
    // debug
    debugColor = Colors.transparent;

    // general
    anchor = Anchor.center;
  }

  void _loadSprite() {
    sprite = loadSprite(game, _path);
    if (_type == PreviousNextBtnType.next) flipHorizontally();
  }
}
