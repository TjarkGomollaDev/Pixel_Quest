import 'dart:async';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/data/static/metadata/level_metadata.dart';
import 'package:pixel_adventure/game/collision/collision.dart';
import 'package:pixel_adventure/game/hud/mini%20map/entity_on_mini_map.dart';
import 'package:pixel_adventure/game/hud/mini%20map/mini_map_arrow_layer.dart';
import 'package:pixel_adventure/game/hud/mini%20map/mini_map_view.dart';
import 'package:pixel_adventure/game/level/player/player.dart';
import 'package:pixel_adventure/game/utils/button.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game/utils/visible_components.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_quest.dart';

/// A HUD container component that displays the mini map inside a decorative frame.
///
/// MiniMap itself is mostly a composition and layout component:
/// - It creates and positions the [`MiniMapView`] which performs all actual rendering of the map.
/// - Scale and offset the [`MiniMapView`] to hide borders in the source sprite
/// - It adds a decorative frame sprite on top.
/// - It manages UI buttons (hide/show + manual scroll).
/// - It provides an [`MiniMapArrowLayer`] below the frame to hint at entities
///   that are currently obscured by the mini map.
///
/// Entity management:
/// - MiniMap receives a single list of entities that can appear on the mini map.
/// - It splits this list into sublists for:
///   - markers above the foreground,
///   - markers behind the foreground,
///   - arrow candidates (only entities that *could* be obscured by the mini map based on `yMoveRange`).
///
/// Important:
/// - MiniMap does not perform any map drawing logic; this lives in [`MiniMapView`].
/// - Arrow rendering is handled by [`MiniMapArrowLayer`].
class MiniMap extends PositionComponent with HasGameReference<PixelQuest> {
  // constructor parameters
  final Sprite _miniMapSprite;
  final double _levelWidth;
  final Player _player;
  final LevelMetadata _levelMetadata;
  final List<EntityOnMiniMap> _miniMapEntities;
  final Vector2 _hudTopRightToScreenTopRightOffset;
  final bool _showAtStart;
  final bool _inistialState;

  MiniMap({
    required Sprite miniMapSprite,
    required double levelWidth,
    required Player player,
    required LevelMetadata levelMetadata,
    required List<EntityOnMiniMap> miniMapEntities,
    required super.position,
    required Vector2 hudTopRightToScreenTopRightOffset,
    bool show = true,
    bool initialState = true,
  }) : _hudTopRightToScreenTopRightOffset = hudTopRightToScreenTopRightOffset,
       _miniMapSprite = miniMapSprite,
       _levelWidth = levelWidth,
       _player = player,
       _levelMetadata = levelMetadata,
       _miniMapEntities = miniMapEntities,
       _inistialState = initialState,
       _showAtStart = show {
    size = miniMapTargetViewSize + Vector2.all(_frameBorderWidth * 2) + Vector2(SpriteBtnType.btnSizeSmallCorrected.x + _btnLeftMargin, 0);

    // optical adjustment to compensate for the protruding ends of the frame
    position.y -= _frameOverhangAdjust;
  }

  // splitting the original list of passed entities into sublists
  final List<EntityOnMiniMap> _entitiesAboveForeground = [];
  final List<EntityOnMiniMap> _entitiesBehindForeground = [];
  final List<EntityOnMiniMap> _arrowCandidates = [];

  // renders the actual mini map
  late final MiniMapView _miniMapView;

  // the target view size represents the size of the mini map view, so the size of the inside of the frame
  static final Vector2 miniMapTargetViewSize = Vector2(96, 48); // [Adjustable]

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
  static const double _btnLeftMargin = 4; // [Adjustable]
  static const double _btnSpacing = 3; // [Adjustable]

  // arrow layer
  static const double _arrowLayerSpacing = 1; // [Adjustable]
  late final MiniMapArrowLayer _arrowLayer;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _splitEntities();
    _setUpMiniMapView();
    _setUpFrame();
    _setUpBtns();
    _setUpArrowLayer();
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

  /// Splits the passed entity list into:
  /// - layer lists for [`MiniMapView`],
  /// - a filtered list of arrow candidates for [`MiniMapArrowLayer`].
  ///
  /// This also wires `onRemovedFromLevel` such that entities remove themselves
  /// from every list they were registered in, keeping references consistent.
  void _splitEntities() {
    // y range in which entities can be obscured by the mini map
    final rangeTop = game.cameraWorldYBounds.top + frameTopLeftToScreenTopRightOffset.y;
    final rangeBottom = rangeTop + frameSize.y;

    for (final entity in _miniMapEntities) {
      final membershipLists = [_miniMapEntities];

      // in which layer of the mini map view should the entity appear
      final layerList = switch (entity.marker.layer) {
        EntityMiniMapMarkerLayer.aboveForeground => _entitiesAboveForeground,
        EntityMiniMapMarkerLayer.behindForeground => _entitiesBehindForeground,
        EntityMiniMapMarkerLayer.none => null,
      };
      if (layerList != null) {
        layerList.add(entity);
        membershipLists.add(layerList);
      }

      // arrow candidates where the arrow layer must be checked to see if they are obscured by the mini map,
      // in reality, you could simply pass the entire list _miniMapEntities to the arrow layer,
      // however, we can sort out the entities in beforehand, which, due to their yMoveRange,
      // can never be obscured by the mini map anyway, it saves us arrow layer performance later on
      if (checkRangeIntersection(entity.yMoveRange.x, entity.yMoveRange.y, rangeTop, rangeBottom)) {
        _arrowCandidates.add(entity);
        membershipLists.add(_arrowCandidates);
      }

      // when the entity disappears from the level, it should automatically remove itself from the corresponding lists
      entity.onRemovedFromLevel = (removed) {
        for (final list in membershipLists) {
          list.remove(removed);
        }
      };
    }
  }

  /// Adds a decorative frame around the mini map.
  ///
  /// Loads the frame sprite and adds it as a child component.
  /// Applies a small vertical adjustment to compensate for the protruding
  /// ends of the frame so that it visually aligns with the mini map view.
  void _setUpFrame() {
    _frame = VisibleSpriteComponent(
      sprite: loadSprite(game, 'Mini Map/${game.staticCenter.getWorld(_levelMetadata.worldUuid).miniMapFrameFileName}.png'),
      show: _showAtStart ? _inistialState : false,
    );
    add(_frame);
  }

  /// Sets up the MiniMap View.
  ///
  /// If there are borders in the source sprite (GameSettings.mapBorderWidth > 0),
  /// this method scales the mini map slightly so that the borders are hidden
  /// behind the frame. The Y scale is calculated to remove top/bottom borders,
  /// and the X scale is increased proportionally to preserve aspect ratio and
  /// hide left/right borders without stretching the sprite.
  void _setUpMiniMapView() {
    Vector2 targetSize;
    Vector2 viewPosition;

    if (GameSettings.hasBorder) {
      // calculate vertical scale to hide top and bottom borders
      final verticalScale = _miniMapSprite.srcSize.y / (_miniMapSprite.srcSize.y - 2);

      // compute scaled height and extra pixels added by scaling
      final scaledHeight = miniMapTargetViewSize.y * verticalScale;
      final extraHeight = scaledHeight - miniMapTargetViewSize.y;

      // scale width proportionally so left/right borders also disappear without distortion
      final scaledWidth = miniMapTargetViewSize.x + extraHeight;

      // scaled target size and an offset so that the view remains centered
      targetSize = Vector2(scaledWidth, scaledHeight);
      viewPosition = Vector2.all(_frameBorderWidth) + (miniMapTargetViewSize - targetSize) / 2;
    } else {
      targetSize = miniMapTargetViewSize;
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
      show: _showAtStart ? _inistialState : false,
    );

    add(_miniMapView);
  }

  /// Adds hide/show toggle and manual scroll buttons.
  ///
  /// Manual scroll temporarily disables the auto-follow mode of [`MiniMapView`]
  /// until the player moves again.
  void _setUpBtns() {
    _hideBtn = SpriteToggleBtn.fromType(
      type: SpriteBtnType.downSmall,
      type_2: SpriteBtnType.upSmall,
      onPressed: _foldInAnimated,
      onPressed_2: _foldOutAnimated,
      position: Vector2(
        size.x - SpriteBtnType.btnSizeSmallCorrected.x / 2,
        SpriteBtnType.btnSizeSmallCorrected.y / 2 + _frameOverhangAdjust,
      ),
      initialState: _inistialState,
      show: _showAtStart,
    );

    _scrollRightBtn = SpriteBtn.fromType(
      type: SpriteBtnType.nextSmall,
      onPressed: () => _miniMapView.scrollManual(1),
      holdMode: true,
      position: Vector2(_hideBtn.position.x, size.y - _frameOverhangAdjust - SpriteBtnType.btnSizeSmallCorrected.y / 2),
      show: _showAtStart ? _inistialState : false,
    );

    _scrollLeftBtn = SpriteBtn.fromType(
      type: SpriteBtnType.previousSmall,
      onPressed: () => _miniMapView.scrollManual(-1),
      holdMode: true,
      position: Vector2(_scrollRightBtn.position.x, _scrollRightBtn.position.y - SpriteBtnType.btnSizeSmallCorrected.y - _btnSpacing),
      show: _showAtStart ? _inistialState : false,
    );

    addAll([_hideBtn, _scrollRightBtn, _scrollLeftBtn]);
  }

  /// Adds the arrow hint bar below the mini map frame.
  ///
  /// The arrow layer receives only pre-filtered arrow candidates.
  void _setUpArrowLayer() {
    _arrowLayer = MiniMapArrowLayer(
      miniMap: this,
      arrowCandidates: _arrowCandidates,
      position: Vector2(_frameOverhangAdjust, miniMapTargetViewSize.y + _frameBorderWidth * 2 + _arrowLayerSpacing),
      show: _showAtStart ? _inistialState : false,
    );
    add(_arrowLayer);
  }

  /// Must be called from outside if _showAtStart is false
  void show() {
    _hideBtn.show();
    if (!_inistialState) return;
    _miniMapView.show();
    _frame.show();
    _arrowLayer.show();
    _scrollLeftBtn.show();
    _scrollRightBtn.show();
  }

  /// Folds the mini map out.
  Future<void> _foldOutAnimated() async {
    _miniMapView.show();
    _frame.show();
    _arrowLayer.show();
    await Future.wait([_scrollLeftBtn.animatedShow(), _scrollRightBtn.animatedShow(delay: 0.15)]);
  }

  /// Folds the mini map in.
  Future<void> _foldInAnimated() async {
    _miniMapView.hide();
    _frame.hide();
    _arrowLayer.hide();
    await Future.wait([_scrollLeftBtn.animatedHide(delay: 0.15), _scrollRightBtn.animatedHide()]);
    _miniMapView.deactivateScrollMode();
  }

  /// Size of the mini map with frame and without overhang.
  static Vector2 get frameSize => miniMapTargetViewSize + Vector2.all(_frameBorderWidth * 2 - _frameOverhangAdjust * 2);

  /// Offset from the frame's top-left corner to the screen top-right.
  Vector2 get frameTopLeftToScreenTopRightOffset => Vector2(
    _hudTopRightToScreenTopRightOffset.x + size.x - _frameOverhangAdjust,
    _hudTopRightToScreenTopRightOffset.y + position.y + _frameOverhangAdjust,
  );
}
