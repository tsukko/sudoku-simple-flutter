class SudokuLevel {
  final int id;
  final String difficulty;
  final List<List<int>> initialGrid;
  final List<List<int>> solutionGrid;

  SudokuLevel({
    required this.id,
    required this.difficulty,
    required this.initialGrid,
    required this.solutionGrid,
  });
}
