import 'dart:async';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/animations/star.dart';
import 'package:pixel_adventure/game/events/game_event_bus.dart';
import 'package:pixel_adventure/game/game_settings.dart';
import 'package:pixel_adventure/game/utils/button.dart';
import 'package:pixel_adventure/game/utils/rrect.dart';
import 'package:pixel_adventure/game/utils/visible_components.dart';
import 'package:pixel_adventure/game/game.dart';
import 'package:pixel_adventure/game/game_router.dart';

/// Top bar for the menu page. Shows the world's total star count and provides quick navigation buttons.
class MenuTopBar extends PositionComponent with HasGameReference<PixelQuest> {
  // constructor parameters
  final int _startWorldIndex;

  MenuTopBar({required int startWorldIndex}) : _startWorldIndex = startWorldIndex {
    final minLeft = game.safePadding.minLeft(GameSettings.hudHorizontalMargin);
    size = Vector2(game.size.x - minLeft - game.safePadding.minRight(GameSettings.hudHorizontalMargin), SpriteBtnType.btnSizeCorrected.y);
    position = Vector2(minLeft, GameSettings.hudVerticalMargin);
  }
  // btns
  late final SpriteBtn _shopBtn;
  late final SpriteBtn _inventoryBtn;
  late final SpriteBtn _settingsBtn;

  // stars count
  late final RRectComponent _starBg;
  late final SpriteComponent _starItem;
  final List<VisibleTextComponent> _worldStarsCounts = [];

  // animation star
  late final Star _animatedStar;
  late final Vector2 _animatedStarStart;
  int _starsCountToken = 0;

  @override
  FutureOr<void> onLoad() {
    _setUpStarsCount();
    _setUpAnimatedStar();
    _setUpBtns();
    return super.onLoad();
  }

  void _setUpStarsCount() {
    // star background
    _starBg = RRectComponent(
      color: AppTheme.tileBlur,
      borderRadius: 2,
      position: Vector2(0, size.y / 2),
      size: Vector2.all(GameSettings.hudBgTileSize),
      anchor: Anchor.centerLeft,
    );

    // star item
    _starItem = Star(variant: StarVariant.filled, position: _starBg.position + Vector2(_starBg.size.x / 2, 0), size: Vector2.all(16));
    addAll([_starBg, _starItem]);

    // world star counts text
    for (final world in game.staticCenter.allWorlds()) {
      final text = VisibleTextComponent(
        text: '${game.storageCenter.worldById(world.uuid).stars}/48',
        anchor: Anchor.centerLeft,
        position: _starBg.position + Vector2(_starBg.size.x + GameSettings.hudBtnTextSpacing, 0),
        textRenderer: AppTheme.hudText.asTextPaint,
        show: world.index == _startWorldIndex,
      );
      add(text);
      _worldStarsCounts.add(text);
    }
  }

  void _setUpAnimatedStar() {
    _animatedStarStart = Vector2(_starItem.position.x, -position.y - _starItem.size.y / 2);
    _animatedStar = Star(variant: StarVariant.filled, position: _animatedStarStart, size: _starItem.size);
    add(_animatedStar);
  }

  void _setUpBtns() {
    // positioning
    final btnBasePosition = Vector2(size.x - SpriteBtnType.btnSizeCorrected.x * 2.5 - GameSettings.hudBtnSpacing * 2, _starBg.position.y);
    final btnOffset = Vector2(SpriteBtnType.btnSizeCorrected.x + GameSettings.hudBtnSpacing, 0);

    // shop btn
    _shopBtn = SpriteBtn.fromType(
      type: SpriteBtnType.dollar,
      onPressed: () => game.router.pushNamed(RouteNames.shop),
      position: btnBasePosition,
    );

    // inventory btn
    _inventoryBtn = SpriteBtn.fromType(
      type: SpriteBtnType.edit,
      onPressed: () => game.eventBus.emit(InventoryStateChanged(PageAction.opend)),
      position: _shopBtn.position + btnOffset,
    );

    // settings btn
    _settingsBtn = SpriteBtn.fromType(
      type: SpriteBtnType.settings,
      onPressed: () => game.router.pushNamed(RouteNames.settings),
      position: _inventoryBtn.position + btnOffset,
    );

    addAll([_shopBtn, _inventoryBtn, _settingsBtn]);
  }

  void _updateStarsCount({required int index, required int stars}) {
    _worldStarsCounts[index].text = '$stars/48';
  }

  void showStarsCount(int index) {
    _worldStarsCounts[index].show();
  }

  void hideStarsCount(int index) {
    _worldStarsCounts[index].hide();
  }

  void setStarsCount({required int index, required int totalStars}) {
    _updateStarsCount(index: index, stars: totalStars);
  }

  Future<void> starsCountAnimation({required int index, required int newStars, required int totalStars}) async {
    final token = ++_starsCountToken;
    for (int i = 0; i < newStars; i++) {
      if (token != _starsCountToken) return;
      _updateStarsCount(index: index, stars: totalStars - newStars + i + 1);
      await _animatedStar.fallToPopIn(_starItem.position);
      if (token != _starsCountToken) return;
      await Future.delayed(Duration(milliseconds: 50));
    }
  }

  void cancelStarsCountAnimation() {
    _starsCountToken++;
    _animatedStar.cancelAnimations();
  }
}
