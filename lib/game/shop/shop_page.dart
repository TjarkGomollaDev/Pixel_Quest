import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/utils/dialog_container.dart';
import 'package:pixel_adventure/game/utils/dialog_page.dart';
import 'package:pixel_adventure/game/game.dart';

class ShopPage extends Route {
  ShopPage() : super(() => _ShopDialog(), transparent: true);
}

class _ShopDialog extends Component with HasGameReference<PixelQuest> {
  @override
  FutureOr<void> onLoad() {
    add(DialogPage(content: _ShopContent(), titleText: 'Shop', contentSize: _ShopContent.contentSize));
    return super.onLoad();
  }
}

class _ShopContent extends PositionComponent with HasGameReference<PixelQuest> {
  _ShopContent() : super(size: contentSize);

  // content size
  static final Vector2 contentSize = Vector2(DialogContainer.contentWidth, 100);

  @override
  FutureOr<void> onLoad() {
    add(
      TextComponent(
        position: size / 2,
        anchor: Anchor.center,
        text: 'Coming Soon...',
        textRenderer: AppTheme.dialogTextStandard.asTextPaint,
      ),
    );
    return super.onLoad();
  }
}
