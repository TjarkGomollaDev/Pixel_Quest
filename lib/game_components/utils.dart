import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/game_components/custom_hitbox.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

bool checkCollision(player, block) {
  // hitbox
  final CustomHitbox hitbox = player.hitbox;

  // actual dimensions of the player
  final double playerX = player.position.x + hitbox.offsetX;
  final double playerY = player.position.y + hitbox.offsetY;
  final double playerWidth = hitbox.width;
  final double playerHeight = hitbox.height;

  final double blockX = block.x;
  final double blockY = block.y;
  final double blockWidth = block.width;
  final double blockHeight = block.height;

  // fixed player x and y
  final fixedX = player.scale.x < 0 ? playerX - (hitbox.offsetX * 2) - playerWidth : playerX;
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
