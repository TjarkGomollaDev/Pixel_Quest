import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:pixel_quest/app_theme.dart';
import 'package:pixel_quest/data/static/metadata/level_metadata.dart';
import 'package:pixel_quest/game/background/background.dart';
import 'package:pixel_quest/game/level/loading/loading_dummy_character.dart';
import 'package:pixel_quest/game/traps/air_particle.dart';
import 'package:pixel_quest/game/utils/cancelable_effects.dart';
import 'package:pixel_quest/game/utils/game_safe_padding.dart';
import 'package:pixel_quest/game/utils/input_blocker.dart';
import 'package:pixel_quest/game/utils/rrect.dart';
import 'package:pixel_quest/game/utils/misc_utils.dart';
import 'package:pixel_quest/game/utils/visible_components.dart';
import 'package:pixel_quest/game/game_settings.dart';
import 'package:pixel_quest/game/game.dart';

enum _OverlayState { notVisible, transition, visible }

/// Fullscreen loading overlay that blocks input and shows a parallax background plus a small “dummy” character animation.
///
/// Handles a simple state machine (hidden / transition / visible), spawns a few air particles while loading,
/// and supports smooth show/hide transitions (including a zoom + fade-out).
class LoadingOverlay extends PositionComponent with HasGameReference<PixelQuest>, CancelableAnimations implements OpacityProvider {
  // constructor parameters
  final double _worldToScreenScale;
  final GameSafePadding _safePadding;

  LoadingOverlay({required double screenToWorldScale, required GameSafePadding safePadding, required super.size})
    : _worldToScreenScale = screenToWorldScale,
      _safePadding = safePadding {
    position = size / 2;
    anchor = Anchor.center;
  }

  // current state
  _OverlayState _state = .notVisible;

  // internal opacity
  double _opacity = 1;

  // components
  late final PositionComponent _root;
  late final InputBlocker _inputBlocker;
  late final Map<BackgroundScene, BackgroundParallax> _backgrounds;
  late final LoadingDummyCharacter _dummy;

  // helper
  final Paint _overlayPaint = Paint();
  BackgroundParallax? _activeBackground;
  static final _random = Random();

  // particle for dummy character
  late Timer _particleTimer;
  static const double _delayParticleSpawn = 0.06;
  static const double _widthParticleStream = 80;

  // stage info
  late final RRectComponent _stageInfoBg;
  late final VisibleTextComponent _stageInfoText;

  // getter
  bool get isShown => _state != .notVisible;

  // animation keys
  static const String _keyZoomAndFadeOut = 'zoom-and-fade-out';

  @override
  FutureOr<void> onLoad() {
    _setUpRoot();
    _setUpInputBlocker();
    _setUpBackground();
    _setUpDummyCharacter();
    _setUpStageInfo();
    _setUpParticleTimer();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (_state == .notVisible) return;
    _particleTimer.update(dt);
    super.update(dt);
  }

  @override
  void renderTree(Canvas canvas) {
    if (_state == .notVisible || _opacity <= 0) return;

    // render entire overlay, including children, into an alpha layer
    _overlayPaint.color = .fromRGBO(255, 255, 255, _opacity);

    canvas.saveLayer(null, _overlayPaint);
    super.renderTree(canvas);
    canvas.restore();
  }

  @override
  double get opacity => _opacity;

  @override
  set opacity(double value) => _opacity = value.clamp(0, 1);

  @override
  void cancelAnimations() {
    super.cancelAnimations();

    // remove all particles
    _particleTimer.pause();
    _removeAllParticles();

    // all animations must also be canceled for the dummy
    _dummy.cancelAnimations();

    // additionally hide and disable all components
    _stageInfoBg.hide();
    _stageInfoText.hide();
    _inputBlocker.disable();

    // initial state
    _state = .notVisible;
  }

  void _setUpRoot() {
    _root = PositionComponent()..scale = .all(_worldToScreenScale);
    add(_root);
  }

  void _setUpInputBlocker() {
    _inputBlocker = InputBlocker(size: size);
    _root.add(_inputBlocker);
  }

  void _setUpBackground() {
    final scenes = BackgroundScene.loadingChoices.isNotEmpty ? BackgroundScene.loadingChoices : const [BackgroundScene.defaultScene];
    _backgrounds = {
      for (final scene in scenes)
        scene: .scene(scene: scene, baseVelocity: GameSettings.parallaxBaseVelocityLoadingOverlay, size: size, show: false),
    };
    _root.addAll(_backgrounds.values);
  }

  void _setUpDummyCharacter() {
    _dummy = LoadingDummyCharacter(screenSize: size);
    _root.add(_dummy);
  }

  void _setUpStageInfo() {
    // stage info text
    _stageInfoText = VisibleTextComponent(text: game.l10n.loadingLevel(0, 12), anchor: .center, textRenderer: AppTheme.hudText.asTextPaint);

    // stage info background
    final stageInfoBgSize = Vector2(_stageInfoText.size.x + 15, GameSettings.hudBgTileSize);
    _stageInfoBg = RRectComponent(
      color: AppTheme.tileBlur,
      borderRadius: GameSettings.hugBgTileRadius,
      size: stageInfoBgSize,
      position: Vector2(
        _safePadding.minLeft(GameSettings.hudHorizontalMinMargin) + stageInfoBgSize.x / 2,
        size.y - stageInfoBgSize.y / 2 - GameSettings.hudVerticalMargin,
      ),
      anchor: .center,
    );
    _stageInfoText.position = _stageInfoBg.position + Vector2(1, 0);

    _root.addAll([_stageInfoBg, _stageInfoText]);
  }

  void _updateStageInfo(LevelMetadata levelMetadata) {
    _stageInfoText.text = game.l10n.loadingLevel(game.staticCenter.worldById(levelMetadata.worldUuid).index + 1, levelMetadata.number);
  }

  void _setUpParticleTimer() {
    _particleTimer = Timer(_delayParticleSpawn, onTick: _spawnParticle, repeat: true, autoStart: false);
  }

  void _spawnParticle() {
    final dummyPosition = _dummy.position.clone();
    final particle = AirParticle(
      streamTop: 0,
      streamLeft: dummyPosition.x - _widthParticleStream / 2,
      streamRight: dummyPosition.x + _widthParticleStream / 2,
      basePosition: dummyPosition + Vector2(-_dummy.size.x / 2, 0),
      baseWidth: _dummy.size.x,
    );
    _root.add(particle);
  }

  void _removeAllParticles() {
    final particles = _root.children.whereType<AirParticle>().toList();
    for (final p in particles) {
      p.removeFromParent();
    }
  }

  void _activateBackground() {
    _activeBackground?.hide();
    final scene = game.storageCenter.inventory.loadingBackground.resolveChoice();
    _activeBackground = scene != null ? _backgrounds[scene] : _backgrounds.values.elementAt(_random.nextInt(_backgrounds.length));
    _activeBackground?.show();
  }

  Future<void> show(LevelMetadata levelMetadata) async {
    if (_state != .notVisible) return;
    _state = .transition;
    final token = bumpToken();

    // reset visuals in every show
    scale = .all(1);
    _opacity = 1;

    // show and enable all components
    _activateBackground();
    _updateStageInfo(levelMetadata);
    _stageInfoBg.show();
    _stageInfoText.show();
    _inputBlocker.enable();

    // dummy character falls in and start particle spawner
    _particleTimer.start();
    await _dummy.fallIn();
    if (token != animationToken) return;

    // update state
    _state = .visible;
  }

  Future<void> hide({VoidCallback? onAfterDummyFallOut}) async {
    if (_state != .visible) return;
    _state = .transition;
    final token = bumpToken();

    // dummy character falls out and then particle timer stops
    await _dummy.fallOut();
    if (token != animationToken) return;
    onAfterDummyFallOut?.call();
    _particleTimer.pause();

    // hide all components
    _stageInfoBg.hide();
    _stageInfoText.hide();

    // zoom and fade out
    await _zoomAndFadeOut();
    if (token != animationToken) return;

    // update state
    _state = .notVisible;

    // input blocker can now also be disabled
    _inputBlocker.disable();
  }

  Future<void> _zoomAndFadeOut({double zoomDuration = 0.8, double fadeOutDuration = 0.4, double targetScale = 5}) {
    // create effect
    final effect = CombinedEffect([
      ScaleEffect.to(.all(targetScale), EffectController(duration: zoomDuration, curve: Curves.easeInQuad)),
      OpacityEffect.to(0, EffectController(duration: fadeOutDuration, startDelay: zoomDuration - fadeOutDuration)),
    ]);
    return registerEffect(_keyZoomAndFadeOut, effect);
  }

  Future<void> warmUp(LevelMetadata levelMetadata) async {
    _activateBackground();
    _updateStageInfo(levelMetadata);
    _inputBlocker.disable();
    final prevState = _state;
    final prevOpacity = _opacity;
    _state = .visible;
    _opacity = 0.001;
    await yieldFrame();
    _opacity = prevOpacity;
    _state = prevState;
  }
}
