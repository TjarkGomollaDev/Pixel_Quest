import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/utils/button.dart';
import 'package:pixel_adventure/game/utils/dialog_container.dart';
import 'package:pixel_adventure/game/utils/dialog_page.dart';

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

class _ConfirmContent extends PositionComponent {
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

  @override
  Future<void> onLoad() async {
    final message = TextBoxComponent(
      text: this.message,
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 0),
      textRenderer: AppTheme.dialogTextStandard.asTextPaint,
      boxConfig: TextBoxConfig(maxWidth: size.x, margins: EdgeInsets.zero),
      align: Anchor.topCenter,
    );
    final cancel = TextBtn(
      text: 'Cancel',
      position: Vector2(
        size.x / 3,
        message.position.y + message.size.y + DialogContainer.spacingBetweenSectionsXL + AppTheme.textBtnStandardHeight / 2,
      ),
      onPressed: onCancel,
    );
    final confirm = TextBtn(text: 'Accept', position: Vector2(size.x / 3 * 2, cancel.position.y), onPressed: onConfirm);
    addAll([message, cancel, confirm]);
    return super.onLoad();
  }
}
