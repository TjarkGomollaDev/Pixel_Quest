import 'dart:async';
import 'package:flame/components.dart';
import 'package:pixel_adventure/game/events/game_event_bus.dart';
import 'package:pixel_adventure/game/level/mobile%20controls/joystick.dart';
import 'package:pixel_adventure/game/level/player/player_input.dart';
import 'package:pixel_adventure/game/level/mobile%20controls/jump_btn.dart';
import 'package:pixel_adventure/game/game_settings.dart';
import 'package:pixel_adventure/game/game.dart';

enum JoystickSetup {
  left,
  right;

  bool get isLeft => this == JoystickSetup.left;
  static const JoystickSetup defaultSetup = JoystickSetup.left;
  static JoystickSetup fromName(String name) => JoystickSetup.values.firstWhere((s) => s.name == name, orElse: () => defaultSetup);
}

class MobileControls extends PositionComponent with HasGameReference<PixelQuest> {
  // constructor parameters
  final PlayerInput _playerInput;
  final bool _showAtStart;

  MobileControls({required PlayerInput playerInput, bool show = false}) : _playerInput = playerInput, _showAtStart = show {
    final minLeft = game.safePadding.minLeft(GameSettings.hudHorizontalMargin);
    size = Vector2(game.size.x - minLeft - game.safePadding.minRight(GameSettings.hudHorizontalMargin), GameSettings.joystickRadius * 2);
    position = Vector2(minLeft, game.size.y - GameSettings.joystickRadius * 2 - GameSettings.mapBorderWidth - 10);
  }

  // controls
  late final Joystick _joystick;
  late final JumpBtn _jumpBtn;

  // setup
  late JoystickSetup _currentSetup;

  // subscription for game events
  GameSubscription? _sub;

  @override
  FutureOr<void> onLoad() {
    _addSubscription();
    _setUpJoystick();
    _setUpJumpBtn();
    _setUpLayout();
    return super.onLoad();
  }

  @override
  void onRemove() {
    _removeSubscription();
    super.onRemove();
  }

  void _addSubscription() {
    _sub = game.eventBus.listen<ControlSettingsChanged>((event) => _applyLayout(event.setup));
  }

  void _removeSubscription() {
    _sub?.cancel();
    _sub = null;
  }

  void _setUpJoystick() {
    _joystick = Joystick(playerInput: _playerInput, show: _showAtStart);
    add(_joystick);
  }

  void _setUpJumpBtn() {
    _jumpBtn = JumpBtn(onJump: _playerInput.jumpPressed, show: _showAtStart);
    add(_jumpBtn);
  }

  void _setUpLayout() {
    _currentSetup = game.storageCenter.settings.joystickSetup;
    _applyLayout(_currentSetup);
  }

  void _applyLayout(JoystickSetup setup) {
    final joystickX = setup.isLeft ? 0.0 : (size.x - GameSettings.joystickRadius * 2);
    final jumpX = setup.isLeft ? (size.x - GameSettings.jumpBtnRadius * 2) : 0.0;
    _joystick.position = Vector2(joystickX, 0);
    _jumpBtn.position = Vector2(jumpX, size.y - GameSettings.jumpBtnRadius * 2);
  }

  void show() {
    _joystick.show();
    _jumpBtn.show();
  }

  void hide() {
    _joystick.hide();
    _jumpBtn.hide();
  }
}
