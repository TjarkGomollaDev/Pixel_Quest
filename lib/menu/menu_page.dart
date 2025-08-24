import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/game/level/level.dart';
import 'package:pixel_adventure/menu/level_btn.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class MenuPage extends Component with HasGameReference<PixelAdventure> {
  late final TextComponent _logo;
  @override
  FutureOr<void> onLoad() {
    add(
      _logo = TextComponent(
        text: 'Your Game',
        textRenderer: TextPaint(
          style: const TextStyle(fontSize: 64, color: Color(0xFFC8FFF5), fontWeight: FontWeight.w800),
        ),
        anchor: Anchor.center,
      ),
    );
    for (var level in MyLevel.values) {
      final levelBtn = LevelBtn(myLevel: level, position: Vector2(30, 40 + 20.0 * level.index));
      add(levelBtn);
    }
    return super.onLoad();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _logo.position = Vector2(size.x / 2, size.y / 2);
  }
}
