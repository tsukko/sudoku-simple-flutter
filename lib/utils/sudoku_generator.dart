import 'dart:math';
import '../models/sudoku_level.dart';

class SudokuGenerator {
  static SudokuLevel generateRandomLevel({required int id, required String difficulty}) {
    // 1. まず完成した盤面を作る
    List<List<int>> solution = _generateSolvedGrid();
    
    // 2. 難易度に応じたターゲットのヒント数を設定
    int targetClues;
    switch (difficulty) {
      case 'とても簡単': targetClues = 55 + Random().nextInt(5); break;
      case '簡単': targetClues = 42 + Random().nextInt(5); break;
      case 'ふつう': targetClues = 32 + Random().nextInt(4); break;
      case '難しい': targetClues = 26 + Random().nextInt(3); break;
      case '超難しい': targetClues = 21 + Random().nextInt(3); break;
      default: targetClues = 30;
    }
    
    // 3. 唯一解を維持しながら数字を抜いていく
    List<List<int>> initial = List.generate(9, (r) => List.from(solution[r]));
    _removeCellsSmartly(initial, targetClues);

    return SudokuLevel(
      id: id,
      difficulty: difficulty,
      initialGrid: initial,
      solutionGrid: solution,
    );
  }

  // --- 盤面生成ロジック ---

  static List<List<int>> _generateSolvedGrid() {
    List<List<int>> grid = List.generate(9, (_) => List.filled(9, 0));
    _fillGrid(grid);
    return grid;
  }

  static bool _fillGrid(List<List<int>> grid) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (grid[row][col] == 0) {
          List<int> numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle();
          for (int num in numbers) {
            if (_isSafe(grid, row, col, num)) {
              grid[row][col] = num;
              if (_fillGrid(grid)) return true;
              grid[row][col] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  static bool _isSafe(List<List<int>> grid, int row, int col, int num) {
    for (int x = 0; x < 9; x++) if (grid[row][x] == num) return false;
    for (int x = 0; x < 9; x++) if (grid[x][col] == num) return false;
    int startRow = row - row % 3, startCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (grid[i + startRow][j + startCol] == num) return false;
      }
    }
    return true;
  }

  // --- 唯一解を保つための賢い削除ロジック ---

  static void _removeCellsSmartly(List<List<int>> grid, int targetClues) {
    List<int> positions = List.generate(81, (i) => i)..shuffle();
    int removed = 0;
    int currentClues = 81;

    for (int pos in positions) {
      if (currentClues <= targetClues) break;

      int r = pos ~/ 9;
      int c = pos % 9;
      int temp = grid[r][c];
      
      grid[r][c] = 0;
      
      // この数字を抜いても解が「唯一」かチェック
      if (_countSolutions(grid) == 1) {
        currentClues--;
      } else {
        // 解が複数できてしまうなら元に戻す
        grid[r][c] = temp;
      }
    }
  }

  // 解の個数を数える（シンプルにするため2つ見つかったら打ち切る）
  static int _countSolutions(List<List<int>> grid, {int limit = 2}) {
    int count = 0;
    
    bool solve(List<List<int>> g) {
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (g[r][c] == 0) {
            for (int n = 1; n <= 9; n++) {
              if (_isSafe(g, r, c, n)) {
                g[r][c] = n;
                if (solve(g)) {
                  if (count >= limit) return true;
                }
                g[r][c] = 0;
              }
            }
            return false;
          }
        }
      }
      count++;
      return count >= limit;
    }

    List<List<int>> copy = List.generate(9, (r) => List.from(grid[r]));
    solve(copy);
    return count;
  }
}
