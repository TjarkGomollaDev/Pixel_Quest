import 'dart:async';
import 'dart:convert';
import 'package:pixel_adventure/data/level_data_entity.dart';
import 'package:pixel_adventure/game/level/level_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataCenter {
  final SharedPreferences _prefs;

  DataCenter._(this._prefs);

  static Future<DataCenter> init() async {
    final prefs = await SharedPreferences.getInstance();
    final dataCenter = DataCenter._(prefs);
    // await dataCenter.clearAllLevels();
    dataCenter._loadAllLevels();
    return dataCenter;
  }

  // data
  final Map<String, LevelDataEntity> _cacheLevelData = {};

  // stream
  final StreamController<String> _onLevelDataChanged = StreamController.broadcast();
  Stream<String> get onLevelDataChanged => _onLevelDataChanged.stream;

  LevelDataEntity getLevel(String key) => _cacheLevelData[key]!;

  Future<void> saveLevel(LevelDataEntity data) async {
    final json = jsonEncode(data.toMap());
    await _prefs.setString(data.uuid, json);
    _cacheLevelData[data.uuid] = data;
    _onLevelDataChanged.add(data.uuid);
  }

  void _loadLevel(String key) {
    final json = _prefs.getString(key);
    if (json == null) {
      _cacheLevelData[key] = LevelDataEntity.newLevelData(uuid: key);
    } else {
      try {
        final map = jsonDecode(json) as Map<String, dynamic>;
        _cacheLevelData[key] = LevelDataEntity.fromMap(map, key);
      } catch (_) {
        _cacheLevelData[key] = LevelDataEntity.newLevelData(uuid: key);
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
}
