import 'dart:ui';

class L10n {
  static Locale locale = window.locale;

  static bool get isJapanese => locale.languageCode == 'ja';

  static String get appTitle => isJapanese ? '数独アプリ' : 'Sudoku Flow';
  static String get levelSelect => isJapanese ? 'レベル選択' : 'Level Selection';
  static String get randomPlay => isJapanese ? 'ランダムプレイ' : 'Random Play';
  static String get settings => isJapanese ? '設定' : 'Settings';
  
  static String get hintLimit => isJapanese ? 'ヒント上限数' : 'Hint Limit';
  static String get lifeLimit => isJapanese ? 'ライフ（ミス制限）' : 'Life (Max Errors)';
  static String get unlockAll => isJapanese ? '全レベル解放' : 'Unlock All Levels';
  static String get vibration => isJapanese ? 'バイブレーション' : 'Vibration';
  static String get unlimited => isJapanese ? '無制限' : 'Unlimited';

  static String get reset => isJapanese ? 'リセット' : 'Reset';
  static String get resetConfirm => isJapanese ? '最初からやり直しますか？' : 'Restart from the beginning?';
  static String get cancel => isJapanese ? 'キャンセル' : 'Cancel';
  
  static String get gameClear => isJapanese ? 'ゲームクリア！' : 'Game Clear!';
  static String get gameOver => isJapanese ? 'ゲームオーバー' : 'Game Over';
  static String get nextLevel => isJapanese ? '次のレベルへ' : 'Next Level';
  static String get nextRandom => isJapanese ? '次のランダム問題へ' : 'Next Random';
  static String get back => isJapanese ? '戻る' : 'Back';
  static String get time => isJapanese ? '時間' : 'Time';
  static String get hint => isJapanese ? 'ヒント' : 'Hint';
  static String get erase => isJapanese ? '消去' : 'Erase';

  static String get startNew => isJapanese ? '最初からスタート' : 'Start New';
  static String get resume => isJapanese ? '途中からスタート' : 'Resume';
}
