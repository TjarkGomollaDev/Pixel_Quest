import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:pixel_adventure/game/level/player.dart';

class PlayerHitboxPositionProvider extends PositionProvider {
  final Player _player;

  PlayerHitboxPositionProvider(this._player);

  @override
  Vector2 get position {
    return Vector2(_player.hitboxLeft, _player.hitboxTop);
  }

  @override
  set position(Vector2 value) {}
}

class StaticPositionProvider implements PositionProvider {
  final Vector2 _position;

  const StaticPositionProvider(this._position);

  static final topLeft = StaticPositionProvider(Vector2.zero());

  @override
  Vector2 get position => _position;

  @override
  set position(Vector2 value) {}
}
