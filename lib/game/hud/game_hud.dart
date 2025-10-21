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
import 'package:pixel_adventure/pixel_quest.dart';

class GameHud extends PositionComponent with HasGameReference<PixelQuest> {
  final int _totalFruitsCount;

  GameHud({required int totalFruitsCount}) : _totalFruitsCount = totalFruitsCount {
    final minLeft = game.safePadding.minLeft(40);
    size = Vector2(game.size.x - minLeft - game.safePadding.minRight(40), Fruit.gridSize.y);
    position = Vector2(minLeft, 10);
    _verticalCenter = size.y / 2;
  }

  // vertical center of the module
  late final double _verticalCenter;

  // btns
  late final InGameActionBtn _menuBtn;
  late final InGameActionToggleBtn _playBtn;
  late final InGameActionBtn _restartBtn;

  // spacing
  static final double _btnSpacing = 4;

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
    _initialSetup();
    _setUpBtns();
    _setUpFruitsCount();
    _setUpDeathCount();
    return super.onLoad();
  }

  void _initialSetup() {
    // debug
    if (GameSettings.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorMenu;
    }

    // general
    anchor = Anchor.topLeft;
  }

  void _setUpBtns() {
    // positioning
    final btnBasePosition = Vector2(InGameActionBtn.btnSize.x / 2, _verticalCenter);
    final btnOffset = Vector2(InGameActionBtn.btnSize.x + _btnSpacing, 0);

    // menu btn
    _menuBtn = InGameActionBtn(
      type: InGameActionBtnType.levels,
      action: () {
        if (game.router.currentRoute is PauseRoute) game.router.pop();
        game.router.pushReplacementNamed(RouteNames.menu);
      },
      position: btnBasePosition,
    );

    // pause and resume btn
    _playBtn = InGameActionToggleBtn(
      type: InGameActionBtnType.pause,
      type_2: InGameActionBtnType.play,
      action: () => game.router.pushNamed(RouteNames.pause),
      action_2: () => game.router.pop(),
      position: btnBasePosition + btnOffset,
    );

    // restart the level btn
    _restartBtn = InGameActionBtn(
      type: InGameActionBtnType.restart,
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
      color: AppTheme.tileBlur,
      borderRadius: 2,
      position: Vector2(_restartBtn.position.x + _restartBtn.size.x + _spacingBetweenElements, _verticalCenter),
      size: Vector2.all(_bgSize),
      anchor: Anchor.centerLeft,
    );

    // fruit item
    _fruitItem = Fruit(
      name: FruitName.Apple.name,
      position: Vector2(_fruitBg.position.x + _fruitBg.size.x / 2, _verticalCenter + 2),
      collectible: false,
    );

    // count text
    _fruitsCount = TextComponent(
      text: '0/$_totalFruitsCount',
      anchor: Anchor(0, 0.32),
      position: Vector2(_fruitBg.position.x + _fruitBg.size.x + _counterTextMarginLeft, _verticalCenter),
      textRenderer: TextPaint(
        style: const TextStyle(fontFamily: 'Pixel Font', fontSize: 8, color: AppTheme.ingameText, height: 1),
      ),
    );

    addAll([_fruitBg, _fruitItem, _fruitsCount]);
  }

  void _setUpDeathCount() {
    // death background
    _deathBg = RoundedComponent(
      color: AppTheme.tileBlur,
      borderRadius: 2,
      position: Vector2(_fruitsCount.position.x + _fruitsCount.size.x + _spacingBetweenElements * 4 / 5, _verticalCenter),
      size: Vector2.all(_bgSize),
      anchor: Anchor.centerLeft,
    );

    // death item
    _deathItem = SpriteComponent(
      sprite: loadSprite(game, 'Other/Bone.png'),
      position: Vector2(_deathBg.position.x + _deathBg.size.x / 2, _verticalCenter),
      size: Vector2.all(32),
      anchor: Anchor.center,
    );

    // count text
    _deathCount = TextComponent(
      text: '0',
      anchor: Anchor(0, 0.32),
      position: Vector2(_deathBg.position.x + _deathBg.size.x + _counterTextMarginLeft, _verticalCenter),
      textRenderer: TextPaint(
        style: const TextStyle(fontFamily: 'Pixel Font', fontSize: 8, color: AppTheme.ingameText, height: 1),
      ),
    );

    addAll([_deathBg, _deathItem, _deathCount]);
  }

  void updateFruitCount(int collected) => _fruitsCount.text = '$collected/$_totalFruitsCount';

  void updateDeathCount(int deaths) => _deathCount.text = deaths.toString();

  void togglePlayButton() => _playBtn.triggerToggle();
}
