import 'package:flutter/material.dart';
import 'dart:math';
import 'level_selection_page.dart';
import 'sudoku_page.dart';
import 'settings_page.dart';
import 'utils/sudoku_generator.dart';
import 'services/game_service.dart';
import 'l10n.dart';

class TopPage extends StatefulWidget {
  const TopPage({super.key});

  @override
  State<TopPage> createState() => _TopPageState();
}

class _TopPageState extends State<TopPage> {
  int _xp = 0;
  String _rank = L10n.rank10;

  // 和風カラーパレット
  static const Color tokiwa = Color(0xFF2D5A27); // 常盤色
  static const Color kurumi = Color(0xFF5D4037); // 胡桃色
  static const Color washi = Color(0xFFF7F1E3);  // 和紙

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final xp = await GameService.getTotalXp();
    setState(() {
      _xp = xp;
      _rank = GameService.getRank(xp);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: washi,
      appBar: AppBar(
        title: Text('${L10n.appTitle}：${L10n.appSubtitle}', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: tokiwa,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              ).then((_) => _loadProgress());
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
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: tokiwa, width: 1.5),
              ),
              child: Column(
                children: [
                  Text(_rank, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: tokiwa)),
                  const SizedBox(height: 5),
                  Text('${L10n.xpLabel}: $_xp', style: const TextStyle(fontSize: 14, color: kurumi)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Icon(Icons.grid_on, size: 120, color: tokiwa.withOpacity(0.8)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const LevelSelectionPage()),
                ).then((_) => _loadProgress());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: tokiwa,
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
                side: const BorderSide(color: tokiwa, width: 2.5),
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(L10n.randomPlay, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: tokiwa)),
            ),
          ],
        ),
      ),
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
      backgroundColor: washi,
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
              Text(L10n.randomMenuTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: tokiwa)),
              const SizedBox(height: 15),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final opt = options[index];
                    return Card(
                      color: Colors.white.withOpacity(0.9),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: tokiwa.withOpacity(0.2))),
                      child: ListTile(
                        leading: Icon(Icons.casino, color: opt['color'], size: 28),
                        title: Text(opt['label'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: tokiwa)),
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

      _loadProgress();

      if (result != null && result.containsKey('nextLevelId') && result['nextLevelId'] == 0) {
        // 次のランダムゲームがリクエストされた場合、ループを継続
        if (result.containsKey('difficulty')) {
          currentDifficulties = [result['difficulty'] as String];
        }
      } else {
        continueLoop = false;
      }
    }
  }
}
