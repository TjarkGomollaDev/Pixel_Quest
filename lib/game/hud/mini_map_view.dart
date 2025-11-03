import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/image_composition.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_quest.dart';

enum MiniMapPlayerMarker { circle, triangel }

class MiniMapView extends PositionComponent with HasGameReference<PixelQuest> {
  // constructor parameters
  final Sprite _sprite;
  final Vector2 _targetSize;
  final double _levelWidth;
  final Player _player;

  MiniMapView({
    required Sprite sprite,
    required Vector2 targetSize,
    required double levelWidth,
    required Player player,
    required super.position,
  }) : _sprite = sprite,
       _levelWidth = levelWidth,
       _targetSize = targetSize,
       _player = player,
       super(size: targetSize);

  // internal offset in pixels -> mini map coordinates
  double _offsetX = 0;

  // scales the sprite so that it matches the target height of the mini map
  late final double spriteToMiniMapScale;

  // ratio between real world width and mini map width
  late final double worldToMiniMapScale;

  // player marker
  static final MiniMapPlayerMarker _playerMarker = MiniMapPlayerMarker.circle; // [Adjustable]
  late final Paint _playerMarkerPaint;
  late final Vector2 _playerMarkerSize;

  @override
  FutureOr<void> onLoad() {
    _setUpScales();
    _setUpPlayerMarker();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    setWorldOffset(game.camera.visibleWorldRect.left - GameSettings.mapBorderWidth);
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, _targetSize.x, _targetSize.y));
    canvas.translate(-_offsetX, 0);
    _sprite.render(canvas, size: Vector2(_sprite.srcSize.x * spriteToMiniMapScale, _targetSize.y));
    _renderPlayerMarker(canvas);
    canvas.restore();
  }

  void _setUpScales() {
    spriteToMiniMapScale = _targetSize.y / _sprite.srcSize.y;
    worldToMiniMapScale = (_sprite.srcSize.x * spriteToMiniMapScale) / _levelWidth;
  }

  void _setUpPlayerMarker() {
    _playerMarkerPaint = Paint()..color = Colors.white;
    _playerMarkerSize = _player.hitboxSize * worldToMiniMapScale;
  }

  void _renderPlayerMarker(Canvas canvas) {
    final x = _player.hitbox.center.dx * worldToMiniMapScale;
    final y = _player.hitbox.center.dy * worldToMiniMapScale;

    return switch (_playerMarker) {
      MiniMapPlayerMarker.circle => _renderCircleMarker(canvas, x, y),
      MiniMapPlayerMarker.triangel => _renderTriangleMarker(canvas, x, y),
    };
  }

  void _renderCircleMarker(Canvas canvas, double x, double y) =>
      canvas.drawCircle(Offset(x, y), _playerMarkerSize.y / 2, _playerMarkerPaint);

  void _renderTriangleMarker(Canvas canvas, double x, double y) {
    final facingRight = _player.scale.x > 0;

    final Path triangle = Path()
      ..moveTo(x + (facingRight ? _playerMarkerSize.x / 2 : -_playerMarkerSize.x / 2), y)
      ..lineTo(x - (facingRight ? _playerMarkerSize.x / 2 : -_playerMarkerSize.x / 2), y - _playerMarkerSize.y / 2)
      ..lineTo(x - (facingRight ? _playerMarkerSize.x / 2 : -_playerMarkerSize.x / 2), y + _playerMarkerSize.y / 2)
      ..close();

    canvas.drawPath(triangle, _playerMarkerPaint);
  }

  /// Sets the visible area of the mini map based on the real world position.
  void setWorldOffset(double worldX) => _offsetX = (worldX * worldToMiniMapScale);
}
