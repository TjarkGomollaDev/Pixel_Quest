import 'package:pixel_adventure/game/background/background_scene.dart';

/// User-selectable background setting.
sealed class BackgroundChoice {
  const BackgroundChoice();

  factory BackgroundChoice.scene(BackgroundScene scene) = BackgroundChoiceScene;
  factory BackgroundChoice.worldDefault() = BackgroundChoiceWorldDefault;
  factory BackgroundChoice.random() = BackgroundChoiceRandom;

  /// Serializes this choice into a simple map for storage.
  Map<String, dynamic> toMap();

  /// Restores a choice from storage (falls back to [BackgroundScene.defaultScene] on invalid input).
  static BackgroundChoice fromMap(Map<String, dynamic> map) {
    final type = map['type'] as String?;
    return switch (type) {
      'scene' => BackgroundChoice.scene(BackgroundScene.fromName(map['scene'] as String)!),
      'worldDefault' => BackgroundChoice.worldDefault(),
      'random' => BackgroundChoice.random(),
      _ => BackgroundChoice.scene(BackgroundScene.defaultScene), // fallback
    };
  }
}

/// Background choice that always uses a specific [BackgroundScene].
class BackgroundChoiceScene extends BackgroundChoice {
  final BackgroundScene scene;
  const BackgroundChoiceScene(this.scene);

  @override
  Map<String, dynamic> toMap() => {'type': 'scene', 'scene': scene.name};
}

/// Background choice that defers to the world’s configured default scene.
class BackgroundChoiceWorldDefault extends BackgroundChoice {
  const BackgroundChoiceWorldDefault();

  @override
  Map<String, dynamic> toMap() => {'type': 'worldDefault'};
}

/// Background choice that lets the caller decide a random scene at runtime.
class BackgroundChoiceRandom extends BackgroundChoice {
  const BackgroundChoiceRandom();

  @override
  Map<String, dynamic> toMap() => {'type': 'random'};
}

/// Resolves a stored [BackgroundChoice] into an explicit scene (or `null` if not fixed).
extension BackgroundChoiceResolve on BackgroundChoice {
  /// Returns the explicit scene, or `null` when the choice is world default or random.
  BackgroundScene? resolveChoice() => switch (this) {
    BackgroundChoiceScene(:final scene) => scene,
    BackgroundChoiceWorldDefault() => null,
    BackgroundChoiceRandom() => null,
  };
}

/// Represents the UI “tail option” shown after all scenes.
enum BackgroundChoiceTail { worldDefault, random }

/// Computes the UI index for a choice when rendered as `[scenes..., tail]`.
extension BackgroundChoiceIndex on BackgroundChoice {
  /// Maps this choice to its UI index for the given [scenes] list and configured [tail] option.
  int indexForScenes(List<BackgroundScene> scenes, {required BackgroundChoiceTail tail, int fallbackIndex = 0}) {
    // index of the special last option ("Default" or "Random")
    final tailIndex = scenes.length;
    if (tailIndex == 0) return fallbackIndex;

    return switch (this) {
      BackgroundChoiceScene(:final scene) => scenes.indexOf(scene).clamp(0, tailIndex - 1),
      BackgroundChoiceWorldDefault() => tail == BackgroundChoiceTail.worldDefault ? tailIndex : fallbackIndex,
      BackgroundChoiceRandom() => tail == BackgroundChoiceTail.random ? tailIndex : fallbackIndex,
    };
  }
}
