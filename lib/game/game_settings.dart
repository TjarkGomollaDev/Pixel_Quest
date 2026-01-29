import 'package:flame/extensions.dart';

abstract class GameSettings {
  // custom debug mode
  static const bool testMode = true;
  static const bool customDebugMode = false;

  // mobile cotrols
  static const bool showMobileControls = true;
  static const double joystickRadius = 42;
  static const double knobRadius = 20;
  static const double jumpBtnRadius = 28;

  // tiled map dimensions
  static const double tileSize = 16;
  static const double mapHeight = 320;
  static const double mapBorderWidth = tileSize / 2;
  static const bool hasBorder = mapBorderWidth != 0;

  // animation settings
  static const double stepTime = 0.05;

  // hud
  static const double hudVerticalMargin = 10;
  static const double hudHorizontalMargin = 40;
  static const double hudBtnSpacing = 6;
  static const double hudBtnTextSpacing = 4;
  static const double hudSectionSpacing = 18;
  static const double hudBgTileSize = 19;

  // in which layers the various objects are rendered
  static const int mapLayerLevel = 0;
  static const int backgroundLayerLevel = -5;
  static const int flashEffectLayerLevel = -4;
  static const int enemieLayerLevel = 10;
  static const int enemieBulletLayerLevel = 9;
  static const int enemieParticleLayerLevel = 8;
  static const int trapLayerLevel = 2;
  static const int trapParticlesLayerLevel = 1;
  static const int trapBehindLayerLevel = -1;
  static const int collectiblesLayerLevel = 5;
  static const int spotlightAnimationLayer = 18;
  static const int spotlightAnimationContentLayer = 19;
  static const int playerLayerLevel = 20;
  static const int hudElementsLayer = 30;
  static const int chracterPicker = 10;

  // default spawn values
  static const bool isLeftDefault = true;
  static const bool isVerticalDefault = false;
  static const double delay = 0;
  static const bool doubleShotDefault = false;
  static const bool showPath = true;
  static const bool doubleSawDefault = false;
  static const bool clockwiseDefault = false;
  static const bool fanAlwaysOnDefault = true;
  static const int sideDefault = 1;
  static const double offsetNegDefault = 1;
  static const double offsetPosDefault = 1;
  static const double extandNegAttackDefault = 0;
  static const double extandPosAttackDefault = 0;
  static const double circleWidthDefault = 6;
  static const double circleHeightDefault = 4;
  static const int spikedBallRadiusDefault = 3;
  static const bool spikedBallStartLeft = false;
  static const int spikedBallSwingArcDec = 170;
  static const int spikedBallSwingSpeed = 320;

  // parallax background
  static final Vector2 parallaxBaseVelocityLevel = Vector2(0.5, 0);
  static final Vector2 parallaxBaseVelocityLoadingOverlay = Vector2(10, 0);
  static final Vector2 coloredBaseVelocity = Vector2(0, 40);
  static final Vector2 velocityMultiplierDelta = Vector2(1.8, 0);
}
