import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLabelMusicVolume.
  ///
  /// In en, this message translates to:
  /// **'Music Volume'**
  String get settingsLabelMusicVolume;

  /// No description provided for @settingsLabelSfxVolume.
  ///
  /// In en, this message translates to:
  /// **'SFX Volume'**
  String get settingsLabelSfxVolume;

  /// No description provided for @settingsLabelMainVolume.
  ///
  /// In en, this message translates to:
  /// **'Main Volume:'**
  String get settingsLabelMainVolume;

  /// No description provided for @settingsLabelLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language:'**
  String get settingsLabelLanguage;

  /// No description provided for @settingsLabelJoystick.
  ///
  /// In en, this message translates to:
  /// **'Joystick:'**
  String get settingsLabelJoystick;

  /// No description provided for @settingsLabelMiniMap.
  ///
  /// In en, this message translates to:
  /// **'Mini Map:'**
  String get settingsLabelMiniMap;

  /// No description provided for @settingsOptionOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get settingsOptionOn;

  /// No description provided for @settingsOptionOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsOptionOff;

  /// No description provided for @settingsOptionLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get settingsOptionLeft;

  /// No description provided for @settingsOptionRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get settingsOptionRight;

  /// No description provided for @settingsOptionShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get settingsOptionShow;

  /// No description provided for @settingsOptionHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get settingsOptionHide;

  /// No description provided for @settingsOptionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsOptionCancel;

  /// No description provided for @settingsOptionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get settingsOptionConfirm;

  /// No description provided for @settingsOptionEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsOptionEnglish;

  /// No description provided for @settingsOptionGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get settingsOptionGerman;

  /// No description provided for @settingsConfirmLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsConfirmLanguageTitle;

  /// No description provided for @settingsConfirmLanguage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure that you want to change the language to {language}?'**
  String settingsConfirmLanguage(String language);

  /// No description provided for @loadingGame.
  ///
  /// In en, this message translates to:
  /// **'Loading Game'**
  String get loadingGame;

  /// No description provided for @loadingLevel.
  ///
  /// In en, this message translates to:
  /// **'Building stage {world}.{level}'**
  String loadingLevel(int world, int level);

  /// No description provided for @pauseTitel.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get pauseTitel;

  /// No description provided for @pauseButtonSettigns.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get pauseButtonSettigns;

  /// No description provided for @pauseButtonMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get pauseButtonMenu;

  /// No description provided for @characterPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get characterPickerTitle;

  /// No description provided for @characterPickerLabelName.
  ///
  /// In en, this message translates to:
  /// **'Name:'**
  String get characterPickerLabelName;

  /// No description provided for @characterPickerLabelOrigin.
  ///
  /// In en, this message translates to:
  /// **'Origin:'**
  String get characterPickerLabelOrigin;

  /// No description provided for @characterPickerLabelAbility.
  ///
  /// In en, this message translates to:
  /// **'Ability:'**
  String get characterPickerLabelAbility;

  /// No description provided for @characterName_maskDude.
  ///
  /// In en, this message translates to:
  /// **'Mojo'**
  String get characterName_maskDude;

  /// No description provided for @characterOrigin_maskDude.
  ///
  /// In en, this message translates to:
  /// **'Banana River'**
  String get characterOrigin_maskDude;

  /// No description provided for @characterAbility_maskDude.
  ///
  /// In en, this message translates to:
  /// **'Monkey Call'**
  String get characterAbility_maskDude;

  /// No description provided for @characterName_ninjaFrog.
  ///
  /// In en, this message translates to:
  /// **'Croakashi'**
  String get characterName_ninjaFrog;

  /// No description provided for @characterOrigin_ninjaFrog.
  ///
  /// In en, this message translates to:
  /// **'Kyoto Swamp'**
  String get characterOrigin_ninjaFrog;

  /// No description provided for @characterAbility_ninjaFrog.
  ///
  /// In en, this message translates to:
  /// **'Spin Attack'**
  String get characterAbility_ninjaFrog;

  /// No description provided for @characterName_pinkMan.
  ///
  /// In en, this message translates to:
  /// **'Popstar P'**
  String get characterName_pinkMan;

  /// No description provided for @characterOrigin_pinkMan.
  ///
  /// In en, this message translates to:
  /// **'Pink Hills'**
  String get characterOrigin_pinkMan;

  /// No description provided for @characterAbility_pinkMan.
  ///
  /// In en, this message translates to:
  /// **'Disco Dash'**
  String get characterAbility_pinkMan;

  /// No description provided for @characterName_virtualGuy.
  ///
  /// In en, this message translates to:
  /// **'Gl1tch.exe'**
  String get characterName_virtualGuy;

  /// No description provided for @characterOrigin_virtualGuy.
  ///
  /// In en, this message translates to:
  /// **'The Cloud'**
  String get characterOrigin_virtualGuy;

  /// No description provided for @characterAbility_virtualGuy.
  ///
  /// In en, this message translates to:
  /// **'Hack Attack'**
  String get characterAbility_virtualGuy;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
