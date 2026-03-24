import 'dart:async';
import 'package:flutter/material.dart';
import '../models/puzzle.dart';
import '../logic/puzzle_generators.dart';
import '../services/puzzle_progress_service.dart';

class PuzzleGameplayScreen extends StatefulWidget {
  final int puzzleId;
  final String category;
  final bool isRandom;

  const PuzzleGameplayScreen({
    super.key,
    required this.puzzleId,
    required this.category,
    this.isRandom = false,
  });

  @override
  State<PuzzleGameplayScreen> createState() => _PuzzleGameplayScreenState();
}

class _PuzzleGameplayScreenState extends State<PuzzleGameplayScreen> {
  final PuzzleProgressService _service = PuzzleProgressService();
  final Stopwatch _stopwatch = Stopwatch();
  late Timer _timer;
  bool _isSolved = false;
  late Puzzle _puzzle;
  dynamic _userState;
  int? _selectedR;
  int? _selectedC;

  @override
  void initState() {
    super.initState();
    _initializePuzzle();
    _startTimer();
  }

  void _initializePuzzle() {
    final progress = _service.getProgress(widget.category, widget.puzzleId);

    switch (widget.category) {
      case 'Sudoku':
        _puzzle = SudokuGenerator.generate(widget.puzzleId);
        if (progress.currentState != null) {
          _userState = (progress.currentState as List)
              .map(
                (row) => (row as List).map((e) => (e as num).toInt()).toList(),
              )
              .toList();
        } else {
          _userState = List.generate(
            9,
            (r) => List<int>.from((_puzzle as SudokuPuzzle).grid[r]),
          );
        }
        break;
      case 'Sequence':
        _puzzle = SequenceGenerator.generate(widget.puzzleId);
        _userState = progress.currentState; // null or int
        break;
      case 'Nonogram':
        _puzzle = NonogramGenerator.generate(widget.puzzleId);
        if (progress.currentState != null) {
          _userState = (progress.currentState as List)
              .map(
                (row) => (row as List).map((e) => (e as num).toInt()).toList(),
              )
              .toList();
        } else {
          int size = (_puzzle as NonogramPuzzle).solution.length;
          _userState = List.generate(size, (_) => List<int>.filled(size, 0));
        }
        break;
      case 'Logic Grid':
        _puzzle = LogicGridGenerator.generate(widget.puzzleId);
        if (progress.currentState != null) {
          _userState = (progress.currentState as List)
              .map(
                (sg) => (sg as List)
                    .map(
                      (row) =>
                          (row as List).map((e) => (e as num).toInt()).toList(),
                    )
                    .toList(),
              )
              .toList();
        } else {
          // 3 subgrids for 3 categories
          _userState = List.generate(
            3,
            (_) => List.generate(3, (_) => List<int>.filled(3, 0)),
          );
        }
        break;
      default:
    }
  }

  void _startTimer() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isSolved) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _onStateChanged(dynamic newState) {
    setState(() {
      _userState = newState;
    });
    _checkSolution();
  }

  void _checkSolution() {
    if (_puzzle.validate(_userState)) {
      _onVictory();
    }
  }

  void _showHelp() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String helpText = '';
    IconData helpIcon = Icons.help_outline_rounded;
    Color helpColor = Colors.indigoAccent;

    switch (widget.category) {
      case 'Sudoku':
        helpText =
            'Fill the 9x9 grid so that every row, column, and 3x3 subgrid contains all digits from 1 to 9. No number can repeat in these groups.\n\nTap a cell to select it, then use the number pad below to enter values.';
        helpIcon = Icons.grid_4x4_rounded;
        helpColor = Colors.blueAccent;
        break;
      case 'Sequence':
        helpText =
            'Analyze the numbers provided and find the mathematical pattern. It could be addition, multiplication, or even more complex sequences like Fibonacci.\n\nEnter the next number in the sequence using the input field.';
        helpIcon = Icons.linear_scale_rounded;
        helpColor = Colors.greenAccent;
        break;
      case 'Logic Grid':
        helpText =
            'Use the clues to determine the unique relationship between items in different categories. \n\nTap once to mark as X (false), twice for Check (true), and three times to clear. Each item in a category maps to exactly one item in another category.';
        helpIcon = Icons.extension_rounded;
        helpColor = Colors.deepPurpleAccent;
        break;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.45,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2125) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 40,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 6,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: helpColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(helpIcon, color: helpColor, size: 28),
                ),
                const SizedBox(width: 20),
                Text(
                  'HOW TO PLAY',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: isDark ? Colors.white : Colors.indigo.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  helpText,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.8,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: helpColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'GOT IT',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _useHint() {
    if (_isSolved) return;
    if (_puzzle is SudokuPuzzle) {
      final p = _puzzle as SudokuPuzzle;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (_userState[r][c] != p.solution[r][c]) {
            _userState[r][c] = p.solution[r][c];
            _onStateChanged(_userState);
            return;
          }
        }
      }
    } else if (_puzzle is NonogramPuzzle) {
      final p = _puzzle as NonogramPuzzle;
      for (int r = 0; r < p.solution.length; r++) {
        for (int c = 0; c < p.solution[0].length; c++) {
          if (_userState[r][c] != p.solution[r][c]) {
            _userState[r][c] = p.solution[r][c];
            _onStateChanged(_userState);
            return;
          }
        }
      }
    } else if (_puzzle is SequencePuzzle) {
      final p = _puzzle as SequencePuzzle;
      _onStateChanged(p.answer);
    } else if (_puzzle is LogicGridPuzzle) {
      final p = _puzzle as LogicGridPuzzle;
      // Hint: reveal one correct "Check" in a random subgrid
      for (int s = 0; s < 3; s++) {
        for (int r = 0; r < 3; r++) {
          for (int c = 0; c < 3; c++) {
            bool shouldBeCheck = false;
            if (s == 0) shouldBeCheck = (p.solution[1][c] == r);
            if (s == 1) shouldBeCheck = (p.solution[2][c] == r);
            if (s == 2) shouldBeCheck = (p.solution[2][c] == p.solution[1][r]);

            if (shouldBeCheck && _userState[s][r][c] != 2) {
              _userState[s][r][c] = 2;
              _onStateChanged(_userState);
              return;
            }
          }
        }
      }
    }
  }

  void _onVictory() async {
    setState(() {
      _isSolved = true;
    });
    _stopwatch.stop();
    _timer.cancel();

    int timeTaken = _stopwatch.elapsed.inSeconds;
    int stars = _calculateStars(timeTaken);

    await _service.saveProgress(
      category: widget.category,
      puzzleId: widget.isRandom ? 0 : widget.puzzleId,
      completed: true,
      stars: stars,
      timeSeconds: timeTaken,
      currentState: _userState,
    );

    if (mounted) {
      _showVictoryDialog(timeTaken, stars);
    }
  }

  int _calculateStars(int timeTaken) {
    if (widget.category == 'Sudoku') {
      if (timeTaken < 300) return 3; // 5 mins
      if (timeTaken < 600) return 2; // 10 mins
      return 1;
    }
    if (widget.category == 'Nonogram') {
      if (timeTaken < 120) return 3;
      if (timeTaken < 240) return 2;
      return 1;
    }
    if (widget.category == 'Logic Grid') {
      if (timeTaken < 180) return 3;
      if (timeTaken < 360) return 2;
      return 1;
    }
    // Sequence or others
    if (timeTaken < 30) return 3;
    if (timeTaken < 60) return 2;
    return 1;
  }

  void _showVictoryDialog(int timeTaken, int stars) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Victory',
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut,
        );
        return ScaleTransition(
          scale: curve,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.indigo.shade900, Colors.indigo.shade700],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'BRILLIANT!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Puzzle Completed',
                    style: TextStyle(color: Colors.indigoAccent, fontSize: 18),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(milliseconds: 1000 + (i * 300)),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Icon(
                                Icons.star_rounded,
                                color: i < stars
                                    ? Colors.amber
                                    : Colors.white24,
                                size: 60,
                                shadows: i < stars
                                    ? [
                                        const Shadow(
                                          color: Colors.orange,
                                          blurRadius: 15,
                                        ),
                                      ]
                                    : null,
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'TIME: $timeTaken SECONDS',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.indigo.shade900,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'CONTINUE TO VAULT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String formattedTime =
        '${_stopwatch.elapsed.inMinutes.toString().padLeft(2, '0')}:${(_stopwatch.elapsed.inSeconds % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          '${widget.category} #${widget.puzzleId}',
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.indigo.shade900,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: _showHelp,
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white24
                  : Colors.indigo.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.lightbulb_rounded),
            onPressed: _useHint,
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white24
                  : Colors.indigo.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111315) : const Color(0xFFF8FAFF),
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.indigo.shade900, Colors.black],
                )
              : null,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.indigo.withValues(alpha: 0.1),
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.indigo.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer_rounded,
                      color: isDark ? Colors.indigoAccent : Colors.indigo,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.indigo.shade900,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildPuzzleBoard(),
                  ),
                ),
              ),
              if (_puzzle is SudokuPuzzle && _selectedR != null)
                _buildNumberPad(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPuzzleBoard() {
    if (_puzzle is SudokuPuzzle) {
      return SudokuBoard(
        puzzle: _puzzle as SudokuPuzzle,
        userState: _userState as List<List<int>>,
        selectedR: _selectedR,
        selectedC: _selectedC,
        onCellSelected: (r, c) => setState(() {
          _selectedR = r;
          _selectedC = c;
        }),
      );
    } else if (_puzzle is SequencePuzzle) {
      return SequenceBoard(
        puzzle: _puzzle as SequencePuzzle,
        onChanged: _onStateChanged,
      );
    } else if (_puzzle is NonogramPuzzle) {
      return NonogramBoard(
        puzzle: _puzzle as NonogramPuzzle,
        userState: _userState as List<List<int>>,
        onChanged: _onStateChanged,
      );
    } else if (_puzzle is LogicGridPuzzle) {
      return LogicGridBoard(
        puzzle: _puzzle as LogicGridPuzzle,
        userState: _userState as List<List<List<int>>>,
        onChanged: _onStateChanged,
      );
    }
    return const Text('Unknown Puzzle Type');
  }

  Widget _buildNumberPad() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.indigo.withValues(alpha: 0.1),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              ...List.generate(9, (i) => i + 1).map((n) {
                return _buildPadButton(
                  n.toString(),
                  onPressed: () {
                    if (_selectedR != null && _selectedC != null) {
                      _userState[_selectedR!][_selectedC!] = n;
                      _onStateChanged(_userState);
                    }
                  },
                );
              }),
              _buildPadButton(
                '',
                icon: Icons.backspace_rounded,
                isDelete: true,
                onPressed: () {
                  if (_selectedR != null && _selectedC != null) {
                    _userState[_selectedR!][_selectedC!] = 0;
                    _onStateChanged(_userState);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPadButton(
    String label, {
    IconData? icon,
    bool isDelete = false,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDelete
                  ? [Colors.red.shade400, Colors.red.shade900]
                  : [Colors.indigoAccent.shade200, Colors.indigo.shade900],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: isDelete
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.indigo.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, color: Colors.white, size: 24)
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class SudokuBoard extends StatelessWidget {
  final SudokuPuzzle puzzle;
  final List<List<int>> userState;
  final int? selectedR;
  final int? selectedC;
  final Function(int, int) onCellSelected;

  const SudokuBoard({
    super.key,
    required this.puzzle,
    required this.userState,
    this.selectedR,
    this.selectedC,
    required this.onCellSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.indigo.shade900.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 9,
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
          ),
          itemCount: 81,
          itemBuilder: (context, index) {
            int r = index ~/ 9;
            int c = index % 9;
            bool isFixed = puzzle.grid[r][c] != 0;
            bool isSelected = selectedR == r && selectedC == c;

            bool isSameGroup = false;
            if (selectedR != null && selectedC != null) {
              if (r == selectedR || c == selectedC) isSameGroup = true;
              if (r ~/ 3 == selectedR! ~/ 3 && c ~/ 3 == selectedC! ~/ 3) {
                isSameGroup = true;
              }
            }

            Color bgColor = isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white;
            if (isSelected) {
              bgColor = isDark
                  ? Colors.indigoAccent.withValues(alpha: 0.1)
                  : Colors.indigo.shade100;
            } else if (isSameGroup) {
              bgColor = isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.indigo.withValues(alpha: 0.1);
            } else if ((r ~/ 3 + c ~/ 3) % 2 == 0) {
              bgColor = isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.shade100;
            }

            return GestureDetector(
              onTap: isFixed ? null : () => onCellSelected(r, c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border(
                    right: BorderSide(
                      color: c % 3 == 2 && c != 8
                          ? (isDark
                                ? Colors.white24
                                : Colors.indigo.shade900.withValues(alpha: 0.1))
                          : Colors.transparent,
                      width: 2,
                    ),
                    bottom: BorderSide(
                      color: r % 3 == 2 && r != 8
                          ? (isDark
                                ? Colors.white24
                                : Colors.indigo.shade900.withValues(alpha: 0.1))
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    userState[r][c] == 0 ? '' : '${userState[r][c]}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: isFixed ? FontWeight.w900 : FontWeight.bold,
                      color: isFixed
                          ? (isDark
                                ? Colors.indigoAccent
                                : Colors.indigo.shade900)
                          : (isSelected
                                ? (isDark ? Colors.white : Colors.indigo)
                                : (isDark
                                      ? Colors.white70
                                      : Colors.indigo.shade400)),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class SequenceBoard extends StatefulWidget {
  final SequencePuzzle puzzle;
  final Function(int) onChanged;

  const SequenceBoard({
    super.key,
    required this.puzzle,
    required this.onChanged,
  });

  @override
  State<SequenceBoard> createState() => _SequenceBoardState();
}

class _SequenceBoardState extends State<SequenceBoard> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        const SizedBox(height: 40),
        Wrap(
          alignment: WrapAlignment.center,
          children:
              widget.puzzle.sequence
                  .map(
                    (n) => Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.indigoAccent.shade400,
                            Colors.indigo.shade900,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withValues(alpha: 0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        '$n',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                  .toList() +
              [
                Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.indigo.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.indigoAccent, width: 2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    '?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.indigoAccent,
                    ),
                  ),
                ),
              ],
        ),
        const SizedBox(height: 80),
        Text(
          'WHAT COMES NEXT?',
          style: TextStyle(
            fontSize: 18,
            color: isDark ? Colors.indigoAccent : Colors.indigo,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 180,
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.indigo.shade900,
              letterSpacing: 4,
            ),
            decoration: InputDecoration(
              hintText: '00',
              hintStyle: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.indigo.withValues(alpha: 0.1),
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white,
              contentPadding: const EdgeInsets.all(24),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.indigo.withValues(alpha: 0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(
                  color: Colors.indigoAccent,
                  width: 2,
                ),
              ),
            ),
            onChanged: (val) {
              int? answer = int.tryParse(val);
              if (answer != null) widget.onChanged(answer);
            },
          ),
        ),
      ],
    );
  }
}

class NonogramBoard extends StatelessWidget {
  final NonogramPuzzle puzzle;
  final List<List<int>> userState;
  final Function(List<List<int>>) onChanged;

  const NonogramBoard({
    super.key,
    required this.puzzle,
    required this.userState,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int size = puzzle.solution.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate max available width for the grid, leaving room for row hints
        double hintWidth = 50.0;
        double gridAvailableWidth =
            constraints.maxWidth - hintWidth - 32; // 32 for padding
        double cellSize = (gridAvailableWidth / size).clamp(24.0, 42.0);
        double colHintHeight = size > 7 ? 60.0 : 80.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Column Hints
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: hintWidth),
                ...List.generate(
                  size,
                  (c) => Container(
                    width: cellSize,
                    height: colHintHeight,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    padding: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.indigo.withValues(alpha: 0.05),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: puzzle.colHints[c]
                          .map(
                            (h) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 1),
                              child: Text(
                                '$h',
                                style: TextStyle(
                                  fontSize: size > 7 ? 10 : 12,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? Colors.indigoAccent
                                      : Colors.indigo,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
            // Grid with Row Hints
            ...List.generate(
              size,
              (r) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: hintWidth,
                    height: cellSize,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.indigo.withValues(alpha: 0.05),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(8),
                      ),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: puzzle.rowHints[r]
                            .map(
                              (h) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: Text(
                                  '$h',
                                  style: TextStyle(
                                    fontSize: size > 7 ? 10 : 12,
                                    fontWeight: FontWeight.w900,
                                    color: isDark
                                        ? Colors.indigoAccent
                                        : Colors.indigo,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  ...List.generate(
                    size,
                    (c) => GestureDetector(
                      onTap: () {
                        userState[r][c] = userState[r][c] == 0 ? 1 : 0;
                        onChanged(userState);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: cellSize,
                        height: cellSize,
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          gradient: userState[r][c] == 1
                              ? LinearGradient(
                                  colors: [
                                    Colors.indigoAccent,
                                    Colors.indigo.shade900,
                                  ],
                                )
                              : null,
                          color: userState[r][c] == 0
                              ? (isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.white)
                              : null,
                          border: Border.all(
                            color: userState[r][c] == 1
                                ? Colors.indigoAccent
                                : (isDark
                                      ? Colors.white10
                                      : Colors.indigo.withValues(alpha: 0.1)),
                          ),
                          borderRadius: BorderRadius.circular(size > 7 ? 4 : 8),
                        ),
                        child: userState[r][c] == 1
                            ? Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: cellSize * 0.6,
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.indigo.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'FILL SQUARES TO MATCH THE HINTS',
                style: TextStyle(
                  color: isDark
                      ? Colors.white38
                      : Colors.indigo.withValues(alpha: 0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class LogicGridBoard extends StatelessWidget {
  final LogicGridPuzzle puzzle;
  final List<List<List<int>>> userState;
  final Function(dynamic) onChanged;

  const LogicGridBoard({
    super.key,
    required this.puzzle,
    required this.userState,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Clues Section
          _buildClueSection(context, isDark),
          const SizedBox(height: 32),
          // Subgrids
          _buildSubgrid(context, isDark, 0, 0, 1), // Cat 0 vs Cat 1
          const SizedBox(height: 16),
          _buildSubgrid(context, isDark, 1, 0, 2), // Cat 0 vs Cat 2
          const SizedBox(height: 16),
          _buildSubgrid(context, isDark, 2, 1, 2), // Cat 1 vs Cat 2
          const SizedBox(height: 32),
          Text(
            'TAP CELLS: EMPTY ➔ X ➔ ✓ ➔ EMPTY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white24 : Colors.black26,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClueSection(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.indigo.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'CLUES',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: isDark ? Colors.white : Colors.indigo.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...puzzle.clues.map(
            (clue) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      color: Colors.indigoAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      clue,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubgrid(
    BuildContext context,
    bool isDark,
    int sgIdx,
    int rowCat,
    int colCat,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.indigo.withValues(alpha: 0.1),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Header Labels
          Row(
            children: [
              const SizedBox(width: 100),
              ...List.generate(
                3,
                (i) => Expanded(
                  child: Center(
                    child: Transform.rotate(
                      angle: -0.5,
                      child: Text(
                        puzzle.items[colCat][i],
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Rows
          ...List.generate(
            3,
            (r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      puzzle.items[rowCat][r],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...List.generate(
                    3,
                    (c) => Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // 0->1(X), 1->2(Check), 2->0(Empty)
                          userState[sgIdx][r][c] =
                              (userState[sgIdx][r][c] + 1) % 3;
                          onChanged(userState);
                        },
                        child: Container(
                          height: 40,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Center(
                            child: _buildCellContent(userState[sgIdx][r][c]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${puzzle.categories[rowCat]} vs ${puzzle.categories[colCat]}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.indigoAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildCellContent(int state) {
    if (state == 1) {
      return const Icon(Icons.close_rounded, color: Colors.red, size: 24);
    }
    if (state == 2) {
      return const Icon(
        Icons.check_circle_rounded,
        color: Colors.green,
        size: 24,
      );
    }
    return null;
  }
}
