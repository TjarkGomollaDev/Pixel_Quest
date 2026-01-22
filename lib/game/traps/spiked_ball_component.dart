import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/level/player/player.dart';
import 'package:pixel_adventure/game/traps/spiked_ball.dart';
import 'package:pixel_adventure/game/utils/debug_components.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game/game_settings.dart';
import 'package:pixel_adventure/game/game.dart';

class ChainItem {
  final DebugSpriteComponent chainComponent;
  final double radiusToCenterOfChain;

  ChainItem({required this.chainComponent, required this.radiusToCenterOfChain});
}

class SpikedBallComponent extends PositionComponent with HasGameReference<PixelQuest> {
  // constructor parameters
  final double _radius;
  final int _swingArcDeg;
  final int _swingSpeed;
  final bool _startLeft;
  final Player _player;

  SpikedBallComponent({
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
       _player = player {
    // in this case, we create the spiked ball in the constructor and not in onLoad(), so that we have access to it
    // immediately after creation via the getter, this is important for the mini map
    _createSpikedBall();
  }

  // animation settings
  static final Vector2 _textureSize = Vector2.all(8);
  static const String _pathChain = 'Traps/Spiked Ball/Chain (8x8).png';

  // center point
  late final Vector2 _centerPoint;

  // spiked ball
  late final SpikedBall _spikedBall;
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

  // getter
  SpikedBall get ball => _spikedBall;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _setUpHalfArc();
    _addSpikedBall();
    _setUpChain();
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
    if (GameSettings.customDebugMode) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
    }

    // general
    priority = GameSettings.trapBehindLayerLevel;
    _centerPoint = Vector2(size.x / 2, SpikedBall.gridSize.x / 2);
  }

  void _createSpikedBall() {
    _radiusToCenterOfSpikedBall = _radius - SpikedBall.gridSize.x / 2;
    _spikedBall = SpikedBall(player: _player);

    // only relevant for mini map not for the actual functionality
    _spikedBall.yMoveRange = Vector2(
      position.y + _spikedBall.position.y + _spikedBall.height / 2,
      position.y + height - _spikedBall.position.y - _spikedBall.height / 2,
    );
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

  void _addSpikedBall() {
    add(_spikedBall);

    // initially align the spiked ball
    _transformSpikedBall();
  }

  void _setUpChain() {
    final count = (_radius - GameSettings.tileSize / 2 - SpikedBall.gridSize.x) / GameSettings.tileSize * 2 + 1;
    final baseRadius = GameSettings.tileSize / 2;
    final chainSprite = loadSprite(game, _pathChain);
    for (var i = 0; i < count; i++) {
      final chainComponent = DebugSpriteComponent(sprite: chainSprite)
        ..anchor = Anchor.center
        ..debugMode = GameSettings.customDebugMode
        ..debugColor = AppTheme.debugColorTrapHitbox;

      final chainItem = ChainItem(chainComponent: chainComponent, radiusToCenterOfChain: baseRadius + i * _textureSize.x);
      _chainList.add(chainItem);
      add(chainComponent);
    }

    // initially align the chain
    _transformChain();
  }

  void _setUpSpeed() {
    _scaledSpeed = _swingSpeed / _radiusToCenterOfSpikedBall / _halfArcRad;
  }

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
