import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:pixel_quest/app_theme.dart';
import 'package:pixel_quest/game/utils/button.dart';
import 'package:pixel_quest/game/utils/rrect.dart';
import 'package:pixel_quest/game/game.dart';

/// A reusable dialog shell that renders a pixel-styled window.
///
/// The dialog sizes itself dynamically based on the provided [_contentSize],
/// adding consistent padding/margins so all dialogs share the same layout rules.
///
/// Typical usage:
/// - Build your dialog body as a component (e.g. a column of text/buttons)
/// - Pass it into [DialogContainer] via `content` + `contentSize`
/// - Place the container centered in a page/overlay (e.g. [DialogPage])
class DialogContainer extends PositionComponent with HasGameReference<PixelQuest> {
  // constructor parameters
  final String _titleText;
  final PositionComponent _content;
  final Vector2 _contentSize;

  DialogContainer({
    required String titleText,
    required PositionComponent content,
    required Vector2 contentSize,
    required super.position,
    super.anchor = Anchor.center,
  }) : _titleText = titleText,
       _content = content,
       _contentSize = contentSize;

  // layers
  late final RRectComponent _layerContentBox;
  late final RRectComponent _layerFrame;
  late final RRectComponent _layerOutlineHightlight;
  late final RRectComponent _layerOutline;
  late final RRectComponent _layerTitleBarShadow;

  // layer sizes
  late final Vector2 _layerContentBoxSize;
  late final Vector2 _layerFrameSize;
  late final Vector2 _layerOutlineHighlightSize;
  late final Vector2 _layerOutlineSize;
  late final Vector2 _layerTitleBarShadowSize;

  // title bar
  late final SpriteBtn _closeBtn;
  late final TextComponent _title;

  // layer colors
  static const Color _layerContentBoxColor = AppTheme.black; // [Adjustable]
  static const Color _layerFrameColor = AppTheme.grayDark4; // [Adjustable]
  static const Color _layerOutlineHightlightColor = AppTheme.white; // [Adjustable]
  static const Color _layerOutlineColor = AppTheme.grayDark6; // [Adjustable]
  static final Color _layerTitleBarShadowColor = AppTheme.grayDark3.withAlpha(160); // [Adjustable]

  // layer radii
  static const double _layerContentBoxRadius = 3; // [Adjustable]
  static const double _layerFrameRadius = 6; // [Adjustable]
  static const double _layerOutlineRadius = 7; // [Adjustable]
  static const double _layerTitleBarShadowRadius = 3.5; // [Adjustable]

  // sizes and spacing
  static const double _contentBoxMargin = 3.5; // [Adjustable]
  static const double _contentBoxPaddingHorizontal = 20; // [Adjustable]
  static const double _contentBoxPaddingVertical = 14; // [Adjustable]
  static const double _outlineHighlighStrokeWidth = 0.5; // [Adjustable]
  static const double _outlineStrokeWidth = 1; // [Adjustable]
  static const double _titleBarShadowMargin = 2; // [Adjustable]
  static const double _closeBtnVerticalMargin = 3; // [Adjustable]

  // use this in your custom dialog for a consistent layout
  static const double subHeadlineMarginBottom = 5; // [Adjustable]
  static const double spacingBetweenSections = 13; // [Adjustable]
  static const double spacingBetweenSectionsXL = 32; // [Adjustable]
  static const double contentWidth = 156; // [Adjustable]

  @override
  FutureOr<void> onLoad() {
    _calculateSizes();
    _setUpLayers();
    _setUpTitleBar();
    _setUpContent();
    return super.onLoad();
  }

  void _calculateSizes() {
    // dynamic calculation of the different layers depending on the content size
    _layerContentBoxSize = _contentSize + Vector2(_contentBoxPaddingHorizontal, _contentBoxPaddingVertical) * 2;
    _layerFrameSize =
        _layerContentBoxSize +
        Vector2(_contentBoxMargin * 2, _contentBoxMargin + SpriteBtnType.btnSizeSmallCorrected.y + _closeBtnVerticalMargin * 2);
    _layerOutlineHighlightSize = _layerFrameSize + Vector2(0, _outlineHighlighStrokeWidth);
    _layerOutlineSize = _layerOutlineHighlightSize + Vector2.all(_outlineStrokeWidth * 2);
    _layerTitleBarShadowSize = Vector2(
      _layerFrameSize.x - _titleBarShadowMargin * 2,
      (SpriteBtnType.btnSizeSmallCorrected.y + _closeBtnVerticalMargin * 2 - _titleBarShadowMargin) / 2,
    );
    size = _layerOutlineSize;
  }

  void _setUpLayers() {
    // outline
    _layerOutline = RRectComponent(
      color: _layerOutlineColor,
      borderRadius: _layerOutlineRadius,
      size: _layerOutlineSize,
      position: size / 2,
      anchor: Anchor.center,
    );

    // outline hightlight
    _layerOutlineHightlight = RRectComponent(
      color: _layerOutlineHightlightColor,
      borderRadius: _layerFrameRadius,
      size: _layerOutlineHighlightSize,
      position: size / 2,
      anchor: Anchor.center,
    );

    // frame
    _layerFrame = RRectComponent(
      color: _layerFrameColor,
      borderRadius: _layerFrameRadius,
      size: _layerFrameSize,
      position: size / 2 + Vector2(0, _outlineHighlighStrokeWidth / 2),
      anchor: Anchor.center,
    );

    // content box
    _layerContentBox = RRectComponent(
      color: _layerContentBoxColor,
      borderRadius: _layerContentBoxRadius,
      size: _layerContentBoxSize,
      position: size / 2 + Vector2(0, (SpriteBtnType.btnSizeSmallCorrected.y + _closeBtnVerticalMargin * 2) / 2 - _contentBoxMargin / 2),
      anchor: Anchor.center,
    );

    // title bar shadow
    _layerTitleBarShadow = RRectComponent(
      color: _layerTitleBarShadowColor,
      borderRadius: _layerTitleBarShadowRadius,
      size: _layerTitleBarShadowSize,
      position: Vector2(
        size.x / 2,
        _layerFrame.position.y - _layerFrame.size.y / 2 + _layerTitleBarShadowSize.y / 2 + _titleBarShadowMargin,
      ),
      anchor: Anchor.center,
    );

    addAll([_layerOutline, _layerOutlineHightlight, _layerFrame, _layerContentBox, _layerTitleBarShadow]);
  }

  void _setUpTitleBar() {
    // close btn
    _closeBtn = SpriteBtn.fromType(
      type: SpriteBtnType.closeSmall,
      onPressed: () => game.router.pop(),
      position: Vector2(
        _layerFrame.position.x + _layerFrame.size.x / 2 - SpriteBtnType.btnSizeSmallCorrected.x / 2 - _contentBoxMargin,
        _layerFrame.position.y - _layerFrame.size.y / 2 + SpriteBtnType.btnSizeSmallCorrected.y / 2 + _closeBtnVerticalMargin,
      ),
    );

    // title
    _title = TextComponent(
      text: _titleText,
      anchor: Anchor.center,
      position: Vector2(size.x / 2, _closeBtn.y),
      textRenderer: AppTheme.dialogHeadingStandard.asTextPaint,
    );

    addAll([_closeBtn, _title]);
  }

  void _setUpContent() {
    _content.anchor = Anchor.topCenter;
    _content.position = Vector2(size.x / 2, _layerContentBox.position.y - _layerContentBox.size.y / 2 + _contentBoxPaddingVertical);
    add(_content);
  }
}
