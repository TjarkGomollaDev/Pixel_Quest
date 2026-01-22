part of 'package:pixel_adventure/game/events/game_event_bus.dart';

enum Lifecycle { paused, resumed }

class GameLifecycleChanged extends GameEvent {
  final Lifecycle lifecycle;
  const GameLifecycleChanged(this.lifecycle);
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
