abstract class StorageEvent {
  const StorageEvent();
}

class NewStarsStorageEvent extends StorageEvent {
  final String worldUuid;
  final String levelUuid;
  final int totalStars;
  final int newStars;
  final int levelStars;

  const NewStarsStorageEvent({
    required this.worldUuid,
    required this.levelUuid,
    required this.totalStars,
    required this.newStars,
    required this.levelStars,
  });
}
