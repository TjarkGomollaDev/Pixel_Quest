import 'dart:ui';
import 'package:flame/components.dart';
import 'package:pixel_adventure/components/custom_hitbox.dart';
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

abstract interface class AnimationState {
  String get name;
  int get amount;
  bool get loop => true;
}

Sprite loadSprite(PixelAdventure game, String path) => Sprite(game.images.fromCache(path));

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

class DebugSpriteComponent extends SpriteComponent {
  DebugSpriteComponent({super.sprite, super.size, super.position, super.priority});

  @override
  void renderDebugMode(Canvas canvas) {
    // Nur den Rahmen der Hitbox zeichnen, keine Koordinaten
    final paint = Paint()
      ..color = debugColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawRect(size.toRect(), paint);
  }
}
