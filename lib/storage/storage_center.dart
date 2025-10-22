import 'dart:async';
import 'dart:convert';
import 'package:pixel_adventure/data/world_data.dart';
import 'package:pixel_adventure/storage/entities/level_entity.dart';
import 'package:pixel_adventure/storage/entities/settings_entity.dart';
import 'package:pixel_adventure/data/level_data.dart';
import 'package:pixel_adventure/storage/entities/world_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum StorageEventType { level, world }

class StorageEvent {
  final StorageEventType type;
  final String uuid;

  StorageEvent(this.type, this.uuid);
}

class StorageCenter {
  final SharedPreferences _prefs;

  StorageCenter._(this._prefs);

  static Future<StorageCenter> init() async {
    final prefs = await SharedPreferences.getInstance();
    final dataCenter = StorageCenter._(prefs);
    await dataCenter.clearAllLevels(); // for testing
    await dataCenter.clearAllWorlds(); // for testing
    dataCenter._loadAllLevels();
    dataCenter._loadAllWorlds();
    dataCenter._loadSettings();
    return dataCenter;
  }

  // data
  final Map<String, LevelEntity> _cacheLevelData = {};
  final Map<String, WorldEntity> _cacheWorldData = {};
  final String _highestUnlockedWorldKey = '014809d5-8ec5-4171-a82e-df72e7839d45';
  late SettingsEntity _cacheSettings;

  // getter
  LevelEntity getLevel(String key) => _cacheLevelData[key]!;
  WorldEntity getWorld(String key) => _cacheWorldData[key]!;
  WorldEntity get highestUnlockedWorld => _cacheWorldData[_highestUnlockedWorldKey]!;
  SettingsEntity get settings => _cacheSettings;

  // stream
  final StreamController<StorageEvent> _onDataChanged = StreamController.broadcast();
  Stream<StorageEvent> get onDataChanged => _onDataChanged.stream;

  // keys
  static const String _storageKeyUserSettings = 'user-settings';

  Future<void> saveLevel(LevelEntity data) async {
    final storedData = _cacheLevelData[data.uuid]!;

    // check if any relevant field has changed
    if (!data.shouldReplace(storedData)) return;

    // update level data
    final json = jsonEncode(data.toMap());
    await _prefs.setString(data.uuid, json);
    _cacheLevelData[data.uuid] = data;
    _onDataChanged.add(StorageEvent(StorageEventType.level, data.uuid));

    // update world data
    final starDiff = data.starDifference(storedData);
    if (starDiff > 0) {
      final uuid = allWorlds.getByLevelUUID(data.uuid);
      final updatedWorld = _cacheWorldData[uuid]!.copyWithIncreasedStars(starDiff);
      await saveWorld(updatedWorld);
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

  void _loadAllLevels() {
    if (allLevels.isEmpty) return;
    for (var levelMetadata in allLevels) {
      _loadLevel(levelMetadata.uuid);
    }
  }

  Future<void> clearAllLevels() async {
    for (var levelMetadata in allLevels) {
      await _prefs.remove(levelMetadata.uuid);
    }
    _cacheLevelData.clear();
  }

  Future<void> saveWorld(WorldEntity data) async {
    final json = jsonEncode(data.toMap());
    await _prefs.setString(data.uuid, json);
    _cacheWorldData[data.uuid] = data;
    _onDataChanged.add(StorageEvent(StorageEventType.world, data.uuid));
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

  void _loadAllWorlds() {
    if (allWorlds.isEmpty) return;
    for (var worldMetadata in allWorlds) {
      _loadWorld(worldMetadata.uuid, worldMetadata.index);
    }
  }

  Future<void> clearAllWorlds() async {
    for (var worldMetadata in allWorlds) {
      await _prefs.remove(worldMetadata.uuid);
    }
    _cacheWorldData.clear();
  }

  Future<void> saveSettings(SettingsEntity data) async {
    final json = jsonEncode(data.toMap());
    await _prefs.setString(_storageKeyUserSettings, json);
    _cacheSettings = data;
  }

  void _loadSettings() {
    final json = _prefs.getString(_storageKeyUserSettings);
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
}
