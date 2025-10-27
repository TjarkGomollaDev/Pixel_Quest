import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/animations/star.dart';
import 'package:pixel_adventure/game/utils/in_game_btn.dart';
import 'package:pixel_adventure/game/traps/fruit.dart';
import 'package:pixel_adventure/game/utils/rrect.dart';
import 'package:pixel_adventure/game/utils/visible_components.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_quest.dart';

class MenuHeader extends PositionComponent with HasGameReference<PixelQuest> {
  final int _startWorldIndex;

  MenuHeader({required int startWorldIndex}) : _startWorldIndex = startWorldIndex {
    final minLeft = game.safePadding.minLeft(40);
    size = Vector2(game.size.x - minLeft - game.safePadding.minRight(40), Fruit.gridSize.y);
    position = Vector2(minLeft, 10);
    _verticalCenter = size.y / 2;
  }

  // vertical center of the module
  late final double _verticalCenter;

  // btns
  late final InGameBtn _settingsBtn;
  late final InGameBtn _achievmentsBtn;

  // spacing
  final double _btnSpacing = 4;

  // stars count
  late final RRectComponent _starBg;
  late final SpriteComponent _starItem;
  final List<VisibleTextComponent> _worldStarsCounts = [];

  // animation star
  late final Star _animatedStar;

  // count settings
  static const double _bgSize = 19;
  static const double _counterTextMarginLeft = 4;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _setUpBtns();
    _setUpStarsCount();
    _setUpAnimatedStar();
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
    _starBg = RRectComponent(
      color: AppTheme.tileBlur,
      borderRadius: 2,
      position: Vector2(0, _verticalCenter),
      size: Vector2.all(_bgSize),
      anchor: Anchor.centerLeft,
    );

    // star item
    _starItem = Star(position: Vector2(_starBg.position.x + _starBg.size.x / 2, _verticalCenter), size: Vector2.all(16));

    addAll([_starBg, _starItem]);

    // world star counts text
    for (var world in game.staticCenter.allWorlds) {
      final text = VisibleTextComponent(
        text: '${game.storageCenter.getWorld(world.uuid).stars}/48',
        anchor: Anchor(0, 0.32),
        position: Vector2(_starBg.position.x + _starBg.size.x + _counterTextMarginLeft, _verticalCenter),
        textRenderer: TextPaint(
          style: const TextStyle(fontFamily: 'Pixel Font', fontSize: 8, color: AppTheme.ingameText, height: 1),
        ),
        show: world.index == _startWorldIndex,
      );
      add(text);
      _worldStarsCounts.add(text);
    }
  }

  void _setUpAnimatedStar() {
    _animatedStar = Star(position: Vector2(_starItem.position.x, -position.y - _starItem.size.y / 2), size: _starItem.size);
    add(_animatedStar);
  }

  void _setUpBtns() {
    // positioning
    final btnBasePosition = Vector2(size.x - InGameBtn.btnSize.x * 1.5 - _btnSpacing, _verticalCenter);
    final btnOffset = Vector2(InGameBtn.btnSize.x + _btnSpacing, 0);

    // settings btn
    _settingsBtn = InGameBtn(type: InGameBtnType.settings, action: () {}, position: btnBasePosition);

    // achievements btn
    _achievmentsBtn = InGameBtn(type: InGameBtnType.volume, action: () {}, position: btnBasePosition + btnOffset);

    addAll([_settingsBtn, _achievmentsBtn]);
  }

  void updateStarsCount({required int index, required int stars}) => _worldStarsCounts[index].text = '$stars/48';

  void showStarsCount(int index) => _worldStarsCounts[index].show();

  void hideStarsCount(int index) => _worldStarsCounts[index].hide();

  Future<void> starsCountAnimation(int count) async {
    for (var i = 0; i < count; i++) {
      await _animatedStar.fallTo(_starItem.position);
      await Future.delayed(Duration(milliseconds: 50));
    }
  }
}
