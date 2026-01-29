part of 'package:pixel_adventure/game/events/game_event_bus.dart';

enum Lifecycle { paused, resumed }

enum PageAction { opend, closed }

class GameLifecycleChanged extends GameEvent {
  final Lifecycle lifecycle;
  final bool reset;
  const GameLifecycleChanged(this.lifecycle, {this.reset = false});
}

class LevelLifecycleChanged extends GameEvent {
  final Lifecycle lifecycle;
  const LevelLifecycleChanged(this.lifecycle);
}

class ControlSettingsChanged extends GameEvent {
  final JoystickSetup setup;
  const ControlSettingsChanged(this.setup);
}

class PlayerRespawned extends GameEvent {
  const PlayerRespawned();
}

class InventoryStateChanged extends GameEvent {
  final PageAction action;
  const InventoryStateChanged(this.action);
}

class InventoryChangedCharacter extends GameEvent {
  final PlayerCharacter character;
  InventoryChangedCharacter(this.character);
}

class NewStarsEarned extends GameEvent {
  final String worldUuid;
  final String levelUuid;
  final int totalStars;
  final int newStars;
  final int levelStars;

  const NewStarsEarned({
    required this.worldUuid,
    required this.levelUuid,
    required this.totalStars,
    required this.newStars,
    required this.levelStars,
  });
}
