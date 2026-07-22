import 'dart:ui';

class L10n {
  static Locale get locale => PlatformDispatcher.instance.locale;

  static bool get isJapanese => locale.languageCode == 'ja';

  static String get appTitle => isJapanese ? '和風数独' : 'Zen Sudoku';
  static String get appSubtitle => isJapanese ? '心和むナンプレ' : 'Soothing Puzzles';
  
  static String get levelSelect => isJapanese ? 'レベル選択' : 'Level Selection';
  static String get randomPlay => isJapanese ? 'ランダムプレイ' : 'Random Play';
  static String get settings => isJapanese ? '設定' : 'Settings';
  
  static String get xpLabel => isJapanese ? '現在の経験値' : 'Current XP';
  
  // Random Play Menu
  static String get randomMenuTitle => isJapanese ? '難易度を選んで開始' : 'Select Difficulty';
  static String get randomAll => isJapanese ? '完全おまかせ' : 'Full Random';
  static String get randomBeginner => isJapanese ? '初級セット (簡単め)' : 'Beginner Set';
  static String get randomAdvanced => isJapanese ? '中上級セット (手応えあり)' : 'Advanced Set';

  // Difficulties
  static String get diffVeryEasy => isJapanese ? 'とても簡単' : 'Very Easy';
  static String get diffEasy => isJapanese ? '簡単' : 'Easy';
  static String get diffNormal => isJapanese ? 'ふつう' : 'Normal';
  static String get diffHard => isJapanese ? '難しい' : 'Hard';
  static String get diffVeryHard => isJapanese ? '超難しい' : 'Insane';

  // Game Page
  static String get levelLabel => isJapanese ? 'レベル' : 'Level';
  static String get randomMode => isJapanese ? 'ランダムモード' : 'Random Mode';
  static String get bgmTooltip => isJapanese ? 'BGMの切り替え' : 'Toggle BGM';
  static String get resetTooltip => isJapanese ? '最初からやり直す' : 'Reset Level';
  static String get hint => isJapanese ? 'ヒント' : 'Hint';
  static String get noteMode => isJapanese ? 'メモ' : 'Notes';
  static String get time => isJapanese ? '時間' : 'Time';
  static String get erase => isJapanese ? '消去' : 'Erase';

  // Dialogs
  static String get reset => isJapanese ? 'リセット' : 'Reset';
  static String get resetConfirm => isJapanese ? '最初からやり直しますか？' : 'Restart from the beginning?';
  static String get cancel => isJapanese ? 'キャンセル' : 'Cancel';
  
  static String get gameClear => isJapanese ? 'ゲームクリア！' : 'Game Clear!';
  static String get gameOver => isJapanese ? 'ゲームオーバー' : 'Game Over';
  static String get clearMessage => isJapanese ? '素晴らしい！クリアしました！' : 'Excellent! Level cleared!';
  static String get xpGained => isJapanese ? '(経験値を獲得しました)' : '(XP earned)';
  static String get gameOverMessage => isJapanese ? 'ミスが制限回数に達しました。' : 'Too many errors.';
  
  static String get nextLevel => isJapanese ? '次のレベルへ' : 'Next Level';
  static String get nextRandom => isJapanese ? '次のランダム問題へ' : 'Next Random';
  static String get back => isJapanese ? '戻る' : 'Back';

  // Level Selection
  static String get startNew => isJapanese ? '最初からスタート' : 'Start New';
  static String get resume => isJapanese ? '途中からスタート' : 'Resume';

  // Settings
  static String get hintLimit => isJapanese ? 'ヒント上限数' : 'Hint Limit';
  static String get lifeLimit => isJapanese ? 'ライフ（ミス制限）' : 'Life (Max Errors)';
  static String get unlockAll => isJapanese ? '全レベル解放' : 'Unlock All Levels';
  static String get unlockAllSub => isJapanese ? 'クリア状況に関わらず全てのレベルを選択可能にします' : 'Enable all levels regardless of progress';
  static String get vibration => isJapanese ? 'バイブレーション' : 'Vibration';
  static String get vibrationSub => isJapanese ? 'ミスした時に端末を振動させます' : 'Vibrate on errors';
  static String get unlimited => isJapanese ? '無制限' : 'Unlimited';
  static String get times => isJapanese ? '回' : 'times';

  // Ranks
  static String get rankLabel => isJapanese ? '段位' : 'Rank';
  static String get rank10 => isJapanese ? '十級：数独見習い' : '10th Kyu: Novice';
  static String get rank7 => isJapanese ? '七級：数独初級' : '7th Kyu: Beginner';
  static String get rank3 => isJapanese ? '三級：数独熟練' : '3rd Kyu: Adept';
  static String get rank1d => isJapanese ? '初段：数独師範' : '1st Dan: Master';
  static String get rank5d => isJapanese ? '五段：数独達人' : '5th Dan: Expert';
  static String get rank9d => isJapanese ? '九段：数独名人' : '9th Dan: Grandmaster';
  static String get rankSaint => isJapanese ? '最高段位：数独聖人' : 'Saint: Sudoku Sage';
}
