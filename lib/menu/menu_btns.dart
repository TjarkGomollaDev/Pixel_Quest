import 'dart:async';
import 'package:flame/components.dart';
import 'package:pixel_adventure/game/hud/in_game_action_btn.dart';
import 'package:pixel_adventure/game/traps/fruit.dart';
import 'package:pixel_adventure/pixel_quest.dart';

class MenuBtns extends PositionComponent with HasGameReference<PixelQuest> {
  MenuBtns() {
    size = Vector2(InGameActionBtn.btnSize.x * 2 + _btnSpacing, Fruit.gridSize.y);
    position = Vector2(game.size.x - game.safePadding.minRight(40), 20);
    anchor = Anchor.centerRight;
  }

  // btns
  late final InGameActionBtn _settingsBtn;
  late final InGameActionBtn _achievmentsBtn;

  // spacing
  final double _btnSpacing = 4;

  @override
  FutureOr<void> onLoad() {
    _setUpBtns();

    return super.onLoad();
  }

  void _setUpBtns() {
    final btnBasePosition = Vector2(InGameActionBtn.btnSize.x / 2, position.y);
    final btnOffset = Vector2(InGameActionBtn.btnSize.x + _btnSpacing, 0);

    // settings btn
    _settingsBtn = InGameActionBtn(name: InGameActionBtnName.settings, action: () {}, position: btnBasePosition);

    // achievements btn
    _achievmentsBtn = InGameActionBtn(name: InGameActionBtnName.leaderboard, action: () {}, position: btnBasePosition + btnOffset);

    addAll([_settingsBtn, _achievmentsBtn]);
  }
}
