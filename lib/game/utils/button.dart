import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/utils/curves.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/pixel_quest.dart';

/// `_BaseBtn` is a mixin providing consistent and safe button behavior for Flame.
///
/// It supports:
/// - Tap interaction (`onTapDown`, `onTapUp`, `onTapCancel`)
/// - Tap locking (prevents double inputs)
/// - Visibility handling by modifying component size
/// - Optional animated show/hide using scale effects
/// - Correct handling of synchronous *and* asynchronous callbacks
/// - Optional **hold mode** (continuous input while the button is held)
///
/// ---
/// ### SETUP REQUIREMENTS
///
/// Any component mixing in `_BaseBtn` **must** call:
///
/// 1. `_setUpBaseBtn(onPressed: ..., show: ..., holdMode: ...)`
///    → Call inside the constructor
///
/// 2. `_setUpOriginalSize(size)`
///    → Call inside `onLoad()` when the final size is known.
///
/// If either of these is missing, the button will not behave correctly.
///
/// ---
/// ### ABOUT THE CALLBACK
///
/// `_onPressed` accepts both:
/// - `void Function()`
/// - `Future<void> Function()`
///
/// Normal tap (not hold mode):
/// - Returning `void` → no blocking
/// - Returning `Future<void>` → `_executing` is set and the button disables further taps until done
///
/// Hold mode:
/// - `_onPressed` is executed **every frame** while held
/// - It is **never awaited**
/// - Hold input **never blocks** other taps after release
///
/// ---
/// ### NON-BLOCKING CALLBACKS
///
/// If you *want* an async callback **not to block the button**, wrap it with:
/// ```dart
/// onPressed: nonBlocking(() async { ... })
/// ```
///
/// `nonBlocking()` returns a `FutureOr<void>` wrapper that starts
/// the async work *fire-and-forget*, so `_executing` never activates.
/// The button remains immediately tappable.
///
/// ---
/// ### WHY NOT USE `isVisible`?
///
/// For buttons, relying on `isVisible` mixin alone can be error-prone with simultaneous
/// animations and taps. Instead, this mixin sets `size = Vector2.zero()` when hiding
/// and restores the original size when showing. This ensures the button cannot be
/// tapped while hidden and avoids subtle race conditions.
///
/// ---
/// ### TAP BLOCKING RULES
///
/// A tap is only accepted when ALL are true:
/// - `_tapLocked == false`
/// - `_logicalVisible == true`
/// - `_animating == false`
/// - `_executing == false` (only true when async callback returns a Future)
///
/// These rules **also apply during hold mode**, ensuring full consistency.
mixin _BaseBtn on PositionComponent, TapCallbacks {
  // the assigned callback for the button
  late FutureOr<void> Function() _onPressed;

  // scale values for press animation
  static final Vector2 _normalScale = Vector2.all(1);
  static final Vector2 _maxScale = Vector2.all(1.05);

  // all three flags are combined ensuring the button
  // reacts only when it is ready, visible, and not animating
  bool _tapLocked = false;
  bool _logicalVisible = true;
  bool _animating = false;
  bool _executing = false;

  // stores the original, tappable size of the button
  late Vector2 _originalSize;

  // flags used for hold mode
  bool _holdMode = false;
  bool _isHeld = false;

  @override
  void onTapDown(TapDownEvent event) {
    if (!_canReceiveTap) return;
    scale = _maxScale;
    if (_holdMode) _isHeld = true;

    super.onTapDown(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!_canReceiveTap) return;
    scale = _normalScale;
    if (!_holdMode) {
      // single tap logic below
      _tapLocked = true;
      Future.delayed(const Duration(milliseconds: 80), () => _tapLocked = false);
      final result = _callOnPressed();
      if (result is Future) {
        _executing = true;
        result.whenComplete(() => _executing = false);
      }
    } else {
      _isHeld = false;
    }

    super.onTapUp(event);
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    if (!_canReceiveTap) return;
    scale = _normalScale;
    if (_holdMode) _isHeld = false;

    super.onTapCancel(event);
  }

  @override
  void update(double dt) {
    if (!(_holdMode && _isHeld && _canReceiveTap)) return;
    _callOnPressed();
    super.update(dt);
  }

  /// Initializes the button.
  /// MUST be called inside the constructor of any class mixing in `_BaseBtn`.
  ///
  /// - [onPressed] : callback to execute when the button is tapped
  /// - [show]      : whether the button starts visible or hidden
  /// - [holdMode]  : if hold mode is to be used instead of a single tap
  void _setUpBaseBtn({required FutureOr<void> Function() onPressed, required bool show, required bool holdMode}) {
    _onPressed = onPressed;
    if (!show) hide();
    _holdMode = holdMode;
    _initialSetup();
  }

  /// Sets the original (intended) size of the button.
  /// MUST be called in `onLoad()` where the true size is finally available.
  void _setUpOriginalSize(Vector2 size) => _originalSize = size;

  void _initialSetup() {
    // debug
    debugColor = AppTheme.transparent;

    // general
    anchor = Anchor.center;
  }

  /// Sets scale to normal.
  void setNormalScale() => scale = _normalScale;

  /// Sets scale to max.
  void setMaxScale() => scale = _maxScale;

  /// Determines whether this button may receive and react to taps.
  ///
  /// All interaction is blocked when:
  /// - `_tapLocked` is true (tap cooldown)
  /// - `_logicalVisible` is false (hidden)
  /// - `_animating` is true (during show/hide animation)
  /// - `_executing` is true (async onPressed callback still running)
  bool get _canReceiveTap => !_tapLocked && _logicalVisible && !_animating && !_executing;

  /// Executes the button callback.
  /// This method simply calls `_onPressed()` and returns its result.
  ///
  /// Return type rules:
  /// - If callback returns `void`: result is `void` → no tap blocking
  /// - If callback returns `Future<void>`: result is a Future → `_executing` is set
  ///
  /// Subclasses may override this to modify behavior (e.g. toggle buttons)
  /// without rewriting the entire `onTapUp` logic.
  FutureOr<void> _callOnPressed() => _onPressed();

  /// Shows the button immediately.
  /// Restores the original size and marks the logical visibility flag.
  void show() {
    size = _originalSize;
    _logicalVisible = true;
  }

  /// Hides the button immediately.
  /// Sets the size to zero to prevent interaction and visual presence.
  void hide() {
    size = Vector2.zero();
    _logicalVisible = false;
  }

  /// Animates the button to appear with a scale effect.
  ///
  /// Sets the button visible, restores its original size, then scales it
  /// from zero to [_normalScale] using a smooth `Curves.easeOutBack` animation.
  /// While animating, taps are blocked.
  ///
  /// Parameters:
  /// - [delay]    : optional delay before the animation starts (in seconds)
  /// - [duration] : duration of the scale animation (in seconds)
  Future<void> animatedShow({double delay = 0.0, double duration = 0.25}) async {
    if (_animating) return;
    _animating = true;
    show();
    scale = Vector2.zero();
    final completer = Completer<void>();

    add(
      ScaleEffect.to(
        _normalScale,
        EffectController(duration: duration, startDelay: delay, curve: Curves.easeOutBack),
        onComplete: () {
          _animating = false;
          completer.complete();
        },
      ),
    );
    return completer.future;
  }

  /// Animates the button to disappear with a scale effect.
  ///
  /// Scales the button from [_normalScale] down to zero over the given [duration].
  /// Sets `_logicalVisible` to false immediately, and the `size` is set to zero
  /// when the animation completes. Taps are blocked during the animation.
  ///
  /// Parameters:
  /// - [delay]    : optional delay before the animation starts (in seconds)
  /// - [duration] : duration of the scale animation (in seconds)
  Future<void> animatedHide({double delay = 0.0, double duration = 0.15}) async {
    if (_animating) return;
    _animating = true;
    _logicalVisible = false;
    scale = _normalScale;
    final completer = Completer<void>();

    add(
      ScaleEffect.to(
        Vector2.zero(),
        EffectController(duration: duration, startDelay: delay, curve: FastStartAccelerateCurve()),
        onComplete: () {
          size = Vector2.zero();
          _animating = false;
          completer.complete();
        },
      ),
    );

    return completer.future;
  }

  /// Performs a subtle visual "pop in" animation on the button.
  ///
  /// This is purely a visual effect: the button's logical visibility
  /// and tap handling are **not affected**. The button can still be
  /// tapped while the animation is running.
  ///
  /// The button first scales up to [_maxScale] and then back to [_normalScale]
  /// using a [SequenceEffect].
  ///
  /// Parameters:
  /// - [delay]    : optional delay before the animation starts (in seconds)
  /// - [duration] : duration of each scale step (in seconds)
  Future<void> animatePopIn({double delay = 0.0, double duration = 0.2}) {
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
/// [TextBtn] uses [_BaseBtn] to provide:
/// - consistent tap handling (tap down/up/cancel)
/// - optional hold mode (callback every frame while held)
/// - tap locking and async-safe execution
/// - show/hide and animated show/hide via scale effects
///
/// Optionally, a custom TextStyle can be provided.
class TextBtn extends PositionComponent with TapCallbacks, HasVisibility, _BaseBtn {
  // constructor parameters
  final String _text;
  final TextStyle? _textStyle;

  TextBtn({
    required String text,
    required void Function() onPressed,
    required super.position,
    bool show = true,
    bool holdMode = false,
    TextStyle? textStyle,
  }) : _text = text,
       _textStyle = textStyle {
    _setUpBaseBtn(onPressed: onPressed, show: show, holdMode: holdMode);
  }

  late final TextComponent _textComponent;

  @override
  FutureOr<void> onLoad() {
    _setUpText();
    _setUpOriginalSize(_textComponent.size);
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

/// Describes all predefined sprite-based menu buttons.
///
/// Each enum value:
/// - holds its file name without extension
/// - can build its full asset path via [path]
/// - provides shared size information for normal and small buttons
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
  upSmall('Up Small'),
  downSmall('Down Small'),
  previousSmall('Previous Small'),
  nextSmall('Next Small');

  // path
  static const String _basePath = 'Menu/Buttons/';
  static const String _pathEnd = '.png';
  String get path => _basePath + fileName + _pathEnd;

  // size
  static final Vector2 _btnSize = Vector2(21, 22);
  static final Vector2 _btnSizeSmall = Vector2(15, 16);
  static final Vector2 _btnOffset = Vector2.all(2);

  // size getter
  static Vector2 get btnSize => _btnSize;
  static Vector2 get btnSizeCorrected => _btnSize - _btnOffset;
  static Vector2 get btnSizeSmall => _btnSizeSmall;
  static Vector2 get btnSizeSmallCorrected => _btnSizeSmall - _btnOffset;

  final String fileName;
  const SpriteBtnType(this.fileName);
}

/// SpriteBtn is a button component that displays a sprite and reacts to taps.
///
/// [SpriteBtn] uses [_BaseBtn] to provide:
/// - consistent tap handling (tap down/up/cancel)
/// - optional hold mode (callback every frame while held)
/// - tap locking and async-safe execution
/// - show/hide and animated show/hide via scale effects
///
/// The sprite is loaded from the provided [path]. For predefined menu buttons,
/// use [SpriteBtn.fromType] with a [SpriteBtnType] value.
class SpriteBtn extends SpriteComponent with HasGameReference<PixelQuest>, TapCallbacks, HasVisibility, _BaseBtn {
  // constructor parameters
  final String _path;

  SpriteBtn({
    required String path,
    required FutureOr<void> Function() onPressed,
    required super.position,
    bool show = true,
    bool holdMode = false,
  }) : _path = path {
    _setUpBaseBtn(onPressed: onPressed, show: show, holdMode: holdMode);
  }

  SpriteBtn.fromType({
    required SpriteBtnType type,
    required FutureOr<void> Function() onPressed,
    required Vector2 position,
    bool show = true,
    bool holdMode = false,
  }) : this(path: type.path, onPressed: onPressed, position: position, show: show, holdMode: holdMode);

  @override
  FutureOr<void> onLoad() {
    _loadSprite();
    _setUpOriginalSize(sprite!.srcSize);
    return super.onLoad();
  }

  void _loadSprite() => sprite = loadSprite(game, _path);
}

/// A [SpriteBtn] that can toggle between two sprites and two actions.
///
/// When tapped, [SpriteToggleBtn]:
/// - toggles its internal state
/// - swaps between the two sprites
/// - executes the corresponding callback for the new state
///
/// It inherits all behavior from [SpriteBtn].
///
/// Use [SpriteToggleBtn.fromType] when both sprites are defined as [SpriteBtnType]s.
class SpriteToggleBtn extends SpriteBtn {
  // constructor parameters
  final String _path_2;
  final FutureOr<void> Function() _onPressed_2;
  bool _toggleState;

  SpriteToggleBtn({
    required super.path,
    required String path_2,
    required super.onPressed,
    required FutureOr<void> Function() onPressed_2,
    required super.position,
    bool initialState = true,
  }) : _path_2 = path_2,
       _onPressed_2 = onPressed_2,
       _toggleState = initialState;

  SpriteToggleBtn.fromType({
    required SpriteBtnType type,
    required SpriteBtnType type_2,
    required FutureOr<void> Function() onPressed,
    required FutureOr<void> Function() onPressed_2,
    required Vector2 position,
    bool initialState = true,
  }) : this(
         path: type.path,
         path_2: type_2.path,
         onPressed: onPressed,
         onPressed_2: onPressed_2,
         position: position,
         initialState: initialState,
       );

  // sprite that is displayed depending on the toggle state
  late final Sprite _sprite;
  late final Sprite _sprite_2;

  @override
  void _loadSprite() {
    _sprite = loadSprite(game, _path);
    _sprite_2 = loadSprite(game, _path_2);
    _setSpriteToState();
  }

  @override
  FutureOr<void> _callOnPressed() => triggerToggle();

  void _setSpriteToState() => sprite = _toggleState ? _sprite : _sprite_2;

  /// Switches the sprite and triggers the corresponding action.
  FutureOr<void> triggerToggle() {
    _toggleState = !_toggleState;
    _setSpriteToState();
    if (_toggleState) return _onPressed_2();
    return _onPressed();
  }

  /// Sets a new toggle state and updates the displayed sprite accordingly.
  void setState(bool value) {
    if (value == _toggleState) return;
    _toggleState = value;
    _setSpriteToState();
  }
}

/// Wraps an async callback so the button does NOT block while it runs.
///
/// Usage:
/// onPressed: nonBlocking(() async { ... });
///
/// The returned function is `FutureOr<void>` and starts the async work
/// without returning the Future to `_BaseBtn`.
/// Because `_callOnPressed()` receives a **void**, `_executing` never activates.
/// This keeps the button tappable even during long async operations.
FutureOr<void> Function() nonBlocking(Future<void> Function() asyncFn) {
  return () {
    asyncFn(); // fire-and-forget
  };
}
