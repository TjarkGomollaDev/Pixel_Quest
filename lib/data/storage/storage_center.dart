import 'dart:async';
import 'dart:convert';
import 'package:pixel_adventure/data/audio/audio_center.dart';
import 'package:pixel_adventure/data/static/metadata/level_metadata.dart';
import 'package:pixel_adventure/data/static/static_center.dart';
import 'package:pixel_adventure/data/static/metadata/world_metadata.dart';
import 'package:pixel_adventure/data/storage/entities/level_entity.dart';
import 'package:pixel_adventure/data/storage/entities/settings_entity.dart';
import 'package:pixel_adventure/data/storage/entities/world_entity.dart';
import 'package:pixel_adventure/game/hud/entity_on_mini_map.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class StorageEvent {
  const StorageEvent();
}

class NewStarsStorageEvent extends StorageEvent {
  final String worldUuid;
  final String levelUuid;
  final int totalStars;
  final int newStars;

  const NewStarsStorageEvent({required this.worldUuid, required this.levelUuid, required this.totalStars, required this.newStars});
}

class StorageCenter {
  // constructor parameters
  final SharedPreferences _prefs;
  final StaticCenter _staticCenter;

  StorageCenter._(this._prefs, this._staticCenter);

  static Future<StorageCenter> init({required StaticCenter staticCenter}) async {
    final prefs = await SharedPreferences.getInstance();
    final dataCenter = StorageCenter._(prefs, staticCenter);
    await dataCenter.clearSettings(); // for testing
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

  Future<void> saveLevel({required LevelEntity data, required String worldUuid}) async {
    final storedData = _cacheLevelData[data.uuid]!;

    // check if any relevant field has changed
    if (!data.shouldReplace(storedData)) return;

    // update level data
    final json = jsonEncode(data.toMap());
    await _prefs.setString(data.uuid, json);
    _cacheLevelData[data.uuid] = data;

    // update world data
    final starDiff = data.starDifference(storedData);
    if (starDiff > 0) {
      final updatedWorld = _cacheWorldData[worldUuid]!.copyWithIncreasedStars(starDiff);
      await saveWorld(updatedWorld, starDiff);
      _onDataChanged.add(
        NewStarsStorageEvent(worldUuid: worldUuid, levelUuid: data.uuid, totalStars: updatedWorld.stars, newStars: starDiff),
      );
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
    final levels = _staticCenter.allLevelsInAllWorlds.flat();
    if (levels.isEmpty) return;
    for (var levelMetadata in levels) {
      _loadLevel(levelMetadata.uuid);
    }
  }

  Future<void> clearAllLevels() async {
    for (var levelMetadata in _staticCenter.allLevelsInAllWorlds.flat()) {
      await _prefs.remove(levelMetadata.uuid);
    }
    _cacheLevelData.clear();
  }

  Future<void> saveWorld(WorldEntity data, int newStars) async {
    final json = jsonEncode(data.toMap());
    await _prefs.setString(data.uuid, json);
    _cacheWorldData[data.uuid] = data;
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
    if (_staticCenter.allWorlds.isEmpty) return;
    for (var worldMetadata in _staticCenter.allWorlds) {
      _loadWorld(worldMetadata.uuid, _staticCenter.allWorlds.getIndexByUUID(worldMetadata.uuid));
    }
  }

  Future<void> clearAllWorlds() async {
    for (var worldMetadata in _staticCenter.allWorlds) {
      await _prefs.remove(worldMetadata.uuid);
    }
    _cacheWorldData.clear();
  }

  Future<void> _saveSettings(SettingsEntity data) async {
    final json = jsonEncode(data.toMap());
    await _prefs.setString(_storageKeyUserSettings, json);
    _cacheSettings = data;
  }

  Future<void> updateSettings({
    SoundState? soundState,
    double? sfxVolume,
    double? musicVolume,
    PlayerCharacter? character,
    PlayerMiniMapMarkerType? playerMarker,
    int? worldSkin,
  }) async => await _saveSettings(
    settings.copyWith(
      soundState: soundState,
      sfxVolume: sfxVolume,
      musicVolume: musicVolume,
      character: character,
      playerMarker: playerMarker,
      worldSkin: worldSkin,
    ),
  );

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

  Future<void> clearSettings() async {
    await _prefs.remove(_storageKeyUserSettings);
  }
}
