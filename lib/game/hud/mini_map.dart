import 'dart:async';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/data/static/metadata/level_metadata.dart';
import 'package:pixel_adventure/game/hud/entity_on_mini_map.dart';
import 'package:pixel_adventure/game/hud/mini_map_view.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/utils/button.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game/utils/visible_components.dart';
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
    size = miniMapTargetSize + Vector2.all(_frameBorderWidth * 2) + Vector2(SpriteBtn.btnSizeSmallCorrected.x + _btnLeftMargin, 0);
  }

  // renders the actual mini map
  late final MiniMapView _miniMapView;

  // the target size represents the size of the mini map view, so the size of the inside of the frame
  static final Vector2 miniMapTargetSize = Vector2(96, 48); // [Adjustable]

  // image of the frame
  late final VisibleSpriteComponent _frame;

  // border width of the frame image
  static const double _frameBorderWidth = 12; // [Adjustable]
  static const double _frameOverhangAdjust = 3; // [Adjustable]

  // btns
  late final SpriteToggleBtn _hideBtn;
  late final SpriteBtn _scrollLeftBtn;
  late final SpriteBtn _scrollRightBtn;

  // btn margin and spacing
  static const double _btnLeftMargin = 4;
  static const double _btnSpacing = 3;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _setUpMiniMap();
    _setUpFrame();
    _setUpBtns();
    return super.onLoad();
  }

  void _initialSetup() {
    // debug
    if (GameSettings.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorMenu;
    }

    // general
    anchor = Anchor.topRight;
  }

  /// Adds a decorative frame around the mini map.
  ///
  /// Loads the frame sprite and adds it as a child component.
  /// Applies a small vertical adjustment to compensate for the protruding
  /// ends of the frame so that it visually aligns with the mini map view.
  void _setUpFrame() {
    _frame = VisibleSpriteComponent(
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
  void _setUpMiniMap() {
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

  void _setUpBtns() {
    _hideBtn = SpriteToggleBtn(
      type: SpriteBtnType.downSmall,
      type_2: SpriteBtnType.upSmall,
      onPressed: () => _hide(),
      onPressed_2: () => _show(),
      position: Vector2(size.x - SpriteBtn.btnSizeSmallCorrected.x / 2, SpriteBtn.btnSizeSmallCorrected.y / 2 + _frameOverhangAdjust),
    );

    _scrollRightBtn = SpriteBtn(
      type: SpriteBtnType.nextSmall,
      onPressed: () {},
      position: Vector2(_hideBtn.position.x, size.y - _frameOverhangAdjust - SpriteBtn.btnSizeSmallCorrected.y / 2),
    );

    _scrollLeftBtn = SpriteBtn(
      type: SpriteBtnType.previousSmall,
      onPressed: () {},
      position: Vector2(_scrollRightBtn.position.x, _scrollRightBtn.position.y - SpriteBtn.btnSizeSmallCorrected.y - _btnSpacing),
    );

    addAll([_hideBtn, _scrollRightBtn, _scrollLeftBtn]);
  }

  bool _transition = false;

  Future<void> _show() async {
    if (_transition) return;
    _transition = true;
    _miniMapView.show();
    _frame.show();
    await Future.wait([_scrollLeftBtn.animatedShow(), _scrollRightBtn.animatedShow(delay: 0.15)]);
    _transition = false;
  }

  Future<void> _hide() async {
    if (_transition) return;
    _transition = true;
    _miniMapView.hide();
    _frame.hide();
    await Future.wait([_scrollLeftBtn.animatedHide(delay: 0.15), _scrollRightBtn.animatedHide()]);
    _transition = false;
  }
}
