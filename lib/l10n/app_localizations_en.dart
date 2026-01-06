// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLabelMusicVolume => 'Music Volume';

  @override
  String get settingsLabelSfxVolume => 'SFX Volume';

  @override
  String get settingsLabelMainVolume => 'Main Volume:';

  @override
  String get settingsLabelLanguage => 'Language:';

  @override
  String get settingsLabelJoystick => 'Joystick:';

  @override
  String get settingsLabelMiniMap => 'Mini Map:';

  @override
  String get settingsOptionOn => 'On';

  @override
  String get settingsOptionOff => 'Off';

  @override
  String get settingsOptionLeft => 'Left';

  @override
  String get settingsOptionRight => 'Right';

  @override
  String get settingsOptionShow => 'Show';

  @override
  String get settingsOptionHide => 'Hide';

  @override
  String get settingsOptionCancel => 'Cancel';

  @override
  String get settingsOptionConfirm => 'Confirm';

  @override
  String get settingsOptionEnglish => 'English';

  @override
  String get settingsOptionGerman => 'German';

  @override
  String get settingsConfirmLanguageTitle => 'Language';

  @override
  String settingsConfirmLanguage(String language) {
    return 'Are you sure that you want to change the language to $language?';
  }

  @override
  String get loadingGame => 'Loading Game';

  @override
  String loadingLevel(int world, int level) {
    return 'Building stage $world.$level';
  }

  @override
  String get pauseTitel => 'Paused';

  @override
  String get pauseButtonSettigns => 'Settings';

  @override
  String get pauseButtonMenu => 'Menu';

  @override
  String get characterPickerTitle => 'Character';

  @override
  String get characterPickerLabelName => 'Name:';

  @override
  String get characterPickerLabelOrigin => 'Origin:';

  @override
  String get characterPickerLabelAbility => 'Ability:';

  @override
  String get characterName_maskDude => 'Mojo';

  @override
  String get characterOrigin_maskDude => 'Banana River';

  @override
  String get characterAbility_maskDude => 'Monkey Call';

  @override
  String get characterName_ninjaFrog => 'Croakashi';

  @override
  String get characterOrigin_ninjaFrog => 'Kyoto Swamp';

  @override
  String get characterAbility_ninjaFrog => 'Spin Attack';

  @override
  String get characterName_pinkMan => 'Popstar P';

  @override
  String get characterOrigin_pinkMan => 'Pink Hills';

  @override
  String get characterAbility_pinkMan => 'Disco Dash';

  @override
  String get characterName_virtualGuy => 'Gl1tch.exe';

  @override
  String get characterOrigin_virtualGuy => 'The Cloud';

  @override
  String get characterAbility_virtualGuy => 'Hack Attack';
}
