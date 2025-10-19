import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:pixel_adventure/game/level/background_szene.dart';
import 'package:pixel_adventure/game/level/level_list.dart';
import 'package:pixel_adventure/menu/level_info.dart';
import 'package:pixel_adventure/menu/menu_btns.dart';
import 'package:pixel_adventure/pixel_quest.dart';

class MenuPage extends World with HasGameReference<PixelQuest> {
  final Map<String, LevelInfo> _levelInfos = {};
  StreamSubscription? _sub;

  late final ParallaxComponent _menuBackground;
  final MenuBtns _menuBtns = MenuBtns();

  @override
  FutureOr<void> onLoad() {
    _menuBackground = BackgroundSzene(szene: Szene.szene1, position: Vector2.zero(), size: game.size);
    add(_menuBackground);
    add(_menuBtns);

    int i = 0;
    for (var levelMetadata in allLevels) {
      final y = 40 + 15.0 * i;

      final info = LevelInfo(levelMetadata: levelMetadata, position: Vector2(30, y));
      add(info);
      _levelInfos[levelMetadata.uuid] = info;
      i++;
    }

    return super.onLoad();
  }

  @override
  void onMount() {
    game.setUpCameraForMenu();
    _sub ??= game.dataCenter.onLevelDataChanged.listen((uuid) {
      _levelInfos[uuid]?.updateStars();
    });

    super.onMount();
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
