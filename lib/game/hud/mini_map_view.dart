import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/image_composition.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/hud/entity_on_mini_map.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/pixel_quest.dart';
import 'package:vector_math/vector_math_64.dart' as math64;

/// A purely visual mini map component that renders a horizontal slice of the level.
///
/// This class performs **no game logic, world calculations, or entity management**.
/// All data required for rendering (pre-rendered foreground sprite, background pattern,
/// entity marker lists, player reference, world width, etc.) is fully prepared and
/// passed into the constructor.
///
/// MiniMapView is strictly responsible for:
/// - visualizing the given map sprite at a scaled size,
/// - visualizung a background pattern (repeating shader)
/// - rendering entities in two separate layers (behind/above foreground),
/// - drawing the player marker,
/// - handling horizontal scrolling based solely on the provided player position.
class MiniMapView extends PositionComponent with HasGameReference<PixelQuest>, HasVisibility {
  // constructor parameters
  final Sprite _spriteForeground;
  final Vector2 _targetSize;
  final double _levelWidth;
  final Player _player;
  final List<EntityOnMiniMap> _entitiesAboveForeground;
  final List<EntityOnMiniMap> _entitiesBehindForeground;

  MiniMapView({
    required Sprite sprite,
    required Vector2 targetSize,
    required double levelWidth,
    required Player player,
    required List<EntityOnMiniMap> entitiesAboveForeground,
    required List<EntityOnMiniMap> entitiesBehindForeground,
    required super.position,
  }) : _spriteForeground = sprite,
       _levelWidth = levelWidth,
       _targetSize = targetSize,
       _player = player,
       _entitiesAboveForeground = entitiesAboveForeground,
       _entitiesBehindForeground = entitiesBehindForeground,
       super(size: targetSize);

  // internal horizontal offset in mini map coordinates used to "scroll" the map when the player moves
  double _offsetX = 0;

  // cached visible horizontal range in mini map coordinates,
  // used to skip rendering entities that are outside the current view (+ small buffer)
  double _visibleMinX = 0;
  double _visibleMaxX = 0;
  static const double _visibleBuffer = 10;

  // scales the sprite so that it matches the target height of the mini map
  late final double _spriteToMiniMapScale;

  // ratio between real world width and mini map width
  late final double _worldToMiniMapScale;

  // scaled map width
  late final double _mapWidth;

  // precomputed map limits
  late final double _mapMaxOffset;
  late final double _halfTargetWidth;

  // used for manual scrolling
  static const double scrollAmount = 10; // [Adjustable]
  bool _manualScrollActive = false;
  double _lastPlayerX = 0;

  // map background
  late final Paint _backgroundPaint;

  // player marker
  late final PlayerMiniMapMarkerType _playerMarker; // [Adjustable]
  late final Paint _playerMarkerPaint;
  late final double _playerMarkerSize;

  // entity marker
  late final Paint _entityMarkerPaint;
  late final Vector2 _entityMarkerPlatformSize;

  @override
  FutureOr<void> onLoad() {
    _setUpScales();
    _setUpBackground();
    _setUpMarker();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    final playerX = _player.hitbox.center.dx;

    // detect if the player moved horizontally, if that is the case automatic follow mode should re-activate
    if ((playerX - _lastPlayerX).abs() > 0.1) _manualScrollActive = false;
    if (!_manualScrollActive) _setWorldOffset(playerX * _worldToMiniMapScale - _halfTargetWidth);
    _lastPlayerX = playerX;

    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, _targetSize.x, _targetSize.y));
    canvas.translate(-_offsetX, 0);

    // background
    canvas.drawRect(Rect.fromLTWH(0, 0, _mapWidth, _targetSize.y), _backgroundPaint);

    // markers between background and foreground
    _renderEntityMarkers(canvas, _entitiesBehindForeground);

    // foreground
    _spriteForeground.render(canvas, size: Vector2(_mapWidth, _targetSize.y));

    // markers above foreground
    _renderEntityMarkers(canvas, _entitiesAboveForeground);
    _renderPlayerMarker(canvas);

    canvas.restore();
  }

  /// Computes all scaling values based solely on provided constructor data.
  void _setUpScales() {
    _spriteToMiniMapScale = _targetSize.y / _spriteForeground.srcSize.y;
    _worldToMiniMapScale = _spriteForeground.srcSize.x * _spriteToMiniMapScale / _levelWidth;
    _mapWidth = _spriteForeground.srcSize.x * _spriteToMiniMapScale;
    _mapMaxOffset = _mapWidth - _targetSize.x;
    _halfTargetWidth = _targetSize.x / 2;
  }

  /// Creates the background paint using a pre-rendered repeating pattern
  /// provided by the game. No texture generation happens here.
  void _setUpBackground() {
    // create a matrix that scales the background pattern to match the mini map scale
    final shaderMatrix = math64.Matrix4.identity()..scaleByVector3(math64.Vector3(_spriteToMiniMapScale, _spriteToMiniMapScale, 1));

    // create a repeatable shader paint using the pre-rendered background texture from the game class
    _backgroundPaint = Paint()
      ..shader = ImageShader(game.miniMapBackgroundPattern, TileMode.repeated, TileMode.repeated, shaderMatrix.storage);
  }

  /// Initializes marker sizes and paints for the player and all entity markers.
  void _setUpMarker() {
    _playerMarker = game.storageCenter.settings.playerMarker;
    _playerMarkerPaint = Paint()..color = AppTheme.playerMarker;
    _playerMarkerSize = _player.hitboxSize.y * _worldToMiniMapScale;
    _entityMarkerPaint = Paint();
    _entityMarkerPlatformSize = Vector2(2, 1) * _spriteToMiniMapScale;
  }

  /// Sets the visible area of the mini map based on a x position in the mini map.
  void _setWorldOffset(double miniMapX) {
    _offsetX = (miniMapX).clamp(0, _mapMaxOffset);
    _visibleMinX = _offsetX - _visibleBuffer;
    _visibleMaxX = _offsetX + _targetSize.x + _visibleBuffer;
  }

  /// Scrolls the minimap manually by a fixed amount.
  /// The `direction` parameter determines the scroll direction:
  ///   -1 → scroll left
  ///    1 → scroll right
  ///
  /// Once this function is called, the minimap will stop automatically
  /// following the player until the player moves again.
  void scrollManual(int direction) {
    _manualScrollActive = true;
    _setWorldOffset(_offsetX + scrollAmount * direction);
  }

  /// Renders the player marker in the mini map using the chosen marker style.
  void _renderPlayerMarker(Canvas canvas) {
    final x = _player.hitbox.center.dx * _worldToMiniMapScale;
    final y = _player.hitbox.center.dy * _worldToMiniMapScale;

    return switch (_playerMarker) {
      PlayerMiniMapMarkerType.circle => _renderCirclePlayerMarker(canvas, x, y),
      PlayerMiniMapMarkerType.triangel => _renderTrianglePlayerMarker(canvas, x, y),
    };
  }

  /// Draws a circular player marker.
  void _renderCirclePlayerMarker(Canvas canvas, double x, double y) =>
      canvas.drawCircle(Offset(x, y), _playerMarkerSize / 2, _playerMarkerPaint);

  /// Draws a triangle player marker.
  void _renderTrianglePlayerMarker(Canvas canvas, double x, double y) {
    final facingRight = _player.scale.x > 0;

    final Path triangle = Path()
      ..moveTo(x + (facingRight ? _playerMarkerSize / 2 : -_playerMarkerSize / 2), y)
      ..lineTo(x - (facingRight ? _playerMarkerSize / 2 : -_playerMarkerSize / 2), y - _playerMarkerSize / 2)
      ..lineTo(x - (facingRight ? _playerMarkerSize / 2 : -_playerMarkerSize / 2), y + _playerMarkerSize / 2)
      ..close();

    canvas.drawPath(triangle, _playerMarkerPaint);
  }

  /// Draws all markers for a given list of entities.
  void _renderEntityMarkers(Canvas canvas, List<EntityOnMiniMap> entities) {
    for (final entity in entities) {
      final position = entity.markerPosition * _worldToMiniMapScale;

      // check: only render if within the visible area
      if (position.x < _visibleMinX || position.x > _visibleMaxX) continue;

      final size = entity.marker.size * _worldToMiniMapScale;
      _entityMarkerPaint.color = entity.marker.color;

      switch (entity.marker.type) {
        case EntityMiniMapMarkerType.circle:
          _renderEntityCircleMarker(canvas, position, size);
          break;
        case EntityMiniMapMarkerType.square:
          _renderEntitySquareMarker(canvas, position, size);
          break;
        case EntityMiniMapMarkerType.platform:
          _renderEntityPlatformMarker(canvas, position);
      }
    }
  }

  /// Draws a circular entity marker.
  void _renderEntityCircleMarker(Canvas canvas, Vector2 position, double size) =>
      canvas.drawCircle(Offset(position.x, position.y - size / 2), size / 2, _entityMarkerPaint);

  /// Draws a square entity marker.
  void _renderEntitySquareMarker(Canvas canvas, Vector2 position, double size) =>
      canvas.drawRect(Rect.fromLTWH(position.x - size / 2, position.y - size, size, size), _entityMarkerPaint);

  /// Draws a platform-style rectangular entity marker.
  void _renderEntityPlatformMarker(Canvas canvas, Vector2 position) =>
      canvas.drawRect(Rect.fromLTWH(position.x, position.y, _entityMarkerPlatformSize.x, _entityMarkerPlatformSize.y), _entityMarkerPaint);

  void show() => isVisible = true;
  void hide() => isVisible = false;
}
