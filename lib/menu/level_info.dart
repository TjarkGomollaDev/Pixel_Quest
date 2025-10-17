import 'dart:async';
import 'package:flame/components.dart';
import 'package:pixel_adventure/game/animations/star.dart';
import 'package:pixel_adventure/game/level/level_list.dart';
import 'package:pixel_adventure/menu/level_btn.dart';
import 'package:pixel_adventure/pixel_quest.dart';

class LevelInfo extends PositionComponent with HasGameReference<PixelQuest> {
  final LevelMetadata _levelMetadata;

  LevelInfo({required LevelMetadata levelMetadata, required super.position}) : _levelMetadata = levelMetadata;

  // btns
  late final LevelBtn _levelBtn;

  // outline stars
  final List<OutlineStar> _outlineStars = [];

  // stars
  final List<Star> _stars = [];

  // spacing
  static const double _starSpacing = 24;

  @override
  FutureOr<void> onLoad() {
    _levelBtn = LevelBtn(levelMetadata: _levelMetadata, position: position);
    add(_levelBtn);

    _setUpStars();

    return super.onLoad();
  }

  void _setUpStars() {
    final data = game.dataCenter.getLevel(_levelMetadata.uuid);
    for (var i = 0; i < data.stars; i++) {
      final star = Star(position: Vector2(position.x + 40 + i * _starSpacing, position.y));
      _stars.add(star);
    }
    for (var i = data.stars; i < data.stars + 3 - data.stars; i++) {
      final outlineStar = OutlineStar(position: Vector2(position.x + 40 + i * _starSpacing, position.y));
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
