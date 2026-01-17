import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:pixel_adventure/game/level/player/player.dart';

class PlayerHitboxPositionProvider extends PositionProvider {
  final Player _player;

  PlayerHitboxPositionProvider(this._player);

  @override
  Vector2 get position => _player.hitboxAbsolutePosition;

  @override
  set position(Vector2 value) {}
}
