import 'package:flame/components.dart';
import 'package:flutter/services.dart';

/// Central input aggregator for the player.
///
/// Combines keyboard and on-screen joystick input into a simple movement axis (`moveX`)
/// and a one-shot jump trigger (`jumped`). Also exposes small helper methods to
/// trigger, clear, and (de)attach mobile controls.
class PlayerInput extends Component with KeyboardHandler {
  // movement output
  double _moveX = 0; // -1, 0, or 1
  bool _jumped = false;

  // getter
  double get moveX => _moveX;
  bool get jumped => _jumped;

  // keyboard state tracking
  double _keyboardMoveX = 0;

  // joystick state tracking
  JoystickComponent? _joystick;
  JoystickDirection _lastJoystickDirection = JoystickDirection.idle;
  double _joystickMoveX = 0;

  @override
  void update(double dt) {
    _updateJoystick();
    _combineMoveX();
    super.update(dt);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final left = keysPressed.contains(LogicalKeyboardKey.keyA) || keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final right = keysPressed.contains(LogicalKeyboardKey.keyD) || keysPressed.contains(LogicalKeyboardKey.arrowRight);
    _keyboardMoveX = (left ? -1 : 0) + (right ? 1 : 0);
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) _jumped = true;
    return super.onKeyEvent(event, keysPressed);
  }

  void _updateJoystick() {
    if (_joystick == null) return;
    if (_joystick!.direction == _lastJoystickDirection) return;
    _lastJoystickDirection = _joystick!.direction;
    switch (_joystick!.direction) {
      case JoystickDirection.left:
      case JoystickDirection.upLeft:
      case JoystickDirection.downLeft:
        _joystickMoveX = -1;
        break;
      case JoystickDirection.right:
      case JoystickDirection.upRight:
      case JoystickDirection.downRight:
        _joystickMoveX = 1;
        break;
      case JoystickDirection.idle:
        _joystickMoveX = 0;
        break;
      default:
        break;
    }
  }

  void _combineMoveX() {
    _moveX = (_keyboardMoveX != 0) ? _keyboardMoveX : _joystickMoveX;
  }

  /// Called to trigger a jump for the current frame.
  void jumpPressed() {
    _jumped = true;
  }

  /// Resets one-shot input flags after the player consumed them.
  void clearInput() {
    _jumped = false;
  }

  /// Attaches a joystick as an input source and resets the cached direction state.
  void attachJoystick(JoystickComponent joystick) {
    _joystick = joystick;
    _lastJoystickDirection = JoystickDirection.idle;
  }

  /// Detaches the current joystick input source and clears related cached state.
  void detachJoystick() {
    _joystick = null;
    _lastJoystickDirection = JoystickDirection.idle;
  }
}
