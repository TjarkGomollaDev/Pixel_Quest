import 'dart:async';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/components/level/player.dart';
import 'package:pixel_adventure/components/traps/fan_air_stream.dart';
import 'package:pixel_adventure/components/utils.dart';
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

class Fan extends SpriteAnimationGroupComponent with HasGameReference<PixelAdventure> {
  Fan({required super.position, required Player player}) : _player = player, super(size: fixedSize) {
    position += fixedOffset;
  }

  // size
  static final Vector2 fixedSize = Vector2(28, 8);
  static final Vector2 fixedOffset = Vector2(2, 8);

  // player ref
  final Player _player;

  // animation settings
  final double _stepTime = 0.05;
  final Vector2 _textureSize = Vector2(24, 8);
  final String _path = 'Traps/Fan/';
  final String _pathEnd = '.png';

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

    // list of all animations
    animations = {for (var state in FanState.values) state: loadAnimation(state)};

    // set current animation state
    current = FanState.on;
  }

  void _loadFanAirStream() {
    _airStream = FanAirStream(baseWidth: width, airStreamHeight: 200, player: _player, position: Vector2(0, 0));
    add(_airStream);
  }
}
