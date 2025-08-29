import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

bool checkCollision(player, block) {
  // actual dimensions of the player
  final double playerX = player.position.x + player.hitbox.position.x;
  final double playerY = player.position.y + player.hitbox.position.y;
  final double playerWidth = player.hitbox.width;
  final double playerHeight = player.hitbox.height;

  final double blockX = block.x;
  final double blockY = block.y;
  final double blockWidth = block.width;
  final double blockHeight = block.height;

  // fixed player x and y
  final fixedX = player.scale.x < 0 ? playerX - (player.hitbox.x * 2) - playerWidth : playerX;
  final fixedY = block.isPlattform ? playerY + playerHeight : playerY;

  return (fixedY < blockY + blockHeight &&
      playerY + playerHeight > blockY &&
      fixedX < blockX + blockWidth &&
      fixedX + playerWidth > blockX);
}

/// Defines a contract for animation states used with [SpriteAnimationGroupComponent].
///
/// Each state has a [name] corresponding to the asset file, an [amount] of frames,
/// and an optional [loop] flag (defaults to true). Implement this interface
/// to provide animation metadata for a component.
abstract interface class AnimationState {
  String get name;
  int get amount;
  bool get loop => true;
}

/// Loads a single [Sprite] from the given asset [path] in the [game]'s cache.
///
/// Use this for static images that do not need animation.
Sprite loadSprite(PixelAdventure game, String path) => Sprite(game.images.fromCache(path));

/// Loads a [SpriteAnimation] from a sprite sheet asset.
///
/// [path] is the asset path in the cache, [amount] is the number of frames,
/// [stepTime] is the duration of a single frame, [textureSize] is the size of each frame,
/// and [texturePosition] can be used to offset the first frame. The [loop] flag
/// determines whether the animation repeats.
SpriteAnimation loadSpriteAnimation(
  PixelAdventure game,
  String path,
  int amount,
  double stepTime,
  Vector2 textureSize, {
  Vector2? texturePosition,
  bool loop = true,
}) {
  return SpriteAnimation.fromFrameData(
    game.images.fromCache(path),
    SpriteAnimationData.sequenced(
      amount: amount,
      stepTime: stepTime,
      textureSize: textureSize,
      texturePosition: texturePosition,
      loop: loop,
    ),
  );
}

/// Returns a function that generates a [SpriteAnimation] for a given [AnimationState].
///
/// This allows you to dynamically create animations based on the state's [name], [amount],
/// and [loop] properties, using a common path prefix and suffix ([path] and [pathEnd]).
/// Useful for grouping all animations of a object or enemy in a [SpriteAnimationGroupComponent].
SpriteAnimation Function(T) spriteAnimationWrapper<T extends AnimationState>(
  PixelAdventure game,
  String path,
  String pathEnd,
  double stepTime,
  Vector2 textureSize,
) {
  return (T state) {
    return loadSpriteAnimation(game, '$path${state.name}$pathEnd', state.amount, stepTime, textureSize, loop: state.loop);
  };
}

/// A [SpriteComponent] that only renders a debug outline of its bounds.
///
/// Unlike the default debug mode in Flame, this component does **not** render coordinates or other
/// debug information—only the rectangular frame of the sprite's size is drawn.
///
/// You can customize the color of the outline via [debugColor], and it respects the component's
/// [size], [position], and [priority].
class DebugSpriteComponent extends SpriteComponent {
  DebugSpriteComponent({super.sprite, super.size, super.position, super.priority});

  @override
  void renderDebugMode(Canvas canvas) {
    // only draw the frame of the hitbox, no coordinates
    final paint = Paint()
      ..color = debugColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawRect(size.toRect(), paint);
  }
}

/// Renders a row of sprites or sprite animations along the given side of a [PositionComponent].
///
/// The components are positioned in a straight line (horizontal or vertical) depending on [side],
/// and rotated accordingly (0 = top, 1 = right, 2 = bottom, 3 = left).
///
/// You must provide either a [sprite] **or** a [spriteAnimation].
/// If both are provided, [spriteAnimation] takes precedence.
void addSpriteRow({
  required PixelAdventure game,
  required int side,
  required double count,
  required PositionComponent parent,
  Sprite? sprite,
  SpriteAnimation? animation,
}) {
  for (int i = 0; i < count; i++) {
    final component = animation != null
        ? SpriteAnimationComponent(animation: animation, size: Vector2(PixelAdventure.tileSize, PixelAdventure.tileSize))
        : SpriteComponent(sprite: sprite, size: Vector2(PixelAdventure.tileSize, PixelAdventure.tileSize));

    component.debugColor = Colors.transparent;

    final angle = [0.0, 1.5708, 3.1416, 4.7124][side - 1];
    final position = switch (side) {
      2 => Vector2(parent.size.x, i * PixelAdventure.tileSize),
      3 => Vector2(parent.size.x - i * PixelAdventure.tileSize, parent.size.y),
      4 => Vector2(0, i * PixelAdventure.tileSize + parent.size.x),
      _ => Vector2(i * PixelAdventure.tileSize, 0),
    };

    component
      ..angle = angle
      ..position = position;

    parent.add(component);
  }
}

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

/// A mixin that adds hooks for handling collisions with the [Player].
///
/// Classes that include this mixin can override the following methods
/// to define custom behavior when a [Player] interacts with them:
///
/// - [onPlayerCollisionStart]: Called when the collision with the player begins.
/// - [onPlayerCollision]: Called while the player is colliding with the object.
/// - [onPlayerCollisionEnd]: Called when the collision with the player ends.
///
/// This allows different game objects to react differently to the player
/// without having to modify the player class itself.
mixin PlayerCollision on PositionComponent {
  void onPlayerCollisionStart(Vector2 intersectionPoint) {}
  void onPlayerCollision(Vector2 intersectionPoint) {}
  void onPlayerCollisionEnd() {}
}
