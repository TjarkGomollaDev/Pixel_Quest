import 'dart:async';
import 'dart:convert';
import 'package:pixel_adventure/data/entities/level_entity.dart';
import 'package:pixel_adventure/data/entities/settings_entity.dart';
import 'package:pixel_adventure/game/level/level_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataCenter {
  final SharedPreferences _prefs;

  DataCenter._(this._prefs);

  static Future<DataCenter> init() async {
    final prefs = await SharedPreferences.getInstance();
    final dataCenter = DataCenter._(prefs);
    await dataCenter.clearAllLevels(); // for testing
    dataCenter._loadAllLevels();
    dataCenter._loadSettings();
    return dataCenter;
  }

  // data
  final Map<String, LevelEntity> _cacheLevelData = {};
  late SettingsEntity _cacheSettings;

  // getter
  LevelEntity getLevel(String key) => _cacheLevelData[key]!;
  SettingsEntity get settings => _cacheSettings;

  // stream
  final StreamController<String> _onLevelDataChanged = StreamController.broadcast();
  Stream<String> get onLevelDataChanged => _onLevelDataChanged.stream;

  // keys
  static const String _storageKeyUserSettings = 'user-settings';

  Future<void> saveLevel(LevelEntity data) async {
    final json = jsonEncode(data.toMap());
    await _prefs.setString(data.uuid, json);
    _cacheLevelData[data.uuid] = data;
    _onLevelDataChanged.add(data.uuid);
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
