import 'package:flutter/material.dart';

abstract class AppTheme {
  // #### ALL COLORS ###########################################

  // Black, White and Transparent
  static const white = Color.fromRGBO(255, 255, 255, 1);
  static const black = Color.fromRGBO(0, 0, 0, 1);
  static const transparent = Color.fromARGB(0, 0, 0, 0);

  // Gray Colors -> LIGHT
  static const grayLight1 = Color.fromRGBO(126, 125, 130, 1);
  static const grayLight2 = Color.fromRGBO(174, 174, 178, 1);
  static const grayLight3 = Color.fromRGBO(199, 199, 204, 1);
  static const grayLight4 = Color.fromRGBO(209, 209, 234, 1);
  static const grayLight5 = Color.fromRGBO(229, 229, 234, 1);
  static const grayLight6 = Color.fromRGBO(242, 242, 247, 1);

  // Gray Colors -> DARK
  static const grayDark1 = Color.fromRGBO(142, 142, 147, 1);
  static const grayDark2 = Color.fromRGBO(99, 99, 102, 1);
  static const grayDark3 = Color.fromRGBO(72, 72, 74, 1);
  static const grayDark4 = Color.fromRGBO(58, 58, 60, 1);
  static const grayDark5 = Color.fromRGBO(44, 44, 46, 1);
  static const grayDark6 = Color.fromRGBO(28, 28, 30, 1);

  // Colors -> LIGHT
  static const blueLight = Color.fromRGBO(0, 122, 255, 1);
  static const redLight = Color.fromRGBO(255, 59, 48, 1);
  static const greenLight = Color.fromRGBO(52, 199, 89, 1);
  static const mintLight = Color.fromRGBO(0, 199, 190, 1);
  static const orangeLight = Color.fromRGBO(255, 149, 0, 1);
  static const yellowLight = Color.fromRGBO(255, 204, 0, 1);
  static const tealLight = Color.fromRGBO(48, 176, 199, 1);
  static const cyanLight = Color.fromRGBO(50, 173, 230, 1);
  static const indigoLight = Color.fromRGBO(88, 86, 214, 1);
  static const purpleLight = Color.fromRGBO(175, 82, 222, 1);
  static const pinkLight = Color.fromRGBO(255, 45, 85, 1);
  static const brownLight = Color.fromRGBO(162, 132, 94, 1);

  // Colors -> DARK
  static const blueDark = Color.fromRGBO(10, 132, 255, 1);
  static const redDark = Color.fromRGBO(255, 69, 58, 1);
  static const greenDark = Color.fromRGBO(48, 209, 88, 1);
  static const mintDark = Color.fromRGBO(99, 230, 226, 1);
  static const orangeDark = Color.fromRGBO(255, 159, 10, 1);
  static const yellowDark = Color.fromRGBO(255, 214, 10, 1);
  static const tealDark = Color.fromRGBO(64, 200, 224, 1);
  static const cyanDark = Color.fromRGBO(100, 210, 255, 1);
  static const indigoDark = Color.fromRGBO(94, 92, 230, 1);
  static const purpleDark = Color.fromRGBO(191, 90, 242, 1);
  static const pinkDark = Color.fromRGBO(255, 55, 95, 1);
  static const brownDark = Color.fromRGBO(172, 142, 104, 1);

  // debug colors
  static const debugColorEnemie = pinkLight;
  static const debugColorEnemieHitbox = indigoLight;
  static const debugColorTrap = black;
  static const debugColorTrapHitbox = greenDark;
  static const debugColorCollectibles = brownLight;
  static const debugColorCollectiblesHitbox = redLight;
  static const debugColorPlayerHitbox = black;
  static const debugColorMenu = purpleDark;
  static const debugColorParticle = grayDark2;
  static const debugColorParticleHitbox = grayLight1;
  static const debugColorWorldBlock = mintDark;

  // ingame text
  static const ingameText = white;
  static final ingameTextShimmer = Color.fromRGBO(114, 114, 114, 1);
  static final starColor = Color.fromRGBO(255, 255, 85, 1);
  static final screenBlur = black.withAlpha(40);
  static final tileBlur = black.withAlpha(56);
}
