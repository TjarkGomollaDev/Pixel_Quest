import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:pixel_adventure/game/level/player/player.dart';

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
