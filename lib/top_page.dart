import 'package:flutter/material.dart';
import 'dart:math';
import 'level_selection_page.dart';
import 'sudoku_page.dart';
import 'settings_page.dart';
import 'utils/sudoku_generator.dart';

class TopPage extends StatelessWidget {
  const TopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数独アプリ'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.grid_on, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Simple Sudoku',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const LevelSelectionPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('レベル選択', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 15),
            OutlinedButton(
              onPressed: () => _showRandomPlayMenu(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('ランダムプレイ', style: TextStyle(fontSize: 20)),
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
              const Text('難易度を選んで開始', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final opt = options[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: Icon(Icons.casino, color: opt['color']),
                        title: Text(opt['label'], style: const TextStyle(fontWeight: FontWeight.bold)),
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
    );
  }
}
