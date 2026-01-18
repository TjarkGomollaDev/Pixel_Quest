import 'package:flutter/foundation.dart';
import 'package:pixel_adventure/game/level/mobile%20controls/mobile_controls.dart';
part 'package:pixel_adventure/game/events/game_events.dart';

/// Typed event bus for in-game events.
///
/// Use this to broadcast *specific* events (with optional payloads) to Flame
/// components and other non-UI systems without tight coupling.
///
/// Why this exists:
/// - Flame components shouldn't depend on Flutter widget state management.
/// - Lightweight alternative to Streams for simple in-game event dispatch.
///
/// Usage:
/// 1) Define an event:
///    `class MyEvent extends GameEvent { ... }`
///
/// 2) Listen somewhere (and store the handle):
///    `final sub = GameEventBus.instance.listen<MyEvent>((e) { ... });`
///
/// 3) Unlisten when the component is removed/disposed:
///    `sub.cancel();`
///
/// 4) Emit from wherever the event happens:
///    `GameEventBus.instance.emit(MyEvent());`
class GameEventBus {
  static final GameEventBus instance = GameEventBus._();
  GameEventBus._();

  final Map<Type, List<void Function(Object)>> _listeners = {};

  GameSubscription listen<T extends GameEvent>(void Function(T event) cb) {
    final list = _listeners.putIfAbsent(T, () => <void Function(Object)>[]);

    void wrapper(Object e) => cb(e as T);
    list.add(wrapper);

    return GameSubscription(() {
      list.remove(wrapper);
      if (list.isEmpty) _listeners.remove(T);
    });
  }

  /// Emit an in-game event.
  ///
  /// The event's type is used to route it to the correct listeners.
  void emit<T extends GameEvent>(T event) {
    final list = _listeners[T];
    if (list == null) return;

    for (final cb in List.of(list)) {
      cb(event);
    }
  }
}

/// Base class for all in-game events.
abstract class GameEvent {
  const GameEvent();
}

/// Handle for a registered listener.
///
/// Call [cancel] to remove the listener and avoid leaks.
/// (Similar concept to a StreamSubscription, but lightweight.)
class GameSubscription {
  final VoidCallback cancel;
  const GameSubscription(this.cancel);
}
