import 'package:flutter/material.dart';
import 'data/sudoku_data.dart';
import 'sudoku_page.dart';
import 'services/game_service.dart';
import 'services/settings_service.dart';
import 'models/sudoku_level.dart';
import 'l10n.dart';

class LevelSelectionPage extends StatefulWidget {
  const LevelSelectionPage({super.key});

  @override
  State<LevelSelectionPage> createState() => _LevelSelectionPageState();
}

class _LevelSelectionPageState extends State<LevelSelectionPage> {
  int _unlockedLevel = 1;
  bool _unlockAll = false;
  bool _isLoading = true;

  // 和風カラーパレット
  static const Color tokiwa = Color(0xFF2D5A27); // 常盤色
  static const Color kurumi = Color(0xFF5D4037); // 胡桃色
  static const Color washi = Color(0xFFF7F1E3);  // 和紙

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
    if (difficulty == L10n.diffVeryEasy || difficulty == 'とても簡単') return L10n.diffVeryEasy;
    if (difficulty == L10n.diffEasy || difficulty == '簡単') return L10n.diffEasy;
    if (difficulty == L10n.diffNormal || difficulty == 'ふつう') return L10n.diffNormal;
    if (difficulty == L10n.diffHard || difficulty == '難しい') return L10n.diffHard;
    if (difficulty == L10n.diffVeryHard || difficulty == '超難しい') return L10n.diffVeryHard;
    return difficulty;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: washi, body: Center(child: CircularProgressIndicator(color: tokiwa)));

    return Scaffold(
      backgroundColor: washi,
      appBar: AppBar(
        title: Text(L10n.levelSelect, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: tokiwa,
        foregroundColor: Colors.white,
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
              backgroundColor: isLocked ? Colors.grey[300] : Colors.white,
              foregroundColor: tokiwa,
              elevation: isLocked ? 0 : 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: isLocked ? Colors.transparent : tokiwa.withValues(alpha: 0.5)),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${L10n.levelLabel} ${level.id}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      if (isLocked) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.lock, size: 20, color: kurumi),
                      ]
                    ],
                  ),
                ),
                Text(_getDifficultyName(level.difficulty), style: TextStyle(fontSize: 14, color: isLocked ? Colors.grey : kurumi)),
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
      _startGame(this.context, level, null);
    } else {
      _showStartOptions(this.context, level, progress);
    }
  }

  void _showStartOptions(BuildContext context, SudokuLevel level, Map<String, dynamic> progress) {
    showModalBottomSheet(
      context: context,
      backgroundColor: washi,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${L10n.levelLabel} ${level.id}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: tokiwa)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.play_arrow, color: tokiwa),
              title: Text(L10n.startNew, style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () async {
                Navigator.pop(context);
                await GameService.clearProgress(level.id);
                if (!mounted) return;
                _startGame(this.context, level, null);
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore, color: kurumi),
              title: Text(L10n.resume, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${L10n.time}: ${_formatTime(progress['seconds'])}'),
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

  Future<void> _startGame(BuildContext context, SudokuLevel level, Map<String, dynamic>? savedProgress) async {
    SudokuLevel? currentLevel = level;
    Map<String, dynamic>? progress = savedProgress;

    while (currentLevel != null) {
      if (!mounted) return;
      final result = await Navigator.push<Map<String, dynamic>>(
        this.context,
        MaterialPageRoute(
          builder: (context) => SudokuPage(level: currentLevel!, savedProgress: progress),
        ),
      );

      // 画面から戻ってきた直後にデータを再読み込み
      await _loadData();

      // 戻り値に `nextLevelId` が指定されている場合は、続けて次のレベルを自動起動する
      if (result != null && result.containsKey('nextLevelId')) {
        final int nextId = result['nextLevelId'] as int;
        if (nextId > 0 && nextId <= sudokuLevels.length) {
          // 次のレベルのインスタンスを特定
          final nextLevel = sudokuLevels.firstWhere((lvl) => lvl.id == nextId);
          
          // 次のレベルの中断データがあるか確認
          final saved = await GameService.loadProgress(nextId);
          
          currentLevel = nextLevel;
          progress = saved;
        } else {
          currentLevel = null;
        }
      } else {
        // 次のレベルへの自動遷移指示がない場合はループを抜ける
        currentLevel = null;
      }
    }
  }
}
