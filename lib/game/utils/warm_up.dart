import 'dart:async';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:pixel_quest/game/utils/misc_utils.dart';
import 'package:pixel_quest/game/game_settings.dart';
import 'package:pixel_quest/game/game.dart';
import 'package:vector_math/vector_math_64.dart' as math64;

class WarmUpRunner extends Component with HasGameReference<PixelQuest> {
  bool _ran = false;

  @override
  void onMount() {
    super.onMount();
    if (_ran) return;
    _ran = true;
    unawaited(_run());
  }

  Future<void> _run() async {
    // ensure we are mounted & at least one frame passed
    await yieldFrame();

    // forces an early GPU sync by creating a tiny image from a recorded picture
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(const .fromLTWH(0, 0, 1, 1), Paint());
    final img = await recorder.endRecording().toImage(1, 1);
    img.dispose();

    // primes the ImageShader pipeline by rendering a small rect once
    final shaderMatrix = math64.Matrix4.identity(); // scale ist egal fürs warmup
    final paint = Paint()
      ..color = const Color(0x00000000)
      ..shader = ImageShader(game.miniMapPatternFor(.defaultScene), .repeated, .repeated, shaderMatrix.storage);
    final shaderWarm = _WarmUpDraw(paint);
    await game.camera.viewport.add(shaderWarm);
    await yieldFrame();
    await yieldFrame();
    shaderWarm.removeFromParent();
    await yieldFrame();

    // warms up flame_tiled parsing and atlas/material setup by loading one TMX once
    final map =
        await TiledComponent.load('${game.staticCenter.allLevelsInWorldByIndex(0).first.tmxFileName}.tmx', .all(GameSettings.tileSize))
          ..priority = -99999;

    // ensures the loaded map gets at least one render pass so caches/shaders are actually touched
    await game.world.add(map);
    await yieldFrame();
    await yieldFrame();
    map.removeFromParent();

    // warms up the loading overlay render path without showing animations or blocking input
    await game.loadingOverlay.warmUp(game.staticCenter.allLevelsInWorldByIndex(0).first);

    removeFromParent();
  }
}

class _WarmUpDraw extends PositionComponent {
  final Paint paint;
  _WarmUpDraw(this.paint) : super(size: Vector2.all(32), position: Vector2.zero());

  @override
  void render(Canvas canvas) {
    canvas.drawRect(const Rect.fromLTWH(0, 0, 32, 32), paint);
  }
}
