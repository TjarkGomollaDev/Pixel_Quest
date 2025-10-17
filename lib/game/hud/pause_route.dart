import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/rendering.dart';
import 'package:flame/text.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/level/level.dart';
import 'package:pixel_adventure/game/utils/corner_outline.dart';
import 'package:pixel_adventure/game/utils/rrect.dart';
import 'package:pixel_adventure/pixel_quest.dart';

class PauseRoute extends Route with HasGameReference<PixelQuest> {
  PauseRoute() : super(PausePage.new, transparent: true);

  @override
  void onPush(Route? previousRoute) {
    if (previousRoute is WorldRoute && previousRoute.world is DecoratedWorld) {
      (previousRoute.world as DecoratedWorld).decorator = PaintDecorator.tint(AppTheme.screenBlur)..addBlur(6.0);
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

class PausePage extends Component with HasGameReference<PixelQuest> {
  @override
  bool containsLocalPoint(Vector2 point) => false;

  @override
  Future<void> onLoad() async {
    final container = PositionComponent(position: game.canvasSize / 2, anchor: Anchor.center);
    final pausedTextPosition = Vector2(0, -60);

    // text background
    final pausedBg = RoundedComponent(
      color: AppTheme.tileBlur,
      borderRadius: 4,
      position: pausedTextPosition,
      size: Vector2(210, 60),
      anchor: Anchor.center,
    );

    // paused text
    final pausedText = TextComponent(
      text: 'PAUSED',
      position: pausedTextPosition,
      anchor: Anchor(0.48, 0.32),
      textRenderer: TextPaint(
        style: const TextStyle(fontFamily: 'Pixel Font', fontSize: 28, color: AppTheme.ingameText, height: 1),
      ),
    );

    // outline
    final pausedOutline = CornerOutline(
      size: pausedBg.size + Vector2.all(16),
      cornerLength: 16,
      strokeWidth: 6,
      color: AppTheme.ingameText,
      anchor: Anchor.center,
      position: pausedText.position,
    );

    // settings
    final settingsText = TextComponent(
      text: 'Settings',
      anchor: Anchor(0.48, 0.32),
      position: Vector2(0, 20),
      textRenderer: TextPaint(
        style: const TextStyle(fontFamily: 'Pixel Font', fontSize: 18, color: AppTheme.ingameText, height: 1),
      ),
    );

    // achievements
    final achievementsText = TextComponent(
      text: 'Achievements',
      anchor: Anchor(0.48, 0.32),
      position: Vector2(0, 60),
      textRenderer: TextPaint(
        style: const TextStyle(fontFamily: 'Pixel Font', fontSize: 18, color: AppTheme.ingameText, height: 1),
      ),
    );

    // exit
    final exitText = TextComponent(
      text: 'Exit',
      anchor: Anchor(0.48, 0.32),
      position: Vector2(0, 100),
      textRenderer: TextPaint(
        style: const TextStyle(fontFamily: 'Pixel Font', fontSize: 18, color: AppTheme.ingameText, height: 1),
      ),
    );

    container.addAll([pausedBg, pausedText, pausedOutline, settingsText, achievementsText, exitText]);

    add(container);
  }
}
