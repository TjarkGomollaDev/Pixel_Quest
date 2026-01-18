import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/data/audio/audio_center.dart';
import 'package:pixel_adventure/game/utils/camera_culling.dart';
import 'package:pixel_adventure/game/game.dart';

mixin AmbientLoopEmitter on Component, HasGameReference<PixelQuest> {
  // configs
  late final LoopSfx _loop;
  late final ShapeHitbox _ambientHitbox;

  // visible check
  bool _ambientVisible = false;
  double _ambientTimer = 0;

  // ambient sync token
  late int _lastAmbientSyncToken;

  @override
  void update(double dt) {
    _syncAmbientLoops(dt);
    super.update(dt);
  }

  @override
  void onRemove() {
    unawaited(game.ambientLoops.unregisterSource(_loop, this));
    super.onRemove();
  }

  void configureAmbientLoop({required LoopSfx loop, required ShapeHitbox hitbox}) {
    _loop = loop;
    _ambientHitbox = hitbox;
    _lastAmbientSyncToken = game.audioCenter.ambientSyncToken;
  }

  void _syncAmbientLoops(double dt) {
    // we don't need to check every update, a lower frequency is perfectly adequate here
    _ambientTimer += dt;
    if (_ambientTimer < 0.1) return;
    _ambientTimer = 0;

    // check whether it is in the visible area
    final visibleNow = game.isEntityInVisibleWorldRectX(_ambientHitbox);

    // if necessary forces a sync event
    final token = game.audioCenter.ambientSyncToken;
    if (token != _lastAmbientSyncToken) {
      _lastAmbientSyncToken = token;
      _ambientVisible = !visibleNow;
    }

    // if anything has changed, sync with ambient loops
    if (visibleNow == _ambientVisible) return;
    _ambientVisible = visibleNow;
    _ambientVisible ? unawaited(game.ambientLoops.registerSource(_loop, this)) : unawaited(game.ambientLoops.unregisterSource(_loop, this));
  }
}
