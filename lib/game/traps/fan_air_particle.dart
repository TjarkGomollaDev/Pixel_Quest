import 'dart:async';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/utils/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class FanAirParticle extends SpriteComponent with PlayerCollision, HasGameReference<PixelAdventure>, CollisionCallbacks {
  // constructor parameters
  final double _streamTop;
  final double _streamLeft;
  final double _streamRight;
  final Vector2 basePosition;
  final double baseWidth;

  FanAirParticle({
    required double streamTop,
    required double streamLeft,
    required double streamRight,
    required this.basePosition,
    required this.baseWidth,
  }) : _streamTop = streamTop,
       _streamLeft = streamLeft,
       _streamRight = streamRight;

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
  final double _moveSpeed = 280; // [Adjustable]
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
    if (PixelAdventure.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorParticle;
    }

    // general
    priority = PixelAdventure.trapParticlesLayerLevel;
  }

  void _loadSprite() => sprite = loadSprite(game, _path);

  void _setUpParticle() {
    // size
    size = _sizeList[_random.nextInt(_sizeList.length)];
    final particleOffset = size.x * _ratioParticleBackground;

    // position
    final spawnX = basePosition.x - particleOffset + (baseWidth - size.x + particleOffset * 2) * _random.nextDouble();
    final spawnY = basePosition.y - size.y + particleOffset;
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
