import '../models/sudoku_level.dart';
import '../utils/sudoku_generator.dart';

final List<SudokuLevel> sudokuLevels = [
  // 1-2: とても簡単 (ヒント 55-65)
  for (int i = 1; i <= 2; i++)
    SudokuGenerator.generateRandomLevel(id: i, difficulty: 'とても簡単'),
    
  // 3-4: 簡単 (ヒント 40-50)
  for (int i = 3; i <= 4; i++)
    SudokuGenerator.generateRandomLevel(id: i, difficulty: '簡単'),
    
  // 5-6: ふつう (ヒント 32-37)
  for (int i = 5; i <= 6; i++)
    SudokuGenerator.generateRandomLevel(id: i, difficulty: 'ふつう'),
    
  // 7-8: 難しい (ヒント 25-29)
  for (int i = 7; i <= 8; i++)
    SudokuGenerator.generateRandomLevel(id: i, difficulty: '難しい'),
    
  // 9-10: 超難しい (ヒント 19-23)
  for (int i = 9; i <= 10; i++)
    SudokuGenerator.generateRandomLevel(id: i, difficulty: '超難しい'),
];
