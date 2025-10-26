import 'package:flame/components.dart';

class VisibleSpriteComponent extends SpriteComponent with HasVisibility {
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
    show ? this.show() : hide();
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
    show ? this.show() : hide();
  }

  void show() => isVisible = true;
  void hide() => isVisible = false;
}
