import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/level/player/player.dart';
import 'package:pixel_adventure/game/traps/fan_air_stream.dart';
import 'package:pixel_adventure/game/utils/animation_state.dart';
import 'package:pixel_adventure/game/utils/grid.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game/game_settings.dart';
import 'package:pixel_adventure/game/game.dart';

enum FanState implements AnimationState {
  off('Off', 1),
  on('On', 4);

  @override
  final String fileName;
  @override
  final int amount;
  @override
  final bool loop = true;

  const FanState(this.fileName, this.amount);
}

/// A fan trap that continuously blows air upwards.
///
/// The fan has a visual representation ([Fan]) and an invisible
/// air stream component ([FanAirStream]) that applies upward force
/// to the player when they are inside it. The air stream also
/// resets the player's ability to double jump while they are being
/// pushed upward.
///
/// The fan animation plays continuously while the trap is active.
/// Damage is not applied; this trap only manipulates player movement.
class Fan extends PositionComponent with FixedGridOriginalSizeGroupAnimation, HasGameReference<PixelQuest> {
  // constructor parameters
  final bool _alwaysOn;
  final Player _player;

  Fan({required bool alwaysOn, required Player player, required super.position})
    : _alwaysOn = alwaysOn,
      _player = player,
      super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2(32, 16);

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(5, 8), size: Vector2(23, 8));

  // animation settings
  static final Vector2 _textureSize = Vector2(24, 8);
  static const String _path = 'Traps/Fan/';
  static const String _pathEnd = '.png';

  // air stream
  late final FanAirStream _airStream;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllAnimation();
    _loadFanAirStream();
    return super.onLoad();
  }

  void _initialSetup() {
    // debug
    if (GameSettings.customDebugMode) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
      _hitbox.debugColor = AppTheme.debugColorTrapHitbox;
    }

    // general
    priority = GameSettings.trapLayerLevel;
    add(_hitbox);
  }

  void _loadAllAnimation() {
    final loadAnimation = spriteAnimationWrapper<FanState>(game, _path, _pathEnd, GameSettings.stepTime, _textureSize);
    final animations = {for (var state in FanState.values) state: loadAnimation(state)};
    addAnimationGroupComponent(textureSize: _textureSize, animations: animations, current: FanState.on);
  }

  void _loadFanAirStream() {
    _airStream = FanAirStream(
      baseWidth: width,
      airStreamHeight: position.y + _hitbox.position.y - GameSettings.mapBorderWidth * 2,
      alwaysOn: _alwaysOn,
      fan: this,
      player: _player,
      position: Vector2(0, _hitbox.position.y),
    );
    add(_airStream);
  }

  void activateFan() {
    animationGroupComponent.current = FanState.on;
  }

  void deactivateFan() {
    animationGroupComponent.current = FanState.off;
  }
}
