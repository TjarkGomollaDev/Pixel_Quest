import 'package:flutter/foundation.dart';

enum SettingsEvent { volume }

/// A lightweight event-based settings notifier.
///
/// This class allows different parts of the game to react to specific
/// settings changes (e.g., volume updates) without requiring direct
/// references between components.
///
/// Usage:
/// - Register a listener for a specific settings event with `addListenerFor`.
/// - Trigger an event using `notify`.
/// - Remove listeners when no longer needed to avoid memory leaks.
///
/// This avoids the overhead of Streams or ChangeNotifier while keeping
/// communication between systems clean and decoupled.
class SettingsNotifier {
  static final SettingsNotifier instance = SettingsNotifier._();
  SettingsNotifier._();

  final Map<SettingsEvent, List<VoidCallback>> _listeners = {};

  void addListenerFor(SettingsEvent event, VoidCallback callback) {
    _listeners.putIfAbsent(event, () => []).add(callback);
  }

  void removeListenerFor(SettingsEvent event, VoidCallback callback) {
    _listeners[event]?.remove(callback);
  }

  void notify(SettingsEvent event) {
    for (final cb in _listeners[event] ?? []) {
      cb();
    }
  }
}
