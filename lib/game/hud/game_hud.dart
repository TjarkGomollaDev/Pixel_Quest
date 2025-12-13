import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/data/static/metadata/level_metadata.dart';
import 'package:pixel_adventure/game/hud/entity_on_mini_map.dart';
import 'package:pixel_adventure/game/hud/mini_map.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/utils/button.dart';
import 'package:pixel_adventure/game/hud/pause_route.dart';
import 'package:pixel_adventure/game/level/level.dart';
import 'package:pixel_adventure/game/traps/fruit.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game/utils/rrect.dart';
import 'package:pixel_adventure/game/utils/volume.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_quest.dart';
import 'package:pixel_adventure/router.dart';

class GameHud extends PositionComponent with HasGameReference<PixelQuest> {
  // constructor parameters
  final int _totalFruitsCount;
  final Sprite _miniMapSprite;
  final double _levelWidth;
  final Player _player;
  final LevelMetadata _levelMetadata;
  final List<EntityOnMiniMap> _miniMapEntities;

  GameHud({
    required int totalFruitsCount,
    required Sprite miniMapSprite,
    required double levelWidth,
    required Player player,
    required LevelMetadata levelMetadata,
    required List<EntityOnMiniMap> miniMapEntities,
  }) : _totalFruitsCount = totalFruitsCount,
       _miniMapSprite = miniMapSprite,
       _levelWidth = levelWidth,
       _player = player,
       _levelMetadata = levelMetadata,
       _miniMapEntities = miniMapEntities {
    final minLeft = game.safePadding.minLeft(40);
    size = Vector2(game.size.x - minLeft - game.safePadding.minRight(40), Fruit.gridSize.y);
    position = Vector2(minLeft, 10);
    _verticalCenter = size.y / 2;
  }

  // vertical center of the module
  late final double _verticalCenter;

  // btns
  late final SpriteBtn _menuBtn;
  late final SpriteToggleBtn _volumeBtn;
  late final SpriteToggleBtn _pauseBtn;
  late final SpriteBtn _restartBtn;

  // btn spacing
  static const double _btnSpacing = 4;

  // fruits count
  late final RRectComponent _fruitBg;
  late final Fruit _fruitItem;
  late final TextComponent _fruitsCount;

  // death count
  late final RRectComponent _deathBg;
  late final SpriteComponent _deathItem;
  late final TextComponent _deathCount;

  // count settings
  static const double _bgSize = 19;
  static const double _spacingBetweenElements = 20;
  static const double _counterTextMarginLeft = 4;

  // mini map
  late final MiniMap _miniMap;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _setUpBtns();
    _setUpFruitsCount();
    _setUpDeathCount();
    _setUpMiniMap();
    return super.onLoad();
  }

  void _initialSetup() {
    // debug
    if (GameSettings.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorMenu;
    }

    // general
  }

  void _setUpBtns() {
    // positioning
    final btnBasePosition = Vector2(SpriteBtnType.btnSize.x / 2, _verticalCenter);
    final btnOffset = Vector2(SpriteBtnType.btnSize.x + _btnSpacing, 0);

    // menu btn
    _menuBtn = SpriteBtn.fromType(
      type: SpriteBtnType.levels,
      onPressed: () {
        if (game.router.currentRoute is PauseRoute) game.router.pop();
        game.router.pushReplacementNamed(RouteNames.menu);
      },
      position: btnBasePosition,
    );

    // volume btn
    _volumeBtn = SpriteToggleBtn.fromType(
      type: SpriteBtnType.volumeOn,
      type_2: SpriteBtnType.volumeOff,
      onPressed: () => switchVolume(game: game, soundsEnabled: false),
      onPressed_2: () => switchVolume(game: game),
      position: _menuBtn.position + btnOffset,
      initialState: game.storageCenter.settings.soundsEnabled,
    );

    // pause btn
    _pauseBtn = SpriteToggleBtn.fromType(
      type: SpriteBtnType.pause,
      type_2: SpriteBtnType.play,
      onPressed: () => game.router.pushNamed(RouteNames.pause),
      onPressed_2: () => game.router.pop(),
      position: _volumeBtn.position + btnOffset,
    );

    // restart the level btn
    _restartBtn = SpriteBtn.fromType(type: SpriteBtnType.restart, onPressed: _restartLevel, position: _pauseBtn.position + btnOffset);

    addAll([_menuBtn, _volumeBtn, _pauseBtn, _restartBtn]);
  }

  void _restartLevel() {
    final currentRoute = game.router.currentRoute;
    WorldRoute? levelRoute;

    switch (currentRoute) {
      case WorldRoute():
        levelRoute = currentRoute;
      case PauseRoute():
        final previousRoute = game.router.previousRoute;
        if (previousRoute is WorldRoute) {
          game.router.pop();
          levelRoute = previousRoute;
        }
    }

    if (levelRoute == null) return;

    final levelMetadata = (levelRoute.world as Level).levelMetadata;
    game.showLoadingOverlay(levelMetadata);
    game.router.pushReplacement(WorldRoute(() => Level(levelMetadata: levelMetadata), maintainState: false), name: levelMetadata.uuid);
  }

  void _setUpFruitsCount() {
    // fruit background
    _fruitBg = RRectComponent(
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
    _deathBg = RRectComponent(
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

  void togglePlayButton() => _pauseBtn.triggerToggle();

  void _setUpMiniMap() {
    _miniMap = MiniMap(
      miniMapSprite: _miniMapSprite,
      player: _player,
      levelMetadata: _levelMetadata,
      levelWidth: _levelWidth,
      miniMapEntities: _miniMapEntities,
      position: Vector2(size.x, _verticalCenter - _fruitBg.size.y / 2),
      hudTopRightToScreenTopRightOffset: position,
    );
    add(_miniMap);
  }
}
