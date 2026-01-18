import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/widgets.dart';
import 'package:pixel_adventure/game/game_settings.dart';
import 'package:pixel_adventure/game/menu/widgets/level_tile.dart';
import 'package:pixel_adventure/game/game.dart';

class LevelGrid extends PositionComponent with HasGameReference<PixelQuest>, HasVisibility {
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
  final double move = LevelTile.tileSize.x / 2; // [Adjustable]

  @override
  FutureOr<void> onLoad() {
    _setUpGrid();
    return super.onLoad();
  }

  void _setUpGrid() {
    final tilePositions = [];
    for (var i = 0; i < 4; i++) {
      for (var j = 0; j < 4; j++) {
        final position = _tileSize / 2 + Vector2((_tileSize.x + _tileSpacing.x) * j, (_tileSize.y + _tileSpacing.y) * i);
        tilePositions.add(position);
      }
    }

    int index = 0;
    for (var position in tilePositions) {
      if (index >= game.staticCenter.allLevelsInOneWorld(_worldUuid).length) break;
      final levelMetadata = game.staticCenter.allLevelsInOneWorld(_worldUuid)[index];
      final levelTile = LevelTile(levelMetadata: levelMetadata, position: position);
      add(levelTile);
      _grid[levelMetadata.uuid] = levelTile;
      index++;
    }

    _show ? show() : hide();
  }

  void show() {
    isVisible = true;
    priority = 1;
  }

  void hide() {
    isVisible = false;
    priority = -1;
    for (var tile in _grid.values) {
      tile.opacity = 0;
    }
  }

  Future<void> animatedShow({required bool toLeft, double duration = 0.4}) async {
    final completer = Completer<void>();
    show();
    final x = _grid.values.last;
    final moveOffset = Vector2(toLeft ? move : -move, 0);
    for (var tile in _grid.values) {
      final endPosition = tile.position.clone();
      tile.position += moveOffset;
      tile.addAll([
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
      ]);
    }

    return completer.future;
  }

  void setStarsInTile({required String levelUuid, required int stars}) => _grid[levelUuid]?.setStars(stars);

  Future<void> newStarsInTileAnimation({required String levelUuid, required int newStars}) async =>
      await _grid[levelUuid]?.newStarsAnimation(newStars);

  void cancelNewStarsInTileAnimation({required String levelUuid}) => _grid[levelUuid]?.cancelNewStarsAnimation();
}
