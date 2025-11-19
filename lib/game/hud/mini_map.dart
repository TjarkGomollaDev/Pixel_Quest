import 'dart:async';
import 'package:flame/components.dart';
import 'package:pixel_adventure/data/static/metadata/level_metadata.dart';
import 'package:pixel_adventure/game/hud/entity_on_mini_map.dart';
import 'package:pixel_adventure/game/hud/mini_map_view.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_quest.dart';

/// A container component for displaying the mini map with a decorative frame.
/// All actual drawing and calculations are handled by MiniMapView.
/// MiniMap only adjusts the `MiniMapView` to account
/// for frame borders and optical alignment.
///
/// Responsibilities:
/// - scale and offset the mini map view to hide borders in the source sprite
/// - provide a fixed target size for the HUD element
/// - add a border sprite for visual decoration
/// - delegate all actual rendering to `MiniMapView`
class MiniMap extends PositionComponent with HasGameReference<PixelQuest> {
  // constructor parameters
  final Sprite _miniMapSprite;
  final double _levelWidth;
  final Player _player;
  final LevelMetadata _levelMetadata;
  final List<EntityOnMiniMap> _entitiesAboveForeground;
  final List<EntityOnMiniMap> _entitiesBehindForeground;

  MiniMap({
    required Sprite miniMapSprite,
    required double levelWidth,
    required Player player,
    required LevelMetadata levelMetadata,
    required List<EntityOnMiniMap> entitiesAboveForeground,
    required List<EntityOnMiniMap> entitiesBehindForeground,
    required super.position,
  }) : _miniMapSprite = miniMapSprite,
       _levelWidth = levelWidth,
       _player = player,
       _levelMetadata = levelMetadata,
       _entitiesAboveForeground = entitiesAboveForeground,
       _entitiesBehindForeground = entitiesBehindForeground {
    size = miniMapTargetSize + Vector2.all(_frameBorderWidth * 2);
  }

  // renders the actual mini map
  late final MiniMapView _miniMapView;

  // the target size represents the size of the mini map view, so the size of the inside of the frame
  static final Vector2 miniMapTargetSize = Vector2(96, 48); // [Adjustable]

  // image of the frame
  late final SpriteComponent _frame;

  // border width of the frame image
  static const double _frameBorderWidth = 12; // [Adjustable]
  static const double _frameOverhangAdjust = 3; // [Adjustable]

  @override
  FutureOr<void> onLoad() {
    anchor = Anchor.topRight;
    setUpMiniMap();
    setUpFrame();
    return super.onLoad();
  }

  /// Adds a decorative frame around the mini map.
  ///
  /// Loads the frame sprite and adds it as a child component.
  /// Applies a small vertical adjustment to compensate for the protruding
  /// ends of the frame so that it visually aligns with the mini map view.
  void setUpFrame() {
    _frame = SpriteComponent(
      sprite: loadSprite(game, 'HUD/${game.staticCenter.getWorld(_levelMetadata.worldUuid).miniMapFrameFileName}.png'),
    );
    add(_frame);

    // optical adjustment to compensate for the protruding ends of the frame
    position.y -= _frameOverhangAdjust;
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
      viewPosition = Vector2.all(_frameBorderWidth) + (miniMapTargetSize - targetSize) / 2;
    } else {
      targetSize = miniMapTargetSize;
      viewPosition = Vector2.all(_frameBorderWidth);
    }

    _miniMapView = MiniMapView(
      sprite: _miniMapSprite,
      targetSize: targetSize,
      levelWidth: _levelWidth,
      player: _player,
      entitiesAboveForeground: _entitiesAboveForeground,
      entitiesBehindForeground: _entitiesBehindForeground,
      position: viewPosition,
    );

    add(_miniMapView);
  }
}
