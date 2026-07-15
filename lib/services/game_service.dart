import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GameService {
  static const String _unlockedLevelKey = 'unlocked_level';
  static const String _progressPrefix = 'progress_';
  static const String _totalXpKey = 'total_xp';

  // XPを取得
  static Future<int> getTotalXp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalXpKey) ?? 0;
  }

  // XPを加算
  static Future<void> addXp(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    int currentXp = await getTotalXp();
    await prefs.setInt(_totalXpKey, currentXp + amount);
  }

  // 段位を取得
  static String getRank(int xp) {
    if (xp >= 5000) return '最高段位：数独聖人';
    if (xp >= 2000) return '九段：数独名人';
    if (xp >= 1000) return '五段：数独達人';
    if (xp >= 500) return '初段：数独師範';
    if (xp >= 200) return '三級：数独熟練';
    if (xp >= 50) return '七級：数独初級';
    return '十級：数独見習い';
  }

  // 解放されている最大レベルを取得 (デフォルトは1)
  static Future<int> getUnlockedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_unlockedLevelKey) ?? 1;
  }

  // レベルを解放する
  static Future<void> unlockLevel(int levelId) async {
    final prefs = await SharedPreferences.getInstance();
    int currentUnlocked = await getUnlockedLevel();
    if (levelId > currentUnlocked) {
      await prefs.setInt(_unlockedLevelKey, levelId);
    }
  }

  // 進捗を保存する
  static Future<void> saveProgress({
    required int levelId,
    required List<List<int>> currentGrid,
    required int errorCount,
    required int secondsElapsed,
    required int hintCount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'grid': currentGrid,
      'errors': errorCount,
      'seconds': secondsElapsed,
      'hints': hintCount,
    };
    await prefs.setString('$_progressPrefix$levelId', jsonEncode(data));
  }

  // 進捗をロードする
  static Future<Map<String, dynamic>?> loadProgress(int levelId) async {
    final prefs = await SharedPreferences.getInstance();
    String? json = prefs.getString('$_progressPrefix$levelId');
    if (json == null) return null;
    
    final Map<String, dynamic> data = jsonDecode(json);
    // JSONからは List<dynamic> で戻ってくるので List<List<int>> に変換
    List<List<int>> grid = (data['grid'] as List)
        .map((row) => (row as List).map((cell) => cell as int).toList())
        .toList();
    
    return {
      'grid': grid,
      'errors': data['errors'],
      'seconds': data['seconds'],
      'hints': data['hints'],
    };
  }

  // 進捗を削除する (クリア時や最初から始める時)
  static Future<void> clearProgress(int levelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_progressPrefix$levelId');
  }
}
