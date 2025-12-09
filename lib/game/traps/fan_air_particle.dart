import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_quest.dart';

class FanAirParticle extends SpriteComponent with HasGameReference<PixelQuest> {
  // constructor parameters
  final double _streamTop;
  final double _streamLeft;
  final double _streamRight;
  final Vector2 _basePosition;
  final double _baseWidth;
  final double? _scaleFactor;

  FanAirParticle({
    required double streamTop,
    required double streamLeft,
    required double streamRight,
    required Vector2 basePosition,
    required double baseWidth,
    double? scaleFactor,
  }) : _streamTop = streamTop,
       _streamLeft = streamLeft,
       _streamRight = streamRight,
       _basePosition = basePosition,
       _baseWidth = baseWidth,
       _scaleFactor = scaleFactor;

  // size
  static final List<Vector2> _sizeList = [Vector2.all(14), Vector2.all(12), Vector2.all(8), Vector2.all(6)];

  // opacity
  static final List<double> _opacityList = [0.2, 0.25, 0.3, 0.4];

  // animation settings
  static const String _path = 'Other/Dust Particle (16x16).png';
  static const double _ratioParticleBackground = 8 / 16 / 2;

  // particle stream borders
  late final Vector3 _borders;

  // movement
  final double _moveSpeed = 400; // [Adjustable]
  late Vector2 _velocity;

  // random
  final Random _random = Random();

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadSprite();
    _setUpParticle();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    _move(dt);
    super.update(dt);
  }

  void _initialSetup() {
    // debug
    if (GameSettings.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorParticle;
    }

    // general
    priority = GameSettings.trapParticlesLayerLevel;
  }

  void _loadSprite() => sprite = loadSprite(game, _path);

  void _setUpParticle() {
    // size
    size = _sizeList[_random.nextInt(_sizeList.length)] * (_scaleFactor ?? 1);
    final particleOffset = size.x * _ratioParticleBackground;

    // position
    final spawnX = _basePosition.x - particleOffset + (_baseWidth - size.x + particleOffset * 2) * _random.nextDouble();
    final spawnY = _basePosition.y - size.y + particleOffset;
    position = Vector2(spawnX, spawnY);

    // velocity
    final horizontalMoveSpeed = (_random.nextDouble() - 0.5) * 120;
    _velocity = Vector2(horizontalMoveSpeed, -_moveSpeed);

    // opacity
    opacity = _opacityList[_random.nextInt(_opacityList.length)];

    // borders
    _borders = Vector3(_streamTop - particleOffset, _streamLeft - particleOffset, _streamRight + particleOffset); // top, left and right
  }

  void _move(double dt) {
    // bounce off the left and right borders
    if (position.x <= _borders.y || position.x + size.x >= _borders.z) _velocity.x = -_velocity.x;

    // despawn when reaching the upper border
    if (position.y <= _borders.x) removeFromParent();

    final newPosition = position + _velocity * dt;
    position.x = newPosition.x.clamp(_borders.y, _borders.z);
    position.y = newPosition.y.clamp(_borders.x, double.infinity);
  }
}
