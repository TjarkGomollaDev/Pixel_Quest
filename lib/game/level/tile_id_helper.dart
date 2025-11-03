import 'dart:ui';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/data/static/metadata/world_metadata.dart';

const grasDarkBlockIds = {95, 96, 97};
const brickBlockIds = {106, 107, 108, 128, 129, 130, 150, 151, 152, 109, 110, 131, 132};
const goldBlockIds = {194, 195, 196, 197, 216, 217, 218, 219, 239, 240, 241};
const orangeBlockIds = {189, 190, 191, 192, 211, 212, 213, 214, 234, 235, 236};
const platformBlockIds = {18, 19, 20, 40, 41, 42, 62, 63, 64};

Color getMiniMapColor({required int tileId, required bool isPlatform, required LevelBaseBlock baseBlock}) {
  if (isPlatform) return AppTheme.platformBlock;

  if (grasDarkBlockIds.contains(tileId)) {
    return switch (baseBlock) {
      LevelBaseBlock.gras => AppTheme.grasLightBlock,
      LevelBaseBlock.mud => AppTheme.grasDarkBlock,
      LevelBaseBlock.sand => AppTheme.white,
    };
  }

  if (brickBlockIds.contains(tileId)) return AppTheme.brickBlock;
  if (goldBlockIds.contains(tileId)) return AppTheme.goldBlock;
  if (orangeBlockIds.contains(tileId)) return AppTheme.orangeBlock;

  return switch (baseBlock) {
    LevelBaseBlock.gras => AppTheme.dirtLightBlock,
    LevelBaseBlock.mud => AppTheme.dirtDarkBlock,
    LevelBaseBlock.sand => AppTheme.black,
  };
}
