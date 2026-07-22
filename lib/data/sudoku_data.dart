import '../models/sudoku_level.dart';
import '../utils/sudoku_generator.dart';

final List<SudokuLevel> sudokuLevels = [
  // 1-20: とても簡単 (ヒント 55-65)
  for (int i = 1; i <= 20; i++)
    SudokuGenerator.generateRandomLevel(id: i, difficulty: 'とても簡単', seed: i),
    
  // 21-40: 簡単 (ヒント 40-50)
  for (int i = 21; i <= 40; i++)
    SudokuGenerator.generateRandomLevel(id: i, difficulty: '簡単', seed: i),
    
  // 41-60: ふつう (ヒント 32-37)
  for (int i = 41; i <= 60; i++)
    SudokuGenerator.generateRandomLevel(id: i, difficulty: 'ふつう', seed: i),
    
  // 61-80: 難しい (ヒント 25-29)
  for (int i = 61; i <= 80; i++)
    SudokuGenerator.generateRandomLevel(id: i, difficulty: '難しい', seed: i),
    
  // 81-100: 超難しい (ヒント 19-23)
  for (int i = 81; i <= 100; i++)
    SudokuGenerator.generateRandomLevel(id: i, difficulty: '超難しい', seed: i),
];
