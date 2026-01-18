import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/data/audio/audio_center.dart';
import 'package:pixel_adventure/game/utils/corner_outline.dart';
import 'package:pixel_adventure/game/utils/curves.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game/game.dart';

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
mixin _BaseBtn on PositionComponent, HasGameReference<PixelQuest>, TapCallbacks {
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

  // tap down is required before tap up
  bool _hadTapDown = false;

  @override
  void onTapDown(TapDownEvent event) {
    if (!_canReceiveTap) return;
    _hadTapDown = true;
    scale = _maxScale;
    if (_holdMode) _isHeld = true;
    game.audioCenter.playSound(Sfx.tap, SfxType.ui);
    super.onTapDown(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!_hadTapDown) return;
    _hadTapDown = false;

    if (!_canReceiveTap) return;
    scale = _normalScale;
    if (!_holdMode) {
      // single tap logic below
      _tapLocked = true;
      Future.delayed(const Duration(milliseconds: 200), () => _tapLocked = false);
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
    _hadTapDown = false;
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
    anchor = Anchor.center;
  }

  /// Sets the original (intended) size of the button.
  /// MUST be called in `onLoad()` where the true size is finally available.
  void _setUpOriginalSize(Vector2 size) => _originalSize = size;

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
class TextBtn extends PositionComponent with HasGameReference<PixelQuest>, TapCallbacks, HasVisibility, _BaseBtn {
  // constructor parameters
  final String _text;
  final TextStyle? _textStyle;

  TextBtn({
    required String text,
    required FutureOr<void> Function() onPressed,
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
      anchor: Anchor.center,
      textRenderer: TextPaint(style: _textStyle ?? AppTheme.textBtnStandard),
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
  dollar('Dollar'),

  // small size
  closeSmall('Close Small'),
  backSmall('Back Small'),
  editSmall('Edit Small'),
  upSmall('Up Small'),
  downSmall('Down Small'),
  previousSmall('Previous Small'),
  nextSmall('Next Small'),

  // blank
  blankOn('Blank On'),
  blankOff('Blank Off');

  // path
  static const String _basePath = 'Menu/Buttons/';
  static const String _pathEnd = '.png';
  String get path => _basePath + fileName + _pathEnd;

  // size
  static final Vector2 _btnSize = Vector2(21, 22);
  static final Vector2 _btnSizeSmall = Vector2(15, 16);
  static final Vector2 _btnSizeBlank = Vector2(15, 72);
  static final Vector2 _btnOffset = Vector2.all(2);

  // size getter
  static Vector2 get btnSize => _btnSize;
  static Vector2 get btnSizeCorrected => _btnSize - _btnOffset;
  static Vector2 get btnSizeSmall => _btnSizeSmall;
  static Vector2 get btnSizeSmallCorrected => _btnSizeSmall - _btnOffset;
  static Vector2 get btnSizeBlank => _btnSizeBlank;
  static Vector2 get btnSizeBlankCorrected => _btnSizeBlank - _btnOffset;

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
  final String? _textOnBtn;

  SpriteBtn({
    required String path,
    required FutureOr<void> Function() onPressed,
    required super.position,
    bool show = true,
    bool holdMode = false,
    String? textOnBtn,
  }) : _path = path,
       _textOnBtn = textOnBtn {
    _setUpBaseBtn(onPressed: onPressed, show: show, holdMode: holdMode);
  }

  SpriteBtn.fromType({
    required SpriteBtnType type,
    required FutureOr<void> Function() onPressed,
    required Vector2 position,
    bool show = true,
    bool holdMode = false,
    String? textOnBtn,
  }) : this(path: type.path, onPressed: onPressed, position: position, show: show, holdMode: holdMode, textOnBtn: textOnBtn);

  // text
  TextComponent? _textComponent;

  @override
  FutureOr<void> onLoad() {
    _loadSprite();
    _addTextOnBtn();
    _setUpOriginalSize(sprite!.srcSize);
    return super.onLoad();
  }

  void _addTextOnBtn() {
    if (_textOnBtn == null) return;
    _textComponent = TextComponent(
      text: _textOnBtn,
      position: size / 2,
      anchor: Anchor(0.5, 0.42),
      textRenderer: TextPaint(
        style: const TextStyle(fontFamily: 'Pixel Font', fontSize: 6, color: AppTheme.ingameText),
      ),
    );
    add(_textComponent!);
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
  String? _textOnBtn_2;

  SpriteToggleBtn({
    required super.path,
    required String path_2,
    required super.onPressed,
    required FutureOr<void> Function() onPressed_2,
    required super.position,
    bool initialState = true,
    super.textOnBtn,
    String? textOnBtn_2,
    super.show = true,
  }) : _path_2 = path_2,
       _onPressed_2 = onPressed_2,
       _toggleState = initialState,
       _textOnBtn_2 = textOnBtn_2;

  SpriteToggleBtn.fromType({
    required SpriteBtnType type,
    required SpriteBtnType type_2,
    required FutureOr<void> Function() onPressed,
    required FutureOr<void> Function() onPressed_2,
    required Vector2 position,
    bool initialState = true,
    String? textOnBtn,
    String? textOnBtn_2,
    bool show = true,
  }) : this(
         path: type.path,
         path_2: type_2.path,
         onPressed: onPressed,
         onPressed_2: onPressed_2,
         position: position,
         initialState: initialState,
         textOnBtn: textOnBtn,
         textOnBtn_2: textOnBtn_2,
         show: show,
       );

  // toggle state
  bool _toggleState;

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
  void _addTextOnBtn() {
    if (_textOnBtn == null && _textOnBtn_2 == null) return;
    _textComponent = TextComponent(
      text: '',
      position: size / 2,
      anchor: Anchor(0.5, 0.42),
      textRenderer: TextPaint(
        style: const TextStyle(fontFamily: 'Pixel Font', fontSize: 6, color: AppTheme.ingameText),
      ),
    );
    add(_textComponent!);
    _setTextToState();
  }

  @override
  FutureOr<void> _callOnPressed() => triggerToggle();

  void _setSpriteToState() => sprite = _toggleState ? _sprite : _sprite_2;

  void _setTextToState() => _textComponent?.text = _toggleState ? (_textOnBtn ?? '') : (_textOnBtn_2 ?? '');

  /// Switches the sprite and triggers the corresponding action.
  FutureOr<void> triggerToggle() {
    _toggleState = !_toggleState;
    _setSpriteToState();
    _setTextToState();
    if (_toggleState) return _onPressed_2();
    return _onPressed();
  }

  /// Sets a new toggle state and updates the displayed sprite accordingly.
  void setState(bool value) {
    if (value == _toggleState) return;
    _toggleState = value;
    _setSpriteToState();
    _setTextToState();
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

class RadioOption {
  // constructor parameters
  final String text;
  final FutureOr<void> Function() onSelected;

  const RadioOption({required this.text, required this.onSelected});
}

class _RadioBtn extends PositionComponent with HasGameReference<PixelQuest>, TapCallbacks, HasVisibility, _BaseBtn {
  // constructor parameters
  final String _text;
  final TextStyle? _textStyle;

  _RadioBtn({
    required String text,
    required super.size,
    required FutureOr<void> Function() onPressed,
    required super.position,
    TextStyle? textStyle,
    bool show = true,
  }) : _text = text,
       _textStyle = textStyle {
    _setUpBaseBtn(onPressed: onPressed, show: show, holdMode: false);
  }

  // text
  late final TextComponent _textComponent;

  @override
  FutureOr<void> onLoad() {
    _setUpText();
    _setUpOriginalSize(size);
    return super.onLoad();
  }

  void _setUpText() {
    _textComponent = TextComponent(
      text: _text,
      position: size / 2,
      anchor: Anchor.center,
      textRenderer: TextPaint(style: _textStyle ?? AppTheme.dialogTextStandard),
    );
    add(_textComponent);
  }
}

class RadioComponent extends PositionComponent {
  // constructor parameters
  final List<RadioOption> _options;
  final Vector2 _optionSize;
  final double _spacingBetweenOptions;
  final TextStyle? _textStyle;
  final int _initialIndex;
  final bool _triggerInitialOnSelected;
  final double _outlineCornerLength;
  final double _outlineStrokeWidth;
  final Color _outlineColor;

  RadioComponent({
    required List<RadioOption> options,
    Vector2? optionSize,
    double spacingBetweenOptions = 6,
    super.position,
    TextStyle? textStyle,
    int initialIndex = 0,
    bool triggerInitialOnSelected = false,
    super.anchor = Anchor.topLeft,
    double outlineCornerLength = 5,
    double outlineStrokeWidth = 1,
    Color outlineColor = AppTheme.ingameText,
  }) : _outlineColor = outlineColor,
       _outlineStrokeWidth = outlineStrokeWidth,
       _outlineCornerLength = outlineCornerLength,
       _triggerInitialOnSelected = triggerInitialOnSelected,
       _initialIndex = initialIndex,
       _textStyle = textStyle,
       _spacingBetweenOptions = spacingBetweenOptions,
       _optionSize = optionSize ?? defaultSize,
       _options = options,
       assert(options.isNotEmpty, 'RadioComponent needs at least 1 option') {
    // calculate size of the component
    size = Vector2(_optionSize.x * _options.length + _spacingBetweenOptions * (_options.length - 1), _optionSize.y);
  }

  // default size
  static final Vector2 defaultSize = Vector2(52, 20);

  // internal
  final List<_RadioBtn> _btns = [];
  final List<Vector2> _centerOfIndex = [];
  late final CornerOutline _outline;

  // index
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  // animation settings
  static const double _switchOutlineDuration = 0.18; // [Adjustable]

  @override
  FutureOr<void> onLoad() {
    _setUpRadioBtns();
    _setUpOutline();
    if (_triggerInitialOnSelected) _options[_selectedIndex].onSelected();
    return super.onLoad();
  }

  void _setUpRadioBtns() {
    _selectedIndex = _initialIndex.clamp(0, _options.length - 1);
    for (var i = 0; i < _options.length; i++) {
      // calculate center
      final center = Vector2(_optionSize.x / 2 + i * (_optionSize.x + _spacingBetweenOptions), _optionSize.y / 2);
      _centerOfIndex.add(center);

      // create radio btns
      final btn = _RadioBtn(
        text: _options[i].text,
        size: _optionSize,
        position: _centerOfIndex[i],
        textStyle: _textStyle,
        onPressed: () => _select(i),
      );
      _btns.add(btn);
      add(btn);
    }
  }

  void _setUpOutline() {
    _outline = CornerOutline(
      size: _optionSize,
      cornerLength: _outlineCornerLength,
      strokeWidth: _outlineStrokeWidth,
      color: _outlineColor,
      anchor: Anchor.center,
      position: _centerOfIndex[_selectedIndex],
    );
    add(_outline);
  }

  FutureOr<void> _select(int index) async {
    if (index == _selectedIndex) return;

    // lock all buttons while the function is running
    for (var btn in _btns) {
      btn._executing = true;
    }
    _selectedIndex = index;
    _animateOutlineTo(index);
    await _options[index].onSelected();
    for (final btn in _btns) {
      btn._executing = false;
    }
  }

  FutureOr<void> setSelectedIndex(int index, {bool triggerCallback = false}) {
    if (triggerCallback) return _select(index);
    if (index == _selectedIndex) return null;
    _selectedIndex = index;
    _animateOutlineTo(index);
  }

  void _animateOutlineTo(int index) {
    // remove any running effects on the outline so we don't stack animations
    for (final e in _outline.children.whereType<Effect>().toList()) {
      e.removeFromParent();
    }

    // animate outline to target center
    final targetCenter = _centerOfIndex[index];
    _outline.add(MoveEffect.to(targetCenter, EffectController(duration: _switchOutlineDuration, curve: Curves.easeOutCubic)));
  }
}
