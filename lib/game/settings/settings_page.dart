import 'dart:async';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/data/audio/audio_center.dart';
import 'package:pixel_adventure/game/events/game_event_bus.dart';
import 'package:pixel_adventure/game/level/mobile%20controls/mobile_controls.dart';
import 'package:pixel_adventure/game/settings/confirm_page.dart';
import 'package:pixel_adventure/game/utils/button.dart';
import 'package:pixel_adventure/game/utils/dialog_container.dart';
import 'package:pixel_adventure/game/utils/dialog_page.dart';
import 'package:pixel_adventure/game/utils/slider.dart';
import 'package:pixel_adventure/game/game.dart';

/// Settings overlay route that opens the in-game settings dialog.
class SettingsPage extends Route {
  SettingsPage() : super(() => _SettingsDialog(), transparent: true);
}

class _SettingsDialog extends Component with HasGameReference<PixelQuest> {
  @override
  FutureOr<void> onLoad() {
    add(DialogPage(content: _SettingsContent(), titleText: game.l10n.settingsTitle, contentSize: _SettingsContent.contentSize));
    return super.onLoad();
  }
}

/// Dialog body component that builds the settings UI sections.
class _SettingsContent extends PositionComponent with HasGameReference<PixelQuest> {
  _SettingsContent() : super(size: contentSize);

  // content size
  static final Vector2 contentSize = Vector2(
    DialogContainer.contentWidth,
    8 * 2 +
        Slider.defaultHeight * 2 +
        RadioComponent.defaultOptionSize.y * 4 +
        DialogContainer.spacingBetweenSections * 5 +
        DialogContainer.headlineMarginBottom * 2,
  );

  // audio settings
  late final TextComponent _soundStateText;
  late final RadioComponent _soundStateSelector;
  late final TextComponent _musicVolumeText;
  late final TextComponent _sfxVolumeText;
  late final Slider _musicSlider;
  late final Slider _sfxSlider;

  // language settings
  late final int _languageIndex;
  late final TextComponent _languageText;
  late final RadioComponent _languageSelector;

  // control settings
  late final TextComponent _controlText;
  late final RadioComponent _controlSelector;

  // mini map settings
  late final TextComponent _miniMapText;
  late final RadioComponent _miniMapSelector;

  @override
  FutureOr<void> onLoad() {
    _setUpAudioSettings();
    _setUpLanguageSettings();
    _setUpControlSettings();
    _setUpMiniMapSettings();
    return super.onLoad();
  }

  void _setUpAudioSettings() {
    // music text
    _musicVolumeText = TextComponent(
      text: game.l10n.settingsLabelMusicVolume,
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 0),
      textRenderer: AppTheme.dialogTextStandard.asTextPaint,
    );

    // music volume slider
    _musicSlider = Slider(
      initialValue: game.audioCenter.musicVolume,
      width: size.x,
      position: _musicVolumeText.position + Vector2(0, _musicVolumeText.size.y + DialogContainer.headlineMarginBottom),
      onChanged: (value) => game.audioCenter.setMusicVolume(value),
      onChangedContinuous: (value) => game.audioCenter.setMusicVolume(value, automaticSave: false),
      enabled: game.audioCenter.soundState.enabled,
    );

    // sfx text
    _sfxVolumeText = TextComponent(
      text: game.l10n.settingsLabelSfxVolume,
      anchor: Anchor.topCenter,
      position: _musicSlider.position + Vector2(0, _musicSlider.size.y + DialogContainer.spacingBetweenSections),
      textRenderer: AppTheme.dialogTextStandard.asTextPaint,
    );

    // sfx volume slider
    _sfxSlider = Slider(
      initialValue: game.audioCenter.sfxVolume,
      width: size.x,
      position: _sfxVolumeText.position + Vector2(0, _sfxVolumeText.size.y + DialogContainer.headlineMarginBottom),
      onChanged: (value) {
        game.audioCenter.setSfxVolume(value);
        game.audioCenter.playSound(Sfx.collected, SfxType.ui);
      },
      enabled: game.audioCenter.soundState.enabled,
    );

    // sound state selector
    _soundStateSelector = RadioComponent(
      position: Vector2(
        DialogContainer.yPositionSecondColumn,
        _sfxSlider.position.y + _sfxSlider.size.y + DialogContainer.spacingBetweenSections,
      ),
      initialIndex: game.audioCenter.soundState.enabled ? 0 : 1,
      options: [
        RadioOptionText(
          text: game.l10n.settingsOptionOn,
          onSelected: () {
            _sfxSlider.enable();
            _musicSlider.enable();
            game.audioCenter.toggleSound(SoundState.on);
          },
        ),
        RadioOptionText(
          text: game.l10n.settingsOptionOff,
          onSelected: () {
            _sfxSlider.disable();
            _musicSlider.disable();
            game.audioCenter.toggleSound(SoundState.off);
          },
        ),
      ],
    );

    // sound state text
    _soundStateText = TextComponent(
      text: game.l10n.settingsLabelMainVolume,
      anchor: Anchor.centerLeft,
      position: Vector2(0, _soundStateSelector.position.y + _soundStateSelector.size.y / 2),
      textRenderer: AppTheme.dialogTextStandard.asTextPaint,
    );

    addAll([_soundStateSelector, _soundStateText, _musicVolumeText, _musicSlider, _sfxVolumeText, _sfxSlider]);
  }

  void _setUpLanguageSettings() {
    _languageIndex = game.l10n.localeName == 'en' ? 0 : 1;

    // language selector
    _languageSelector = RadioComponent(
      position: Vector2(
        DialogContainer.yPositionSecondColumn,
        _soundStateSelector.position.y + _soundStateSelector.size.y + DialogContainer.spacingBetweenSections,
      ),
      initialIndex: _languageIndex,
      options: [
        RadioOptionText(
          text: game.l10n.settingsOptionEnglish,
          onSelected: () => _confirmLanguageChange(const Locale('en'), game.l10n.settingsOptionEnglish),
        ),
        RadioOptionText(
          text: game.l10n.settingsOptionGerman,
          onSelected: () => _confirmLanguageChange(const Locale('de'), game.l10n.settingsOptionGerman),
        ),
      ],
    );

    // language text
    _languageText = TextComponent(
      text: game.l10n.settingsLabelLanguage,
      anchor: Anchor.centerLeft,
      position: Vector2(0, _languageSelector.position.y + _languageSelector.size.y / 2),
      textRenderer: AppTheme.dialogTextStandard.asTextPaint,
    );

    addAll([_languageSelector, _languageText]);
  }

  void _setUpControlSettings() {
    // control selector
    _controlSelector = RadioComponent(
      position: Vector2(
        DialogContainer.yPositionSecondColumn,
        _languageSelector.position.y + _languageSelector.size.y + DialogContainer.spacingBetweenSections,
      ),
      initialIndex: game.storageCenter.settings.joystickSetup.isLeft ? 0 : 1,
      options: [
        RadioOptionText(text: game.l10n.settingsOptionLeft, onSelected: () => _controlSettingChanged(JoystickSetup.left)),
        RadioOptionText(text: game.l10n.settingsOptionRight, onSelected: () => _controlSettingChanged(JoystickSetup.right)),
      ],
    );

    // control text
    _controlText = TextComponent(
      text: game.l10n.settingsLabelJoystick,
      anchor: Anchor.centerLeft,
      position: Vector2(0, _controlSelector.position.y + _controlSelector.size.y / 2),
      textRenderer: AppTheme.dialogTextStandard.asTextPaint,
    );

    addAll([_controlSelector, _controlText]);
  }

  void _setUpMiniMapSettings() {
    // mini map selector
    _miniMapSelector = RadioComponent(
      position: Vector2(
        DialogContainer.yPositionSecondColumn,
        _controlSelector.position.y + _controlSelector.size.y + DialogContainer.spacingBetweenSections,
      ),
      initialIndex: game.storageCenter.settings.showMiniMapAtStart ? 0 : 1,
      options: [
        RadioOptionText(
          text: game.l10n.settingsOptionShow,
          onSelected: nonBlocking(() => game.storageCenter.updateSettings(showMiniMapAtStart: true)),
        ),
        RadioOptionText(
          text: game.l10n.settingsOptionHide,
          onSelected: nonBlocking(() => game.storageCenter.updateSettings(showMiniMapAtStart: false)),
        ),
      ],
    );

    // mini map text
    _miniMapText = TextComponent(
      text: game.l10n.settingsLabelMiniMap,
      anchor: Anchor.centerLeft,
      position: Vector2(0, _miniMapSelector.position.y + _miniMapSelector.size.y / 2),
      textRenderer: AppTheme.dialogTextStandard.asTextPaint,
    );

    addAll([_miniMapSelector, _miniMapText]);
  }

  void _confirmLanguageChange(Locale newLocale, String langName) {
    unawaited(
      game.router
          .pushAndWait(ConfirmPage(titleText: game.l10n.settingsConfirmLanguageTitle, message: game.l10n.settingsConfirmLanguage(langName)))
          .then((confirmed) {
            if (!confirmed) {
              _languageSelector.setSelectedIndex(_languageIndex);
              return;
            }

            // restart app with new language
            game.requestLocaleChange(newLocale);
          }),
    );
  }

  void _controlSettingChanged(JoystickSetup setup) {
    unawaited(game.storageCenter.updateSettings(joystickSetup: setup));
    game.eventBus.emit(ControlSettingsChanged(setup));
  }
}
