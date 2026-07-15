import 'package:flutter/material.dart';
import 'dart:math';
import 'level_selection_page.dart';
import 'sudoku_page.dart';
import 'settings_page.dart';
import 'utils/sudoku_generator.dart';
import 'services/game_service.dart';

class TopPage extends StatefulWidget {
  const TopPage({super.key});

  @override
  State<TopPage> createState() => _TopPageState();
}

class _TopPageState extends State<TopPage> {
  int _xp = 0;
  String _rank = '十級：数独見習い';

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
        title: const Text('和風数独：心和むナンプレ', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  Text('現在の経験値: $_xp', style: const TextStyle(fontSize: 14, color: kurumi)),
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
              child: const Text('レベル選択', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => _showRandomPlayMenu(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: tokiwa, width: 2.5),
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('ランダムプレイ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: tokiwa)),
            ),
          ],
        ),
      ),
    );
  }

  void _showRandomPlayMenu(BuildContext context) {
    final List<Map<String, dynamic>> options = [
      {'label': '完全おまかせ', 'difficulties': ['とても簡単', '簡単', 'ふつう', '難しい', '超難しい'], 'color': Colors.blueGrey},
      {'label': '初級セット (簡単め)', 'difficulties': ['とても簡単', '簡単'], 'color': Colors.green},
      {'label': '中上級セット (手応えあり)', 'difficulties': ['ふつう', '難しい'], 'color': Colors.orange},
      {'label': 'とても簡単', 'difficulties': ['とても簡単'], 'color': Colors.blue[200]},
      {'label': '簡単', 'difficulties': ['簡単'], 'color': Colors.blue[400]},
      {'label': 'ふつう', 'difficulties': ['ふつう'], 'color': Colors.blue[600]},
      {'label': '難しい', 'difficulties': ['難しい'], 'color': Colors.blue[800]},
      {'label': '超難しい', 'difficulties': ['超難しい'], 'color': Colors.purple},
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
              const Text('難易度を選んで開始', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: tokiwa)),
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

  void _startRandomGame(BuildContext context, List<String> possibleDifficulties) {
    final randomDifficulty = possibleDifficulties[Random().nextInt(possibleDifficulties.length)];
    final randomLevel = SudokuGenerator.generateRandomLevel(
      id: 0, 
      difficulty: randomDifficulty
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => SudokuPage(level: randomLevel)),
    ).then((_) => _loadProgress());
  }
}
