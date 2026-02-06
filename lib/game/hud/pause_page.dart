import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:pixel_quest/app_theme.dart';
import 'package:pixel_quest/game/events/game_event_bus.dart';
import 'package:pixel_quest/game/utils/corner_outline.dart';
import 'package:pixel_quest/game/utils/rrect.dart';
import 'package:pixel_quest/game/utils/button.dart';
import 'package:pixel_quest/game/game.dart';
import 'package:pixel_quest/game/game_router.dart';

/// Route that pauses/resumes the level by emitting lifecycle events when shown/closed.
class PausePage extends Route with HasGameReference<PixelQuest> {
  PausePage() : super(_PauseContent.new, transparent: true);

  @override
  void onPush(Route? previousRoute) {
    game.eventBus.emit(const LevelLifecycleChanged(.paused));
  }

  @override
  void onPop(Route nextRoute) {
    game.eventBus.emit(const LevelLifecycleChanged(.resumed));
  }
}

/// Pause menu UI content: builds the overlay layout and optionally plays a simple show animation.
class _PauseContent extends Component with HasGameReference<PixelQuest> {
  // container
  late final PositionComponent _root;
  late final PositionComponent _pauseContainer;

  // pause label
  late final RRectComponent _pauseBg;
  late final TextComponent _pauseText;
  late final CornerOutline _pauseOutline;

  // btns
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
    _root = PositionComponent(size: game.size)..scale = .all(game.worldToScreenScale);
    add(_root);
  }

  void _setUpPauseContainer() {
    // pause text
    _pauseText = TextComponent(
      text: game.l10n.pauseTitel.toUpperCase(),
      position: Vector2(0, -12),
      anchor: .center,
      textRenderer: AppTheme.pausedHeading.asTextPaint,
    );

    // text background
    _pauseBg = RRectComponent(
      color: AppTheme.tileBlur,
      borderRadius: 4,
      position: _pauseText.position,
      size: Vector2(_pauseText.size.x + 30, 32),
      anchor: .center,
    );

    // outline
    _pauseOutline = CornerOutline(
      size: _pauseBg.size + .all(12),
      cornerLength: 10,
      strokeWidth: 2.6,
      color: AppTheme.white,
      anchor: .center,
      position: _pauseText.position,
    );

    // settings btn
    _settingsBtn = TextBtn(
      text: game.l10n.pauseButtonSettigns,
      onPressed: () {
        if (animationEnabled) _stopShowAnimation();
        game.router.pushNamed(RouteNames.settings);
      },
      position: _pauseText.position + Vector2(0, 46),
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
    _pauseContainer = PositionComponent(position: _root.size / 2, anchor: .center);
    _pauseContainer.addAll([_pauseBg, _pauseText, _pauseOutline, _settingsBtn, _menuBtn]);
    _root.add(_pauseContainer);
  }

  /// Stops all running button animations and resets scale.
  void _stopShowAnimation() {
    if (_btnAnimationsStopped) return;
    for (final button in _btns) {
      button.resetAllAnimations();
    }
    _btnAnimationsStopped = true;
  }

  /// Starts the pause page scale-in and pop-in button animations.
  void _startShowAnimation() {
    _pauseContainer.scale = .all(0.92);

    // add scale-in effect
    _pauseContainer.add(ScaleEffect.to(.all(1.0), EffectController(duration: 0.18, curve: Curves.easeOutQuad)));

    // add pop-in effect for all buttons
    for (int i = 0; i < _btns.length; i++) {
      _btns[i].animatedPopIn(delay: (i + 2) * 0.45);
    }
  }
}
