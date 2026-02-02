import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:pixel_quest/game/animations/star.dart';
import 'package:pixel_quest/data/static/metadata/level_metadata.dart';
import 'package:pixel_quest/game/utils/button.dart';
import 'package:pixel_quest/game/utils/load_sprites.dart';
import 'package:pixel_quest/game/utils/misc_utils.dart';
import 'package:pixel_quest/game/utils/visible_components.dart';
import 'package:pixel_quest/game/game.dart';

class LevelTile extends PositionComponent with HasGameReference<PixelQuest>, HasPaint implements OpacityProvider {
  // constructor parameters
  final LevelMetadata _levelMetadata;

  LevelTile({required LevelMetadata levelMetadata, required super.position}) : _levelMetadata = levelMetadata, super(size: tileSize) {
    anchor = Anchor.center;
  }

  // size
  static final Vector2 tileSize = Vector2(54, 38); // [Adjustable]

  // animation settings
  static const String _pathTile = 'Menu/Worlds/Level_Tile.png';

  // background
  late final VisibleSpriteComponent _tileBg;

  // level btn
  late final SpriteBtn _levelBtn;

  // stars
  static final Vector2 _starSize = Vector2.all(20); // [Adjustable]
  late final List<Vector2> _starPositions;
  final List<double> _starAngles = [-0.1, 0, 0.1]; // [Adjustable]
  final List<Star> _outlineStars = [];
  final List<Star> _stars = [];
  int _newStarsToken = 0;

  // spacing
  static const double _starSpacingHorizontal = -6; // [Adjustable]
  static const double _starsMarginTop = 2; // [Adjustable]
  static const double _btnMarginBottom = -1; // [Adjustable]

  @override
  FutureOr<void> onLoad() {
    _setUpTileBg();
    _setUpBtn();
    _setUpStars();
    return super.onLoad();
  }

  @override
  set opacity(double value) {
    _levelBtn.opacity = value;
    _tileBg.opacity = value;
    for (final star in _stars) {
      star.opacity = value;
    }
    for (final outlineStar in _outlineStars) {
      outlineStar.opacity = value;
    }
    super.opacity = value;
  }

  void _setUpTileBg() {
    final sprite = loadSprite(game, _pathTile);
    _tileBg = VisibleSpriteComponent(sprite: sprite, anchor: Anchor.center, position: size / 2);
    add(_tileBg);
  }

  void _setUpBtn() {
    _levelBtn = SpriteBtn(
      path: 'Menu/Levels/${_levelMetadata.btnFileName}.png',
      onPressed: () async {
        game.audioCenter.stopBackgroundMusic();
        unawaited(game.loadingOverlay.show(_levelMetadata));
        await yieldFrame();
        game.router.pushReplacementNamed(_levelMetadata.uuid);
      },
      position: Vector2(_tileBg.x, size.y - 17 / 2 - _btnMarginBottom),
    );
    add(_levelBtn);
  }

  void _setUpStars() {
    final yPos = _starSize.y / 2 + _starsMarginTop;
    _starPositions = [
      Vector2(_tileBg.x - _starSize.x - _starSpacingHorizontal, yPos + 2),
      Vector2(_tileBg.x, yPos),
      Vector2(_tileBg.x + _starSize.x + _starSpacingHorizontal, yPos + 2),
    ];
    _rebuildStars(game.storageCenter.levelById(_levelMetadata.uuid).stars);
  }

  void _rebuildStars(int stars) {
    for (int i = 0; i < stars; i++) {
      final star = Star(variant: StarVariant.filled, position: _starPositions[i], size: _starSize)..angle = _starAngles[i];
      _stars.add(star);
    }
    for (int i = stars; i < stars + 3 - stars; i++) {
      final outlineStar = Star(variant: StarVariant.outline, position: _starPositions[i], size: _starSize)..angle = _starAngles[i];
      _outlineStars.add(outlineStar);
    }
    addAll([..._stars, ..._outlineStars]);
  }

  void _removeStars() {
    for (final star in _stars) {
      star.removeFromParent();
    }
    for (final outlineStar in _outlineStars) {
      outlineStar.removeFromParent();
    }
    _stars.clear();
    _outlineStars.clear();
  }

  void setStars(int stars) {
    // remove existing stars and outline stars
    _removeStars();

    // rebuild with correct amount for clean refresh
    _rebuildStars(stars);
  }

  Future<void> newStarsAnimation(int newStars) async {
    final token = ++_newStarsToken;
    for (int i = 0; i < newStars; i++) {
      if (token != _newStarsToken || !isMounted) return;

      // safety: do not exceed 3 stars
      if (_stars.length >= 3) return;

      // add new star with animation
      final star = Star(variant: StarVariant.filled, position: _starPositions[_stars.length], size: _starSize, spawnSizeZero: true)
        ..angle = _starAngles[_stars.length];
      add(star);
      _stars.add(star);
      await star.popIn();

      // visual delay
      if (token != _newStarsToken || !isMounted) return;
      if (i != newStars - 1) await Future.delayed(Duration(milliseconds: 100));
    }

    // covered outline stars can now be removed
    if (token != _newStarsToken || !isMounted) return;
    _consumeOutlineStars(newStars);
  }

  void _consumeOutlineStars(int count) {
    for (int i = 0; i < count.clamp(0, _outlineStars.length); i++) {
      remove(_outlineStars.first);
      _outlineStars.removeAt(0);
    }
  }

  void cancelNewStarsAnimation() {
    _newStarsToken++;
    for (final star in _stars) {
      star.cancelAnimations();
    }
  }
}
