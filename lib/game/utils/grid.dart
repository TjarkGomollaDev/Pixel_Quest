import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

/// Mixin to add a `SpriteComponent` in its original size
/// while keeping the parent `PositionComponent` aligned to a fixed grid size
/// (e.g. 16x16 for Tiled maps).
///
/// This prevents sprites (e.g. 28x28 sprites) from being stretched
/// to the parent's size. The animation is positioned relative to the
/// parent (default: bottom center).
mixin FixedGridOriginalSizeSprite on PositionComponent {
  /// Holds the reference to the added sprite component.
  late final SpriteComponent spriteComponent;

  /// Adds a `SpriteComponent` in its original [textureSize]
  /// without scaling it to the parent's grid size.
  ///
  /// The sprite is positioned either at the bottom center (default)
  /// or at the center of the parent, and starts with the given [current] state.
  void addSpriteComponent({required Vector2 textureSize, required Sprite sprite, bool isBottomCenter = true}) {
    spriteComponent =
        SpriteComponent(
            size: textureSize,
            position: isBottomCenter ? Vector2(width / 2, height) : Vector2(width / 2, height / 2),
            anchor: isBottomCenter ? Anchor.bottomCenter : Anchor.center,
            sprite: sprite,
          )
          ..debugColor = Colors.transparent
          ..priority = -1;
    add(spriteComponent);
  }
}

/// Mixin to add a `SpriteAnimationComponent` in its original size
/// while keeping the parent `PositionComponent` aligned to a fixed grid size
/// (e.g. 16x16 for Tiled maps).
///
/// This prevents animations (e.g. 28x28 sprites) from being stretched
/// to the parent's size. The animation is positioned relative to the
/// parent (default: bottom center) and plays with the given [animation].
mixin FixedGridOriginalSizeAnimation on PositionComponent {
  /// Holds the reference to the added single animation component.
  late final SpriteAnimationComponent animationComponent;

  /// Adds a `SpriteAnimationComponent` in its original [textureSize]
  /// without scaling it to the parent's grid size.
  ///
  /// The animation is positioned either at the bottom center (default)
  /// or at the center of the parent.
  void addAnimationComponent({required Vector2 textureSize, required SpriteAnimation animation, bool isBottomCenter = true}) {
    animationComponent =
        SpriteAnimationComponent(
            size: textureSize,
            position: isBottomCenter ? Vector2(width / 2, height) : Vector2(width / 2, height / 2),
            anchor: isBottomCenter ? Anchor.bottomCenter : Anchor.center,
            animation: animation,
          )
          ..debugColor = Colors.transparent
          ..priority = -1;

    add(animationComponent);
  }
}

/// Mixin to add a `SpriteAnimationGroupComponent` in its original size
/// while keeping the parent `PositionComponent` aligned to a fixed grid size
/// (e.g. 16x16 for Tiled maps).
///
/// This prevents animations (e.g. 28x28 sprites) from being stretched
/// to the parent's size. The animation is positioned relative to the
/// parent (default: bottom center) and starts with the given state.
mixin FixedGridOriginalSizeGroupAnimation on PositionComponent {
  /// Holds the reference to the added animation component.
  late final SpriteAnimationGroupComponent animationGroupComponent;

  /// Adds a `SpriteAnimationGroupComponent` in its original [textureSize]
  /// without scaling it to the parent's grid size.
  ///
  /// The animation is positioned either at the bottom center (default)
  /// or at the center of the parent, and starts with the given [current] state.
  void addAnimationGroupComponent<T extends Enum>({
    required Vector2 textureSize,
    required Map<T, SpriteAnimation> animations,
    required T current,
    bool isBottomCenter = true,
  }) {
    animationGroupComponent =
        SpriteAnimationGroupComponent<T>(
            size: textureSize,
            position: isBottomCenter ? Vector2(width / 2, height) : Vector2(width / 2, height / 2),
            anchor: isBottomCenter ? Anchor.bottomCenter : Anchor.center,
            animations: animations,
            current: current,
          )
          ..debugColor = Colors.transparent
          ..priority = -1;
    add(animationGroupComponent);
  }
}

/// Snaps a single value to the nearest multiple of the global tile size.
double snapValueToGrid(double value) => ((value / PixelAdventure.tileSize).round()) * PixelAdventure.tileSize;

/// Snaps a 2D vector to the nearest multiple of the global tile size.
Vector2 snapVectorToGrid(Vector2 vector) => Vector2(snapValueToGrid(vector.x), snapValueToGrid(vector.y));
