import 'package:flutter/material.dart';
import 'data/sudoku_data.dart';
import 'sudoku_page.dart';
import 'services/game_service.dart';
import 'services/settings_service.dart';
import 'utils/sudoku_generator.dart';
import 'models/sudoku_level.dart';
import 'theme/app_colors.dart';
import 'widgets/zen_app_bar.dart';
import 'widgets/banner_ad_widget.dart';
import 'l10n.dart';

class LevelSelectionPage extends StatefulWidget {
  const LevelSelectionPage({super.key});

  @override
  State<LevelSelectionPage> createState() => _LevelSelectionPageState();
}

class _LevelSelectionPageState extends State<LevelSelectionPage> {
  int _unlockedLevel = 1;
  bool _unlockAll = false;

  @override
  void initState() {
    super.initState();
    // 同期的に初期値をセット
    _unlockedLevel = GameService.unlockedLevelSync;
    _unlockAll = SettingsService.isUnlockAllSync;
  }

  void _refreshData() {
    if (mounted) {
      setState(() {
        _unlockedLevel = GameService.unlockedLevelSync;
        _unlockAll = SettingsService.isUnlockAllSync;
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
    return Scaffold(
      appBar: ZenAppBar(
        title: Text(L10n.levelSelect),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: sudokuLevelConfigs.length,
        itemBuilder: (context, index) {
          final config = sudokuLevelConfigs[index];
          bool isLocked = !_unlockAll && config.id > _unlockedLevel;

          return ElevatedButton(
            onPressed: isLocked ? null : () => _handleLevelTap(context, config),
            style: ElevatedButton.styleFrom(
              backgroundColor: isLocked ? Colors.grey[300] : Colors.white,
              foregroundColor: AppColors.tokiwa,
              elevation: isLocked ? 0 : 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: isLocked ? Colors.transparent : AppColors.tokiwa.withValues(alpha: 0.5)),
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
                      Text('${L10n.levelLabel} ${config.id}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      if (isLocked) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.lock, size: 20, color: AppColors.kurumi),
                      ]
                    ],
                  ),
                ),
                Text(_getDifficultyName(config.difficulty), style: TextStyle(fontSize: 14, color: isLocked ? Colors.grey : AppColors.kurumi)),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }

  Future<void> _handleLevelTap(BuildContext context, LevelConfig config) async {
    final progress = await GameService.loadProgress(config.id);
    if (!mounted) return;
    
    final level = SudokuGenerator.generateRandomLevel(
      id: config.id, 
      difficulty: config.difficulty,
      seed: config.id,
    );

    if (progress == null) {
      _startGame(this.context, level, null);
    } else {
      _showStartOptions(this.context, level, progress);
    }
  }

  void _showStartOptions(BuildContext context, SudokuLevel level, Map<String, dynamic> progress) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.washi,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${L10n.levelLabel} ${level.id}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.tokiwa)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.play_arrow, color: AppColors.tokiwa),
              title: Text(L10n.startNew, style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () async {
                Navigator.pop(context);
                await GameService.clearProgress(level.id);
                if (!mounted) return;
                _startGame(this.context, level, null);
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore, color: AppColors.kurumi),
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

      _refreshData();

      if (result != null && result.containsKey('nextLevelId')) {
        final int nextId = result['nextLevelId'] as int;
        if (nextId > 0 && nextId <= sudokuLevelConfigs.length) {
          final difficulty = getDifficultyById(nextId);
          final nextLevel = SudokuGenerator.generateRandomLevel(
            id: nextId, 
            difficulty: difficulty,
            seed: nextId,
          );
          final saved = await GameService.loadProgress(nextId);
          currentLevel = nextLevel;
          progress = saved;
        } else {
          currentLevel = null;
        }
      } else {
        currentLevel = null;
      }
    }
  }
}
