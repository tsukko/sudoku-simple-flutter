import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _hintLimitKey = 'setting_hint_limit';
  static const String _lifeLimitKey = 'setting_life_limit';
  static const String _unlockAllKey = 'setting_unlock_all';
  static const String _vibrationEnabledKey = 'setting_vibration_enabled';
  static const String _bgmEnabledKey = 'setting_bgm_enabled';

  // BGM設定
  static Future<bool> isBgmEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_bgmEnabledKey) ?? true;
  }

  static Future<void> setBgmEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bgmEnabledKey, value);
  }

  // バイブレーション設定
  static Future<bool> isVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vibrationEnabledKey) ?? true;
  }

  static Future<void> setVibrationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationEnabledKey, value);
  }

  // ヒント設定 (0は無制限)
  static Future<int> getHintLimit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_hintLimitKey) ?? 3;
  }

  static Future<void> setHintLimit(int limit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hintLimitKey, limit);
  }

  // ライフ設定 (0は無制限)
  static Future<int> getLifeLimit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lifeLimitKey) ?? 5;
  }

  static Future<void> setLifeLimit(int limit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lifeLimitKey, limit);
  }

  // 全解放設定
  static Future<bool> isUnlockAll() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_unlockAllKey) ?? false;
  }

  static Future<void> setUnlockAll(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_unlockAllKey, value);
  }
}
