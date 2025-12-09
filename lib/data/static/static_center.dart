import 'package:pixel_adventure/data/static/metadata/character_data.dart';
import 'package:pixel_adventure/data/static/metadata/level_metadata.dart';
import 'package:pixel_adventure/data/static/metadata/world_metadata.dart';
import 'package:pixel_adventure/game/level/player.dart';

class StaticCenter {
  StaticCenter._();

  static Future<StaticCenter> init() async {
    final metadataCenter = StaticCenter._();
    await metadataCenter._loadData();
    return metadataCenter;
  }

  // json paths
  static const String _levelsPath = 'assets/data/levels.json';
  static const String _worldsPath = 'assets/data/worlds.json';
  static const String _charactersPath = 'assets/data/characters.json';

  // data
  late final Map<String, List<LevelMetadata>> _allLevels;
  late final List<WorldMetadata> _allWorlds;
  late final Map<PlayerCharacter, CharacterMetadata> _allCharacters;

  // getter
  List<LevelMetadata> allLevelsInOneWorld(String worldUuid) => _allLevels[worldUuid]!;
  List<LevelMetadata> allLevelsInOneWorldByIndex(int index) => _allLevels[_allWorlds[index].uuid]!;
  Map<String, List<LevelMetadata>> get allLevelsInAllWorlds => _allLevels;
  List<WorldMetadata> get allWorlds => _allWorlds;
  WorldMetadata getWorld(String worldUuid) => _allWorlds.getWorldByUUID(worldUuid);
  Map<PlayerCharacter, CharacterMetadata> get allCharacters => _allCharacters;

  Future<void> _loadData() async {
    _allLevels = await LevelMetadata.loadFromJson(_levelsPath);
    _allWorlds = await WorldMetadata.loadFromJson(_worldsPath);
    _allCharacters = await CharacterMetadata.loadFromJson(_charactersPath);
  }
}
