import 'package:flutter/material.dart';
import 'data/sudoku_data.dart';
import 'sudoku_page.dart';
import 'services/game_service.dart';
import 'services/settings_service.dart';
import 'models/sudoku_level.dart';

class LevelSelectionPage extends StatefulWidget {
  const LevelSelectionPage({super.key});

  @override
  State<LevelSelectionPage> createState() => _LevelSelectionPageState();
}

class _LevelSelectionPageState extends State<LevelSelectionPage> {
  int _unlockedLevel = 1;
  bool _unlockAll = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final level = await GameService.getUnlockedLevel();
    final unlockAll = await SettingsService.isUnlockAll();
    if (mounted) {
      setState(() {
        _unlockedLevel = level;
        _unlockAll = unlockAll;
        _isLoading = false;
      });
    }
  }

  String _getDifficultyName(String difficulty) {
    switch (difficulty) {
      case 'とても簡単': return 'とても簡単';
      case '簡単': return '簡単';
      case 'ふつう': return 'ふつう';
      case '難しい': return '難しい';
      case '超難しい': return '超難しい';
      default: return difficulty;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('レベル選択'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: sudokuLevels.length,
        itemBuilder: (context, index) {
          final level = sudokuLevels[index];
          bool isLocked = !_unlockAll && level.id > _unlockedLevel;

          return ElevatedButton(
            onPressed: isLocked ? null : () => _handleLevelTap(context, level),
            style: ElevatedButton.styleFrom(
              backgroundColor: isLocked ? Colors.grey[300] : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('レベル ${level.id}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    if (isLocked) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.lock, size: 20),
                    ]
                  ],
                ),
                Text(_getDifficultyName(level.difficulty), style: const TextStyle(fontSize: 14)),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleLevelTap(BuildContext context, SudokuLevel level) async {
    final progress = await GameService.loadProgress(level.id);

    if (!mounted) return;
    if (progress == null) {
      _startGame(context, level, null);
    } else {
      _showStartOptions(context, level, progress);
    }
  }

  void _showStartOptions(BuildContext context, SudokuLevel level, Map<String, dynamic> progress) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('レベル ${level.id}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.play_arrow, color: Colors.blue),
              title: const Text('最初からスタート'),
              onTap: () async {
                Navigator.pop(context);
                await GameService.clearProgress(level.id);
                if (!mounted) return;
                _startGame(context, level, null);
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore, color: Colors.orange),
              title: const Text('途中からスタート'),
              subtitle: Text('経過時間: ${_formatTime(progress['seconds'])}'),
              onTap: () {
                Navigator.pop(context);
                _startGame(context, level, progress);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _startGame(BuildContext context, SudokuLevel level, Map<String, dynamic>? savedProgress) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SudokuPage(level: level, savedProgress: savedProgress),
      ),
    ).then((_) => _loadData());
  }
}
