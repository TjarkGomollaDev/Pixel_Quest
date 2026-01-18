import 'dart:ui';
import 'package:flame/components.dart';

mixin VisibleComponent on Component {
  bool isVisible = true;

  @override
  void renderTree(Canvas canvas) {
    if (isVisible) {
      super.renderTree(canvas);
    }
  }

  void initVisibility(bool show) {
    if (!show) hide();
  }

  void show() => isVisible = true;
  void hide() => isVisible = false;
}

class VisibleSpriteComponent extends SpriteComponent with VisibleComponent {
  VisibleSpriteComponent({
    super.sprite,
    super.autoResize,
    super.paint,
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.nativeAngle,
    super.anchor,
    super.children,
    super.priority,
    super.bleed,
    super.key,
    bool show = true,
  }) {
    initVisibility(show);
  }
}

class VisibleTextComponent extends TextComponent with VisibleComponent {
  VisibleTextComponent({
    super.text,
    super.textRenderer,
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.children,
    super.priority,
    super.key,
    bool show = true,
  }) {
    initVisibility(show);
  }
}

class VisibleFpsTextComponent extends FpsTextComponent with VisibleComponent {
  VisibleFpsTextComponent({
    super.windowSize,
    super.decimalPlaces,
    super.textRenderer,
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.priority,
    bool show = true,
  }) {
    initVisibility(show);
  }
}
