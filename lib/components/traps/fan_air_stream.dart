import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/components/level/player.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class FanAirStream extends PositionComponent with HasGameReference<PixelAdventure>, CollisionCallbacks {
  final double baseWidth;
  final double airStreamHeight;

  FanAirStream(this.baseWidth, this.airStreamHeight, {required Player player, super.position}) : _player = player {
    final airStreamWidth = baseWidth * _widenFactor;
    final airStreamOffset = Vector2(-(airStreamWidth - baseWidth) / 2, -airStreamHeight);
    size = Vector2(airStreamWidth, airStreamHeight);
    position = airStreamOffset;
  }

  // actual hitbox
  final RectangleHitbox hitbox = RectangleHitbox(isSolid: true); // important to set the isSolid parameter

  // player ref
  final Player _player;

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
      hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    priority = PixelAdventure.trapLayerLevel;
    hitbox.collisionType = CollisionType.passive;
    add(hitbox);
  }

  void collidedWithPlayer(Vector2 collisionPoint) {
    _playerInStream = true;
    _player.canDoubleJump = true;
  }

  void collidedWithPlayerEnd() => _playerInStream = false;
}
