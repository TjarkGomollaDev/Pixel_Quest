import 'package:flame/game.dart';
import 'package:pixel_adventure/data/static/metadata/level_metadata.dart';
import 'package:pixel_adventure/data/static/static_center.dart';
import 'package:pixel_adventure/game/hud/pause_route.dart';
import 'package:pixel_adventure/game/hud/settings_route.dart';
import 'package:pixel_adventure/game/level/level.dart';
import 'package:pixel_adventure/menu/menu_page.dart';

abstract class RouteNames {
  static const String menu = 'menu';
  static const String pause = 'pause';
  static const String settings = 'settings';
}

RouterComponent createRouter({required StaticCenter staticCenter, String? initialRoute}) {
  final levelRoutes = {
    RouteNames.menu: WorldRoute(() => MenuPage()),
    RouteNames.pause: PauseRoute(),
    RouteNames.settings: SettingsRoute(),
    for (final levelMetadata in staticCenter.allLevelsInAllWorlds.flat())
      levelMetadata.uuid: WorldRoute(() => Level(levelMetadata: levelMetadata), maintainState: false),
  };

  return RouterComponent(routes: levelRoutes, initialRoute: initialRoute ?? RouteNames.menu);
}
