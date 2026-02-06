import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:pixel_quest/app_theme.dart';
import 'package:pixel_quest/game/utils/dialog_container.dart';
import 'package:pixel_quest/game/game.dart';

/// A full-screen overlay page that displays a centered [DialogContainer].
///
/// Features:
/// - Optional blur overlay behind the dialog
/// - Closes the dialog when the user taps outside the dialog bounds
/// - Scales a root component by `game.worldToScreenScale` so UI matches world scaling
///
/// Typical usage:
/// Push this component via your router to show modal dialogs consistently:
/// - The page captures taps everywhere (`containsLocalPoint` always true)
/// - Outside-tap detection uses the dialog's absolute rect
class DialogPage extends Component with HasGameReference<PixelQuest>, TapCallbacks {
  // constructor parameters
  final String _titleText;
  final PositionComponent _content;
  final Vector2 _contentSize;
  final bool _blurBackground;
  final Vector2? _dialogPosition;

  DialogPage({
    required String titleText,
    required PositionComponent content,
    required Vector2 contentSize,
    bool blurBackground = true,
    Vector2? dialogPosition,
  }) : _titleText = titleText,
       _content = content,
       _contentSize = contentSize,
       _blurBackground = blurBackground,
       _dialogPosition = dialogPosition;

  // components
  late final PositionComponent _root;
  RectangleComponent? _blurLayer;
  late final DialogContainer _dialogContainer;

  @override
  Future<void> onLoad() async {
    _setUpRoot();
    _setUpBlurLayer();
    _setUpDialog();
  }

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  bool onTapDown(TapDownEvent event) {
    final dialogRect = _dialogContainer.toAbsoluteRect();
    if (!dialogRect.contains(Offset(event.canvasPosition.x, event.canvasPosition.y))) {
      game.router.pop();
      return true;
    }
    return false;
  }

  void _setUpRoot() {
    _root = PositionComponent()..scale = .all(game.worldToScreenScale);
    add(_root);
  }

  void _setUpBlurLayer() {
    if (!_blurBackground) return;
    _blurLayer = RectangleComponent(size: game.canvasSize / game.worldToScreenScale, paint: Paint()..color = AppTheme.overlayBlur);
    _root.add(_blurLayer!);
  }

  void _setUpDialog() {
    _dialogContainer = DialogContainer(
      titleText: _titleText,
      content: _content,
      contentSize: _contentSize,
      position: _dialogPosition ?? game.canvasSize / game.worldToScreenScale / 2,
    );
    _root.add(_dialogContainer);
  }
}
