import 'dart:math';
import 'dart:ui';
import 'package:flame/game.dart';
import 'package:pixel_quest/app_theme.dart';
import 'package:pixel_quest/game/background/background.dart';

enum LevelBaseBlock {
  gras,
  mud,
  sand;

  static const LevelBaseBlock defaultBaseBlock = mud;
  static LevelBaseBlock fromName(String name) => values.firstWhere((e) => e.name == name, orElse: () => defaultBaseBlock);
}

const grasDarkBlockIds = {95, 96, 97};
const brickBlockIds = {106, 107, 108, 128, 129, 130, 150, 151, 152, 109, 110, 131, 132};
const goldBlockIds = {194, 195, 196, 197, 216, 217, 218, 219, 239, 240, 241};
const orangeBlockIds = {189, 190, 191, 192, 211, 212, 213, 214, 234, 235, 236};
const platformBlockIds = {18, 19, 20, 40, 41, 42, 62, 63, 64};

/// Returns the mini map color for a tile, based on tile id groups, platform state, and the level's base block theme.
Color getMiniMapColor({required int tileId, required bool isPlatform, required LevelBaseBlock baseBlock}) {
  // platform block
  if (isPlatform) return AppTheme.platformBlock;

  // base block (surface)
  if (grasDarkBlockIds.contains(tileId)) {
    return switch (baseBlock) {
      .gras => AppTheme.grasLightBlock,
      .mud => AppTheme.grasDarkBlock,
      .sand => AppTheme.white,
    };
  }

  // special blocks
  if (brickBlockIds.contains(tileId)) return AppTheme.brickBlock;
  if (goldBlockIds.contains(tileId)) return AppTheme.goldBlock;
  if (orangeBlockIds.contains(tileId)) return AppTheme.orangeBlock;

  // base block (fallback)
  return switch (baseBlock) {
    .gras => AppTheme.dirtLightBlock,
    .mud => AppTheme.dirtDarkBlock,
    .sand => const .fromARGB(255, 201, 242, 168),
  };
}

/// 4x4 checkpoint marker pixel pattern for the mini map (`null` = transparent).
const List<List<Color?>> miniMapCheckpointPattern = [
  [AppTheme.black, AppTheme.white, AppTheme.black, AppTheme.white],
  [AppTheme.white, AppTheme.black, AppTheme.white, AppTheme.black],
  [AppTheme.black, AppTheme.white, AppTheme.black, AppTheme.white],
  [AppTheme.woodBlock, null, null, null],
];

/// Generates tiny randomized background pattern images for each [BackgroundScene], using its configured mini map colors.
Future<Map<BackgroundScene, Image>> createMiniMapBackgroundPatterns(List<BackgroundScene> scenes) async {
  final patternSize = Vector2.all(16);
  final output = <BackgroundScene, Image>{};
  final paint = Paint();
  final random = Random(999);

  for (final scene in scenes) {
    final colors = scene.miniMapBackgroundColors;
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    // create a small pattern
    for (int y = 0; y < patternSize.y; y++) {
      for (int x = 0; x < patternSize.x; x++) {
        paint.color = colors[random.nextInt(colors.length)];
        canvas.drawRect(.fromLTWH(x.toDouble(), y.toDouble(), 1, 1), paint);
      }
    }
    // convert pattern to image
    final picture = recorder.endRecording();
    output[scene] = await picture.toImage(patternSize.x.toInt(), patternSize.y.toInt());
  }
  return output;
}
