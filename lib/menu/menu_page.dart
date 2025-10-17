import 'dart:async';
import 'package:flame/components.dart';
import 'package:pixel_adventure/game/level/background_szene.dart';
import 'package:pixel_adventure/game/level/level_list.dart';
import 'package:pixel_adventure/menu/level_info.dart';
import 'package:pixel_adventure/pixel_quest.dart';

class MenuPage extends Component with HasGameReference<PixelQuest> {
  final Map<String, LevelInfo> _levelInfos = {};
  StreamSubscription? _sub;

  late final ParallaxComponent _menuBackground;

  @override
  FutureOr<void> onLoad() {
    _menuBackground = BackgroundSzene(szene: Szene.szene1, position: Vector2.zero(), size: game.camera.viewport.size);
    add(_menuBackground);

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
    _sub ??= game.dataCenter.onLevelDataChanged.listen((uuid) => _levelInfos[uuid]?.updateStars());
    super.onMount();
  }

  @override
  void onRemove() {
    _sub?.cancel();
    _sub = null;
    super.onRemove();
  }
}
