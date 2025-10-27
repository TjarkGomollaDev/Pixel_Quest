import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/animations/spotlight.dart';
import 'package:pixel_adventure/game/utils/in_game_btn.dart';
import 'package:pixel_adventure/game/utils/rrect.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/menu/widgets/character_bio.dart';
import 'package:pixel_adventure/menu/widgets/dummy_character.dart';
import 'package:pixel_adventure/pixel_quest.dart';

class CharacterPicker extends PositionComponent with HasGameReference<PixelQuest> {
  CharacterPicker() {
    size = game.size;
  }

  // dummy player
  late final DummyCharacter _dummy;

  // extra inforamtion
  late final RRectComponent _titelBg;
  late final TextComponent _title;
  late final CharacterBio _characterBio;

  // spotlight
  late final InGameBtn _editBtn;
  late final Spotlight _spotlight;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _setUpDummyCharacter();
    _setUpTitle();
    _setUpEditBtn();
    _setUpSpotlight();

    return super.onLoad();
  }

  void _initialSetup() {
    // debug
    if (GameSettings.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorMenu;
    }

    // general
    priority = 10;
  }

  void _setUpDummyCharacter() {
    _characterBio = CharacterBio(position: Vector2(24, 94));
    _dummy = DummyCharacter(
      defaultPosition: Vector2(
        game.size.x / 2 - 17 * GameSettings.tileSize + DummyCharacter.gridSize.x / 2,
        7 * GameSettings.tileSize + DummyCharacter.gridSize.y / 2,
      ),
      characterBio: _characterBio,
    );
    add(_dummy);
  }

  void _setUpTitle() {
    _titelBg = RRectComponent(
      color: AppTheme.tileBlur,
      borderRadius: 2,
      position: _dummy.position + Vector2(0, -38),
      size: Vector2(58, 15),
      anchor: Anchor.center,
    );
    _title = TextComponent(
      text: 'Your Player',
      anchor: Anchor(0.5, 0.32),
      position: _titelBg.position,
      textRenderer: TextPaint(
        style: const TextStyle(fontFamily: 'Pixel Font', fontSize: 6, color: AppTheme.ingameText, height: 1),
      ),
    );

    addAll([_titelBg, _title]);
  }

  void _setUpEditBtn() {
    _editBtn = InGameBtn(
      type: InGameBtnType.editSmall,
      action: () {
        _spotlight.startAnimation(0.5);
      },
      position: _dummy.position + Vector2(0, 39),
    );
    add(_editBtn);
  }

  void _setUpSpotlight() {
    _spotlight = Spotlight(targetCenter: _dummy.center.clone());
    add(_spotlight);
  }

  void pause() => _dummy.pauseAnimation();

  void resume() => _dummy.resumeAnimation();
}
