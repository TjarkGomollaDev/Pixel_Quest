import 'package:flutter/foundation.dart';
import 'package:pixel_quest/game/level/mobile%20controls/mobile_controls.dart';
import 'package:pixel_quest/game/level/player/player.dart';
part 'package:pixel_quest/game/events/game_events.dart';

typedef EventListener<T extends GameEvent> = void Function(T event);
typedef OnEvent = GameSubscription Function<T extends GameEvent>(EventListener<T> handler);
typedef _RawListener = void Function(Object event);

/// Typed event bus for in-game events.
///
/// Use this to broadcast *specific* events (with optional payloads) to Flame
/// components and other non-UI systems without tight coupling.
///
/// Why this exists:
/// - Flame components shouldn't depend on Flutter widget state management.
/// - Lightweight alternative to Streams for simple in-game event dispatch.
/// - Kept per game instance to avoid global state and dangling listeners.
///
/// Lifecycle:
/// - Register listeners with [listen] (single event type) or [listenMany] (multiple).
/// - Keep the returned [GameSubscription] and call [GameSubscription.cancel]
///   when your component is removed/disposed.
///
/// Example:
/// ```dart
/// late final GameSubscription _sub;
///
/// @override
/// void onMount() {
///   _sub = game.eventBus.listenMany((on) {
///     on<GameStateChanged>((event) { /* ... */ });
///     on<NewStarsEarned>((event) { /* ... */ });
///   });
/// }
///
/// @override
/// void onRemove() {
///   _sub.cancel();
/// }
/// ```
class GameEventBus {
  final Map<Type, List<_RawListener>> _listeners = {};

  /// Listen for a single event type [T].
  ///
  /// Returns a [GameSubscription] that must be cancelled to avoid leaks.
  GameSubscription listen<T extends GameEvent>(EventListener<T> handler) {
    final list = _listeners.putIfAbsent(T, () => <_RawListener>[]);

    void wrapper(Object e) => handler(e as T);
    list.add(wrapper);

    return GameSubscription([
      () {
        list.remove(wrapper);
        if (list.isEmpty) _listeners.remove(T);
      },
    ]);
  }

  /// Register multiple listeners and get a single [GameSubscription] back.
  ///
  /// This is just a convenience to avoid managing multiple subscriptions.
  /// If you need individual subs as well, the returned value of `on<T>(...)`
  /// is the individual subscription.
  GameSubscription listenMany(void Function(OnEvent on) build) {
    final group = GameSubscription();

    GameSubscription on<T extends GameEvent>(EventListener<T> handler) {
      final sub = listen<T>(handler);
      group._add(sub);
      return sub;
    }

    try {
      build(on);
    } catch (_) {
      group.cancel();
      rethrow;
    }

    return group;
  }

  /// Emit an in-game event.
  ///
  /// The event's type is used to route it to the correct listeners.
  /// Note: listeners are matched by the event's *runtimeType* (exact type).
  void emit(GameEvent event) {
    final list = _listeners[event.runtimeType];
    if (list == null) return;

    // snapshot the list so listeners can safely unregister themselves during emit
    for (final handler in List.of(list)) {
      handler(event);
    }
  }
}

/// A lightweight handle for one or many event listeners.
///
/// Call [cancel] to remove all registered event listeners and avoid leaks.
/// (Similar concept to a StreamSubscription, but lightweight.)
class GameSubscription {
  final List<VoidCallback> _cancellers;
  bool _cancelled = false;

  /// Creates a subscription from one or more cancellation callbacks.
  ///
  /// Usually you don't call this directly; it is returned by [GameEventBus.listen]
  /// or built through [GameEventBus.listenMany].
  GameSubscription([List<VoidCallback>? cancellers]) : _cancellers = cancellers ?? [];

  /// Adds another subscription into this subscription.
  ///
  /// Cancelling this subscription will also cancel [other].
  void _add(GameSubscription other) {
    if (_cancelled) return;
    _cancellers.add(other.cancel);
  }

  /// Cancels all registered listeners.
  ///
  /// Cancellation is executed in reverse registration order (LIFO), which is a
  /// small safety net when later listeners depend on earlier ones.
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;

    for (final c in _cancellers.reversed) {
      c();
    }
    _cancellers.clear();
  }
}

/// Base class for all in-game events.
abstract class GameEvent {
  const GameEvent();
}
