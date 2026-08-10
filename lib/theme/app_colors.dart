import 'package:flutter/material.dart';

class AppColors {
  static const Color tokiwa = Color(0xFF2D5A27); // 常盤色 (深い緑)
  static const Color kurumi = Color(0xFF5D4037); // 胡桃色 (土茶)
  static const Color washi = Color(0xFFF7F1E3);  // 和紙 (温かみのあるベージュ)
  static const Color wakakusa = Color(0xFF6B8E23); // 若草 (正しい入力)
  static const Color enji = Color(0xFFB22D35);    // 臙脂 (間違い)
  
  static Color highlightedCell = tokiwa.withValues(alpha: 0.05);
  static Color selectedCell = tokiwa.withValues(alpha: 0.15);
}
