import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/pixel_quest.dart';

/// BaseBtn is a mixin that provides basic button functionality for Flame components.
///
/// It handles:
/// - Tap interactions (onTapDown, onTapUp, onTapCancel)
/// - Scale animations when pressed
/// - Visibility control
/// - Animated show effect
///
/// IMPORTANT: Any component using this mixin **must call `_setUpBaseBtn`**
/// during initialization (e.g., in the constructor) to set up the `_onPressed` callback
/// and initial visibility. Failure to call this will result in the button not functioning correctly.
mixin _BaseBtn on PositionComponent, TapCallbacks, HasVisibility {
  late void Function() _onPressed;
  static final Vector2 _normalScale = Vector2.all(1);
  static final Vector2 _maxScale = Vector2.all(1.05);

  /// Sets scale to normal.
  void setNormalScale() => scale = _normalScale;

  /// Sets scale to max.
  void setMaxScale() => scale = _maxScale;

  @override
  void onTapDown(TapDownEvent event) {
    scale = _maxScale;
    super.onTapDown(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    scale = _normalScale;
    _onPressed();
    super.onTapUp(event);
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    scale = _normalScale;
    super.onTapCancel(event);
  }

  void _setUpBaseBtn({required void Function() onPressed, required bool show}) {
    _onPressed = onPressed;
    if (!show) hide();
    _initialSetup();
  }

  void _initialSetup() {
    // debug
    debugColor = AppTheme.transparent;

    // general
    anchor = Anchor.center;
  }

  /// Sets visibility to true.
  void show() => isVisible = true;

  /// Sets visibility to false.
  void hide() => isVisible = false;

  /// Animates the component to appear with a scale effect.
  ///
  /// Sets the component visible, then scales it from [_normalScale] using a smooth
  /// `Curves.easeOutBack` animation over the given [duration].
  /// Returns a Future that completes when the animation finishes.
  Future<void> scaleIn({double duration = 0.25}) async {
    if (isVisible) return;
    scale = Vector2.all(0);
    isVisible = true;
    final completer = Completer<void>();

    add(
      ScaleEffect.to(
        _normalScale,
        EffectController(duration: duration, curve: Curves.easeOutBack),
        onComplete: () => completer.complete(),
      ),
    );

    return completer.future;
  }

  /// Animates the button with a subtle "pop in" effect.
  ///
  /// The button first scales up to [_maxScale] and then back to [_normalScale]
  /// using a [SequenceEffect]. You can optionally set a [delay] before the
  /// animation starts and control the [duration] of each scale effect.
  Future<void> popIn({double delay = 0.0, double duration = 0.2}) {
    final completer = Completer<void>();
    add(
      SequenceEffect([
        ScaleEffect.to(_maxScale, EffectController(duration: duration, startDelay: delay)),
        ScaleEffect.to(_normalScale, EffectController(duration: duration), onComplete: () => completer.complete()),
      ]),
    );

    return completer.future;
  }

  /// Stops all running animations on the button and resets its scale.
  ///
  /// This method copies all current effects, sets them to their end state,
  /// removes them from the component, and resets the button's scale to [_normalScale].
  void resetAllAnimations() {
    // copy list before removing
    final effects = List<Effect>.from(children.whereType<Effect>());

    for (var effect in effects) {
      effect.controller.setToEnd();
      effect.removeFromParent();
    }

    scale = _normalScale;
  }
}

/// TextBtn is a button component that displays text and reacts to taps.
///
/// It uses [_BaseBtn] for scaling and tap handling.
/// Optionally, a custom TextStyle can be provided.
class TextBtn extends PositionComponent with TapCallbacks, HasVisibility, _BaseBtn {
  // constructor parameters
  final String _text;
  final TextStyle? _textStyle;

  TextBtn({required String text, required void Function() onPressed, required super.position, bool show = true, TextStyle? textStyle})
    : _text = text,
      _textStyle = textStyle {
    _setUpBaseBtn(onPressed: onPressed, show: show);
  }

  late final TextComponent _textComponent;

  @override
  FutureOr<void> onLoad() {
    _setUpText();
    return super.onLoad();
  }

  void _setUpText() {
    _textComponent = TextComponent(
      text: _text,
      anchor: Anchor(0.5, 0.38),
      textRenderer: TextPaint(
        style: _textStyle ?? const TextStyle(fontFamily: 'Pixel Font', fontSize: 18, color: AppTheme.ingameText),
      ),
    );
    add(_textComponent);

    // PositionComponent still needs to be given a size so that it can be clicked on
    size = _textComponent.size;
    _textComponent.position = _textComponent.size / 2;
  }
}

enum SpriteBtnType {
  // normal size
  achievements('Achievements'),
  leaderboard('Leaderboard'),
  levels('Levels'),
  next('Next'),
  play('Play'),
  pause('Pause'),
  previous('Previous'),
  restart('Restart'),
  settings('Settings'),
  volumeOn('Volume On'),
  volumeOff('Volume Off'),

  // small size
  closeSmall('Close Small'),
  backSmall('Back Small'),
  editSmall('Edit Small'),
  previousSmall('Previous Small'),
  nexStSmall('Next Small');

  final String fileName;

  const SpriteBtnType(this.fileName);
}

/// SpriteBtn is a button component that displays a sprite and reacts to taps.
///
/// It uses [_BaseBtn] for scaling and tap handling.
/// Sprite is loaded from a path based on the provided SpriteBtnType.
class SpriteBtn extends SpriteComponent with HasGameReference<PixelQuest>, TapCallbacks, HasVisibility, _BaseBtn {
  // constructor parameters
  final SpriteBtnType _type;

  SpriteBtn({required SpriteBtnType type, required void Function() onPressed, required super.position, bool show = true}) : _type = type {
    _setUpBaseBtn(onPressed: onPressed, show: show);
  }

  // size
  static final Vector2 btnSize = Vector2(21, 22);
  static final Vector2 btnSizeSmall = Vector2(15, 16);

  // animation settings
  static const String _path = 'Menu/Buttons/';
  static const String _pathEnd = '.png';

  @override
  FutureOr<void> onLoad() {
    _loadSprite();
    return super.onLoad();
  }

  void _loadSprite() => sprite = loadSprite(game, '$_path${_type.fileName}$_pathEnd');

  void _setSpriteByName(SpriteBtnType name) => sprite = loadSprite(game, '$_path${name.fileName}$_pathEnd');
}

/// SpriteToggleBtn is a [SpriteBtn] that can toggle between two sprites and actions.
///
/// When tapped, it switches sprite and calls the respective action.
class SpriteToggleBtn extends SpriteBtn {
  // constructor parameters
  final SpriteBtnType _type_2;
  final void Function() _onPressed_2;
  bool _toggle;

  SpriteToggleBtn({
    required super.type,
    required SpriteBtnType type_2,
    required super.onPressed,
    required void Function() onPressed_2,
    required super.position,
    super.show = true,
    bool initialState = true,
  }) : _type_2 = type_2,
       _onPressed_2 = onPressed_2,
       _toggle = initialState;

  @override
  FutureOr<void> onLoad() {
    _setSpriteByName(_toggle ? _type : _type_2);
  }

  @override
  void onTapUp(TapUpEvent event) {
    scale = _BaseBtn._normalScale;
    triggerToggle();
  }

  /// Switches the sprite and triggers the correct action.
  void triggerToggle() {
    if (_toggle) {
      _setSpriteByName(_type_2);
      _onPressed();
    } else {
      _setSpriteByName(_type);
      _onPressed_2();
    }
    _toggle = !_toggle;
  }

  void setState(bool value) {
    if (value == _toggle) return;
    _toggle = value;
    _toggle ? _setSpriteByName(_type) : _setSpriteByName(_type_2);
  }
}
