import 'package:flame/components.dart';
import 'package:pixel_adventure/game/utils/animation_state.dart';
import 'package:pixel_adventure/pixel_quest.dart';

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

/// A [SpriteComponent] that only renders a debug outline of its bounds.
///
/// Unlike the default debug mode in Flame, this component does **not** render coordinates or other
/// debug information—only the rectangular frame of the sprite's size is drawn.
///
/// You can customize the color of the outline via [debugColor], and it respects the component's
/// [size], [position], and [priority].
