import 'dart:ui';
import 'package:flame/components.dart';

/// Small visibility helper for Flame components.
///
/// If [isVisible] is `false`, the component (and its children) won’t render.
/// This is meant for simple UI/show-hide cases where you just want to stop drawing,
/// without changing layout/size or removing the component from the tree.
mixin VisibleComponent on Component {
  bool isVisible = true;

  @override
  void renderTree(Canvas canvas) {
    if (isVisible) {
      super.renderTree(canvas);
    }
  }

  /// Convenience init so constructors can easily start hidden/visible.
  void initVisibility(bool show) {
    show ? this.show() : hide();
  }

  /// Shows the component (renders again).
  void show() => isVisible = true;

  /// Hides the component (skips rendering).
  void hide() => isVisible = false;
}

/// SpriteComponent variant that supports the [VisibleComponent] show/hide pattern.
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

/// TextComponent variant that supports the [VisibleComponent] show/hide pattern.
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

/// FpsTextComponent variant that supports the [VisibleComponent] show/hide pattern.
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
