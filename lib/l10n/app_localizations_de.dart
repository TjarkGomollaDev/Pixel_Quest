// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsLabelMusicVolume => 'Musiklautstärke';

  @override
  String get settingsLabelSfxVolume => 'SFX-Lautstärke';

  @override
  String get settingsLabelMainVolume => 'Lautstärke:';

  @override
  String get settingsLabelLanguage => 'Sprache:';

  @override
  String get settingsLabelJoystick => 'Joystick:';

  @override
  String get settingsLabelMiniMap => 'Minikarte:';

  @override
  String get settingsOptionOn => 'An';

  @override
  String get settingsOptionOff => 'Aus';

  @override
  String get settingsOptionLeft => 'Links';

  @override
  String get settingsOptionRight => 'Rechts';

  @override
  String get settingsOptionShow => 'Anzeigen';

  @override
  String get settingsOptionHide => 'Ausblenden';

  @override
  String get settingsOptionCancel => 'Abbrechen';

  @override
  String get settingsOptionConfirm => 'Bestätigen';

  @override
  String get settingsOptionEnglish => 'Englisch';

  @override
  String get settingsOptionGerman => 'Deutsch';

  @override
  String get settingsConfirmLanguageTitle => 'Sprache';

  @override
  String settingsConfirmLanguage(String language) {
    return 'Möchtest du die Sprache wirklich auf $language ändern?';
  }

  @override
  String get loadingGame => 'Spiel wird geladen';

  @override
  String loadingLevel(int world, int level) {
    return 'Erstelle Level $level.$world';
  }

  @override
  String get pauseTitel => 'Pausiert';

  @override
  String get pauseButtonSettigns => 'Einstellungen';

  @override
  String get pauseButtonAchievements => 'Erungenschaften';

  @override
  String get pauseButtonMenu => 'Menü';

  @override
  String get characterPickerTitle => 'Charakter';

  @override
  String get characterPickerLabelName => 'Name:';

  @override
  String get characterPickerLabelOrigin => 'Herkunft:';

  @override
  String get characterPickerLabelAbility => 'Fähigkeit:';

  @override
  String get characterName_maskDude => 'Mojo';

  @override
  String get characterOrigin_maskDude => 'Banana River';

  @override
  String get characterAbility_maskDude => 'Affenschrei';

  @override
  String get characterName_ninjaFrog => 'Croakashi';

  @override
  String get characterOrigin_ninjaFrog => 'Kyoto Swamp';

  @override
  String get characterAbility_ninjaFrog => 'Wirbelangriff';

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
  String get characterAbility_virtualGuy => 'Hack-Angriff';
}
