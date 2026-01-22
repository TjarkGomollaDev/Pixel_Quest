import 'dart:async';
import 'package:flame/components.dart';
import 'package:pixel_adventure/game/animations/spotlight.dart';
import 'package:pixel_adventure/game/utils/button.dart';
import 'package:pixel_adventure/game/utils/input_blocker.dart';
import 'package:pixel_adventure/game/game_settings.dart';
import 'package:pixel_adventure/game/menu/widgets/character_bio.dart';
import 'package:pixel_adventure/game/menu/widgets/menu_dummy_character.dart';
import 'package:pixel_adventure/game/game.dart';

class CharacterPicker extends PositionComponent with HasGameReference<PixelQuest> {
  // constructor parameters
  final InputBlocker _inputBlocker;
  final Vector2 _spotlightCenter;

  CharacterPicker({required InputBlocker inputBlocker, required Vector2 spotlightCenter})
    : _inputBlocker = inputBlocker,
      _spotlightCenter = spotlightCenter {
    size = game.size;
    priority = GameSettings.chracterPicker;
  }

  // character picker
  late final MenuDummyCharacter _dummy;
  late final SpriteBtn _editBtn;

  // spotlight
  late final Spotlight _spotlight;
  late final SpriteBtn _closeBtn;
  late final CharacterBio _characterBio;
  late final SpriteBtn _previousCharacterBtn;
  late final SpriteBtn _nextCharacterBtn;
  bool _isSpotlightActive = false;

  // spotlight spacing
  static const double _characterChangeBtnSpacing = 14; // [Adjustable]

  @override
  FutureOr<void> onLoad() {
    _setUpCharacterBio();
    _setUpDummyCharacter();
    _setUpEditBtn();
    _setUpCloseBtn();
    _setUpCharacterChangeBtns();
    _setUpSpotlight();
    return super.onLoad();
  }

  void _setUpCharacterBio() {
    _characterBio = CharacterBio(position: _spotlightCenter + Vector2(Spotlight.playerTargetRadius * 1.2, 0), show: false)
      ..priority = GameSettings.spotlightAnimationContentLayer;
    add(_characterBio);
  }

  void _setUpDummyCharacter() {
    _dummy = MenuDummyCharacter(defaultPosition: _spotlightCenter, characterBio: _characterBio);
    add(_dummy);
  }

  void _setUpEditBtn() {
    _editBtn = SpriteBtn.fromType(
      type: SpriteBtnType.editSmall,
      onPressed: () async {
        if (_isSpotlightActive) return;
        _isSpotlightActive = true;
        _inputBlocker.enable();
        await _spotlight.focusOnTarget();
        _showSpotlightContent();
      },
      position: _dummy.position + Vector2(0, 39),
    );
    add(_editBtn);
  }

  void _setUpCloseBtn() {
    _closeBtn = SpriteBtn.fromType(
      type: SpriteBtnType.closeSmall,
      onPressed: () async {
        if (!_isSpotlightActive) return;
        _isSpotlightActive = false;
        _inputBlocker.disable();
        _hideSpotlightContent();
        await _spotlight.expandToFull();
      },
      position: _dummy.position + Vector2(Spotlight.playerTargetRadius * 0.9, -Spotlight.playerTargetRadius * 0.9),
      show: false,
    )..priority = GameSettings.spotlightAnimationContentLayer;
    add(_closeBtn);
  }

  void _setUpCharacterChangeBtns() {
    final basePosition = Vector2(_characterBio.x + 28, _characterBio.position.y + _characterBio.size.y / 2);
    final btnHorizontalCenter = SpriteBtnType.btnSizeSmall.x / 2;
    _previousCharacterBtn = SpriteBtn.fromType(
      type: SpriteBtnType.previousSmall,
      onPressed: () {
        if (!_isSpotlightActive) return;
        _dummy.switchCharacter(next: false);
      },
      position: basePosition + Vector2(-_characterChangeBtnSpacing / 2 - btnHorizontalCenter, 0),
      show: false,
    )..priority = GameSettings.spotlightAnimationContentLayer;
    _nextCharacterBtn = SpriteBtn.fromType(
      type: SpriteBtnType.nextSmall,
      onPressed: () {
        if (!_isSpotlightActive) return;
        _dummy.switchCharacter();
      },
      position: basePosition + Vector2(_characterChangeBtnSpacing / 2 + btnHorizontalCenter, 0),
      show: false,
    )..priority = GameSettings.spotlightAnimationContentLayer;
    addAll([_previousCharacterBtn, _nextCharacterBtn]);
  }

  void _setUpSpotlight() {
    _spotlight = Spotlight(targetCenter: _spotlightCenter);
    add(_spotlight);
  }

  void _showSpotlightContent() {
    _closeBtn.animatedShow();
    _characterBio.animatedShow();
    _nextCharacterBtn.animatedShow();
    _previousCharacterBtn.animatedShow();
  }

  void _hideSpotlightContent() {
    _closeBtn.hide();
    _characterBio.hide();
    _nextCharacterBtn.hide();
    _previousCharacterBtn.hide();
  }

  void pause() {
    _dummy.pauseAnimation();
  }

  void resume() {
    _dummy.resumeAnimation();
  }
}
