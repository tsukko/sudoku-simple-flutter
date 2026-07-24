import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'models/sudoku_level.dart';
import 'services/game_service.dart';
import 'services/settings_service.dart';
import 'services/ad_service.dart';
import 'data/sudoku_data.dart';
import 'l10n.dart';

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
  late List<List<Set<int>>> _notesGrid;
  
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
  bool _seEnabled = true;
  bool _highlightEnabled = true;
  bool _isNoteMode = false;

  late AnimationController _shakeController;
  late AudioPlayer _bgmPlayer;
  late AudioPlayer _effectPlayer;

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
    _effectPlayer = AudioPlayer();
    _initGame();
  }

  // アプリのライフサイクルが変化した時の処理
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (_bgmEnabled && !_isGameOver) {
        _bgmPlayer.pause();
      }
      _effectPlayer.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (_bgmEnabled && !_isGameOver) {
        _bgmPlayer.resume();
      }
      _effectPlayer.resume();
    }
  }

  Future<void> _initGame() async {
    final hintLimit = await SettingsService.getHintLimit();
    final lifeLimit = await SettingsService.getLifeLimit();
    final vibration = await SettingsService.isVibrationEnabled();
    final bgm = await SettingsService.isBgmEnabled();
    final se = await SettingsService.isSeEnabled();
    final highlight = await SettingsService.isHighlightEnabled();

    setState(() {
      _initialGrid = widget.level.initialGrid;
      _solutionGrid = widget.level.solutionGrid;
      _maxErrors = lifeLimit == 0 ? 999 : lifeLimit;
      _initialHintLimit = hintLimit;
      _vibrationEnabled = vibration;
      _bgmEnabled = bgm;
      _seEnabled = se;
      _highlightEnabled = highlight;

      if (widget.savedProgress != null) {
        _currentGrid = widget.savedProgress!['grid'];
        _notesGrid = widget.savedProgress!['notes'];
        _errorCount = widget.savedProgress!['errors'];
        _secondsElapsed = widget.savedProgress!['seconds'];
        _hintCount = widget.savedProgress!['hints'];
      } else {
        _currentGrid = List.generate(9, (i) => List.from(_initialGrid[i]));
        _notesGrid = List.generate(9, (i) => List.generate(9, (j) => <int>{}));
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
    _effectPlayer.stop();
    _effectPlayer.dispose();
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
      notesGrid: _notesGrid,
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
      if (_isNoteMode && num != 0) {
        // メモモードの場合
        if (_currentGrid[_selectedRow!][_selectedCol!] == 0) {
          if (_notesGrid[_selectedRow!][_selectedCol!].contains(num)) {
            _notesGrid[_selectedRow!][_selectedCol!].remove(num);
          } else {
            _notesGrid[_selectedRow!][_selectedCol!].add(num);
          }
        }
      } else {
        // 通常モードの場合
        if (num == 0) {
          _currentGrid[_selectedRow!][_selectedCol!] = 0;
          _notesGrid[_selectedRow!][_selectedCol!].clear();
        } else {
          final int correctNum = _solutionGrid[_selectedRow!][_selectedCol!];
          _currentGrid[_selectedRow!][_selectedCol!] = num;
          
          if (num != correctNum) {
            // 正解と異なる場合は即座にミス判定
            _errorCount++;
            _shakeScreen();
            if (_errorCount >= _maxErrors) _endGame(false);
          } else {
            // 正解を入力した場合、そのマスのメモをクリアし、
            // 同一の行・列・ブロックにある同じ数字のメモも自動で消去する
            _notesGrid[_selectedRow!][_selectedCol!].clear();
            _clearSyncNotes(_selectedRow!, _selectedCol!, num);
            
            if (_isComplete()) _endGame(true);
          }
        }
      }
    });
    _autoSave();
  }

  // 指定されたマスの周囲（行・列・ブロック）から特定の数字のメモを消去する
  void _clearSyncNotes(int row, int col, int num) {
    for (int i = 0; i < 9; i++) {
      _notesGrid[row][i].remove(num);
      _notesGrid[i][col].remove(num);
    }
    int startRow = row - row % 3;
    int startCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        _notesGrid[startRow + i][startCol + j].remove(num);
      }
    }
  }

  void _shakeScreen() async {
    _shakeController.forward(from: 0.0);
    if (_vibrationEnabled && await Vibration.hasVibrator() == true) {
      Vibration.vibrate(duration: 100);
    }
  }

  void _useHint() {
    if (_isGameOver) return;
    
    // ヒント切れの場合にリワード広告を提示
    if (_initialHintLimit != 0 && _hintCount <= 0) {
      _showRewardHintDialog();
      return;
    }

    Point<int>? target;

    // 1. 現在選択されているマスが空か、間違っている場合、そこをヒント対象にする
    if (_selectedRow != null && _selectedCol != null) {
      final int r = _selectedRow!;
      final int c = _selectedCol!;
      if (_initialGrid[r][c] == 0 && _currentGrid[r][c] != _solutionGrid[r][c]) {
        target = Point(r, c);
      }
    }

    // 2. 選択マスがない、もしくはすでに正解で埋まっている場合、
    //    周囲（行、列、3x3ブロック）に最も数字が埋まっている（＝最も詰まっている、制約が多い）空きマスを探す
    if (target == null) {
      int maxConstraints = -1;
      List<Point<int>> bestCandidates = [];

      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          // 初期値ではなく、現在正解と異なっているマス（未入力を含む）が候補
          if (_currentGrid[r][c] != _solutionGrid[r][c] && _initialGrid[r][c] == 0) {
            // このマスの周囲の埋まり具合（手がかり数）を算出する
            int filledCount = 0;

            // 同一列の埋まっているマスの数（正しい数字または0でない入力）
            for (int col = 0; col < 9; col++) {
              if (col != c && _currentGrid[r][col] != 0) {
                filledCount++;
              }
            }

            // 同一横行の埋まっているマスの数
            for (int row = 0; row < 9; row++) {
              if (row != r && _currentGrid[row][c] != 0) {
                filledCount++;
              }
            }

            // 同一3x3ブロックの埋まっているマスの数
            int startRow = r - r % 3;
            int startCol = c - c % 3;
            for (int i = 0; i < 3; i++) {
              for (int j = 0; j < 3; j++) {
                int currR = startRow + i;
                int currC = startCol + j;
                if ((currR != r || currC != c) && _currentGrid[currR][currC] != 0) {
                  filledCount++;
                }
              }
            }

            if (filledCount > maxConstraints) {
              maxConstraints = filledCount;
              bestCandidates = [Point(r, c)];
            } else if (filledCount == maxConstraints) {
              bestCandidates.add(Point(r, c));
            }
          }
        }
      }

      if (bestCandidates.isNotEmpty) {
        // 同率で最も詰まっているマスがある場合は、その中からランダムで1つ選ぶ
        target = bestCandidates[Random().nextInt(bestCandidates.length)];
      }
    }

    if (target == null) return;
    final hintTarget = target;

    setState(() {
      if (_initialHintLimit != 0) _hintCount--;
      final int val = _solutionGrid[hintTarget.x][hintTarget.y];
      _currentGrid[hintTarget.x][hintTarget.y] = val;
      _selectedRow = hintTarget.x;
      _selectedCol = hintTarget.y;
      
      // ヒントで埋めたマスのメモをクリアし、周囲の同期メモも消去する
      _notesGrid[hintTarget.x][hintTarget.y].clear();
      _clearSyncNotes(hintTarget.x, hintTarget.y, val);
      
      if (_isComplete()) _endGame(true);
    });
    _autoSave();
  }

  void _showRewardHintDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: washi,
        title: Text(L10n.rewardHintTitle, style: const TextStyle(color: tokiwa, fontWeight: FontWeight.bold)),
        content: Text(L10n.rewardHintMsg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(L10n.cancel, style: const TextStyle(color: kurumi))),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _playRewardedAd(
                adUnitId: AdService.rewardHintAdUnitId,
                onRewarded: () {
                  setState(() {
                    _hintCount += 3;
                  });
                  _autoSave();
                },
              );
            },
            icon: const Icon(Icons.play_circle_fill),
            label: Text(L10n.watchAd),
            style: ElevatedButton.styleFrom(backgroundColor: tokiwa, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  void _playRewardedAd({required String adUnitId, required VoidCallback onRewarded}) {
    // 読み込み中表示などの処理をここに入れても良い
    AdService.showRewardedAd(
      adUnitId: adUnitId,
      onRewardEarned: (reward) {
        onRewarded();
      },
      onClosed: () {
        // 必要に応じて処理
      },
    );
  }

  void _resetLevel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: washi,
        title: Text(L10n.reset, style: const TextStyle(color: tokiwa, fontWeight: FontWeight.bold)),
        content: Text(L10n.resetConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(L10n.cancel, style: const TextStyle(color: kurumi))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentGrid = List.generate(9, (i) => List.from(_initialGrid[i]));
                _notesGrid = List.generate(9, (i) => List.generate(9, (j) => <int>{}));
                _errorCount = 0;
                _secondsElapsed = 0;
                _hintCount = _initialHintLimit == 0 ? 99 : _initialHintLimit;
              });
              _autoSave();
            }, 
            child: Text(L10n.reset, style: const TextStyle(color: enji))
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

    // 効果音の再生
    if (_seEnabled) {
      await _effectPlayer.play(AssetSource(isWin ? 'sounds/clear.mp3' : 'sounds/gameover.mp3'));
    }

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
                Text(isWin ? L10n.gameClear : L10n.gameOver, style: TextStyle(fontWeight: FontWeight.bold, color: isWin ? Colors.orange : enji)),
              ]),
              content: Text(isWin 
                ? '${L10n.clearMessage}${widget.level.id != 0 ? '\n${L10n.levelLabel} ${widget.level.id}' : ''}\n${L10n.xpGained}\n${L10n.time}: ${_formatTime(_secondsElapsed)}' 
                : L10n.gameOverMessage, textAlign: TextAlign.center),
              actions: [
                Column(
                  children: [
                    if (isWin)
                      ElevatedButton(
                        onPressed: () {
                          // ダイアログを閉じる
                          Navigator.pop(context);
                          
                          // 広告を表示してから次のレベルへ
                          AdService.showInterstitialAd(
                            onComplete: () {
                              if (widget.level.id != 0 && widget.level.id < sudokuLevels.length) {
                                Navigator.pop(context, {'nextLevelId': widget.level.id + 1});
                              } else if (widget.level.id == 0) {
                                Navigator.pop(context, {'nextLevelId': 0, 'difficulty': widget.level.difficulty});
                              } else {
                                Navigator.pop(context);
                              }
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: tokiwa, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 45)),
                        child: Text(widget.level.id != 0 ? L10n.nextLevel : L10n.nextRandom),
                      )
                    else
                      // ゲームオーバー時のライフ回復オプション
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _playRewardedAd(
                            adUnitId: AdService.rewardLifeAdUnitId,
                            onRewarded: () {
                              setState(() {
                                _isGameOver = false;
                                _errorCount = 0; // 全回復
                              });
                              _startTimer();
                              _autoSave();
                            },
                          );
                        },
                        icon: const Icon(Icons.favorite),
                        label: Text(L10n.rewardLifeTitle),
                        style: ElevatedButton.styleFrom(backgroundColor: enji, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 45)),
                      ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () { 
                        Navigator.pop(context); // ダイアログを閉じる
                        Navigator.pop(context); // 数独画面を閉じる（通常通り戻る）
                      },
                      child: Text(L10n.back, style: const TextStyle(color: kurumi)),
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
          title: Text(widget.level.id == 0 ? L10n.randomMode : '${L10n.levelLabel} ${widget.level.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: tokiwa,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: Icon(_bgmEnabled ? Icons.music_note : Icons.music_off),
              onPressed: _toggleBGM,
              tooltip: L10n.bgmTooltip,
            ),
          ],
        ),
        body: Column(
          children: [
            _buildStatusBar(),
            _buildGrid(),
            const Spacer(),
            _buildControlPanel(),
            const SizedBox(height: 16),
            _buildKeypad(),
            const SizedBox(height: 30),
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
              
              // 強調表示の判定
              bool isHighlighted = false;
              if (_highlightEnabled && _selectedRow != null && _selectedCol != null) {
                int selectedVal = _currentGrid[_selectedRow!][_selectedCol!];
                if (selectedVal != 0 && val == selectedVal && !isSelected) {
                  isHighlighted = true;
                }
              }

              return GestureDetector(
                onTap: () => _onCellTap(r, c),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? tokiwa.withValues(alpha: 0.15) 
                        : (isHighlighted ? tokiwa.withValues(alpha: 0.05) : Colors.transparent),
                    border: Border(
                      bottom: r == 8 
                          ? BorderSide.none 
                          : BorderSide(color: (r + 1) % 3 == 0 ? kurumi : Colors.black12, width: (r + 1) % 3 == 0 ? 3.0 : 0.5),
                      right: c == 8 
                          ? BorderSide.none 
                          : BorderSide(color: (c + 1) % 3 == 0 ? kurumi : Colors.black12, width: (c + 1) % 3 == 0 ? 3.0 : 0.5),
                    ),
                  ),
                  child: Center(
                    child: val != 0
                      ? Text(
                          val.toString(), 
                          style: TextStyle(
                            fontSize: 22, 
                            fontWeight: FontWeight.bold, 
                            color: isInitial ? kurumi : (val != _solutionGrid[r][c] ? enji : wakakusa)
                          )
                        )
                      : _buildNotes(r, c),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNotes(int row, int col) {
    final notes = _notesGrid[row][col];
    if (notes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.0,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          final num = index + 1;
          return Center(
            child: Text(
              notes.contains(num) ? num.toString() : '',
              style: TextStyle(
                fontSize: 8,
                color: kurumi.withValues(alpha: 0.6),
                height: 1.0,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      color: Colors.white.withValues(alpha: 0.5),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: tokiwa.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${L10n.time}: ${_formatTime(_secondsElapsed)}', 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tokiwa)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: Icons.lightbulb_outline,
            label: '${L10n.hint} ${_initialHintLimit == 0 ? '∞' : "($_hintCount)"}',
            onPressed: (_initialHintLimit == 0 || _hintCount > 0) && !_isGameOver ? _useHint : null,
          ),
          _buildControlButton(
            icon: _isNoteMode ? Icons.edit : Icons.edit_outlined,
            label: L10n.noteMode, // このキーがL10nにあるか確認が必要
            onPressed: _isGameOver ? null : () {
              setState(() {
                _isNoteMode = !_isNoteMode;
              });
            },
            color: _isNoteMode ? tokiwa : null,
            isFilled: _isNoteMode,
          ),
          _buildControlButton(
            icon: Icons.refresh,
            label: L10n.reset,
            onPressed: _isGameOver ? null : _resetLevel,
            color: enji.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon, 
    required String label, 
    VoidCallback? onPressed, 
    Color? color,
    bool isFilled = false,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: BorderSide(color: (color ?? tokiwa).withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: isFilled ? (color ?? tokiwa).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.8),
            foregroundColor: color ?? tokiwa,
          ),
          child: Column(
            children: [
              Icon(icon, size: 24),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
            children: List.generate(5, (i) => _buildKeypadButton(i + 1))
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
            children: [
              ...List.generate(4, (i) => _buildKeypadButton(i + 6)),
              _buildKeypadButton(0, label: L10n.erase),
            ]
          ),
        ],
      ),
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
          child: AspectRatio(
            aspectRatio: 1.0, // ボタンを正方形に保つ
            child: ElevatedButton(
              onPressed: isCompleted ? null : () => _onNumberInput(num),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: isCompleted ? Colors.grey[300] : Colors.white.withValues(alpha: 0.9),
                foregroundColor: isEraser ? kurumi.withValues(alpha: 0.7) : tokiwa,
                surfaceTintColor: washi,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: kurumi.withValues(alpha: 0.3))),
                elevation: 2,
              ),
              child: Text(
                label ?? num.toString(), 
                style: TextStyle(
                  fontSize: isEraser ? 14 : 24, // 消去ボタンの文字サイズを少し小さく
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
