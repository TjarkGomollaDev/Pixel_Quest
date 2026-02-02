import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_quest/data/audio/audio_center.dart';
import 'package:pixel_quest/game/utils/camera_culling.dart';
import 'package:pixel_quest/game/game.dart';

/// Mixin for entities that should automatically start/stop an ambient loop sound.
///
/// The emitter periodically checks whether its [hitbox] is visible to the camera
/// and optionally applies an additional [guard]. Based on that, it registers or
/// unregisters itself with [AmbientLoopManager].
mixin AmbientLoopEmitter on Component, HasGameReference<PixelQuest> {
  // configs
  late final LoopSfx _loop;
  late final ShapeHitbox _ambientHitbox;

  // optional guard configs
  bool Function()? _ambientGuard;
  late final bool _ambientGuardFadeOut;

  // visible check
  bool _ambientVisible = false;
  double _ambientTimer = 0;

  // ambient sync token
  late int _lastAmbientSyncToken;

  // once stopped, we never sync again
  bool _ambientStopped = false;

  @override
  void update(double dt) {
    _syncAmbientLoops(dt);
    super.update(dt);
  }

  @override
  void onRemove() {
    stopAmbientLoop();
    super.onRemove();
  }

  /// Configures which loop to emit and which hitbox to use for visibility checks.
  void configureAmbientLoop({required LoopSfx loop, required ShapeHitbox hitbox, bool Function()? guard, bool guardFadeOut = true}) {
    _loop = loop;
    _ambientHitbox = hitbox;
    _ambientGuard = guard;
    _ambientGuardFadeOut = guardFadeOut;
    _lastAmbientSyncToken = game.audioCenter.ambientSyncToken;
  }

  /// Call this if the emitter should be permanently disabled (e.g. entity got hit/dies).
  /// It unregisters immediately and prevents any future register/unregister attempts.
  void stopAmbientLoop() {
    if (_ambientStopped) return;
    _ambientStopped = true;
    unawaited(game.ambientLoops.unregisterSource(_loop, this, fadeOut: false));
  }

  void _syncAmbientLoops(double dt) {
    if (_ambientStopped) return;

    // we don't need to check every update, a lower frequency is perfectly adequate here
    _ambientTimer += dt;
    if (_ambientTimer < 0.1) return;
    _ambientTimer = 0;

    // check whether it is in the visible area
    final visibleNow = game.isEntityInVisibleWorldRectX(_ambientHitbox);

    // compute guard
    final guardOk = _ambientGuard?.call() ?? true;

    // token changes are used as a global "resync" signal
    final token = game.audioCenter.ambientSyncToken;
    if (token != _lastAmbientSyncToken) {
      _lastAmbientSyncToken = token;

      // we force a local state change so the register/unregister logic runs even
      // if visibility didn't change, when the guard is false, registration is forbidden,
      // in this case we force the local state to inactive to prevent an accidental register
      _ambientVisible = guardOk ? !visibleNow : false;
    }

    // unregister if we're currently active but should not be
    if (_ambientVisible && (!visibleNow || !guardOk)) {
      final unregisterBecauseGuard = visibleNow && !guardOk;
      final fadeOut = unregisterBecauseGuard ? _ambientGuardFadeOut : false;
      _ambientVisible = false;
      unawaited(game.ambientLoops.unregisterSource(_loop, this, fadeOut: fadeOut));
      return;
    }

    // register only if visible + guardOk
    if (!_ambientVisible && visibleNow && guardOk) {
      _ambientVisible = true;
      unawaited(game.ambientLoops.registerSource(_loop, this));
      return;
    }
  }
}
