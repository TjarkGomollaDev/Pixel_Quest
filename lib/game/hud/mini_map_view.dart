import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/image_composition.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/hud/entity_on_mini_map.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/pixel_quest.dart';

enum MiniMapPlayerMarker { circle, triangel }

class MiniMapView extends PositionComponent with HasGameReference<PixelQuest> {
  // constructor parameters
  final Sprite _sprite;
  final Vector2 _targetSize;
  final double _levelWidth;
  final Player _player;
  final List<EntityOnMiniMap> _entities;

  MiniMapView({
    required Sprite sprite,
    required Vector2 targetSize,
    required double levelWidth,
    required Player player,
    required List<EntityOnMiniMap> entities,
    required super.position,
  }) : _sprite = sprite,
       _levelWidth = levelWidth,
       _targetSize = targetSize,
       _player = player,
       _entities = entities,
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

  // precomputed map limits
  late final double _mapMaxOffset;
  late final double _halfTargetWidth;

  // player marker
  static final MiniMapPlayerMarker _playerMarker = MiniMapPlayerMarker.triangel; // [Adjustable]
  late final Paint _playerMarkerPaint;
  late final double _playerMarkerSize;

  // entity marker
  late final Paint _entityMarkerPaint;

  @override
  FutureOr<void> onLoad() {
    _setUpScales();
    _setUpMarker();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    _setWorldOffset(_player.hitbox.center.dx);
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, _targetSize.x, _targetSize.y));
    canvas.translate(-_offsetX, 0);
    _sprite.render(canvas, size: Vector2(_sprite.srcSize.x * _spriteToMiniMapScale, _targetSize.y));
    _renderEntities(canvas);
    _renderPlayerMarker(canvas);
    canvas.restore();
  }

  void _setUpScales() {
    _spriteToMiniMapScale = _targetSize.y / _sprite.srcSize.y;
    _worldToMiniMapScale = (_sprite.srcSize.x * _spriteToMiniMapScale) / _levelWidth;

    _mapMaxOffset = (_sprite.srcSize.x * _spriteToMiniMapScale) - _targetSize.x;
    _halfTargetWidth = _targetSize.x / 2;
  }

  void _setUpMarker() {
    _playerMarkerPaint = Paint()..color = AppTheme.playerMarker;
    _playerMarkerSize = _player.hitboxSize.y * _worldToMiniMapScale;
    _entityMarkerPaint = Paint();
  }

  /// Sets the visible area of the mini map based on the real world position.
  void _setWorldOffset(double worldX) {
    _offsetX = (worldX * _worldToMiniMapScale - _halfTargetWidth).clamp(0, _mapMaxOffset);
    _visibleMinX = _offsetX - _visibleBuffer;
    _visibleMaxX = _offsetX + _targetSize.x + _visibleBuffer;
  }

  void _renderPlayerMarker(Canvas canvas) {
    final x = _player.hitbox.center.dx * _worldToMiniMapScale;
    final y = _player.hitbox.center.dy * _worldToMiniMapScale;

    return switch (_playerMarker) {
      MiniMapPlayerMarker.circle => _renderCircleMarker(canvas, x, y),
      MiniMapPlayerMarker.triangel => _renderTriangleMarker(canvas, x, y),
    };
  }

  void _renderCircleMarker(Canvas canvas, double x, double y) => canvas.drawCircle(Offset(x, y), _playerMarkerSize / 2, _playerMarkerPaint);

  void _renderTriangleMarker(Canvas canvas, double x, double y) {
    final facingRight = _player.scale.x > 0;

    final Path triangle = Path()
      ..moveTo(x + (facingRight ? _playerMarkerSize / 2 : -_playerMarkerSize / 2), y)
      ..lineTo(x - (facingRight ? _playerMarkerSize / 2 : -_playerMarkerSize / 2), y - _playerMarkerSize / 2)
      ..lineTo(x - (facingRight ? _playerMarkerSize / 2 : -_playerMarkerSize / 2), y + _playerMarkerSize / 2)
      ..close();

    canvas.drawPath(triangle, _playerMarkerPaint);
  }

  void _renderEntities(Canvas canvas) {
    for (final entity in _entities) {
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
      }
    }
  }

  void _renderEntityCircleMarker(Canvas canvas, Vector2 position, double size) =>
      canvas.drawCircle(Offset(position.x, position.y - size / 2), size / 2, _entityMarkerPaint);

  void _renderEntitySquareMarker(Canvas canvas, Vector2 pos, double size) =>
      canvas.drawRect(Rect.fromLTWH(pos.x - size / 2, pos.y - size, size, size), _entityMarkerPaint);
}
