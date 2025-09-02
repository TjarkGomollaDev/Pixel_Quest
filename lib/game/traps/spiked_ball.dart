import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/traps/spiked_ball_ball.dart';
import 'package:pixel_adventure/game/utils/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class ChainItem {
  final DebugSpriteComponent chainComponent;
  final double radiusToCenterOfChain;

  ChainItem({required this.chainComponent, required this.radiusToCenterOfChain});
}

class SpikedBall extends PositionComponent with HasGameReference<PixelAdventure> {
  // constructor parameters
  final double _radius;
  final int _swingArcDeg;
  final int _swingSpeed;
  final bool _startLeft;
  final Player _player;

  SpikedBall({
    required double radius,
    required int swingArcDeg,
    required int swingSpeed,
    required bool startLeft,
    required Player player,
    required super.position,
    required super.size,
  }) : _radius = radius,
       _swingArcDeg = swingArcDeg,
       _swingSpeed = swingSpeed,
       _startLeft = startLeft,
       _player = player;

  // animation settings
  static final Vector2 _textureSize = Vector2.all(8);
  static const String _pathChain = 'Traps/Spiked Ball/Chain (8x8).png';

  // center point
  late final Vector2 _centerPoint;

  // spiked ball
  late final SpikedBallBall _spikedBall;
  late final double _radiusToCenterOfSpikedBall;

  // list of all chain elements
  final List<ChainItem> _chainList = [];

  // half arc
  late final double _halfArcRad;
  late final double _halfArcRadStart;
  late final double _halfArcRadEnd;

  // movement
  late int _moveDirection;
  late final double _scaledSpeed;
  late double _angle;
  late double _time;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _setUpHalfArc();
    _createSpikedBall();
    _creatChain();
    _setUpSpeed();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    _movement(dt);
    super.update(dt);
  }

  void _initialSetup() {
    // debug
    if (game.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
    }

    // general
    priority = PixelAdventure.trapBehindLayerLevel;
    _centerPoint = Vector2(size.x / 2, SpikedBallBall.gridSize.x / 2);
  }

  void _setUpHalfArc() {
    // convert deg to rad
    _halfArcRad = _swingArcDeg.clamp(40, 180) * pi / 180;

    // define the start and end points of the half arc
    _halfArcRadStart = pi / 2 - _halfArcRad / 2;
    _halfArcRadEnd = _halfArcRadStart + _halfArcRad;
    _angle = _startLeft ? _halfArcRadEnd : _halfArcRadStart;

    // start point for cosine curve
    _time = _startLeft ? 0 : pi;
  }

  void _createSpikedBall() {
    _radiusToCenterOfSpikedBall = _radius - SpikedBallBall.gridSize.x / 2;
    _spikedBall = SpikedBallBall(player: _player);
    add(_spikedBall);

    // initially align the spiked ball
    _transformSpikedBall();
  }

  void _creatChain() {
    final count = (_radius - PixelAdventure.tileSize / 2 - SpikedBallBall.gridSize.x) / PixelAdventure.tileSize * 2 + 1;
    final baseRadius = PixelAdventure.tileSize / 2;
    final chainSprite = loadSprite(game, _pathChain);
    for (var i = 0; i < count; i++) {
      final chainComponent = DebugSpriteComponent(sprite: chainSprite)
        ..anchor = Anchor.center
        ..debugMode = game.customDebug
        ..debugColor = AppTheme.debugColorTrapHitbox;

      final chainItem = ChainItem(chainComponent: chainComponent, radiusToCenterOfChain: baseRadius + i * _textureSize.x);
      _chainList.add(chainItem);
      add(chainComponent);
    }

    // initially align the chain
    _transformChain();
  }

  void _setUpSpeed() => _scaledSpeed = _swingSpeed / _radiusToCenterOfSpikedBall / _halfArcRad;

  void _movement(double dt) {
    // check whether we have reached the ends of our arc
    if (_angle <= _halfArcRadStart) {
      _moveDirection = 1;
    } else if (_angle >= _halfArcRadEnd) {
      _moveDirection = -1;
    }

    // with the cosine curve, we can represent a realistic swing, cosine provides values between -1 and 1
    _time += dt * _scaledSpeed * _moveDirection;
    final t = cos(_time);
    final normalized = (t + 1) / 2;

    // movement
    final newAngle = _halfArcRadStart + normalized * (_halfArcRadEnd - _halfArcRadStart);
    _angle = newAngle.clamp(_halfArcRadStart, _halfArcRadEnd);

    // transform to the new angle
    _transformSpikedBall();
    _transformChain();
  }

  void _transformSpikedBall() => _applyTransform(_spikedBall, _radiusToCenterOfSpikedBall);

  void _transformChain() {
    for (var chainItem in _chainList) {
      _applyTransform(chainItem.chainComponent, chainItem.radiusToCenterOfChain);
    }
  }

  void _applyTransform(PositionComponent component, double radius) {
    final offset = Vector2(cos(_angle) * radius, sin(_angle) * radius);
    component.position = _centerPoint + offset;

    // the top side of the chain should always face the center
    component.angle = _angle - pi / 2;
  }
}
