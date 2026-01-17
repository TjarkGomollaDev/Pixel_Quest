import 'package:flutter/foundation.dart';
import 'package:pixel_adventure/game/level/mobile%20controls/mobile_controls.dart';

abstract class SettingsEvent {
  const SettingsEvent();
}

class ControlSettingsChanged extends SettingsEvent {
  final JoystickSetup setup;
  const ControlSettingsChanged(this.setup);
}

/// Typed event bus for settings changes.
///
/// Use this to broadcast *specific* settings changes (with optional payloads)
/// to Flame components and other non-UI systems without tight coupling.
///
/// Why this exists:
/// - Flame components shouldn't depend on Flutter widget state management.
/// - We want targeted updates (e.g. joystick setup changed) instead of "everything changed".
/// - Lightweight alternative to Streams for simple in-game event dispatch.
///
/// Usage:
/// 1) Define an event:
///    `class ControlSettingsChanged extends SettingsEvent { ... }`
///
/// 2) Listen somewhere (and store the handle):
///    `final sub = SettingsNotifier.instance.listen<ControlSettingsChanged>((e) { ... });`
///
/// 3) Unlisten when the component is removed/disposed:
///    `sub.cancel();`
///
/// 4) Emit from wherever the setting is changed:
///    `SettingsNotifier.instance.notify(ControlSettingsChanged(setup));`
class SettingsNotifier {
  static final SettingsNotifier instance = SettingsNotifier._();
  SettingsNotifier._();

  final Map<Type, List<void Function(Object)>> _listeners = {};

  SettingsSubscription listen<T extends SettingsEvent>(void Function(T event) cb) {
    final list = _listeners.putIfAbsent(T, () => <void Function(Object)>[]);

    void wrapper(Object e) => cb(e as T);
    list.add(wrapper);

    return SettingsSubscription(() {
      list.remove(wrapper);
      if (list.isEmpty) _listeners.remove(T);
    });
  }

  /// Emit a settings event.
  ///
  /// The event type is used to route it to the correct listeners.
  void notify<T extends SettingsEvent>(T event) {
    final list = _listeners[T];
    if (list == null) return;

    for (final cb in List.of(list)) {
      cb(event);
    }
  }
}

/// Handle for a registered listener.
///
/// Call [cancel] to remove the listener and avoid leaks.
/// (Similar concept to a StreamSubscription, but lightweight.)
class SettingsSubscription {
  final VoidCallback cancel;
  const SettingsSubscription(this.cancel);
}
