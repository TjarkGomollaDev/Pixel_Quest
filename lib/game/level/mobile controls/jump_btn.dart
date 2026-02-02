import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:pixel_quest/app_theme.dart';
import 'package:pixel_quest/game/game_settings.dart';
import 'package:pixel_quest/game/game.dart';
import 'package:pixel_quest/game/utils/visible_components.dart';

/// Simple on-screen jump button that triggers the provided callback on tap.
///
/// Uses [VisibleComponent] so it can be shown/hidden without removing it, and ignores taps while hidden.
class JumpBtn extends PositionComponent with HasGameReference<PixelQuest>, TapCallbacks, VisibleComponent {
  // constructor parameters
  final VoidCallback _onJump;

  JumpBtn({required VoidCallback onJump, super.position, bool show = true}) : _onJump = onJump {
    size = Vector2.all(GameSettings.jumpBtnRadius * 2);
    initVisibility(show);
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
      textRenderer: AppTheme.jumpBtn.asTextPaint,
      anchor: Anchor.center,
      position: size / 2 + Vector2.all(1),
    );
    addAll([background, text]);
  }
}
