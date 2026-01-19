import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/utils/dialog_container.dart';
import 'package:pixel_adventure/game/game.dart';

class DialogPage extends Component with HasGameReference<PixelQuest>, TapCallbacks {
  // constructor parameters
  final String _titleText;
  final PositionComponent _content;
  final Vector2 _contentSize;

  DialogPage({required String titleText, required PositionComponent content, required Vector2 contentSize})
    : _titleText = titleText,
      _content = content,
      _contentSize = contentSize;

  // components
  late final PositionComponent _root;
  late final RectangleComponent _blurLayer;
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
    _root = PositionComponent()..scale = Vector2.all(game.worldToScreenScale);
    add(_root);
  }

  void _setUpBlurLayer() {
    _blurLayer = RectangleComponent(size: game.canvasSize / game.worldToScreenScale, paint: Paint()..color = AppTheme.overlayBlur);
    _root.add(_blurLayer);
  }

  void _setUpDialog() {
    _dialogContainer = DialogContainer(
      titleText: _titleText,
      content: _content,
      contentSize: _contentSize,
      position: game.canvasSize / game.worldToScreenScale / 2,
    );
    _root.add(_dialogContainer);
  }
}
