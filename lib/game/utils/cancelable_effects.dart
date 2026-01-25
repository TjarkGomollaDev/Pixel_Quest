import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/foundation.dart';

/// A mixin that provides a registry for Effects keyed by a string, so
/// that animations can be canceled deterministically.
///
/// Core features:
/// - Register one active [Effect] per key.
/// - Register returns a Future that completes when the effect finishes
///   or is canceled.
/// - [cancelAnimations] cancels all registered effects and completes
///   all pending Futures.
/// - [bumpToken] allows you to invalidate in-flight async flows that capture
///   a token and check it later.
///
/// Requirements:
/// - This mixin must be applied to a Flame [Component], because it uses
///   [add] and [remove] to manage effects.
mixin CancelableAnimations on Component {
  final Map<String, Effect> _activeEffects = {};
  final Map<String, Completer<void>> _activeCompleters = {};
  int _animationToken = 0;

  /// Returns the current animation token used for invalidation checks.
  int get animationToken => _animationToken;

  /// Increments the animation token and returns the new value.
  ///
  /// Any async flow that captured the previous token can detect cancellation
  /// by comparing to [animationToken].
  int bumpToken() => ++_animationToken;

  /// Cancels all registered effects and completes all pending Futures.
  ///
  /// Marked with `@mustCallSuper` so overriding implementations can add their
  /// own cleanup while still ensuring registry cleanup happens.
  @mustCallSuper
  void cancelAnimations() {
    bumpToken();
    for (final key in _activeEffects.keys.toList()) {
      _cancelKey(key);
    }
  }

  /// Cancels the effect registered under [key] (if any) and completes the
  /// associated Future.
  ///
  /// This is safe to call even if no effect exists for [key].
  void _cancelKey(String key) {
    final effect = _activeEffects.remove(key);
    final completer = _activeCompleters.remove(key);

    // remove effect and complete completer
    if (effect != null && effect.parent != null) remove(effect);
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  /// Registers [effect] under [key] and adds it to this component.
  ///
  /// If a previous effect is already registered under the same [key], it will
  /// be canceled immediately (and its Future completed).
  ///
  /// The returned Future completes when:
  /// - the effect finishes naturally, or
  /// - the effect is canceled via [cancelAnimations] or another registration
  ///   with the same key.
  ///
  /// [additionallyOnStart] can be used to run key-specific setup logic right
  /// before the effect is added.
  ///
  /// [additionallyInOnComplete] can be used for key-specific teardown logic
  /// when the effect completes.
  ///
  /// Note:
  /// Do not set `onComplete` on the passed [effect] yourself. `registerEffect`
  /// installs its own `onComplete` callback to perform registry cleanup and
  /// to complete the returned Future.
  ///
  /// If you need completion logic, use [additionallyInOnComplete].
  Future<void> registerEffect(String key, Effect effect, {VoidCallback? additionallyOnStart, VoidCallback? additionallyInOnComplete}) {
    // cancel previous effects
    _cancelKey(key);

    // create completer
    final completer = Completer<void>();
    _activeCompleters[key] = completer;

    // if you want something extra to be done at the start
    additionallyOnStart?.call();

    // add visual effect
    effect.onComplete = () {
      // clean up and then confirm that the effect is complete
      _activeEffects.remove(key);
      _activeCompleters.remove(key);
      if (!completer.isCompleted) completer.complete();

      // if you want something extra to be done in on complete
      additionallyInOnComplete?.call();
    };
    _activeEffects[key] = effect;
    add(effect);

    return completer.future;
  }
}
