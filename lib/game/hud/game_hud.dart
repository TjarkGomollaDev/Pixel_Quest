import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/hud/in_game_action_btn.dart';
import 'package:pixel_adventure/game/hud/pause_route.dart';
import 'package:pixel_adventure/game/level/level.dart';
import 'package:pixel_adventure/game/traps/fruit.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game/utils/rrect.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class GameHud extends PositionComponent with HasGameReference<PixelAdventure> {
  final int _totalFruitsCount;

  GameHud({required int totalFruitsCount}) : _totalFruitsCount = totalFruitsCount {
    size = Vector2(160, Fruit.gridSize.y);
    position = Vector2(GameSettings.tileSize * 3, 20);
    anchor = Anchor.centerLeft;
  }

  // btns
  late final InGameActionBtn _menuBtn;
  late final InGameActionBtn _playBtn;
  late final InGameActionBtn _restartBtn;

  // spacing
  final double _btnSpacing = 4;

  // fruits count
  late final RoundedComponent _fruitBg;
  late final Fruit _fruitItem;
  late final TextComponent _fruitsCount;

  // death count
  late final RoundedComponent _deathBg;
  late final SpriteComponent _deathItem;
  late final TextComponent _deathCount;

  // count settings
  static const double _bgSize = 19;
  static const double _spacingBetweenElements = 20;
  static const double _counterTextMarginLeft = 4;

  @override
  FutureOr<void> onLoad() {
    _setUpBtns();
    _setUpFruitsCount();
    _setUpDeathCount();
    return super.onLoad();
  }

  void _setUpBtns() {
    // positioning
    final btnBasePosition = Vector2(InGameActionBtn.btnSize.x / 2, position.y);
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
          final myLevel = (currentRoute.world as Level).levelMetadata;

          // at this point, we need to create a new instance of the route, because otherwise the router will assume
          // that the route already exists and will not even create a new one, which is explicitly what we want to do here
          game.router.pushReplacement(WorldRoute(() => Level(levelMetadata: myLevel), maintainState: false), name: myLevel.uuid);
        } else if (currentRoute is PauseRoute) {
          final previousRoute = game.router.previousRoute;
          if (previousRoute is WorldRoute) {
            final myLevel = (previousRoute.world as Level).levelMetadata;
            game.router.pop();

            // same as above
            game.router.pushReplacement(WorldRoute(() => Level(levelMetadata: myLevel), maintainState: false), name: myLevel.uuid);
          }
        }
      },
      position: btnBasePosition + btnOffset * 2,
    );

    addAll([_menuBtn, _playBtn, _restartBtn]);
  }

  void _setUpFruitsCount() {
    // fruit background
    _fruitBg = RoundedComponent(
      color: AppTheme.black.withAlpha(56),
      borderRadius: 2,
      position: Vector2(_restartBtn.position.x + _bgSize + _spacingBetweenElements, position.y),
      size: Vector2.all(_bgSize),
      anchor: Anchor.center,
    );

    // fruit item
    _fruitItem = Fruit(name: FruitName.Apple.name, position: Vector2(_fruitBg.position.x, position.y + 1), collectible: false);

    // count text
    _fruitsCount = TextComponent(
      text: '0/$_totalFruitsCount',
      anchor: Anchor(0, 0.32),
      position: Vector2(_fruitBg.position.x + _fruitBg.size.x / 2 + _counterTextMarginLeft, position.y),
      textRenderer: TextPaint(
        style: const TextStyle(fontFamily: 'Pixel Font', fontSize: 8, color: AppTheme.ingameText, height: 1),
      ),
    );

    addAll([_fruitBg, _fruitItem, _fruitsCount]);
  }

  void _setUpDeathCount() {
    // death background
    _deathBg = RoundedComponent(
      color: AppTheme.black.withAlpha(56),
      borderRadius: 2,
      position: Vector2(_fruitsCount.position.x + _fruitsCount.size.x + _bgSize / 2 + _spacingBetweenElements * 4 / 5, position.y),
      size: Vector2.all(_bgSize),
      anchor: Anchor.center,
    );

    // death item
    _deathItem = SpriteComponent(
      sprite: loadSprite(game, 'Other/Bone.png'),
      position: _deathBg.position,
      size: Vector2.all(32),
      anchor: Anchor.center,
    );

    // count text
    _deathCount = TextComponent(
      text: '0',
      anchor: Anchor(0, 0.32),
      position: Vector2(_deathBg.position.x + _deathBg.size.x / 2 + _counterTextMarginLeft, position.y),
      textRenderer: TextPaint(
        style: const TextStyle(fontFamily: 'Pixel Font', fontSize: 8, color: AppTheme.ingameText, height: 1),
      ),
    );

    addAll([_deathBg, _deathItem, _deathCount]);
  }

  void updateFruitCount(int collected) => _fruitsCount.text = '$collected/$_totalFruitsCount';

  void updateDeathCount(int deaths) => _deathCount.text = deaths.toString();
}
