import '../models/sudoku_level.dart';
import '../utils/sudoku_generator.dart';

final List<SudokuLevel> sudokuLevels = [
  // 1-10: とても簡単 (ヒント 55-65)
  for (int i = 1; i <= 10; i++)
    SudokuGenerator.generateRandomLevel(id: i, difficulty: 'とても簡単'),
    
  // 11-20: 簡単 (ヒント 40-50)
  for (int i = 11; i <= 20; i++)
    SudokuGenerator.generateRandomLevel(id: i, difficulty: '簡単'),
    
  // 21-30: ふつう (ヒント 32-37)
  for (int i = 21; i <= 30; i++)
    SudokuGenerator.generateRandomLevel(id: i, difficulty: 'ふつう'),
    
  // 31-40: 難しい (ヒント 25-29)
  for (int i = 31; i <= 40; i++)
    SudokuGenerator.generateRandomLevel(id: i, difficulty: '難しい'),
    
  // 41-50: 超難しい (ヒント 19-23)
  for (int i = 41; i <= 50; i++)
    SudokuGenerator.generateRandomLevel(id: i, difficulty: '超難しい'),
];
