import 'package:flame/components.dart';
import 'package:flame/effects.dart';

class VisibleSpriteComponent extends SpriteComponent with HasVisibility implements OpacityProvider {
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
    if (!show) hide();
  }

  void show() => isVisible = true;
  void hide() => isVisible = false;
}

class VisibleTextComponent extends TextComponent with HasVisibility {
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
    if (!show) hide();
  }

  void show() => isVisible = true;
  void hide() => isVisible = false;
}
