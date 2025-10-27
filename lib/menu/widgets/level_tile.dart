import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/foundation.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/animations/star.dart';
import 'package:pixel_adventure/data/static/metadata/level_metadata.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game/utils/visible_components.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/menu/widgets/level_btn.dart';
import 'package:pixel_adventure/pixel_quest.dart';

class LevelTile extends PositionComponent with HasGameReference<PixelQuest>, HasPaint implements OpacityProvider {
  final LevelMetadata _levelMetadata;

  LevelTile({required LevelMetadata levelMetadata, required super.position}) : _levelMetadata = levelMetadata, super(size: tileSize) {
    _center = size / 2;
  }

  // center of the module
  late final Vector2 _center;

  // size
  static final Vector2 tileSize = Vector2(54, 38); // [Adjustable]

  // background
  late final VisibleSpriteComponent _tileBg;

  // btn
  late final LevelBtn _levelBtn;

  // stars
  static final Vector2 _starSize = Vector2.all(12); // [Adjustable]
  late final List<Vector2> _starPositions;
  final List<double> _starAngles = [-0.1, 0, 0.1];
  final List<OutlineStar> _outlineStars = [];
  final List<Star> _stars = [];

  // spacing
  static const double _starSpacingHorizontal = 2; // [Adjustable]
  static const double _starsMarginTop = 5; // [Adjustable]
  static const double _btnMarginBottom = -1; // [Adjustable]

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _setUpTileBg();
    _setUpBtn();
    _setUpStars();
    return super.onLoad();
  }

  @override
  set opacity(double value) {
    if (value == 0.1) debugPrint(value.toString());
    _levelBtn.opacity = value;
    _tileBg.opacity = value;
    for (var star in _stars) {
      star.opacity = value;
    }
    for (var outlineStar in _outlineStars) {
      outlineStar.opacity = value;
    }
    super.opacity = value;
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
    final sprite = loadSprite(game, 'Menu/Worlds/Level_Tile.png');
    _tileBg = VisibleSpriteComponent(sprite: sprite, anchor: Anchor.center, position: _center);
    add(_tileBg);
  }

  void _setUpBtn() {
    _levelBtn = LevelBtn(levelMetadata: _levelMetadata, position: Vector2(_center.x, size.y - LevelBtn.btnSize.y / 2 - _btnMarginBottom));
    add(_levelBtn);
  }

  void _setUpStars() {
    final yPos = _starSize.y / 2 + _starsMarginTop;
    _starPositions = [
      Vector2(_center.x - _starSize.x - _starSpacingHorizontal, yPos + 2),
      Vector2(_center.x, yPos),
      Vector2(_center.x + _starSize.x + _starSpacingHorizontal, yPos + 2),
    ];
    final data = game.storageCenter.getLevel(_levelMetadata.uuid);
    for (var i = 0; i < data.stars; i++) {
      final star = Star(position: _starPositions[i], size: _starSize)..angle = _starAngles[i];
      _stars.add(star);
    }
    for (var i = data.stars; i < data.stars + 3 - data.stars; i++) {
      final outlineStar = OutlineStar(position: _starPositions[i], size: _starSize)..angle = _starAngles[i];
      _outlineStars.add(outlineStar);
    }
    addAll(_stars);
    addAll(_outlineStars);
  }

  void _removeOutlineStars(int stars) {
    for (var i = 0; i < stars; i++) {
      remove(_outlineStars.first);
      _outlineStars.removeAt(0);
    }
  }

  Future<void> addNewStars(int stars) async {
    for (var i = 0; i < stars; i++) {
      final star = Star(position: _starPositions[_stars.length], size: _starSize, spawnSizeZero: true)..angle = _starAngles[_stars.length];
      add(star);
      _stars.add(star);
      await star.popIn();
      if (i != stars - 1) await Future.delayed(Duration(milliseconds: 100));
    }
    _removeOutlineStars(stars);
  }
}
