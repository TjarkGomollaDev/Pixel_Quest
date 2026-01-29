import 'package:pixel_adventure/data/static/metadata/level_metadata.dart';
import 'package:pixel_adventure/data/static/metadata/world_metadata.dart';

/// Central access point for static, read-only game data.
///
/// The StaticCenter loads and holds metadata that ships with the game (e.g.
/// worlds and levels). This data does not change at runtime and is typically
/// loaded once during app startup, then reused everywhere.
class StaticCenter {
  StaticCenter._();

  /// Loads all data and returns a fully initialized StaticCenter instance.
  static Future<StaticCenter> init() async {
    final metadataCenter = StaticCenter._();
    await metadataCenter._loadData();
    return metadataCenter;
  }

  // json paths
  static const String _levelsPath = 'assets/data/levels.json';
  static const String _worldsPath = 'assets/data/worlds.json';

  // data
  late final Map<String, List<LevelMetadata>> _allLevels;
  late final List<WorldMetadata> _allWorlds;

  Future<void> _loadData() async {
    _allLevels = await LevelMetadata.loadFromJson(_levelsPath);
    _allWorlds = await WorldMetadata.loadFromJson(_worldsPath);
  }

  /// Returns all level metadata grouped by world.
  Map<String, List<LevelMetadata>> allLevelsInAllWorlds() => _allLevels;

  /// Returns all level metadata entries for the given world id.
  List<LevelMetadata> allLevelsInWorldById(String worldUuid) => _allLevels[worldUuid]!;

  /// Returns all level metadata entries for the world at the given index.
  List<LevelMetadata> allLevelsInWorldByIndex(int worldIndex) => _allLevels[_allWorlds[worldIndex].uuid]!;

  /// Returns the list of all worlds.
  List<WorldMetadata> allWorlds() => _allWorlds;

  /// Returns the world metadata for the given world id.
  WorldMetadata worldById(String worldUuid) => _allWorlds.worldById(worldUuid);
}
