import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/rendering.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/level/level.dart';
import 'package:pixel_adventure/game/utils/corner_outline.dart';
import 'package:pixel_adventure/game/utils/rrect.dart';
import 'package:pixel_adventure/game/utils/button.dart';
import 'package:pixel_adventure/pixel_quest.dart';

class PauseRoute extends Route with HasGameReference<PixelQuest> {
  PauseRoute() : super(PausePage.new, transparent: true);

  @override
  void onPush(Route? previousRoute) {
    if (previousRoute is WorldRoute && previousRoute.world is DecoratedWorld) {
      (previousRoute.world as DecoratedWorld).decorator = PaintDecorator.tint(AppTheme.screenBlur)..addBlur(6.0);
      (previousRoute.world as DecoratedWorld).timeScale = 0;
    }
  }

  @override
  void onPop(Route nextRoute) {
    if (nextRoute is WorldRoute && nextRoute.world is DecoratedWorld) {
      (nextRoute.world as DecoratedWorld).decorator = null;
      (nextRoute.world as DecoratedWorld).timeScale = 1;
    }
  }
}

class PausePage extends Component with HasGameReference<PixelQuest> {
  // pause container
  late final PositionComponent _pauseContainer;

  // pause label
  late final RRectComponent _pauseBg;
  late final TextComponent _pauseText;
  late final CornerOutline _pauseOutline;

  // text btns
  late final TextBtn _settingsBtn;
  late final TextBtn _achievementsBtn;
  late final TextBtn _menuBtn;

  // list for btn animations
  final List<TextBtn> _btns = [];

  // btn spacing
  static const double _btnSpacing = 44;

  // flag to avoid resetting button animations multiple times
  bool _btnAnimationsStopped = false;

  @override
  bool containsLocalPoint(Vector2 point) => false;

  @override
  Future<void> onLoad() async {
    _setUpPauseContainer();
  }

  @override
  void onMount() {
    _startShowAnimation();
    super.onMount();
  }

  @override
  void onRemove() {
    _stopShowAnimation();
    _btnAnimationsStopped = false;
    super.onRemove();
  }

  void _setUpPauseContainer() {
    _pauseContainer = PositionComponent(position: game.canvasSize / 2, anchor: Anchor.center);

    // text background
    _pauseBg = RRectComponent(
      color: AppTheme.tileBlur,
      borderRadius: 4,
      position: Vector2(0, -60),
      size: Vector2(210, 60),
      anchor: Anchor.center,
    );

    // paused text
    _pauseText = TextComponent(
      text: 'PAUSED',
      position: _pauseBg.position,
      anchor: Anchor(0.48, 0.32),
      textRenderer: TextPaint(
        style: const TextStyle(fontFamily: 'Pixel Font', fontSize: 28, color: AppTheme.ingameText, height: 1),
      ),
    );

    // outline
    _pauseOutline = CornerOutline(
      size: _pauseBg.size + Vector2.all(16),
      cornerLength: 16,
      strokeWidth: 5,
      color: AppTheme.ingameText,
      anchor: Anchor.center,
      position: _pauseText.position,
    );

    // settings btn
    _settingsBtn = TextBtn(
      text: 'Settings',
      onPressed: () {
        _stopShowAnimation();
      },
      position: Vector2(0, 20),
    );

    // achievements btn
    _achievementsBtn = TextBtn(
      text: 'Achievements',
      onPressed: () {
        _stopShowAnimation();
      },
      position: _settingsBtn.position + Vector2(0, _btnSpacing),
    );

    // menu btn
    _menuBtn = TextBtn(
      text: 'Menu',
      onPressed: () {
        _stopShowAnimation();
        if (game.router.currentRoute is PauseRoute) game.router.pop();
        game.router.pushReplacementNamed(RouteNames.menu);
      },
      position: _achievementsBtn.position + Vector2(0, _btnSpacing),
    );

    _btns.addAll([_settingsBtn, _achievementsBtn, _menuBtn]);
    _pauseContainer.addAll([_pauseBg, _pauseText, _pauseOutline, _settingsBtn, _achievementsBtn, _menuBtn]);
    add(_pauseContainer);
  }

  /// Stops all running button animations and resets scale.
  void _stopShowAnimation() {
    if (_btnAnimationsStopped) return;
    for (var button in _btns) {
      button.resetAllAnimations();
    }
    _btnAnimationsStopped = true;
  }

  /// Starts the pause page scale-in and pop-in button animations.
  void _startShowAnimation() {
    _pauseContainer.scale = Vector2.all(0.92);

    // add scale-in effect
    _pauseContainer.add(ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.18, curve: Curves.easeOutQuad)));

    // add pop-in effect for all buttons
    for (var i = 0; i < _btns.length; i++) {
      _btns[i].popIn(delay: (i + 1) * 0.45);
    }
  }
}
