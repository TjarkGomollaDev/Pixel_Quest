import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class JumpBtn extends SpriteComponent with HasGameReference<PixelAdventure>, TapCallbacks {
  final Player player;

  JumpBtn(this.player);

  @override
  FutureOr<void> onLoad() {
    sprite = Sprite(game.images.fromCache('HUD/JumpButton.png'));
    position = Vector2(
      game.size.x - GameSettings.hudMobileControlsSize - GameSettings.hudMargin,
      game.size.y - GameSettings.hudMobileControlsSize - GameSettings.hudMargin,
    );
    priority = 10;
    return super.onLoad();
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (player.isOnGround) {
      player.hasJumped = true;
    } else if (!player.hasDoubleJumped && player.canDoubleJump) {
      player.hasDoubleJumped = true;
      player.canDoubleJump = false;
    }
    super.onTapDown(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    player.hasJumped = false;
    super.onTapUp(event);
  }
}
