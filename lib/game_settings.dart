import 'package:flame/extensions.dart';

abstract class GameSettings {
  // custom debug mode
  static const bool customDebug = false;

  // mobile
  static const bool showMobileControls = false;

  // tiled map dimensions
  static const double tileSize = 16;
  static const double mapHeight = 320;
  static const double mapBorderWidth = tileSize / 2;

  // animation settings
  static const double stepTime = 0.05;
  static const double finishSpotlightAnimationRadius = 60;

  // margin HUD elements
  static const double hudMargin = 32;
  static const double hudMobileControlsSize = 64;

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
}
