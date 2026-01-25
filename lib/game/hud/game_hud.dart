import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/data/static/metadata/level_metadata.dart';
import 'package:pixel_adventure/game/hud/mini%20map/entity_on_mini_map.dart';
import 'package:pixel_adventure/game/hud/mini%20map/mini_map.dart';
import 'package:pixel_adventure/game/level/player/player.dart';
import 'package:pixel_adventure/game/utils/button.dart';
import 'package:pixel_adventure/game/hud/pause_page.dart';
import 'package:pixel_adventure/game/level/level.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game/utils/rrect.dart';
import 'package:pixel_adventure/game/utils/visible_components.dart';
import 'package:pixel_adventure/game/game_settings.dart';
import 'package:pixel_adventure/game/game.dart';
import 'package:pixel_adventure/game/game_router.dart';

class GameHud extends PositionComponent with HasGameReference<PixelQuest> {
  // constructor parameters
  final int _totalFruitsCount;
  final Sprite _miniMapSprite;
  final double _levelWidth;
  final Player _player;
  final LevelMetadata _levelMetadata;
  final List<EntityOnMiniMap> _miniMapEntities;
  final bool _showAtStart;

  GameHud({
    required int totalFruitsCount,
    required Sprite miniMapSprite,
    required double levelWidth,
    required Player player,
    required LevelMetadata levelMetadata,
    required List<EntityOnMiniMap> miniMapEntities,
    bool show = false,
  }) : _totalFruitsCount = totalFruitsCount,
       _miniMapSprite = miniMapSprite,
       _levelWidth = levelWidth,
       _player = player,
       _levelMetadata = levelMetadata,
       _miniMapEntities = miniMapEntities,
       _showAtStart = show {
    final minLeft = game.safePadding.minLeft(GameSettings.hudHorizontalMargin);
    size = Vector2(game.size.x - minLeft - game.safePadding.minRight(GameSettings.hudHorizontalMargin), SpriteBtnType.btnSizeCorrected.y);
    position = Vector2(minLeft, GameSettings.mapBorderWidth + GameSettings.hudVerticalMargin);
  }

  // btns
  late final SpriteBtn _menuBtn;
  late final SpriteToggleBtn _pauseBtn;
  late final SpriteBtn _restartBtn;

  // fruits count
  late final RRectComponent _fruitBg;
  late final VisibleSpriteComponent _fruitItem;
  late final VisibleTextComponent _fruitsCount;

  // death count
  late final RRectComponent _deathBg;
  late final VisibleSpriteComponent _deathItem;
  late final VisibleTextComponent _deathCount;

  // mini map
  late final MiniMap _miniMap;

  @override
  FutureOr<void> onLoad() {
    _setUpBtns();
    _setUpFruitsCount();
    _setUpDeathCount();
    _setUpMiniMap();
    return super.onLoad();
  }

  void _setUpBtns() {
    // positioning
    final btnBasePosition = Vector2(SpriteBtnType.btnSizeCorrected.x / 2, size.y / 2);
    final btnOffset = Vector2(SpriteBtnType.btnSizeCorrected.x + GameSettings.hudBtnSpacing, 0);

    // menu btn
    _menuBtn = SpriteBtn.fromType(
      type: SpriteBtnType.levels,
      onPressed: () {
        if (game.router.currentRoute is PausePage) game.router.pop();
        game.router.pushReplacementNamed(RouteNames.menu);
      },
      position: btnBasePosition,
      show: _showAtStart,
    );

    // pause btn
    _pauseBtn = SpriteToggleBtn.fromType(
      type: SpriteBtnType.pause,
      type_2: SpriteBtnType.play,
      onPressed: () => game.router.pushNamed(RouteNames.pause),
      onPressed_2: () => game.router.pop(),
      position: _menuBtn.position + btnOffset,
      show: _showAtStart,
    );

    // restart the level btn
    _restartBtn = SpriteBtn.fromType(
      type: SpriteBtnType.restart,
      onPressed: _restartLevel,
      position: _pauseBtn.position + btnOffset,
      show: _showAtStart,
    );

    addAll([_menuBtn, _pauseBtn, _restartBtn]);
  }

  void _setUpFruitsCount() {
    // fruit background
    _fruitBg = RRectComponent(
      color: AppTheme.tileBlur,
      borderRadius: 2,
      position: _restartBtn.position + Vector2(SpriteBtnType.btnSizeCorrected.x / 2 + GameSettings.hudSectionSpacing, 0),
      size: Vector2.all(GameSettings.hudBgTileSize),
      anchor: Anchor.centerLeft,
      show: _showAtStart,
    );

    // fruit item
    _fruitItem = VisibleSpriteComponent(
      sprite: loadSprite(game, 'Other/Apple.png'),
      position: _fruitBg.position + Vector2(_fruitBg.size.x / 2, 2),
      size: Vector2.all(32),
      anchor: Anchor.center,
      show: _showAtStart,
    );

    // count text
    _fruitsCount = VisibleTextComponent(
      text: '0/$_totalFruitsCount',
      anchor: Anchor.centerLeft,
      position: _fruitBg.position + Vector2(_fruitBg.size.x + GameSettings.hudBtnTextSpacing, 0),
      textRenderer: AppTheme.hudText.asTextPaint,
      show: _showAtStart,
    );

    addAll([_fruitBg, _fruitItem, _fruitsCount]);
  }

  void _setUpDeathCount() {
    // death background
    _deathBg = RRectComponent(
      color: AppTheme.tileBlur,
      borderRadius: 2,
      position: _fruitsCount.position + Vector2(_fruitsCount.size.x + GameSettings.hudSectionSpacing, 0),
      size: Vector2.all(GameSettings.hudBgTileSize),
      anchor: Anchor.centerLeft,
      show: _showAtStart,
    );

    // death item
    _deathItem = VisibleSpriteComponent(
      sprite: loadSprite(game, 'Other/Bone.png'),
      position: _deathBg.position + Vector2(_deathBg.size.x / 2, 0),
      size: Vector2.all(32),
      anchor: Anchor.center,
      show: _showAtStart,
    );

    // count text
    _deathCount = VisibleTextComponent(
      text: '0',
      anchor: Anchor.centerLeft,
      position: _deathBg.position + Vector2(_deathBg.size.x + GameSettings.hudBtnTextSpacing, 0),
      textRenderer: AppTheme.hudText.asTextPaint,
      show: _showAtStart,
    );

    addAll([_deathBg, _deathItem, _deathCount]);
  }

  void _setUpMiniMap() {
    _miniMap = MiniMap(
      miniMapSprite: _miniMapSprite,
      player: _player,
      levelMetadata: _levelMetadata,
      levelWidth: _levelWidth,
      miniMapEntities: _miniMapEntities,
      position: Vector2(size.x, _deathBg.position.y - _deathBg.size.y / 2),
      hudTopRightToScreenTopRightOffset: position,
      initialState: game.storageCenter.settings.showMiniMapAtStart,
      show: _showAtStart,
    );
    add(_miniMap);
  }

  void show() {
    _menuBtn.show();
    _pauseBtn.show();
    _restartBtn.show();
    _fruitBg.show();
    _fruitItem.show();
    _fruitsCount.show();
    _deathBg.show();
    _deathItem.show();
    _deathCount.show();
    _miniMap.show();
  }

  void _restartLevel() {
    // check whether the pause page is currently at the top, if so, it must be popped first
    switch (game.router.currentRoute) {
      case WorldRoute():
        break;
      case PausePage():
        if (game.router.previousRoute is WorldRoute) game.router.pop();
        break;
      default:
        // safety check, should never actually occur
        return;
    }

    // game sound should be muted immediately
    unawaited(game.audioCenter.muteGameSfx());

    // at this point, we deliberately overwrite the existing route in the router by resetting the name,
    // this is the only way we can force the router to completely reload the level,
    // otherwise, the existing level would simply be placed on top of the stack without being reloaded
    game.loadingOverlay.show(_levelMetadata);
    game.router.pushReplacement(WorldRoute(() => Level(levelMetadata: _levelMetadata), maintainState: false), name: _levelMetadata.uuid);
  }

  void updateFruitCount(int collected) {
    _fruitsCount.text = '$collected/$_totalFruitsCount';
  }

  void updateDeathCount(int deaths) {
    _deathCount.text = deaths.toString();
  }

  void triggerPause() {
    _pauseBtn.triggerToggle();
  }
}
