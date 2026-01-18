import 'package:flame/components.dart';
import 'package:pixel_adventure/game/utils/animation_state.dart';
import 'package:pixel_adventure/game/game.dart';

/// Loads a single [Sprite] from the given asset [path] in the [game]'s cache.
///
/// Use this for static images that do not need animation.
Sprite loadSprite(PixelQuest game, String path) => Sprite(game.images.fromCache(path));

/// Loads a [SpriteAnimation] from a sprite sheet asset.
///
/// [path] is the asset path in the cache, [amount] is the number of frames,
/// [stepTime] is the duration of a single frame, [textureSize] is the size of each frame,
/// and [texturePosition] can be used to offset the first frame. The [loop] flag
/// determines whether the animation repeats.
SpriteAnimation loadSpriteAnimation(
  PixelQuest game,
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
/// Useful for grouping all animations of a entity in a [SpriteAnimationGroupComponent].
SpriteAnimation Function(T) spriteAnimationWrapper<T extends AnimationState>(
  PixelQuest game,
  String path,
  String pathEnd,
  double stepTime,
  Vector2 textureSize,
) {
  return (T state) {
    return loadSpriteAnimation(game, '$path${state.fileName}$pathEnd', state.amount, stepTime, textureSize, loop: state.loop);
  };
}

Vector2 calculateSizeForHeight(Vector2 spriteSize, double desiredHeight) {
  final aspectRatio = spriteSize.x / spriteSize.y;
  final width = desiredHeight * aspectRatio;
  return Vector2(width, desiredHeight);
}

Vector2 calculateSizeForBoxFit(Vector2 spriteSize, Vector2 targetSize) {
  final imageRatio = spriteSize.x / spriteSize.y;
  final screenRatio = targetSize.x / targetSize.y;

  if (imageRatio > screenRatio) {
    return Vector2(targetSize.y * imageRatio, targetSize.y);
  } else {
    return Vector2(targetSize.x, targetSize.x / imageRatio);
  }
}
