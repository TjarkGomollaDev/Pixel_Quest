import 'package:flame/game.dart';
import 'package:pixel_adventure/data/static/metadata/level_metadata.dart';
import 'package:pixel_adventure/data/static/static_center.dart';
import 'package:pixel_adventure/game/hud/pause_page.dart';
import 'package:pixel_adventure/game/settings/settings_page.dart';
import 'package:pixel_adventure/game/level/level.dart';
import 'package:pixel_adventure/game/menu/menu_page.dart';
import 'package:pixel_adventure/game/shop/shop_page.dart';

abstract class RouteNames {
  static const String menu = 'menu';
  static const String pause = 'pause';
  static const String settings = 'settings';
  static const String shop = 'shop';
}

RouterComponent createRouter({required StaticCenter staticCenter, String? initialRoute}) {
  final levelRoutes = {
    RouteNames.menu: WorldRoute(() => MenuPage()),
    RouteNames.pause: PausePage(),
    RouteNames.settings: SettingsPage(),
    RouteNames.shop: ShopPage(),
    for (final levelMetadata in staticCenter.allLevelsInAllWorlds.flat())
      levelMetadata.uuid: WorldRoute(() => Level(levelMetadata: levelMetadata), maintainState: false),
  };

  return RouterComponent(routes: levelRoutes, initialRoute: initialRoute ?? RouteNames.menu);
}
