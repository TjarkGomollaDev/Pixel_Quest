import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_quest.dart';

class JumpBtn extends PositionComponent with HasGameReference<PixelQuest>, TapCallbacks, HasVisibility {
  // constructor parameters
  final VoidCallback _onJump;

  JumpBtn({required VoidCallback onJump, super.position, bool show = true}) : _onJump = onJump {
    size = Vector2.all(GameSettings.jumpBtnRadius * 2);
    if (!show) hide();
  }

  @override
  FutureOr<void> onLoad() {
    _setUpButton();
    return super.onLoad();
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!isVisible) return;
    _onJump();
    super.onTapDown(event);
  }

  void _setUpButton() {
    final background = CircleComponent(radius: GameSettings.jumpBtnRadius, paint: Paint()..color = AppTheme.tileBlur);
    final text = TextComponent(
      text: 'UP',
      textRenderer: AppTheme.textBtnStandard.asTextPaint,
      anchor: Anchor.center,
      position: size / 2 + Vector2.all(1),
    );
    addAll([background, text]);
  }

  void show() => isVisible = true;
  void hide() => isVisible = false;
}
