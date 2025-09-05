import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/traps/saw_circle_single_saw.dart';
import 'package:pixel_adventure/game/utils/grid.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

/// A circular saw trap that moves one or two saws along the edges of a rectangular path.
///
/// The saws can travel clockwise or counterclockwise and automatically follow
/// a continuous loop around the trap’s bounding box. The path is normalized
/// to align with the game’s tile grid, ensuring consistent placement.
///
/// A single saw moves around the full loop, while a double-saw configuration
/// places a second saw on the opposite side of the path, keeping both in sync.
/// The saws act as passive collision areas that can interact with the [Player].
class SawCircle extends PositionComponent with HasGameReference<PixelAdventure> {
  // constructor parameters
  final bool _doubleSaw;
  final bool _clockwise;
  final Player _player;

  SawCircle({required bool doubleSaw, required bool clockwise, required Player player, required Vector2 position, required Vector2 size})
    : _clockwise = clockwise,
      _doubleSaw = doubleSaw,
      _player = player,
      super(size: _adjustedSize(size), position: position - Vector2.all(sawRadius));

  static Vector2 _adjustedSize(Vector2 input) {
    final gridSize = snapVectorToGrid(input);
    return Vector2(max(gridSize.x, PixelAdventure.circleWidthDefault), max(gridSize.y, PixelAdventure.circleHeightDefault)) +
        Vector2.all(sawRadius * 2);
  }

  // saw radius for the size
  static double sawRadius = SawCircleSingleSaw.gridSize.x / 2;

  // single saws
  late final SawCircleSingleSaw _saw1;
  late final SawCircleSingleSaw? _saw2;

  // path
  late final List<Vector2> _path;
  late final double _pathWidth;
  late final double _pathHeight;
  late final double _pathLength;

  // dinstance on path
  double _distanceOnPathSaw1 = 0;

  // movement
  final double _moveSpeed = 60; // [Adjustable]

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _setUpPath();
    _addSingleSaws();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    _movement(dt);
    super.update(dt);
  }

  void _initialSetup() {
    // debug
    if (PixelAdventure.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorTrap;
    }

    // general
    priority = PixelAdventure.trapBehindLayerLevel;
  }

  void _setUpPath() {
    _path = [
      Vector2.all(sawRadius), // top left
      Vector2(sawRadius, height - sawRadius), // bottom left
      Vector2(width - sawRadius, height - sawRadius), // bottom right
      Vector2(width - sawRadius, sawRadius), // top right
    ];
    _pathWidth = _path[3].x - _path[0].x;
    _pathHeight = _path[1].y - _path[0].y;
    _pathLength = _pathWidth * 2 + _pathHeight * 2;
  }

  void _addSingleSaws() {
    _saw1 = SawCircleSingleSaw(clockwise: _clockwise, player: _player, position: _path[0]);
    add(_saw1);

    // if needed, add the second saw
    if (_doubleSaw) {
      _saw2 = SawCircleSingleSaw(clockwise: _clockwise, player: _player, position: _path[2]);
      add(_saw2!);
    } else {
      _saw2 = null;
    }

    // by default, the saw moves counterclockwise.
    if (_clockwise) _distanceOnPathSaw1 = _pathWidth + _pathHeight * 2;
  }

  void _movement(double dt) {
    final moveStep = _nextStepOnPath(_distanceOnPathSaw1, dt);

    // add the new step to the position of the saw
    if (_clockwise && moveStep.x != 0) {
      // when moving clockwise, we have to reverse the movement on the top and bottom edges
      _saw1.position += moveStep * -1;
      if (_saw2 != null) _saw2.position += moveStep;
    } else {
      // default
      _saw1.position += moveStep;
      if (_saw2 != null) _saw2.position += moveStep * -1;
    }

    // add the new step to the distance on the path
    _distanceOnPathSaw1 += (moveStep.x + moveStep.y).abs();

    // the end of the path has been reached, at this point, you could simply use modulo arithmetic,
    // but we have a hard reset with absolute values, which eliminates potential inaccuracies in the long run => sync point
    if (_distanceOnPathSaw1 >= _pathLength) {
      _distanceOnPathSaw1 = 0;
      if (!_clockwise) {
        _saw1.position = _path[0];
        if (_saw2 != null) _saw2.position = _path[2];
      } else {
        _saw1.position = _path[3];
        if (_saw2 != null) _saw2.position = _path[1];
      }
    }
  }

  Vector2 _nextStepOnPath(double distance, double dt) {
    final move = _moveSpeed * dt;

    // check how far we are on the path and decide which direction to take based on that
    if (distance < _pathHeight) {
      // left edge down
      final moveStep = (distance + move).clamp(0, _pathHeight) - distance;
      return Vector2(0, moveStep);
    } else if (distance < _pathHeight + _pathWidth) {
      // bottom edge to the right
      final moveStep = (distance + move).clamp(0, _pathHeight + _pathWidth) - distance;
      return Vector2(moveStep, 0);
    } else if (distance < _pathLength - _pathWidth) {
      // right edge up
      final moveStep = (distance + move).clamp(0, _pathLength - _pathWidth) - distance;
      return Vector2(0, -moveStep);
    } else {
      // top edge to the left
      final moveStep = (distance + move).clamp(0, _pathLength) - distance;
      return Vector2(-moveStep, 0);
    }
  }
}
