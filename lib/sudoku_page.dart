import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'models/sudoku_level.dart';
import 'services/game_service.dart';
import 'services/settings_service.dart';
import 'data/sudoku_data.dart';
import 'utils/sudoku_generator.dart';

class SudokuPage extends StatefulWidget {
  final SudokuLevel level;
  final Map<String, dynamic>? savedProgress;

  const SudokuPage({super.key, required this.level, this.savedProgress});

  @override
  State<SudokuPage> createState() => _SudokuPageState();
}

// WidgetsBindingObserver をミックスインしてライフサイクルを監視
class _SudokuPageState extends State<SudokuPage> with TickerProviderStateMixin, WidgetsBindingObserver {
  late List<List<int>> _initialGrid;
  late List<List<int>> _solutionGrid;
  late List<List<int>> _currentGrid;
  
  int? _selectedRow;
  int? _selectedCol;
  int _errorCount = 0;
  int _hintCount = 3;
  int _secondsElapsed = 0;
  int _maxErrors = 5;
  int _initialHintLimit = 3;
  Timer? _timer;
  bool _isGameOver = false;
  bool _isLoading = true;
  bool _vibrationEnabled = true;
  bool _bgmEnabled = true;

  late AnimationController _shakeController;
  late AudioPlayer _bgmPlayer;

  // 和風カラーパレット（緑・茶系）
  static const Color tokiwa = Color(0xFF2D5A27); // 常盤色 (深い緑)
  static const Color kurumi = Color(0xFF5D4037); // 胡桃色 (土茶)
  static const Color washi = Color(0xFFF7F1E3);  // 和紙 (温かみのあるベージュ)
  static const Color wakakusa = Color(0xFF6B8E23); // 若草 (正しい入力)
  static const Color enji = Color(0xFFB22D35);    // 臙脂 (間違い)

  final List<String> _bgmFiles = [
    'sounds/Stone_and_Water_Basin.mp3',
    'sounds/The_Floating_Pavilion.mp3',
    'sounds/Reflections_In_The_Shallow.mp3',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 監視開始
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _bgmPlayer = AudioPlayer();
    _initGame();
  }

  // アプリのライフサイクルが変化した時の処理
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_bgmEnabled || _isGameOver) return;

    if (state == AppLifecycleState.paused) {
      // バックグラウンドに移行した時に停止
      _bgmPlayer.pause();
    } else if (state == AppLifecycleState.resumed) {
      // フォアグラウンドに戻ってきた時に再開
      _bgmPlayer.resume();
    }
  }

  Future<void> _initGame() async {
    final hintLimit = await SettingsService.getHintLimit();
    final lifeLimit = await SettingsService.getLifeLimit();
    final vibration = await SettingsService.isVibrationEnabled();
    final bgm = await SettingsService.isBgmEnabled();

    setState(() {
      _initialGrid = widget.level.initialGrid;
      _solutionGrid = widget.level.solutionGrid;
      _maxErrors = lifeLimit == 0 ? 999 : lifeLimit;
      _initialHintLimit = hintLimit;
      _vibrationEnabled = vibration;
      _bgmEnabled = bgm;

      if (widget.savedProgress != null) {
        _currentGrid = widget.savedProgress!['grid'];
        _errorCount = widget.savedProgress!['errors'];
        _secondsElapsed = widget.savedProgress!['seconds'];
        _hintCount = widget.savedProgress!['hints'];
      } else {
        _currentGrid = List.generate(9, (i) => List.from(_initialGrid[i]));
        _hintCount = hintLimit == 0 ? 99 : hintLimit;
      }
      _isLoading = false;
    });
    
    _startTimer();
    if (_bgmEnabled) {
      _playRandomBGM();
    }
  }

  Future<void> _playRandomBGM() async {
    final randomSong = _bgmFiles[Random().nextInt(_bgmFiles.length)];
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.play(AssetSource(randomSong));
  }

  void _toggleBGM() async {
    setState(() {
      _bgmEnabled = !_bgmEnabled;
    });
    await SettingsService.setBgmEnabled(_bgmEnabled);
    if (_bgmEnabled) {
      _playRandomBGM();
    } else {
      await _bgmPlayer.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 監視解除
    _timer?.cancel();
    _shakeController.dispose();
    _bgmPlayer.stop();
    _bgmPlayer.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsElapsed++;
      });
      if (_secondsElapsed % 10 == 0) _autoSave();
    });
  }

  void _autoSave() {
    if (_isGameOver || widget.level.id == 0) return;
    GameService.saveProgress(
      levelId: widget.level.id,
      currentGrid: _currentGrid,
      errorCount: _errorCount,
      secondsElapsed: _secondsElapsed,
      hintCount: _hintCount,
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _onCellTap(int row, int col) {
    if (_isGameOver) return;
    setState(() {
      _selectedRow = row;
      _selectedCol = col;
    });
  }

  bool _hasConflict(int row, int col, int val) {
    if (val == 0) return false;
    for (int c = 0; c < 9; c++) {
      if (c != col && _currentGrid[row][c] == val) return true;
    }
    for (int r = 0; r < 9; r++) {
      if (r != row && _currentGrid[r][col] == val) return true;
    }
    int startRow = row - row % 3;
    int startCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        int currR = startRow + i;
        int currC = startCol + j;
        if ((currR != row || currC != col) && _currentGrid[currR][currC] == val) return true;
      }
    }
    return false;
  }

  void _onNumberInput(int num) {
    if (_isGameOver || _selectedRow == null || _selectedCol == null) return;
    if (_initialGrid[_selectedRow!][_selectedCol!] != 0) return;

    setState(() {
      if (num == 0) {
        _currentGrid[_selectedRow!][_selectedCol!] = 0;
      } else {
        _currentGrid[_selectedRow!][_selectedCol!] = num;
        if (num != _solutionGrid[_selectedRow!][_selectedCol!] && _hasConflict(_selectedRow!, _selectedCol!, num)) {
          _errorCount++;
          _shakeScreen();
          if (_errorCount >= _maxErrors) _endGame(false);
        } else {
          if (_isComplete()) _endGame(true);
        }
      }
    });
    _autoSave();
  }

  void _shakeScreen() async {
    _shakeController.forward(from: 0.0);
    if (_vibrationEnabled && await Vibration.hasVibrator() == true) {
      Vibration.vibrate(duration: 100);
    }
  }

  void _useHint() {
    if (_isGameOver || (_initialHintLimit != 0 && _hintCount <= 0)) return;
    List<Point<int>> targetCells = [];
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (_currentGrid[r][c] != _solutionGrid[r][c]) {
          targetCells.add(Point(r, c));
        }
      }
    }
    if (targetCells.isEmpty) return;
    final target = targetCells[Random().nextInt(targetCells.length)];
    setState(() {
      if (_initialHintLimit != 0) _hintCount--;
      _currentGrid[target.x][target.y] = _solutionGrid[target.x][target.y];
      _selectedRow = target.x;
      _selectedCol = target.y;
      if (_isComplete()) _endGame(true);
    });
    _autoSave();
  }

  void _resetLevel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: washi,
        title: const Text('リセット', style: TextStyle(color: tokiwa, fontWeight: FontWeight.bold)),
        content: const Text('最初からやり直しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル', style: TextStyle(color: kurumi))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentGrid = List.generate(9, (i) => List.from(_initialGrid[i]));
                _errorCount = 0;
                _secondsElapsed = 0;
                _hintCount = _initialHintLimit == 0 ? 99 : _initialHintLimit;
              });
              _autoSave();
            }, 
            child: const Text('最初からやり直す', style: TextStyle(color: enji))
          ),
        ],
      ),
    );
  }

  bool _isComplete() {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        int val = _currentGrid[r][c];
        if (val == 0 || _hasConflict(r, c, val)) return false;
      }
    }
    return true;
  }

  int _getCorrectDigitCount(int num) {
    int count = 0;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (_currentGrid[r][c] == num && !_hasConflict(r, c, num)) count++;
      }
    }
    return count;
  }

  void _endGame(bool isWin) async {
    _timer?.cancel();
    _isGameOver = true;
    _bgmPlayer.stop();

    if (isWin) {
      int xpGained = (widget.level.id == 0) ? 5 : 10;
      await GameService.addXp(xpGained);
      if (widget.level.id != 0) {
        await GameService.clearProgress(widget.level.id);
        await GameService.unlockLevel(widget.level.id + 1);
      }
    }

    if (!mounted) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              backgroundColor: washi,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: tokiwa, width: 2)),
              title: Column(children: [
                Icon(isWin ? Icons.emoji_events : Icons.sentiment_very_dissatisfied, size: 80, color: isWin ? Colors.orange : enji),
                Text(isWin ? 'ゲームクリア！' : 'ゲームオーバー', style: TextStyle(fontWeight: FontWeight.bold, color: isWin ? Colors.orange : enji)),
              ]),
              content: Text(isWin 
                ? '素晴らしい！${widget.level.id != 0 ? 'レベル${widget.level.id}をクリアしました！' : ''}\n(経験値を獲得しました)\nタイム: ${_formatTime(_secondsElapsed)}' 
                : 'ミスが制限回数に達しました。', textAlign: TextAlign.center),
              actions: [
                Column(
                  children: [
                    if (isWin)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          if (widget.level.id != 0 && widget.level.id < sudokuLevels.length) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => SudokuPage(level: sudokuLevels[widget.level.id])),
                            );
                          } else {
                            final randomLevel = SudokuGenerator.generateRandomLevel(id: 0, difficulty: widget.level.difficulty);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => SudokuPage(level: randomLevel)),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: tokiwa, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 45)),
                        child: Text(widget.level.id != 0 ? '次のレベルへ進む' : '次のランダム問題へ'),
                      ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                      child: const Text('戻る', style: TextStyle(color: kurumi)),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: washi, body: Center(child: CircularProgressIndicator(color: tokiwa)));

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final double shakeValue = sin(_shakeController.value * pi * 10) * 8 * (1 - _shakeController.value);
        return Transform.translate(
          offset: Offset(shakeValue, 0),
          child: child,
        );
      },
      child: Scaffold(
        backgroundColor: washi,
        appBar: AppBar(
          title: Text(widget.level.id == 0 ? 'ランダムモード' : 'レベル ${widget.level.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: tokiwa,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: Icon(_bgmEnabled ? Icons.music_note : Icons.music_off),
              onPressed: _toggleBGM,
              tooltip: 'BGMの切り替え',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isGameOver ? null : _resetLevel,
              tooltip: '最初からやり直す',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.lightbulb_outline, size: 20, color: Colors.white),
                  label: Text('ヒント ${_initialHintLimit == 0 ? '∞' : "($_hintCount)"}', style: const TextStyle(color: Colors.white)),
                  onPressed: (_initialHintLimit == 0 || _hintCount > 0) && !_isGameOver ? _useHint : null,
                ),
              ),
            )
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: _maxErrors > 10 
                      ? [const Icon(Icons.favorite, color: enji), Text(' x ∞', style: const TextStyle(fontSize: 18, color: tokiwa))]
                      : List.generate(_maxErrors, (index) => Icon(
                          index < _errorCount ? Icons.close : Icons.favorite, 
                          color: index < _errorCount ? Colors.grey : enji, 
                          size: 20
                        )),
                  ),
                  Text('時間: ${_formatTime(_secondsElapsed)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tokiwa)),
                ],
              ),
            ),
            _buildGrid(),
            const Spacer(),
            _buildKeypad(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: kurumi, width: 3.0)),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 9),
            itemCount: 81,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              int r = index ~/ 9, c = index % 9, val = _currentGrid[r][c];
              bool isInitial = _initialGrid[r][c] != 0, isSelected = _selectedRow == r && _selectedCol == c;
              bool isWrong = !isInitial && val != 0 && _hasConflict(r, c, val);

              return GestureDetector(
                onTap: () => _onCellTap(r, c),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? tokiwa.withOpacity(0.15) : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(color: (r + 1) % 3 == 0 ? kurumi : Colors.black12, width: (r + 1) % 3 == 0 ? 3.0 : 0.5),
                      right: BorderSide(color: (c + 1) % 3 == 0 ? kurumi : Colors.black12, width: (c + 1) % 3 == 0 ? 3.0 : 0.5),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      val == 0 ? '' : val.toString(), 
                      style: TextStyle(
                        fontSize: 22, 
                        fontWeight: FontWeight.bold, 
                        color: isInitial ? kurumi : (isWrong ? enji : wakakusa)
                      )
                    )
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
          children: List.generate(5, (i) => _buildKeypadButton(i + 1))
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
          children: [...List.generate(4, (i) => _buildKeypadButton(i + 6)), _buildKeypadButton(0, label: '消去')]
        ),
      ]),
    );
  }

  Widget _buildKeypadButton(int num, {String? label}) {
    bool isCompleted = num != 0 && _getCorrectDigitCount(num) >= 9;
    bool isEraser = num == 0;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Opacity(
          opacity: isCompleted ? 0.3 : 1.0,
          child: SizedBox(
            height: 65,
            child: ElevatedButton(
              onPressed: isCompleted ? null : () => _onNumberInput(num),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: isCompleted ? Colors.grey[300] : Colors.white.withOpacity(0.9),
                foregroundColor: isEraser ? kurumi.withOpacity(0.7) : tokiwa,
                surfaceTintColor: washi,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: kurumi.withOpacity(0.3))),
                elevation: 2,
              ),
              child: Text(
                label ?? num.toString(), 
                style: TextStyle(
                  fontSize: isEraser ? 16 : 24,
                  fontWeight: FontWeight.bold
                )
              ),
            ),
          ),
        ),
      ),
    );
  }
}
