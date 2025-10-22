import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/utils/corner_outline.dart';
import 'package:pixel_adventure/game/utils/rrect.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/menu/character_bio.dart';
import 'package:pixel_adventure/menu/dummy_character.dart';
import 'package:pixel_adventure/pixel_quest.dart';

class CharacterPicker extends PositionComponent with HasGameReference<PixelQuest> {
  CharacterPicker({required super.position}) : super(size: Vector2(100, 86)) {
    _center = size / 2;
  }

  // center of the module
  late final Vector2 _center;

  // dummy player
  late final DummyCharacter _dummy;

  // draggable outline
  late final DraggableCornerOutline _dummyOutline;

  // extra inforamtion
  late final RoundedComponent _titelBg;
  late final TextComponent _title;
  late final CharacterBio _characterBio;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _setUpTitle();
    _setUpCharacterBio();
    _setUpDummyCharacter();
    _setUpOutline();
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

  void _setUpTitle() {
    _titelBg = RoundedComponent(
      color: AppTheme.tileBlur,
      borderRadius: 2,
      position: Vector2(_center.x, _center.y - 40),
      size: Vector2(62, 14),
      anchor: Anchor.center,
    );
    _title = TextComponent(
      text: 'Your Player',
      anchor: Anchor(0.5, 0.32),
      position: Vector2(_center.x, _center.y - 40),
      textRenderer: TextPaint(
        style: const TextStyle(fontFamily: 'Pixel Font', fontSize: 6, color: AppTheme.ingameText, height: 1),
      ),
    );
    addAll([_titelBg, _title]);
  }

  void _setUpCharacterBio() {
    _characterBio = CharacterBio(character: game.storageCenter.settings.character, position: Vector2(24, 94));
    add(_characterBio);
  }

  void _setUpDummyCharacter() {
    _dummy = DummyCharacter(defaultPosition: _center, characterBio: _characterBio);
    add(_dummy);
  }

  void _setUpOutline() {
    _dummyOutline = DraggableCornerOutline(
      onSwipeRight: () => _dummy.switchCharacter(),
      onSwipeLeft: () => _dummy.switchCharacter(next: false),
      size: Vector2(44, 46),
      cornerLength: 4,
      strokeWidth: 1.2,
      color: AppTheme.starColor,
      anchor: Anchor.center,
      position: _center,
    );
    add(_dummyOutline);
  }
}
