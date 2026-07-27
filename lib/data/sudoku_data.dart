class LevelConfig {
  final int id;
  final String difficulty;
  const LevelConfig({required this.id, required this.difficulty});
}

final List<LevelConfig> sudokuLevelConfigs = [
  // 1-20: とても簡単
  for (int i = 1; i <= 20; i++)
    LevelConfig(id: i, difficulty: 'とても簡単'),
    
  // 21-40: 簡単
  for (int i = 21; i <= 40; i++)
    LevelConfig(id: i, difficulty: '簡単'),
    
  // 41-60: ふつう
  for (int i = 41; i <= 60; i++)
    LevelConfig(id: i, difficulty: 'ふつう'),
    
  // 61-80: 難しい
  for (int i = 61; i <= 80; i++)
    LevelConfig(id: i, difficulty: '難しい'),
    
  // 81-100: 超難しい
  for (int i = 81; i <= 100; i++)
    LevelConfig(id: i, difficulty: '超難しい'),
];

String getDifficultyById(int id) {
  if (id <= 20) return 'とても簡単';
  if (id <= 40) return '簡単';
  if (id <= 60) return 'ふつう';
  if (id <= 80) return '難しい';
  return '超難しい';
}
