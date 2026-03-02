import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  Future<void> saveString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }
  
  Future<void> saveJson(String key, Map<String, dynamic> json) async {
      await _prefs.setString(key, jsonEncode(json));
  }
  
  Map<String, dynamic>? getJson(String key) {
      final String? jsonString = _prefs.getString(key);
      if (jsonString == null) return null;
      return jsonDecode(jsonString);
  }
  Future<void> remove(String key) async {
      await _prefs.remove(key);
  }
}
