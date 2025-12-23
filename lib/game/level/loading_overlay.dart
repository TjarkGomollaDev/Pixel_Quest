import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/data/static/metadata/level_metadata.dart';
import 'package:pixel_adventure/game/level/background_szene.dart';
import 'package:pixel_adventure/game/level/loading_dummy_character.dart';
import 'package:pixel_adventure/game/traps/fan_air_particle.dart';
import 'package:pixel_adventure/game/utils/game_safe_padding.dart';
import 'package:pixel_adventure/game/utils/input_blocker.dart';
import 'package:pixel_adventure/game/utils/rrect.dart';
import 'package:pixel_adventure/game/utils/visible_components.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_quest.dart';

class LoadingOverlay extends PositionComponent with HasGameReference<PixelQuest>, HasVisibility implements OpacityProvider {
  // constructor parameters
  final double _worldToScreenScale;
  final GameSafePadding _safePadding;

  LoadingOverlay({required double screenToWorldScale, required GameSafePadding safePadding, required super.size})
    : _worldToScreenScale = screenToWorldScale,
      _safePadding = safePadding {
    position = size / 2;
    anchor = Anchor.center;
    _hide();
  }

  // components
  late final PositionComponent _root;
  late final InputBlocker _inputBlocker;
  late final BackgroundSzene _background;
  late final LoadingDummyCharacter _dummy;

  // particle for dummy character
  late Timer _particleTimer;
  static const double _delayParticleSpawn = 0.06;
  static const double _widthParticleStream = 80;

  // stage info
  late final RRectComponent _stageInfoBg;
  late final VisibleTextComponent _stageInfoText;

  // internal opacity
  double _opacity = 1;

  // flag indicating whether the overlay is currently being shown
  bool _isShown = false;

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
    if (_isShown) _particleTimer.update(dt);
    super.update(dt);
  }

  @override
  void renderTree(Canvas canvas) {
    if (!isVisible || opacity <= 0) return;

    // render entire overlay, including children, into an alpha layer
    final paint = Paint()..color = Color.fromRGBO(255, 255, 255, opacity);

    canvas.saveLayer(null, paint);
    super.renderTree(canvas);
    canvas.restore();
  }

  @override
  double get opacity => _opacity;

  @override
  set opacity(double value) => _opacity = value.clamp(0, 1);

  void _show() => isVisible = true;
  void _hide() => isVisible = false;

  Future<void> _animatedHide({double duration = 0.8, double targetScale = 5}) {
    final completer = Completer();
    final scaleEffect = ScaleEffect.to(Vector2.all(targetScale), EffectController(duration: duration, curve: Curves.easeInQuad));
    final opacityEffect = OpacityEffect.to(
      0,
      EffectController(duration: 0.2, startDelay: duration - 0.2),
      onComplete: () {
        completer.complete();
        scale = Vector2.all(1);
        _opacity = 1;
        _hide();
      },
    );
    addAll([scaleEffect, opacityEffect]);

    return completer.future;
  }

  void _setUpRoot() {
    _root = PositionComponent()..scale = Vector2.all(_worldToScreenScale);
    add(_root);
  }

  void _setUpInputBlocker() {
    _inputBlocker = InputBlocker(size: size);
    _root.add(_inputBlocker);
  }

  void _setUpBackground() {
    _background = BackgroundSzene(szene: Szene.szene3, size: size, baseVelocity: GameSettings.parallaxBaseVelocityLoadingOverlay);
    _root.add(_background);
  }

  void _setUpDummyCharacter() {
    _dummy = LoadingDummyCharacter(screenSize: size);
    _root.add(_dummy);
  }

  void _setUpStageInfo() {
    // stage info text
    _stageInfoText = VisibleTextComponent(
      text: game.l10n.loadingLevel(0, 0),
      anchor: Anchor.center,
      textRenderer: AppTheme.characterPickerHeading.asTextPaint,
    );

    // stage info background
    final stageInfoBgSize = Vector2(_stageInfoText.size.x + 15, 15);
    _stageInfoBg = RRectComponent(
      color: AppTheme.tileBlur,
      borderRadius: 2,
      size: stageInfoBgSize,
      position: Vector2(_safePadding.minLeft(40) + stageInfoBgSize.x / 2, -20 + size.y - stageInfoBgSize.y / 2),
      anchor: Anchor.center,
    );
    _stageInfoText.position = _stageInfoBg.position;

    _root.addAll([_stageInfoBg, _stageInfoText]);
  }

  void _updateStageInfo(LevelMetadata levelMetadata) =>
      _stageInfoText.text = game.l10n.loadingLevel(game.staticCenter.getWorld(levelMetadata.worldUuid).index + 1, levelMetadata.number);

  void _setUpParticleTimer() => _particleTimer = Timer(_delayParticleSpawn, onTick: _spawnParticle, repeat: true, autoStart: false);

  void _spawnParticle() {
    final dummyPosition = _dummy.position.clone();
    final particle = FanAirParticle(
      streamTop: 0,
      streamLeft: dummyPosition.x - _widthParticleStream / 2,
      streamRight: dummyPosition.x + _widthParticleStream / 2,
      basePosition: dummyPosition + Vector2(-_dummy.size.x / 2, 0),
      baseWidth: _dummy.size.x,
    );
    _root.add(particle);
  }

  Future<void> showOverlay(LevelMetadata levelMetadata) async {
    if (_isShown) return;
    _isShown = true;
    _inputBlocker.enable();
    _updateStageInfo(levelMetadata);
    _stageInfoBg.show();
    _stageInfoText.show();
    _particleTimer.start();
    _show();
    await _dummy.fallIn();
  }

  Future<void> hideOverlay() async {
    if (!_isShown) return;
    _isShown = false;
    await _dummy.fallOut();
    _particleTimer.pause();
    _stageInfoBg.hide();
    _stageInfoText.hide();
    await _animatedHide();
    _inputBlocker.disable();
  }
}
