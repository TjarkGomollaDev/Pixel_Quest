import 'package:pixel_quest/game/background/background.dart';
import 'package:pixel_quest/game/level/player/player.dart';

class InventoryEntity {
  // constructor parameters
  final PlayerCharacter character;
  final BackgroundChoice levelBackground;
  final BackgroundChoice loadingBackground;

  const InventoryEntity({required this.character, required this.levelBackground, required this.loadingBackground});

  InventoryEntity.defaultInventory()
    : this(
        character: PlayerCharacter.defaultCharacter,
        levelBackground: BackgroundChoice.worldDefault(),
        loadingBackground: BackgroundChoice.scene(BackgroundScene.scene3),
      );

  Map<String, dynamic> toMap() => {
    'character': character.name,
    'levelBackground': levelBackground.toMap(),
    'loadingBackground': loadingBackground.toMap(),
  };

  factory InventoryEntity.fromMap(Map<String, dynamic> map) {
    return InventoryEntity(
      character: PlayerCharacter.fromName(map['character'] as String),
      levelBackground: BackgroundChoice.fromMap(map['levelBackground'] as Map<String, dynamic>),
      loadingBackground: BackgroundChoice.fromMap(map['loadingBackground'] as Map<String, dynamic>),
    );
  }

  InventoryEntity copyWith({PlayerCharacter? character, BackgroundChoice? levelBackground, BackgroundChoice? loadingBackground}) {
    return InventoryEntity(
      character: character ?? this.character,
      levelBackground: levelBackground ?? this.levelBackground,
      loadingBackground: loadingBackground ?? this.loadingBackground,
    );
  }
}
