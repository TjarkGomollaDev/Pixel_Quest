import 'dart:async';
import 'package:flame/components.dart';
import 'package:pixel_adventure/game/hud/mini_map_view.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_quest.dart';

class MiniMap extends PositionComponent with HasGameReference<PixelQuest> {
  // constructor parameters
  final Sprite _miniMapSprite;
  final double _levelWidth;
  final Player _player;

  MiniMap({required Sprite miniMapSprite, required double levelWidth, required Player player, required super.position})
    : _player = player,
      _levelWidth = levelWidth,
      _miniMapSprite = miniMapSprite {
    size = miniMapTargetSize + Vector2.all(_borderWidth * 2);
  }

  // the target size represents the size of the mini map view without the mini map frame
  late final MiniMapView _miniMapView;
  static final Vector2 miniMapTargetSize = Vector2(96, 48); // [Adjustable]
  static const double _borderWidth = 12; // [Adjustable]

  @override
  FutureOr<void> onLoad() {
    anchor = Anchor.topRight;
    setUpMiniMap();
    setUpFrame();
    return super.onLoad();
  }

  void setUpFrame() {
    final sprite = SpriteComponent(sprite: loadSprite(game, 'HUD/MiniMap Border 4.png'));
    add(sprite);

    // optical adjustment to compensate for the protruding ends of the frame
    position.y -= 3;
  }

  /// Sets up the MiniMap View.
  ///
  /// If there are borders in the source sprite (GameSettings.mapBorderWidth > 0),
  /// this method scales the mini map slightly so that the borders are hidden
  /// behind the frame. The Y scale is calculated to remove top/bottom borders,
  /// and the X scale is increased proportionally to preserve aspect ratio and
  /// hide left/right borders without stretching the sprite.
  void setUpMiniMap() {
    Vector2 targetSize;
    Vector2 viewPosition;

    if (GameSettings.mapBorderWidth != 0) {
      // calculate vertical scale to hide top and bottom borders
      final verticalScale = _miniMapSprite.srcSize.y / (_miniMapSprite.srcSize.y - 2);

      // compute scaled height and extra pixels added by scaling
      final scaledHeight = miniMapTargetSize.y * verticalScale;
      final extraHeight = scaledHeight - miniMapTargetSize.y;

      // scale width proportionally so left/right borders also disappear without distortion
      final scaledWidth = miniMapTargetSize.x + extraHeight;

      // scaled target size and an offset so that the view remains centered
      targetSize = Vector2(scaledWidth, scaledHeight);
      viewPosition = Vector2.all(_borderWidth) + (miniMapTargetSize - targetSize) / 2;
    } else {
      targetSize = miniMapTargetSize;
      viewPosition = Vector2.all(_borderWidth);
    }

    _miniMapView = MiniMapView(
      sprite: _miniMapSprite,
      targetSize: targetSize,
      levelWidth: _levelWidth,
      player: _player,
      position: viewPosition,
    );

    add(_miniMapView);
  }
}
