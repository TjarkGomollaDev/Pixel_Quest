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
