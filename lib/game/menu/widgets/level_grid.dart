import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/widgets.dart';
import 'package:pixel_adventure/game/game_settings.dart';
import 'package:pixel_adventure/game/menu/widgets/level_tile.dart';
import 'package:pixel_adventure/game/game.dart';
import 'package:pixel_adventure/game/utils/visible_components.dart';

class LevelGrid extends PositionComponent with HasGameReference<PixelQuest>, VisibleComponent {
  // constructor parameters
  final String _worldUuid;
  final bool _show;

  LevelGrid({required String worldUuid, bool show = true}) : _worldUuid = worldUuid, _show = show {
    size = _tileSize * 4 + _tileSpacing * 3;
    position = Vector2((game.size.x - size.x) / 2, GameSettings.tileSize * 4);
  }

  // grid
  static final _tileSize = Vector2(GameSettings.tileSize * 3, GameSettings.tileSize * 2);
  static final Vector2 _tileSpacing = Vector2(GameSettings.tileSize * 2, GameSettings.tileSize);
  final Map<String, LevelTile> _grid = {};

  // show animation settings
  final double _moveTileDistanceAnimation = LevelTile.tileSize.x / 2; // [Adjustable]

  @override
  FutureOr<void> onLoad() {
    _setUpGrid();
    return super.onLoad();
  }

  @override
  void show() {
    isVisible = true;
    priority = 1;
  }

  @override
  void hide() {
    isVisible = false;
    priority = -1;
    for (var tile in _grid.values) {
      tile.opacity = 0;
    }
  }

  void _setUpGrid() {
    final levels = game.staticCenter.allLevelsInOneWorld(_worldUuid);
    int index = 0;
    for (int i = 0; i < 4 && index < levels.length; i++) {
      for (int j = 0; j < 4 && index < levels.length; j++) {
        // calculate position
        final position = _tileSize / 2 + Vector2((_tileSize.x + _tileSpacing.x) * j, (_tileSize.y + _tileSpacing.y) * i);

        // create single tile
        final levelMetadata = levels[index++];
        final levelTile = LevelTile(levelMetadata: levelMetadata, position: position);
        add(levelTile);
        _grid[levelMetadata.uuid] = levelTile;
      }
    }

    // unlike other places in the code, we only set this here because we may need to access the tiles
    initVisibility(_show);
  }

  Future<void> animatedShow({required bool toLeft, double duration = 0.4}) async {
    final completer = Completer<void>();
    show();
    final x = _grid.values.last;
    final moveOffset = Vector2(toLeft ? _moveTileDistanceAnimation : -_moveTileDistanceAnimation, 0);
    for (var tile in _grid.values) {
      final endPosition = tile.position.clone();
      tile.position += moveOffset;

      // add visual effect
      tile.add(
        CombinedEffect([
          MoveEffect.to(endPosition, EffectController(duration: duration, curve: Curves.linear)),
          OpacityEffect.to(
            1,
            EffectController(duration: duration, curve: Curves.easeIn),
            onComplete: () {
              if (x == tile) {
                completer.complete();
              }
            },
          ),
        ]),
      );
    }

    return completer.future;
  }

  void setStarsInTile({required String levelUuid, required int stars}) {
    _grid[levelUuid]?.setStars(stars);
  }

  Future<void> newStarsInTileAnimation({required String levelUuid, required int newStars}) async {
    await _grid[levelUuid]?.newStarsAnimation(newStars);
  }

  void cancelNewStarsInTileAnimation({required String levelUuid}) {
    _grid[levelUuid]?.cancelNewStarsAnimation();
  }
}
