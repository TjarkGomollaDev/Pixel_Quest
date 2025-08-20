import 'dart:async';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game_components/level/player.dart';
import 'package:pixel_adventure/game_components/traps/fan_air_stream.dart';
import 'package:pixel_adventure/game_components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum FanState implements AnimationState {
  off('Off', 1),
  on('On', 4);

  @override
  final String name;
  @override
  final int amount;
  @override
  final bool loop = true;

  const FanState(this.name, this.amount);
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
class Fan extends SpriteAnimationGroupComponent with HasGameReference<PixelAdventure> {
  // constructor parameters
  final Player _player;

  Fan({required Player player, required Vector2 position}) : _player = player, super(size: _fixedSize, position: position + _fixedOffset);

  // size
  static final Vector2 _fixedSize = Vector2(28, 8);
  static final Vector2 _fixedOffset = Vector2(2, 8);

  // animation settings
  static const double _stepTime = 0.05;
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
    if (game.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
    }

    // general
    priority = PixelAdventure.trapLayerLevel;
  }

  void _loadAllAnimation() {
    final loadAnimation = spriteAnimationWrapper<FanState>(game, _path, _pathEnd, _stepTime, _textureSize);
    animations = {for (var state in FanState.values) state: loadAnimation(state)};

    // set current animation state
    current = FanState.on;
  }

  void _loadFanAirStream() {
    _airStream = FanAirStream(baseWidth: width, airStreamHeight: position.y, player: _player, position: Vector2(0, 0));
    add(_airStream);
  }
}
