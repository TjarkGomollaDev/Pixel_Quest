import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/hud/in_game_action_btn.dart';
import 'package:pixel_adventure/game/traps/fruit.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game/utils/rrect.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_quest.dart';

class MenuHeader extends PositionComponent with HasGameReference<PixelQuest> {
  MenuHeader() {
    final minLeft = game.safePadding.minLeft(40);
    size = Vector2(game.size.x - minLeft - game.safePadding.minRight(40), Fruit.gridSize.y);
    position = Vector2(minLeft, 10);
    _verticalCenter = size.y / 2;
  }

  // vertical center of the module
  late final double _verticalCenter;

  // btns
  late final InGameActionBtn _settingsBtn;
  late final InGameActionBtn _achievmentsBtn;

  // spacing
  final double _btnSpacing = 4;

  // stars count
  late final RoundedComponent _starBg;
  late final SpriteComponent _starItem;
  late final TextComponent _starsCount;

  // count settings
  static const double _bgSize = 19;
  static const double _counterTextMarginLeft = 4;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _setUpBtns();
    _setUpStarsCount();
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

  void _setUpStarsCount() {
    // star background
    _starBg = RoundedComponent(
      color: AppTheme.tileBlur,
      borderRadius: 2,
      position: Vector2(0, _verticalCenter),
      size: Vector2.all(_bgSize),
      anchor: Anchor.centerLeft,
    );

    // star item
    _starItem = SpriteComponent(
      sprite: loadSprite(game, 'Other/Star.png'),
      position: Vector2(_starBg.position.x + _starBg.size.x / 2, _verticalCenter),
      size: Vector2.all(16),
      anchor: Anchor.center,
    );

    // count text
    _starsCount = TextComponent(
      text: '${game.storageCenter.highestUnlockedWorld.stars}/48',
      anchor: Anchor(0, 0.32),
      position: Vector2(_starBg.position.x + _starBg.size.x + _counterTextMarginLeft, _verticalCenter),
      textRenderer: TextPaint(
        style: const TextStyle(fontFamily: 'Pixel Font', fontSize: 8, color: AppTheme.ingameText, height: 1),
      ),
    );

    addAll([_starBg, _starItem, _starsCount]);
  }

  void _setUpBtns() {
    // positioning
    final btnBasePosition = Vector2(size.x - InGameActionBtn.btnSize.x * 1.5 - _btnSpacing, _verticalCenter);
    final btnOffset = Vector2(InGameActionBtn.btnSize.x + _btnSpacing, 0);

    // settings btn
    _settingsBtn = InGameActionBtn(type: InGameActionBtnType.settings, action: () {}, position: btnBasePosition);

    // achievements btn
    _achievmentsBtn = InGameActionBtn(type: InGameActionBtnType.leaderboard, action: () {}, position: btnBasePosition + btnOffset);

    addAll([_settingsBtn, _achievmentsBtn]);
  }

  void updateStarsCount(int stars) => _starsCount.text = '$stars/48';
}
