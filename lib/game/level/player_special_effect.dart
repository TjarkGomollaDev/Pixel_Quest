import 'package:flame/components.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/utils/animation_state.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
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

  // offset
  static final Vector2 _offset = (gridSize - Player.gridSize) / 2;

  // animation settings
  static final Vector2 _textureSize = Vector2(96, 96);
  static const String _path = 'Main Characters/';
  static const String _pathEnd = ' (96x96).png';

  @override
  Future<void> onLoad() async {
    _loadAllSpriteAnimations();
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<PlayerSpecialEffectState>(game, _path, _pathEnd, PixelAdventure.stepTime, _textureSize);
    animations = {for (var state in PlayerSpecialEffectState.values) state: loadAnimation(state)};
    isVisible = false;
  }

  Future<void> playAppearing(Vector2 effectPosition) async {
    position = effectPosition - _offset;
    isVisible = true;
    current = PlayerSpecialEffectState.appearing;
    await animationTickers![PlayerSpecialEffectState.appearing]!.completed;
    isVisible = false;
  }

  Future<void> playDisappearing(Vector2 effectPosition) async {
    position = effectPosition - _offset;
    isVisible = true;
    current = PlayerSpecialEffectState.disappearing;
    await animationTickers![PlayerSpecialEffectState.disappearing]!.completed;
    isVisible = false;
  }
}
