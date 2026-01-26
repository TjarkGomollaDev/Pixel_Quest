import 'dart:async';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/animations/spotlight.dart';
import 'package:pixel_adventure/game/game_router.dart';
import 'package:pixel_adventure/game/level/player/player.dart';
import 'package:pixel_adventure/game/utils/button.dart';
import 'package:pixel_adventure/game/utils/dialog_container.dart';
import 'package:pixel_adventure/game/utils/input_blocker.dart';
import 'package:pixel_adventure/game/game_settings.dart';
import 'package:pixel_adventure/game/menu/widgets/character_bio.dart';
import 'package:pixel_adventure/game/menu/widgets/menu_dummy_character.dart';
import 'package:pixel_adventure/game/game.dart';
import 'package:pixel_adventure/game/utils/visible_components.dart';

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

  // dummy character and open btn
  late final MenuDummyCharacter _dummy;
  late final SpriteBtn _openBtn;

  // spotlight
  bool _isSpotlightActive = false;
  late final Spotlight _spotlight;
  late final SpriteBtn _closeBtn;
  late final CharacterBio _characterBio;

  // title

  @override
  FutureOr<void> onLoad() {
    _setUpCharacterBio();
    _setUpDummyCharacter();
    _setUpOpenBtn();
    _setUpCloseBtn();
    _setUpSpotlight();

    _setUpTitle();
    _setUpCharacterPicker();
    _setUpLevelBgPicker();
    _setUpLoadingBgPicker();
    return super.onLoad();
  }

  @override
  Future<void> onMount() async {
    _isSpotlightActive = true;
    _inputBlocker.enable();
    await _spotlight.focusOnTarget();
    _showSpotlightContent();

    game.router.pushNamed(RouteNames.settings);
    super.onMount();
  }

  void _setUpTitle() {
    _title = VisibleTextComponent(
      text: 'Your Inventory',
      anchor: Anchor.topCenter,
      position: Vector2((size.x - _spotlightCenter.x + Spotlight.playerTargetRadius / 2) / 2 + _spotlightCenter.x, 30),
      textRenderer: AppTheme.dialogHeadingStandard.asTextPaint,
      show: false,
    )..priority = GameSettings.spotlightAnimationContentLayer;

    addAll([_title]);
  }

  late final VisibleTextComponent _title;
  late final VisibleTextComponent _characterPickerText;
  late final RadioComponent _characterPickerSelector;
  late final VisibleTextComponent _levelBgPickerText;
  late final RadioComponent _levelBgPickerSelector;
  late final VisibleTextComponent _loadingBgPickerText;
  late final RadioComponent _loadingBgPickerSelector;

  void _setUpCharacterPicker() {
    // character picker text
    _characterPickerText = VisibleTextComponent(
      text: 'Chracter',
      anchor: Anchor.topCenter,
      position: _title.position + Vector2(0, _title.height + 20),
      textRenderer: AppTheme.dialogTextStandard.asTextPaint,
      show: false,
    )..priority = GameSettings.spotlightAnimationContentLayer;

    // character picker selector
    _characterPickerSelector = RadioComponent(
      anchor: Anchor.topCenter,
      position: _characterPickerText.position + Vector2(0, _characterPickerText.height + DialogContainer.headlineMarginBottom),
      initialIndex: game.audioCenter.soundState.enabled ? 0 : 1,
      optionSize: Vector2(38, 44),
      spacingBetweenOptions: 12,
      spriteOffset: Vector2(0, -4),
      show: false,
      options: [
        RadioOptionSprite(
          path: 'Menu/Inventory/Mask_Dude_Preview.png',
          onSelected: () {
            if (!_isSpotlightActive) return;
            _dummy.setCharacter(PlayerCharacter.maskDude);
          },
        ),
        RadioOptionSprite(
          path: 'Menu/Inventory/Ninja_Frog_Preview.png',
          onSelected: () {
            if (!_isSpotlightActive) return;
            _dummy.setCharacter(PlayerCharacter.ninjaFrog);
          },
        ),
        RadioOptionSprite(
          path: 'Menu/Inventory/Pink_Man_Preview.png',
          onSelected: () {
            if (!_isSpotlightActive) return;
            _dummy.setCharacter(PlayerCharacter.pinkMan);
          },
        ),
        RadioOptionSprite(
          path: 'Menu/Inventory/Virtual_Guy_Preview.png',
          onSelected: () {
            if (!_isSpotlightActive) return;
            _dummy.setCharacter(PlayerCharacter.virtualGuy);
          },
        ),
      ],
    )..priority = GameSettings.spotlightAnimationContentLayer;

    addAll([_characterPickerText, _characterPickerSelector]);
  }

  void _setUpLevelBgPicker() {
    // level background picker text
    _levelBgPickerText = VisibleTextComponent(
      text: 'Level',
      anchor: Anchor.topCenter,
      position: _characterPickerSelector.position + Vector2(0, _characterPickerSelector.height + DialogContainer.spacingBetweenSections),
      textRenderer: AppTheme.dialogTextStandard.asTextPaint,
      show: false,
    )..priority = GameSettings.spotlightAnimationContentLayer;

    // level background picker selector
    _levelBgPickerSelector = RadioComponent(
      anchor: Anchor.topCenter,
      position: _levelBgPickerText.position + Vector2(0, _levelBgPickerText.height + DialogContainer.headlineMarginBottom),
      initialIndex: game.audioCenter.soundState.enabled ? 0 : 1,
      optionSize: Vector2(62, 37.5),
      spacingBetweenOptions: 12,
      spriteSize: Vector2(56, 31.5),
      show: false,
      options: [
        // RadioOptionText(
        //   text: 'Default',
        //   onSelected: () {
        //     if (!_isSpotlightActive) return;
        //   },
        // ),
        RadioOptionSprite(
          path: 'Background/Szene 1/4.png',
          onSelected: () {
            if (!_isSpotlightActive) return;
          },
        ),
        RadioOptionSprite(
          path: 'Background/Szene 2/4.png',
          onSelected: () {
            if (!_isSpotlightActive) return;
          },
        ),
        RadioOptionSprite(
          path: 'Background/Szene 4/4.png',
          onSelected: () {
            if (!_isSpotlightActive) return;
          },
        ),
      ],
    )..priority = GameSettings.spotlightAnimationContentLayer;

    addAll([_levelBgPickerText, _levelBgPickerSelector]);
  }

  void _setUpLoadingBgPicker() {
    // loading background picker text
    _loadingBgPickerText = VisibleTextComponent(
      text: 'Loading',
      anchor: Anchor.topCenter,
      position: _levelBgPickerSelector.position + Vector2(0, _levelBgPickerSelector.height + DialogContainer.spacingBetweenSections),
      textRenderer: AppTheme.dialogTextStandard.asTextPaint,
      show: false,
    )..priority = GameSettings.spotlightAnimationContentLayer;

    // loading background picker selector
    _loadingBgPickerSelector = RadioComponent(
      anchor: Anchor.topCenter,
      position: _loadingBgPickerText.position + Vector2(0, _loadingBgPickerText.height + DialogContainer.headlineMarginBottom),
      initialIndex: game.audioCenter.soundState.enabled ? 0 : 1,
      optionSize: Vector2(62, 37.5),
      spacingBetweenOptions: 12,
      spriteSize: Vector2(56, 31.5),
      show: false,
      options: [
        // RadioOptionText(
        //   text: 'Default',
        //   onSelected: () {
        //     if (!_isSpotlightActive) return;
        //   },
        // ),
        RadioOptionSprite(
          path: 'Background/Szene 3/4.png',
          onSelected: () {
            if (!_isSpotlightActive) return;
          },
        ),
        RadioOptionSprite(
          path: 'Background/Szene 6/4.png',
          onSelected: () {
            if (!_isSpotlightActive) return;
          },
        ),
      ],
    )..priority = GameSettings.spotlightAnimationContentLayer;

    addAll([_loadingBgPickerText, _loadingBgPickerSelector]);
  }

  void _setUpCharacterBio() {
    _characterBio = CharacterBio(
      position: _spotlightCenter + Vector2(-Spotlight.playerTargetRadius + 22, Spotlight.playerTargetRadius + 32),
      show: false,
    )..priority = GameSettings.spotlightAnimationContentLayer;
    add(_characterBio);
  }

  void _setUpDummyCharacter() {
    _dummy = MenuDummyCharacter(defaultPosition: _spotlightCenter, characterBio: _characterBio);
    add(_dummy);
  }

  void _setUpOpenBtn() {
    _openBtn = SpriteBtn.fromType(
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
    add(_openBtn);
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
      position: _spotlightCenter + Vector2(Spotlight.playerTargetRadius, -Spotlight.playerTargetRadius),
      show: false,
    )..priority = GameSettings.spotlightAnimationContentLayer;
    add(_closeBtn);
  }

  void _setUpSpotlight() {
    _spotlight = Spotlight(targetCenter: _spotlightCenter);
    add(_spotlight);
  }

  void _showSpotlightContent() {
    _closeBtn.animatedShow();
    _characterBio.animatedShow();
    _title.show();
    _characterPickerText.show();
    _characterPickerSelector.show();
    _levelBgPickerText.show();
    _levelBgPickerSelector.show();
    _loadingBgPickerText.show();
    _loadingBgPickerSelector.show();
  }

  void _hideSpotlightContent() {
    _closeBtn.hide();
    _characterBio.hide();
    _title.hide();
    _characterPickerText.hide();
    _characterPickerSelector.hide();
    _levelBgPickerText.hide();
    _levelBgPickerSelector.hide();
    _loadingBgPickerText.hide();
    _loadingBgPickerSelector.hide();
  }

  void stopCharacterAnimationLoop() {
    _dummy.stop();
  }

  void startCharacterAnimationLoop() {
    _dummy.start();
  }
}
