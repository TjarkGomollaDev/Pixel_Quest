import 'dart:async';
import 'dart:convert';
import 'package:pixel_quest/data/audio/audio_center.dart';
import 'package:pixel_quest/data/static/metadata/level_metadata.dart';
import 'package:pixel_quest/data/static/static_center.dart';
import 'package:pixel_quest/data/static/metadata/world_metadata.dart';
import 'package:pixel_quest/data/storage/entities/inventory_entity.dart';
import 'package:pixel_quest/data/storage/entities/level_entity.dart';
import 'package:pixel_quest/data/storage/entities/settings_entity.dart';
import 'package:pixel_quest/data/storage/entities/world_entity.dart';
import 'package:pixel_quest/data/storage/storage_events.dart';
import 'package:pixel_quest/game/background/background.dart';
import 'package:pixel_quest/game/level/mobile%20controls/mobile_controls.dart';
import 'package:pixel_quest/game/level/player/player.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central access point for mutable, persisted game data.
///
/// The StorageCenter loads and manages player-specific progress and settings
/// Data is cached in memory for fast reads and persisted via SharedPreferences.
/// Changes can emit events so the game layer can react.
class StorageCenter {
  // constructor parameters
  final SharedPreferences _prefs;
  final StaticCenter _staticCenter;

  StorageCenter._(this._prefs, this._staticCenter);

  /// Loads all data and returns a fully initialized StorageCenter instance.
  static Future<StorageCenter> init({required StaticCenter staticCenter}) async {
    final prefs = await SharedPreferences.getInstance();
    final dataCenter = StorageCenter._(prefs, staticCenter);
    await dataCenter.clearAllLevels(); // for testing
    await dataCenter.clearAllWorlds(); // for testing
    // await dataCenter.clearSettings(); // for testing
    // await dataCenter.clearInventory(); // for testing
    dataCenter._loadAllLevels();
    dataCenter._loadAllWorlds();
    dataCenter._loadSettings();
    dataCenter._loadInventory();
    return dataCenter;
  }

  // data
  final Map<String, LevelEntity> _cacheLevelData = {};
  final Map<String, WorldEntity> _cacheWorldData = {};
  final String _highestUnlockedWorldKey = '014809d5-8ec5-4171-a82e-df72e7839d45';
  late SettingsEntity _cacheSettings;
  late InventoryEntity _cacheInventory;

  // stream
  final StreamController<StorageEvent> _onDataChanged = StreamController.broadcast();
  Stream<StorageEvent> get onDataChanged => _onDataChanged.stream;

  // storage keys
  static const String _storageKeySettings = 'key-settings';
  static const String _storageKeyInventory = 'key-inventory';

  // getter
  WorldEntity get highestUnlockedWorld => _cacheWorldData[_highestUnlockedWorldKey]!;
  SettingsEntity get settings => _cacheSettings;
  InventoryEntity get inventory => _cacheInventory;

  void dispose() {
    _onDataChanged.close();
  }

  void _loadAllLevels() {
    final levels = _staticCenter.allLevelsInAllWorlds().flat();
    if (levels.isEmpty) return;
    for (final levelMetadata in levels) {
      _loadLevel(levelMetadata.uuid);
    }
  }

  void _loadLevel(String key) {
    final json = _prefs.getString(key);
    if (json == null) {
      _cacheLevelData[key] = LevelEntity.defaultLevel(uuid: key);
    } else {
      try {
        final map = jsonDecode(json) as Map<String, dynamic>;
        _cacheLevelData[key] = LevelEntity.fromMap(map, key);
      } catch (_) {
        _cacheLevelData[key] = LevelEntity.defaultLevel(uuid: key);
      }
    }
  }

  void _loadAllWorlds() {
    if (_staticCenter.allWorlds().isEmpty) return;
    for (final worldMetadata in _staticCenter.allWorlds()) {
      _loadWorld(worldMetadata.uuid, _staticCenter.allWorlds().indexById(worldMetadata.uuid));
    }
  }

  void _loadWorld(String key, int index) {
    final json = _prefs.getString(key);
    if (json == null) {
      _cacheWorldData[key] = WorldEntity.defaultWorld(uuid: key, locked: index != 1);
    } else {
      try {
        final map = jsonDecode(json) as Map<String, dynamic>;
        _cacheWorldData[key] = WorldEntity.fromMap(map, key);
      } catch (_) {
        _cacheWorldData[key] = WorldEntity.defaultWorld(uuid: key, locked: index != 1);
      }
    }
  }

  void _loadSettings() {
    final json = _prefs.getString(_storageKeySettings);
    if (json == null) {
      _cacheSettings = SettingsEntity.defaultSettings();
    } else {
      try {
        final map = jsonDecode(json) as Map<String, dynamic>;
        _cacheSettings = SettingsEntity.fromMap(map);
      } catch (_) {
        _cacheSettings = SettingsEntity.defaultSettings();
      }
    }
  }

  void _loadInventory() {
    final json = _prefs.getString(_storageKeyInventory);
    if (json == null) {
      _cacheInventory = InventoryEntity.defaultInventory();
    } else {
      try {
        final map = jsonDecode(json) as Map<String, dynamic>;
        _cacheInventory = InventoryEntity.fromMap(map);
      } catch (_) {
        _cacheInventory = InventoryEntity.defaultInventory();
      }
    }
  }

  /// Clears all persisted level data and resets the in-memory cache (test/debug utility only).
  Future<void> clearAllLevels() async {
    for (final levelMetadata in _staticCenter.allLevelsInAllWorlds().flat()) {
      await _prefs.remove(levelMetadata.uuid);
    }
    _cacheLevelData.clear();
  }

  /// Clears all persisted world data and resets the in-memory cache (test/debug utility only).
  Future<void> clearAllWorlds() async {
    for (final worldMetadata in _staticCenter.allWorlds()) {
      await _prefs.remove(worldMetadata.uuid);
    }
    _cacheWorldData.clear();
  }

  /// Clears all persisted settings data (test/debug utility only).
  Future<void> clearSettings() async {
    await _prefs.remove(_storageKeySettings);
  }

  /// Clears all persisted inventory data (test/debug utility only).
  Future<void> clearInventory() async {
    await _prefs.remove(_storageKeyInventory);
  }

  /// Returns the stored data for the given level id.
  LevelEntity levelById(String levelUuid) => _cacheLevelData[levelUuid]!;

  /// Returns the stored data for the given world id.
  WorldEntity worldById(String worldUuid) => _cacheWorldData[worldUuid]!;

  /// Persists the given level data and updates related state if needed.
  Future<void> saveLevel(LevelEntity data, String worldUuid) async {
    final storedData = _cacheLevelData[data.uuid]!;

    // check if any relevant field has changed
    if (!data.shouldReplace(storedData)) return;

    // optimistic cache update
    _cacheLevelData[data.uuid] = data;

    // update stored level data
    final json = jsonEncode(data.toMap());
    await _prefs.setString(data.uuid, json);

    // update stored world data
    final starDiff = data.starDifference(storedData);
    if (starDiff > 0) {
      final updatedWorld = _cacheWorldData[worldUuid]!.copyWithIncreasedStars(starDiff);

      // add event to stream
      _onDataChanged.add(
        NewStarsStorageEvent(
          worldUuid: worldUuid,
          levelUuid: data.uuid,
          totalStars: updatedWorld.stars,
          newStars: starDiff,
          levelStars: data.stars,
        ),
      );

      await saveWorld(updatedWorld);
    }
  }

  /// Persists the given world data.
  Future<void> saveWorld(WorldEntity data) async {
    // optimistic cache update
    _cacheWorldData[data.uuid] = data;

    final json = jsonEncode(data.toMap());
    await _prefs.setString(data.uuid, json);
  }

  /// Persists the given settings data.
  Future<void> saveSettings({
    SoundState? soundState,
    double? sfxVolume,
    double? musicVolume,
    JoystickSetup? joystickSetup,
    bool? showMiniMapAtStart,
  }) async {
    final data = settings.copyWith(
      soundState: soundState,
      sfxVolume: sfxVolume,
      musicVolume: musicVolume,
      joystickSetup: joystickSetup,
      showMiniMapAtStart: showMiniMapAtStart,
    );

    // optimistic cache update
    _cacheSettings = data;

    final json = jsonEncode(data.toMap());
    await _prefs.setString(_storageKeySettings, json);
  }

  /// Persists the given inventory data.
  Future<void> saveInventory({PlayerCharacter? character, BackgroundChoice? levelBackground, BackgroundChoice? loadingBackground}) async {
    final data = inventory.copyWith(character: character, levelBackground: levelBackground, loadingBackground: loadingBackground);

    // optimistic cache update
    _cacheInventory = data;

    final json = jsonEncode(data.toMap());
    await _prefs.setString(_storageKeyInventory, json);
  }
}
