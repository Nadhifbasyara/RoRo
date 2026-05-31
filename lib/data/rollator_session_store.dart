import 'package:shared_preferences/shared_preferences.dart';

class RollatorSessionStore {
  static const String _activeRollatorCodeKey = 'active_rollator_code';

  static Future<void> saveRollatorCode(String rollatorCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeRollatorCodeKey, rollatorCode.trim());
  }

  static Future<String?> loadRollatorCode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_activeRollatorCodeKey);
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static Future<bool> hasActiveSession() async {
    return (await loadRollatorCode()) != null;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeRollatorCodeKey);
  }
}