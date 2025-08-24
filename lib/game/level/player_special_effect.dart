import 'package:flame/components.dart';
import 'package:pixel_adventure/game/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum PlayerSpecialEffectState implements AnimationState {
  appearing('Appearing', 7, loop: false, special: true),
  disappearing('Disappearing', 7, loop: false, special: true);

  @override
  final String name;
  @override
  final int amount;
  @override
  final bool loop;
  final bool special;

  const PlayerSpecialEffectState(this.name, this.amount, {this.loop = true, this.special = false});
}

class PlayerSpecialEffect extends SpriteAnimationGroupComponent with HasGameReference<PixelAdventure>, HasVisibility {
  PlayerSpecialEffect() : super(position: Vector2.zero(), size: gridSize);

  // size
  static final Vector2 gridSize = Vector2.all(96);

  // animation settings
  final double _stepTime = 0.05;
  final Vector2 _textureSize = Vector2(96, 96);
  final String _path = 'Main Characters/';
  final String _pathEnd = ' (96x96).png';

  @override
  Future<void> onLoad() async {
    _loadAllSpriteAnimations();
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<PlayerSpecialEffectState>(game, _path, _pathEnd, _stepTime, _textureSize);
    animations = {for (var state in PlayerSpecialEffectState.values) state: loadAnimation(state)};
    isVisible = false;
  }

  Future<void> playAppearing(Vector2 effectPosition) async {
    position = effectPosition - Vector2.all(32);
    isVisible = true;
    current = PlayerSpecialEffectState.appearing;
    await animationTickers![PlayerSpecialEffectState.appearing]!.completed;
    isVisible = false;
  }

  Future<void> playDisappearing(Vector2 effectPosition, double scaleX) async {
    position = effectPosition - Vector2(scaleX > 0 ? 32 : -32, 32);
    isVisible = true;
    current = PlayerSpecialEffectState.disappearing;
    await animationTickers![PlayerSpecialEffectState.disappearing]!.completed;
    isVisible = false;
  }
}
