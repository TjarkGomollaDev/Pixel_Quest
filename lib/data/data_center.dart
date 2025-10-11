import 'dart:convert';
import 'package:pixel_adventure/data/level_data_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataCenter {
  final SharedPreferences _prefs;

  // data
  final Map<int, LevelDataEntity> _cacheLevels = {};
  int _cacheTotalLevels = 0;

  // keys
  String _levelKey(int index) => 'level-$index';
  static const String _keyTotalLevels = 'total-levels';

  DataCenter._(this._prefs);

  static Future<DataCenter> init() async {
    final prefs = await SharedPreferences.getInstance();
    final dataCenter = DataCenter._(prefs);
    dataCenter._loadTotalLevels();
    dataCenter._loadAllLevels();
    return dataCenter;
  }

  // getter
  int get totalLevels => _cacheTotalLevels;
  LevelDataEntity getLevel(int index) => _cacheLevels[index]!;

  Future<void> saveTotalLevels(int total) async {
    await _prefs.setInt(_keyTotalLevels, total);
    _cacheTotalLevels = total;
  }

  void _loadTotalLevels() => _cacheTotalLevels = _prefs.getInt(_keyTotalLevels) ?? 0;

  Future<void> saveLevel(LevelDataEntity data) async {
    final json = jsonEncode(data.toMap());
    await _prefs.setString(_levelKey(data.index), json);
    _cacheLevels[data.index] = data;
  }

  void _loadLevel(int index) {
    final json = _prefs.getString(_levelKey(index));
    if (json == null) {
      _cacheLevels[index] = LevelDataEntity.newLevelData(index: index);
    } else {
      try {
        final map = jsonDecode(json) as Map<String, dynamic>;
        _cacheLevels[index] = LevelDataEntity.fromMap(map, index);
      } catch (_) {
        _cacheLevels[index] = LevelDataEntity.newLevelData(index: index);
      }
    }
  }

  void _loadAllLevels() {
    if (_cacheTotalLevels <= 0) return;
    for (int i = 1; i <= _cacheTotalLevels; i++) {
      _loadLevel(i);
    }
  }

  Future<void> clearAllLevels() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith('level-')).toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
    _cacheLevels.clear();
    await _prefs.remove(_keyTotalLevels);
    _cacheTotalLevels = 0;
  }
}
