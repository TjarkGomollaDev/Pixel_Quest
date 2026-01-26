import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/level/player/player_input.dart';
import 'package:pixel_adventure/game/utils/arrow_indicator.dart';
import 'package:pixel_adventure/game/game_settings.dart';
import 'package:pixel_adventure/game/utils/visible_components.dart';

/// Wrapper around Flame’s [JoystickComponent] that can be shown/hidden and (de)attached to [PlayerInput].
///
/// Keeps input wiring in one place: when the component is visible it attaches the joystick to the player input,
/// and when it’s hidden or removed it detaches again to avoid stale input references.
class Joystick extends PositionComponent with VisibleComponent {
  // constructor parameters
  final PlayerInput _playerInput;

  Joystick({required PlayerInput playerInput, bool show = true}) : _playerInput = playerInput {
    size = Vector2.all(GameSettings.joystickRadius * 2);
    initVisibility(show);
  }

  // component
  late final JoystickComponent _joystick;
  bool _attached = false;

  @override
  FutureOr<void> onLoad() {
    _setUpComponent();
    return super.onLoad();
  }

  @override
  void onRemove() {
    _detach();
    super.onRemove();
  }

  @override
  void show() {
    isVisible = true;
    _attach();
  }

  @override
  void hide() {
    isVisible = false;
    _detach();
  }

  void _setUpComponent() {
    _joystick = JoystickComponent(
      knob: CircleComponent(
        radius: GameSettings.knobRadius,
        paint: Paint()
          // white circle with a shader to create a 3D effect
          ..shader =
              const RadialGradient(
                colors: [AppTheme.white, AppTheme.white, Color.fromARGB(255, 176, 176, 178)],
                stops: [0.0, 0.8, 1.0],
              ).createShader(
                Rect.fromCircle(center: Offset(GameSettings.knobRadius, GameSettings.knobRadius), radius: GameSettings.knobRadius),
              ),
      ),
      background: _JoystickBackground(),
      anchor: Anchor.topLeft,
    );
    add(_joystick);
  }

  void _attach() {
    if (_attached) return;
    _playerInput.attachJoystick(_joystick);
    _attached = true;
  }

  void _detach() {
    if (!_attached) return;
    _playerInput.detachJoystick();
    _attached = false;
  }
}

/// Visual background for the joystick.
///
/// Purely decorative: it doesn’t handle input itself, it just renders the base UI for the joystick.
class _JoystickBackground extends PositionComponent {
  _JoystickBackground() : super(size: Vector2.all(GameSettings.joystickRadius * 2));

  // styling
  static final Color _bgColor = AppTheme.tileBlur; // [Adjustable]
  static const Color _arrowColor = AppTheme.grayLight6; // [Adjustable]
  static final Vector2 _arrowSize = Vector2(5, 6); // [Adjustable]
  static const double _arrowDistanceFromCenter = 0.7; // [Adjustable]

  @override
  Future<void> onLoad() async {
    _setUpBackground();
    return super.onLoad();
  }

  void _setUpBackground() {
    // circle background
    final bg = CircleComponent(
      radius: GameSettings.joystickRadius,
      paint: Paint()..color = _bgColor,
      anchor: Anchor.center,
      position: size / 2,
    );

    // arrows
    final center = size / 2;
    final dx = GameSettings.joystickRadius * _arrowDistanceFromCenter;
    final leftArrow = ArrowIndicator(dir: ArrowDir.left, arrowSize: _arrowSize, color: _arrowColor, position: center + Vector2(-dx, 0));
    final rightArrow = ArrowIndicator(dir: ArrowDir.right, arrowSize: _arrowSize, color: _arrowColor, position: center + Vector2(dx, 0));

    addAll([bg, leftArrow, rightArrow]);
  }
}
