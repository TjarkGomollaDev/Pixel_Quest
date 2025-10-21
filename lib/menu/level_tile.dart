import 'dart:async';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/animations/star.dart';
import 'package:pixel_adventure/data/level_data.dart';
import 'package:pixel_adventure/game/utils/rrect.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/menu/level_btn.dart';
import 'package:pixel_adventure/pixel_quest.dart';

class LevelTile extends PositionComponent with HasGameReference<PixelQuest> {
  final LevelMetadata _levelMetadata;

  LevelTile({required LevelMetadata levelMetadata, required super.position}) : _levelMetadata = levelMetadata, super(size: tileSize) {
    _center = size / 2;
  }

  // center of the module
  late final Vector2 _center;

  // size
  static final Vector2 tileSize = Vector2(62, 42);

  // background
  late final RoundedComponent _tileBg;

  // btns
  late final LevelBtn _levelBtn;

  // stars
  final List<OutlineStar> _outlineStars = [];
  final List<Star> _stars = [];
  static const double _starSpacing = 14;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _setUpTileBg();
    _setUpBtn();
    _setUpStars();

    return super.onLoad();
  }

  void _initialSetup() {
    // debug
    if (GameSettings.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorMenu;
    }

    // general
    anchor = Anchor.center;
  }

  void _setUpTileBg() {
    _tileBg = RoundedComponent(color: AppTheme.levelTileBlur, borderRadius: 3, position: _center, size: size, anchor: Anchor.center);
    add(_tileBg);
  }

  void _setUpBtn() {
    _levelBtn = LevelBtn(levelMetadata: _levelMetadata, position: Vector2(_center.x, 29));
    add(_levelBtn);
  }

  void _setUpStars() {
    final data = game.storageCenter.getLevel(_levelMetadata.uuid);
    final positions = [Vector2(_center.x - _starSpacing, 13), Vector2(_center.x, 11), Vector2(_center.x + _starSpacing, 13)];
    final angles = [-0.1, 0.0, 0.1];
    final starSize = Vector2.all(12);
    for (var i = 0; i < data.stars; i++) {
      final star = Star(position: positions[i], size: starSize);
      star.angle = angles[i];
      _stars.add(star);
    }
    for (var i = data.stars; i < data.stars + 3 - data.stars; i++) {
      final outlineStar = OutlineStar(position: positions[i], size: starSize);
      outlineStar.angle = angles[i];
      _outlineStars.add(outlineStar);
    }
    addAll(_stars);
    addAll(_outlineStars);
  }

  void _removeStars() {
    for (var star in _stars) {
      remove(star);
    }
    _stars.clear();
    for (var outlineStar in _outlineStars) {
      remove(outlineStar);
    }
    _outlineStars.clear();
  }

  void updateStars() {
    _removeStars();
    _setUpStars();
  }
}
