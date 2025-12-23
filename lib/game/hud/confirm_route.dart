import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/utils/button.dart';
import 'package:pixel_adventure/game/utils/dialog_container.dart';
import 'package:pixel_adventure/game/utils/dialog_page.dart';
import 'package:pixel_adventure/pixel_quest.dart';

class ConfirmRoute extends ValueRoute<bool> {
  // constructor parameters
  final String titleText;
  final String message;

  ConfirmRoute({required this.titleText, required this.message}) : super(value: false, transparent: true);

  @override
  Component build() {
    return DialogPage(
      titleText: titleText,
      content: _ConfirmContent(
        titleText: titleText,
        message: message,
        onConfirm: () => completeWith(true),
        onCancel: () => completeWith(false),
      ),
      contentSize: _ConfirmContent.contentSize,
    );
  }
}

class _ConfirmContent extends PositionComponent with HasGameReference<PixelQuest> {
  // constructor parameters
  final String titleText;
  final String message;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  _ConfirmContent({required this.titleText, required this.message, required this.onConfirm, required this.onCancel})
    : super(size: contentSize);

  // content size
  static final Vector2 contentSize = Vector2(
    DialogContainer.contentWidth,
    AppTheme.dialogTextStandardHeight * 2 + DialogContainer.spacingBetweenSectionsXL + AppTheme.textBtnStandardHeight,
  );

  // spacing
  static const double _buttonSpacing = 80;

  @override
  Future<void> onLoad() async {
    _setUpContent();
    return super.onLoad();
  }

  void _setUpContent() {
    final centerX = size.x / 2;

    // user message
    final message = TextBoxComponent(
      text: this.message,
      anchor: Anchor.topCenter,
      position: Vector2(centerX, 0),
      textRenderer: AppTheme.dialogTextStandard.asTextPaint,
      boxConfig: TextBoxConfig(maxWidth: size.x, margins: EdgeInsets.zero),
      align: Anchor.topCenter,
    );

    // cancel btn
    final cancel = TextBtn(
      text: game.l10n.settingsOptionCancel,
      position: Vector2(
        centerX - _buttonSpacing / 2,
        message.position.y + message.size.y + DialogContainer.spacingBetweenSectionsXL + AppTheme.textBtnStandardHeight / 2,
      ),
      onPressed: onCancel,
    );

    // confirm btn
    final confirm = TextBtn(
      text: game.l10n.settingsOptionConfirm,
      position: Vector2(centerX + _buttonSpacing / 2, cancel.position.y),
      onPressed: onConfirm,
    );

    addAll([message, cancel, confirm]);
  }
}
