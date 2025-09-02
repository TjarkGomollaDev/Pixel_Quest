import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/rendering.dart';
import 'package:flame/text.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/level/level.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class PauseRoute extends Route with HasGameReference<PixelAdventure> {
  PauseRoute() : super(PausePage.new, transparent: true);

  @override
  void onPush(Route? previousRoute) {
    if (previousRoute is WorldRoute && previousRoute.world is DecoratedWorld) {
      (previousRoute.world as DecoratedWorld).decorator = PaintDecorator.tint(AppTheme.black.withAlpha(50))..addBlur(5.0);
      (previousRoute.world as DecoratedWorld).timeScale = 0;
    }
  }

  @override
  void onPop(Route nextRoute) {
    if (nextRoute is WorldRoute && nextRoute.world is DecoratedWorld) {
      (nextRoute.world as DecoratedWorld).decorator = null;
      (nextRoute.world as DecoratedWorld).timeScale = 1;
    }
  }
}

class PausePage extends Component with HasGameReference<PixelAdventure> {
  @override
  bool containsLocalPoint(Vector2 point) => false;

  @override
  Future<void> onLoad() async {
    final game = findGame()!;
    addAll([
      TextComponent(
        text: 'PAUSED',
        position: game.canvasSize / 2,
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(fontSize: 36, color: AppTheme.ingameText, fontWeight: FontWeight.w600),
        ),
      )..priority = 30,
    ]);
  }
}
