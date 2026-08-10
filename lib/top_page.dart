import 'package:flutter/material.dart';
import 'dart:math';
import 'level_selection_page.dart';
import 'sudoku_page.dart';
import 'settings_page.dart';
import 'utils/sudoku_generator.dart';
import 'services/game_service.dart';
import 'theme/app_colors.dart';
import 'widgets/zen_app_bar.dart';
import 'widgets/banner_ad_widget.dart';
import 'l10n.dart';

class TopPage extends StatefulWidget {
  const TopPage({super.key});

  @override
  State<TopPage> createState() => _TopPageState();
}

class _TopPageState extends State<TopPage> {
  int _xp = 0;
  String _rank = L10n.rank10;

  @override
  void initState() {
    super.initState();
    // 同期的に初期値をセット
    _xp = GameService.totalXpSync;
    _rank = GameService.getRank(_xp);
  }

  void _refreshProgress() {
    if (mounted) {
      setState(() {
        _xp = GameService.totalXpSync;
        _rank = GameService.getRank(_xp);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ZenAppBar(
        title: Text('${L10n.appTitle}：${L10n.appSubtitle}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              ).then((_) => _refreshProgress());
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.tokiwa, width: 1.5),
              ),
              child: Column(
                children: [
                  Text(_rank, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.tokiwa)),
                  const SizedBox(height: 5),
                  Text('${L10n.xpLabel}: $_xp', style: const TextStyle(fontSize: 14, color: AppColors.kurumi)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Icon(Icons.grid_on, size: 120, color: AppColors.tokiwa.withValues(alpha: 0.8)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const LevelSelectionPage()),
                ).then((_) => _refreshProgress());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tokiwa,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(L10n.levelSelect, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => _showRandomPlayMenu(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.tokiwa, width: 2.5),
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(L10n.randomPlay, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.tokiwa)),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }

  void _showRandomPlayMenu(BuildContext context) {
    final List<Map<String, dynamic>> options = [
      {'label': L10n.randomAll, 'difficulties': [L10n.diffVeryEasy, L10n.diffEasy, L10n.diffNormal, L10n.diffHard, L10n.diffVeryHard], 'color': Colors.blueGrey},
      {'label': L10n.randomBeginner, 'difficulties': [L10n.diffVeryEasy, L10n.diffEasy], 'color': Colors.green},
      {'label': L10n.randomAdvanced, 'difficulties': [L10n.diffNormal, L10n.diffHard], 'color': Colors.orange},
      {'label': L10n.diffVeryEasy, 'difficulties': [L10n.diffVeryEasy], 'color': Colors.blue[200]},
      {'label': L10n.diffEasy, 'difficulties': [L10n.diffEasy], 'color': Colors.blue[400]},
      {'label': L10n.diffNormal, 'difficulties': [L10n.diffNormal], 'color': Colors.blue[600]},
      {'label': L10n.diffHard, 'difficulties': [L10n.diffHard], 'color': Colors.blue[800]},
      {'label': L10n.diffVeryHard, 'difficulties': [L10n.diffVeryHard], 'color': Colors.purple},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.washi,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(L10n.randomMenuTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.tokiwa)),
              const SizedBox(height: 15),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final opt = options[index];
                    return Card(
                      color: Colors.white.withValues(alpha: 0.9),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.tokiwa.withValues(alpha: 0.2))),
                      child: ListTile(
                        leading: Icon(Icons.casino, color: opt['color'], size: 28),
                        title: Text(opt['label'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.tokiwa)),
                        onTap: () {
                          Navigator.pop(context);
                          _startRandomGame(context, opt['difficulties'] as List<String>);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startRandomGame(BuildContext context, List<String> possibleDifficulties) async {
    List<String> currentDifficulties = possibleDifficulties;
    bool continueLoop = true;

    while (continueLoop) {
      final randomDifficulty = currentDifficulties[Random().nextInt(currentDifficulties.length)];
      final randomLevel = SudokuGenerator.generateRandomLevel(
        id: 0, 
        difficulty: randomDifficulty
      );
      
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(builder: (context) => SudokuPage(level: randomLevel)),
      );

      _refreshProgress();

      if (result != null && result.containsKey('nextLevelId') && result['nextLevelId'] == 0) {
        if (result.containsKey('difficulty')) {
          currentDifficulties = [result['difficulty'] as String];
        }
      } else {
        continueLoop = false;
      }
    }
  }
}
