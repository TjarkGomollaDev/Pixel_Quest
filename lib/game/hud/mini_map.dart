import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/game/hud/mini_map_view.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/pixel_quest.dart';

class MiniMap extends PositionComponent with HasGameReference<PixelQuest> {
  // constructor parameters
  final Sprite miniMapSprite;
  final double levelWidth;
  final Player player;

  MiniMap({required this.miniMapSprite, required this.levelWidth, required this.player, required super.position}) {
    size = miniMapTargetSize + Vector2.all(borderWidth * 2);
  }

  late final MiniMapView _miniMapView;
  static final Vector2 miniMapTargetSize = Vector2(94, 46); // [Adjustable]
  static const double borderWidth = 9; // [Adjustable]

  @override
  FutureOr<void> onLoad() {
    anchor = Anchor.topRight;
    setUpMiniMap();
    setUpFrame();

    return super.onLoad();
  }

  void setUpFrame() {
    final rect = RectangleComponent.fromRect(
      Rect.fromLTWH(borderWidth / 2, borderWidth / 2, size.x - borderWidth, size.y - borderWidth),
      paint: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..color = Colors.white,
    );
    add(rect);

    final sprite = SpriteComponent(sprite: loadSprite(game, 'HUD/MiniMap Border.png'));
    add(sprite);
  }

  void setUpMiniMap() {
    _miniMapView = MiniMapView(
      sprite: miniMapSprite,
      targetSize: miniMapTargetSize,
      levelWidth: levelWidth,
      player: player,
      position: Vector2.all(borderWidth),
    );
    add(_miniMapView);
  }
}
