import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game_components/level/player.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

/// Invisible component representing the fan's air stream.
///
/// The air stream extends vertically above the fan and pushes the
/// player upward with a configurable force. The width of the stream
/// can be adjusted using a widen factor. The stream also allows the
/// player to regain their double jump while inside.
///
/// Collision handling is used to detect when the player enters or
/// leaves the stream, setting [_playerInStream] accordingly.
class FanAirStream extends PositionComponent with HasGameReference<PixelAdventure>, CollisionCallbacks {
  // constructor parameters
  final double _baseWidth;
  final double _airStreamHeight;
  final Player _player;

  FanAirStream({required double baseWidth, required double airStreamHeight, required Player player, required super.position})
    : _baseWidth = baseWidth,
      _airStreamHeight = airStreamHeight,
      _player = player {
    final airStreamWidth = _baseWidth * _widenFactor;
    final airStreamOffset = Vector2(-(airStreamWidth - _baseWidth) / 2, -_airStreamHeight);
    size = Vector2(airStreamWidth, _airStreamHeight);
    position = airStreamOffset;
  }

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(isSolid: true); // important to set the isSolid parameter

  // widen factor that multiplies the width of the fan
  final double _widenFactor = 2.7; // [Adjustable]

  // push player when in stream
  bool _playerInStream = false;
  final _pushStrength = 150.0; // [Adjustable]

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (_playerInStream) _player.bounceUp(jumpForce: _pushStrength, resetDoubleJump: false);
    super.update(dt);
  }

  void _initialSetup() {
    // debug
    if (game.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
      _hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    priority = PixelAdventure.trapLayerLevel;
    _hitbox.collisionType = CollisionType.passive;
    add(_hitbox);
  }

  void collidedWithPlayer(Vector2 collisionPoint) {
    _playerInStream = true;
    _player.canDoubleJump = true;
  }

  void collidedWithPlayerEnd() => _playerInStream = false;
}
