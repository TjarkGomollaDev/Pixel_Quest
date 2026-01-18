import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/rendering.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/level/level.dart';
import 'package:pixel_adventure/game/utils/corner_outline.dart';
import 'package:pixel_adventure/game/utils/rrect.dart';
import 'package:pixel_adventure/game/utils/button.dart';
import 'package:pixel_adventure/game/game.dart';
import 'package:pixel_adventure/game/game_router.dart';

class PausePage extends Route with HasGameReference<PixelQuest> {
  PausePage() : super(_PauseContent.new, transparent: true);

  @override
  void onPush(Route? previousRoute) {
    if (previousRoute is WorldRoute && previousRoute.world is DecoratedWorld) {
      (previousRoute.world as DecoratedWorld).decorator = PaintDecorator.tint(AppTheme.screenBlur)..addBlur(6.0);
      (previousRoute.world as DecoratedWorld).timeScale = 0;
      (previousRoute.world as Level).hideOverlayOnPause();
      unawaited(game.audioCenter.pauseAllLoops());
    }
  }

  @override
  void onPop(Route nextRoute) {
    if (nextRoute is WorldRoute && nextRoute.world is DecoratedWorld) {
      (nextRoute.world as DecoratedWorld).decorator = null;
      (nextRoute.world as DecoratedWorld).timeScale = 1;
      (nextRoute.world as Level).showOverlayOnResume();
      unawaited(game.audioCenter.resumeAllLoops());
    }
  }
}

class _PauseContent extends Component with HasGameReference<PixelQuest> {
  // container
  late final PositionComponent _root;
  late final PositionComponent _pauseContainer;

  // pause label
  late final RRectComponent _pauseBg;
  late final TextComponent _pauseText;
  late final CornerOutline _pauseOutline;

  // text btns
  late final TextBtn _settingsBtn;
  late final TextBtn _menuBtn;

  // list for btn animations
  final List<TextBtn> _btns = [];

  // btn spacing
  static const double _btnSpacing = 30; // [Adjustable]

  // animation can be enabled and disabled
  static const bool animationEnabled = false; // [Adjustable]

  // flag to avoid resetting button animations multiple times
  bool _btnAnimationsStopped = false;

  @override
  Future<void> onLoad() async {
    _setUpRoot();
    _setUpPauseContainer();
  }

  @override
  void onMount() {
    if (animationEnabled) _startShowAnimation();
    super.onMount();
  }

  @override
  void onRemove() {
    if (animationEnabled) {
      _stopShowAnimation();
      _btnAnimationsStopped = false;
    }
    super.onRemove();
  }

  void _setUpRoot() {
    _root = PositionComponent(size: game.size)..scale = Vector2.all(game.worldToScreenScale);
    add(_root);
  }

  void _setUpPauseContainer() {
    // pause text
    _pauseText = TextComponent(
      text: game.l10n.pauseTitel.toUpperCase(),
      position: Vector2(0, -30),
      anchor: Anchor.center,
      textRenderer: AppTheme.pausedHeading.asTextPaint,
    );

    // text background
    _pauseBg = RRectComponent(
      color: AppTheme.tileBlur,
      borderRadius: 4,
      position: _pauseText.position,
      size: Vector2(_pauseText.size.x + 40, 40),
      anchor: Anchor.center,
    );

    // outline
    _pauseOutline = CornerOutline(
      size: _pauseBg.size + Vector2.all(16),
      cornerLength: 12,
      strokeWidth: 3.5,
      color: AppTheme.ingameText,
      anchor: Anchor.center,
      position: _pauseText.position,
    );

    // settings btn
    _settingsBtn = TextBtn(
      text: game.l10n.pauseButtonSettigns,
      onPressed: () {
        if (animationEnabled) _stopShowAnimation();
        game.router.pushNamed(RouteNames.settings);
      },
      position: Vector2(0, 24),
    );

    // menu btn
    _menuBtn = TextBtn(
      text: game.l10n.pauseButtonMenu,
      onPressed: () {
        if (animationEnabled) _stopShowAnimation();
        game.router.pop();
        game.router.pushReplacementNamed(RouteNames.menu);
      },
      position: _settingsBtn.position + Vector2(0, _btnSpacing),
    );

    _btns.addAll([_settingsBtn, _menuBtn]);
    _pauseContainer = PositionComponent(position: _root.size / 2, anchor: Anchor.center);
    _pauseContainer.addAll([_pauseBg, _pauseText, _pauseOutline, _settingsBtn, _menuBtn]);
    _root.add(_pauseContainer);
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
      _btns[i].animatePopIn(delay: (i + 2) * 0.45);
    }
  }
}
