import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/game/level/level_list.dart';
import 'package:pixel_adventure/menu/level_info.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class MenuPage extends Component with HasGameReference<PixelAdventure> {
  late final TextComponent _logo;
  final Map<String, LevelInfo> _levelInfos = {};
  late final StreamSubscription _sub;

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
    int i = 0;
    for (var levelMetadata in allLevels) {
      final y = 40 + 15.0 * i;

      final info = LevelInfo(levelMetadata: levelMetadata, position: Vector2(30, y));
      add(info);
      _levelInfos[levelMetadata.uuid] = info;
      i++;
    }

    _sub = game.dataCenter.onLevelDataChanged.listen((uuid) => _levelInfos[uuid]!.updateStars());

    return super.onLoad();
  }

  @override
  void onRemove() {
    _sub.cancel();
    super.onRemove();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _logo.position = Vector2(size.x / 2, size.y / 2);
  }
}
