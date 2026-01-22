import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/collision/collision.dart';
import 'package:pixel_adventure/game/collision/entity_collision.dart';
import 'package:pixel_adventure/game/events/game_event_bus.dart';
import 'package:pixel_adventure/game/traps/air_particle.dart';
import 'package:pixel_adventure/game/level/player/player.dart';
import 'package:pixel_adventure/game/traps/fan.dart';
import 'package:pixel_adventure/game/utils/camera_culling.dart';
import 'package:pixel_adventure/game/game_settings.dart';
import 'package:pixel_adventure/game/game.dart';

/// Invisible component representing the fan's air stream.
///
/// The air stream extends vertically above the fan and pushes the
/// player upward with a configurable force. The width of the stream
/// can be adjusted using a widen factor. The stream also allows the
/// player to regain their double jump while inside.
///
/// Collision handling is used to detect when the player enters or
/// leaves the stream, setting [_playerInStream] accordingly.
class FanAirStream extends PositionComponent with EntityCollision, EntityCollisionEnd, HasGameReference<PixelQuest> {
  // constructor parameters
  final double _baseWidth;
  final double _airStreamHeight;
  final bool _alwaysOn;
  final Fan _fan;
  final Player _player;

  FanAirStream({
    required double baseWidth,
    required double airStreamHeight,
    required bool alwaysOn,
    required Fan fan,
    required Player player,
    required super.position,
  }) : _baseWidth = baseWidth,
       _airStreamHeight = airStreamHeight,
       _alwaysOn = alwaysOn,
       _fan = fan,
       _player = player {
    final airStreamWidth = _baseWidth * _widenFactor;
    final airStreamOffset = Vector2(-(airStreamWidth - _baseWidth) / 2, -_airStreamHeight);
    size = Vector2(airStreamWidth, _airStreamHeight);
    position += airStreamOffset;
  }

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(isSolid: true); // important to set the isSolid parameter

  // widen factor that multiplies the width of the fan
  final double _widenFactor = 2.2; // [Adjustable]

  // push player when in stream
  bool _playerInStream = false;
  final _pushStrength = 150.0; // [Adjustable]

  // particle
  late Timer _particleTimer;
  final double _delayParticleSpawn = 0.04;
  late final Vector2 _particleBasePosition;

  // fan state
  late Timer? _fanTimer;
  final double _durationFanOff = 4; // [Adjustable]
  final double _durationFanOn = 5; // [Adjustable]
  bool _isFanOn = true;

  // subscription for game events
  GameSubscription? _sub;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _addSubscription();
    _setUpParticle();
    _startParticleTimer();
    if (!_alwaysOn) _startSwitchMode();
    return super.onLoad();
  }

  @override
  void onRemove() {
    _removeSubscription();
    super.onRemove();
  }

  @override
  void update(double dt) {
    if (_playerInStream && _isFanOn) _player.bounceUp(jumpForce: _pushStrength, resetDoubleJump: false);
    _particleTimer.update(dt);
    if (!_alwaysOn) _fanTimer!.update(dt);
    super.update(dt);
  }

  @override
  void onEntityCollision(CollisionSide collisionSide) {
    _playerInStream = true;
    _player.activateDoubleJump();
  }

  @override
  void onEntityCollisionEnd() => _playerInStream = false;

  @override
  EntityCollisionType get collisionType => EntityCollisionType.any;

  @override
  ShapeHitbox get entityHitbox => _hitbox;

  void _initialSetup() {
    // debug
    if (GameSettings.customDebugMode) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
      _hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    priority = GameSettings.trapLayerLevel;
    _hitbox.collisionType = CollisionType.passive;
    add(_hitbox);
  }

  void _addSubscription() {
    _sub = game.eventBus.listen<PlayerRespawned>((_) => onEntityCollisionEnd());
  }

  void _removeSubscription() {
    _sub?.cancel();
    _sub = null;
  }

  void _setUpParticle() {
    _particleBasePosition = Vector2((size.x - _baseWidth) / 2, size.y);
  }

  void _startParticleTimer() {
    _particleTimer = Timer(_delayParticleSpawn, onTick: _spawnParticle, repeat: true);
  }

  void _spawnParticle() {
    // camera culling
    if (!game.isEntityInVisibleWorldRectX(_hitbox)) return;

    // create new particle
    final particle = AirParticle(
      streamTop: 0,
      streamLeft: 0,
      streamRight: size.x,
      basePosition: _particleBasePosition,
      baseWidth: _baseWidth,
    );
    add(particle);
  }

  void _startSwitchMode() {
    _fanTimer = Timer(_durationFanOff, onTick: _switchOff);
  }

  void _switchOn() {
    _particleTimer.start();
    _isFanOn = true;
    _fan.activateFan();
    _fanTimer!
      ..limit = _durationFanOff
      ..onTick = _switchOff
      ..start();
  }

  void _switchOff() {
    _particleTimer.pause();
    _isFanOn = false;
    _fan.deactivateFan();
    _fanTimer!
      ..limit = _durationFanOn
      ..onTick = _switchOn
      ..start();
  }
}
