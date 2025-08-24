import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/hud/in_game_action_btn.dart';
import 'package:pixel_adventure/game/hud/pause_route.dart';
import 'package:pixel_adventure/game/level/level.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class GameHud extends PositionComponent with HasGameReference<PixelAdventure> {
  GameHud({required super.position}) {
    size = Vector2(InGameActionBtn.btnSize.x * 3 + _btnSpacing * 2, InGameActionBtn.btnSize.y);
  }

  // btns
  late final InGameActionBtn _menuBtn;
  late final InGameActionBtn _playBtn;
  late final InGameActionBtn _restartBtn;

  // spacing
  final double _btnSpacing = 4;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _setUpBtns();
    return super.onLoad();
  }

  void _initialSetup() {
    // debug
    if (game.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugMenu;
    }
    // general
  }

  void _setUpBtns() {
    // positioning
    final btnBasePosition = InGameActionBtn.btnSize / 2;
    final btnOffset = Vector2(InGameActionBtn.btnSize.x + _btnSpacing, 0);

    // menu btn
    _menuBtn = InGameActionBtn(
      name: InGameActionBtnName.levels,
      action: () {
        if (game.router.currentRoute is PauseRoute) game.router.pop();
        game.router.pushReplacementNamed(RouteNames.menu);
      },
      position: btnBasePosition,
    );

    // pause and resume btn
    _playBtn = InGameActionToggleBtn(
      name: InGameActionBtnName.pause,
      name_2: InGameActionBtnName.play,
      action: () => game.router.pushNamed(RouteNames.pause),
      action_2: () => game.router.pop(),
      position: btnBasePosition + btnOffset,
    );

    // restart the level btn
    _restartBtn = InGameActionBtn(
      name: InGameActionBtnName.restart,
      action: () {
        final currentRoute = game.router.currentRoute;
        if (currentRoute is WorldRoute) {
          final myLevel = (currentRoute.world as Level).myLvel;
          // at this point, we need to create a new instance of the route, because otherwise the router will assume
          // that the route already exists and will not even create a new one, which is explicitly what we want to do here
          game.router.pushReplacement(WorldRoute(() => Level(myLvel: myLevel), maintainState: false), name: myLevel.name);
        } else if (currentRoute is PauseRoute) {
          final previousRoute = game.router.previousRoute;
          if (previousRoute is WorldRoute) {
            final myLevel = (previousRoute.world as Level).myLvel;
            game.router.pop();
            // same as above
            game.router.pushReplacement(WorldRoute(() => Level(myLvel: myLevel), maintainState: false), name: myLevel.name);
          }
        }
      },
      position: btnBasePosition + btnOffset * 2,
    );

    addAll([_menuBtn, _playBtn, _restartBtn]);
  }
}
