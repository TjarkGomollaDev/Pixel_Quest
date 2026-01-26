import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:pixel_adventure/game/level/player/player.dart';

/// Exposes the player's hitbox position as a [PositionProvider], e.g. for camera follow logic.
///
/// This uses the player's *absolute hitbox* position (not the sprite's origin), so the camera can
/// track the actual collision body even when the player sprite is flipped or offset.
class PlayerHitboxPositionProvider extends PositionProvider {
  // constructor parameters
  final Player _player;

  PlayerHitboxPositionProvider(this._player);

  @override
  Vector2 get position => _player.hitboxAbsolutePosition;

  // we don't need the method, so it doesn't matter
  @override
  set position(Vector2 value) {}
}
