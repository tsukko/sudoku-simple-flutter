import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n.dart';

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
    if (xp >= 5000) return L10n.rankSaint;
    if (xp >= 2000) return L10n.rank9d;
    if (xp >= 1000) return L10n.rank5d;
    if (xp >= 500) return L10n.rank1d;
    if (xp >= 200) return L10n.rank3;
    if (xp >= 50) return L10n.rank7;
    return L10n.rank10;
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
    required List<List<Set<int>>> notesGrid,
    required int errorCount,
    required int secondsElapsed,
    required int hintCount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // SetをListに変換してからシリアライズ
    final serializedNotes = notesGrid.map((row) => row.map((set) => set.toList()).toList()).toList();
    
    final data = {
      'grid': currentGrid,
      'notes': serializedNotes,
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
    // Gridの復元
    List<List<int>> grid = (data['grid'] as List)
        .map((row) => (row as List).map((cell) => cell as int).toList())
        .toList();
    
    // Notesの復元
    List<List<Set<int>>> notes = (data['notes'] as List?)
        ?.map((row) => (row as List).map((cell) => (cell as List).map((n) => n as int).toSet()).toList())
        .toList() ?? List.generate(9, (i) => List.generate(9, (j) => <int>{}));
    
    return {
      'grid': grid,
      'notes': notes,
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
