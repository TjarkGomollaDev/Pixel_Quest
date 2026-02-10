import 'package:flame/components.dart';
import 'package:flutter/material.dart';

abstract class AppTheme {
  // #### ALL COLORS ###########################################

  // Black, White and Transparent
  static const Color white = .fromRGBO(255, 255, 255, 1);
  static const Color black = .fromRGBO(0, 0, 0, 1);
  static const Color transparent = .fromARGB(0, 0, 0, 0);

  // Gray Colors -> LIGHT
  static const Color grayLight1 = .fromRGBO(126, 125, 130, 1);
  static const Color grayLight2 = .fromRGBO(174, 174, 178, 1);
  static const Color grayLight3 = .fromRGBO(199, 199, 204, 1);
  static const Color grayLight4 = .fromRGBO(209, 209, 234, 1);
  static const Color grayLight5 = .fromRGBO(229, 229, 234, 1);
  static const Color grayLight6 = .fromRGBO(242, 242, 247, 1);

  // Gray Colors -> DARK
  static const Color grayDark1 = .fromRGBO(142, 142, 147, 1);
  static const Color grayDark2 = .fromRGBO(99, 99, 102, 1);
  static const Color grayDark3 = .fromRGBO(72, 72, 74, 1);
  static const Color grayDark4 = .fromRGBO(58, 58, 60, 1);
  static const Color grayDark5 = .fromRGBO(44, 44, 46, 1);
  static const Color grayDark6 = .fromRGBO(28, 28, 30, 1);

  // Colors -> LIGHT
  static const Color blueLight = .fromRGBO(0, 122, 255, 1);
  static const Color redLight = .fromRGBO(255, 59, 48, 1);
  static const Color greenLight = .fromRGBO(52, 199, 89, 1);
  static const Color mintLight = .fromRGBO(0, 199, 190, 1);
  static const Color orangeLight = .fromRGBO(255, 149, 0, 1);
  static const Color yellowLight = .fromRGBO(255, 204, 0, 1);
  static const Color tealLight = .fromRGBO(48, 176, 199, 1);
  static const Color cyanLight = .fromRGBO(50, 173, 230, 1);
  static const Color indigoLight = .fromRGBO(88, 86, 214, 1);
  static const Color purpleLight = .fromRGBO(175, 82, 222, 1);
  static const Color pinkLight = .fromRGBO(255, 45, 85, 1);
  static const Color brownLight = .fromRGBO(162, 132, 94, 1);

  // Colors -> DARK
  static const Color blueDark = .fromRGBO(10, 132, 255, 1);
  static const Color redDark = .fromRGBO(255, 69, 58, 1);
  static const Color greenDark = .fromRGBO(48, 209, 88, 1);
  static const Color mintDark = .fromRGBO(99, 230, 226, 1);
  static const Color orangeDark = .fromRGBO(255, 159, 10, 1);
  static const Color yellowDark = .fromRGBO(255, 214, 10, 1);
  static const Color tealDark = .fromRGBO(64, 200, 224, 1);
  static const Color cyanDark = .fromRGBO(100, 210, 255, 1);
  static const Color indigoDark = .fromRGBO(94, 92, 230, 1);
  static const Color purpleDark = .fromRGBO(191, 90, 242, 1);
  static const Color pinkDark = .fromRGBO(255, 55, 95, 1);
  static const Color brownDark = .fromRGBO(172, 142, 104, 1);

  // Debug Colors
  static const Color debugColorEnemie = pinkLight;
  static const Color debugColorEnemieHitbox = indigoLight;
  static const Color debugColorTrap = black;
  static const Color debugColorTrapHitbox = greenDark;
  static const Color debugColorCollectibles = brownLight;
  static const Color debugColorCollectiblesHitbox = redLight;
  static const Color debugColorPlayerHitbox = black;
  static const Color debugColorMenu = purpleDark;
  static const Color debugColorParticle = grayDark6;
  static const Color debugColorParticleHitbox = redLight;
  static const Color debugColorWorldBlock = mintDark;

  // Game Colors
  static const Color whiteShimmer = .fromRGBO(114, 114, 114, 1);
  static const Color starColor = .fromRGBO(255, 255, 85, 1);
  static const Color backgroundColor = .fromRGBO(33, 31, 47, 1);
  static final Color screenBlur = black.withAlpha(40);
  static final Color tileBlur = black.withAlpha(56);
  static final Color overlayBlur = black.withAlpha(140);

  // Mini Map Block Colors
  static const Color brickBlock = .fromRGBO(207, 76, 94, 1);
  static const Color grasDarkBlock = .fromRGBO(218, 145, 80, 1);
  static const Color grasLightBlock = .fromRGBO(124, 160, 56, 1);
  static const Color dirtDarkBlock = .fromRGBO(150, 76, 71, 1);
  static const Color dirtLightBlock = .fromRGBO(175, 114, 89, 1);
  static const Color woodBlock = .fromRGBO(84, 45, 42, 1);
  static const Color platformBlock = woodBlock;
  static const Color goldBlock = yellowDark;
  static const Color orangeBlock = orangeDark;

  // Mini Map Marker Colors
  static const Color playerMarker = redDark;
  static const Color entityMarkerStandard = white;
  static const Color entityMarkerSpecial = grayLight4;

  // Mini Map Background Colors for Parallax Backgrounds
  static const ({Color a, Color b, Color c}) miniMapBgScene1 = (
    a: .fromARGB(255, 2, 121, 247),
    b: .fromARGB(255, 8, 117, 251),
    c: .fromARGB(255, 0, 127, 243),
  );
  static const ({Color a, Color b, Color c}) miniMapBgScene2 = (
    a: .fromARGB(255, 79, 107, 161),
    b: .fromARGB(255, 86, 112, 161),
    c: .fromARGB(255, 94, 117, 161),
  );
  static const ({Color a, Color b, Color c}) miniMapBgScene3 = (
    a: .fromARGB(255, 168, 216, 224),
    b: .fromARGB(255, 176, 224, 232),
    c: .fromARGB(255, 184, 232, 240),
  );
  static const ({Color a, Color b, Color c}) miniMapBgScene4 = (
    a: .fromARGB(255, 96, 68, 160),
    b: .fromARGB(255, 105, 75, 164),
    c: .fromARGB(255, 112, 82, 168),
  );
  static const ({Color a, Color b, Color c}) miniMapBgScene5 = (
    a: .fromARGB(255, 184, 184, 176),
    b: .fromARGB(255, 192, 192, 184),
    c: .fromARGB(255, 200, 200, 192),
  );
  static const ({Color a, Color b, Color c}) miniMapBgScene6 = (
    a: .fromARGB(255, 70, 70, 101),
    b: .fromARGB(255, 72, 72, 106),
    c: .fromARGB(255, 73, 73, 108),
  );

  // #### ALL TEXT STYLES ######################################

  // Dialog Text Styles
  static const TextStyle dialogTextStandard = TextStyle(
    fontFamily: 'Pixel Font',
    fontSize: 5.5,
    color: AppTheme.white,
    height: 1.2,
    decoration: .none,
  );
  static final TextStyle dialogHeadingStandard = dialogTextStandard.copyWith(fontSize: 8, height: 1.7);
  static final TextStyle textBtnStandard = dialogTextStandard.copyWith(fontSize: 9, height: 1.4);
  static const double dialogTextStandardHeight = 7;
  static const double textBtnStandardHeight = 13;

  // HUD Text Styles
  static final TextStyle hudText = dialogTextStandard.copyWith(fontSize: 8, height: 2.4);
  static final TextStyle pausedHeading = dialogTextStandard.copyWith(fontSize: 16, height: 3.4);
  static final TextStyle jumpBtn = dialogTextStandard.copyWith(fontSize: 12, height: 1.8);

  // Splash Text Styles
  static final TextStyle splashText = dialogTextStandard.copyWith(fontSize: 12);
  static final TextStyle splashDeveloperText = dialogTextStandard.copyWith(fontSize: 8);
}

extension TextStyleExtension on TextStyle {
  TextPaint get asTextPaint => TextPaint(style: this);
}
