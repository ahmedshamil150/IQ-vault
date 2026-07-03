import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/puzzle.dart';
import '../logic/puzzle_generators.dart';
import '../services/puzzle_progress_service.dart';
import '../services/currency_service.dart';
import '../services/sound_service.dart';
import '../services/ad_service.dart';

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
  final CurrencyService _currencyService = CurrencyService();
  final SoundService _soundService = SoundService();
  final AdService _adService = AdService();
  final Stopwatch _stopwatch = Stopwatch();
  late Timer _timer;
  bool _isSolved = false;
  late Puzzle _puzzle;
  dynamic _userState;
  int? _selectedR;
  int? _selectedC;
  Set<String> _sudokuErrorCells = {};
  String? _lastIncorrectSudokuSignature;

  void _watchAdForPoints() async {
    _soundService.playClick();
    _adService.showRewardedAd(
      onUserEarnedReward: (ad, reward) async {
        await _currencyService.addReward();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('+25 IQ Points Earned!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
              margin: EdgeInsets.all(24),
            ),
          );
        }
      },
      onAdDismissed: () {},
    );
  }

  @override
  void initState() {
    super.initState();
    _adService.loadRewardedAd();
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
    _adService.dispose();
    _timer.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _onStateChanged(dynamic newState) {
    _soundService.playClick();
    setState(() {
      _userState = newState;
      if (_puzzle is SudokuPuzzle && !_isSudokuFilled()) {
        _sudokuErrorCells = {};
        _lastIncorrectSudokuSignature = null;
      }
    });
    _saveCurrentProgress();
    _checkSolution();
  }

  void _saveCurrentProgress() {
    if (_isSolved) return;
    _service.saveProgress(
      category: widget.category,
      puzzleId: widget.isRandom ? 0 : widget.puzzleId,
      completed: false,
      stars: 0,
      timeSeconds: _stopwatch.elapsed.inSeconds,
      progressPercentage: _calculateProgress(),
      currentState: _userState,
    );
  }

  double _calculateProgress() {
    try {
      if (widget.category == 'Sudoku') {
        int filled = 0;
        for (var row in (_userState as List)) {
          for (var cell in (row as List)) {
            if (cell != 0) filled++;
          }
        }
        return filled / 81.0;
      } else if (widget.category == 'Nonogram') {
        int filled = 0;
        int total = (_userState as List).length * ((_userState as List)[0] as List).length;
        for (var row in (_userState as List)) {
          for (var cell in (row as List)) {
            if (cell != 0) filled++;
          }
        }
        return filled / total.toDouble();
      } else if (widget.category == 'Logic Grid') {
        int filled = 0;
        int total = 3 * 3 * 3;
        for (var sub in (_userState as List)) {
          for (var row in (sub as List)) {
            for (var cell in (row as List)) {
              if (cell != 0) filled++;
            }
          }
        }
        return filled / total.toDouble();
      }
    } catch (e) {
      return 0.0;
    }
    return 0.0;
  }

  void _checkSolution() {
    if (_isSolved) return;

    if (_puzzle.validate(_userState)) {
      _onVictory();
    } else if (_puzzle is SudokuPuzzle && _isSudokuFilled()) {
      final signature = _userState
          .map((row) => (row as List).join(','))
          .join('|');
      final errors = _findSudokuErrors();
      setState(() {
        _sudokuErrorCells = errors;
      });

      if (_lastIncorrectSudokuSignature != signature) {
        _lastIncorrectSudokuSignature = signature;
        _soundService.playError();
        _showIncorrectSolutionMessage(
          'Some Sudoku cells are incorrect. Highlighted cells need another look.',
        );
      }
    } else if (_puzzle is SequencePuzzle && _userState != null) {
      _soundService.playError();
      _showIncorrectSolutionMessage('Not quite. Try again.');
    }
  }

  bool _isSudokuFilled() {
    if (_puzzle is! SudokuPuzzle) return false;
    for (final row in (_userState as List<List<int>>)) {
      for (final cell in row) {
        if (cell == 0) return false;
      }
    }
    return true;
  }

  Set<String> _findSudokuErrors() {
    final puzzle = _puzzle as SudokuPuzzle;
    final errors = <String>{};
    final state = _userState as List<List<int>>;

    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (puzzle.grid[r][c] == 0 && state[r][c] != puzzle.solution[r][c]) {
          errors.add('$r,$c');
        }
      }
    }

    return errors;
  }

  List<List<int>> _copySudokuState() {
    return (_userState as List<List<int>>)
        .map((row) => List<int>.from(row))
        .toList();
  }

  void _showIncorrectSolutionMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(24),
        duration: const Duration(seconds: 3),
      ),
    );
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

  void _useHint() async {
    if (_isSolved) return;

    final canAfford = await _currencyService.spendCurrency(CurrencyService.hintCost);

    if (!canAfford) {
      _soundService.playError();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'NOT ENOUGH IQ POINTS! HINT COSTS ${CurrencyService.hintCost} PTS.',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(24),
          action: SnackBarAction(
            label: 'GET POINTS',
            textColor: Colors.white,
            onPressed: () {
              _watchAdForPoints();
            },
          ),
        ),
      );
      return;
    }

    if (_puzzle is SudokuPuzzle) {
      final p = _puzzle as SudokuPuzzle;
      final updatedState = _copySudokuState();
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (updatedState[r][c] != p.solution[r][c]) {
            updatedState[r][c] = p.solution[r][c];
            _soundService.playHint();
            _onStateChanged(updatedState);
            return;
          }
        }
      }
    } else if (_puzzle is NonogramPuzzle) {
      final p = _puzzle as NonogramPuzzle;
      final updatedState = (_userState as List<List<int>>)
          .map((row) => List<int>.from(row))
          .toList();
      for (int r = 0; r < p.solution.length; r++) {
        for (int c = 0; c < p.solution[0].length; c++) {
          if (updatedState[r][c] != p.solution[r][c]) {
            updatedState[r][c] = p.solution[r][c];
            _soundService.playHint();
            _onStateChanged(updatedState);
            return;
          }
        }
      }
    } else if (_puzzle is SequencePuzzle) {
      final p = _puzzle as SequencePuzzle;
      _soundService.playHint();
      
      final random = math.Random();
      Set<int> options = {p.answer};
      while (options.length < 4) {
        int offset = (random.nextInt(15) + 1) * (random.nextBool() ? 1 : -1);
        options.add(p.answer + offset);
      }
      List<int> shuffledOptions = options.toList()..shuffle();

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E2125) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: const Text(
                'SEQUENCE HINT',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Choose the correct next number in the sequence. If you guess wrong, you lose this hint!',
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ...shuffledOptions.map((opt) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          if (opt == p.answer) {
                            _userState = p.answer;
                            _onStateChanged(_userState);
                          } else {
                            _soundService.playError();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: Colors.white),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'WRONG CHOICE! KEEP TRYING.',
                                      style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                margin: const EdgeInsets.all(24),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigoAccent.withValues(alpha: 0.1),
                          foregroundColor: isDark ? Colors.white : Colors.indigo.shade900,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Colors.indigoAccent, width: 1),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          '$opt',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            );
          },
        );
      }
    } else if (_puzzle is LogicGridPuzzle) {
      final p = _puzzle as LogicGridPuzzle;
      final updatedState = (_userState as List<List<List<int>>>)
          .map((subgrid) => subgrid.map((row) => List<int>.from(row)).toList())
          .toList();
      // Hint: reveal one correct "Check" in a random subgrid
      for (int s = 0; s < 3; s++) {
        for (int r = 0; r < 3; r++) {
          for (int c = 0; c < 3; c++) {
            bool shouldBeCheck = false;
            if (s == 0) shouldBeCheck = (p.solution[1][c] == r);
            if (s == 1) shouldBeCheck = (p.solution[2][c] == r);
            if (s == 2) shouldBeCheck = (p.solution[2][c] == p.solution[1][r]);

            if (shouldBeCheck && updatedState[s][r][c] != 2) {
              updatedState[s][r][c] = 2;
              _soundService.playHint();
              _onStateChanged(updatedState);
              return;
            }
          }
        }
      }
    }
  }

  void _showCalculator() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const calculatorCost = CurrencyService.calculatorCost;

    // Show confirmation dialog first
    bool? confirm = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Confirm Calculator',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E2125) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: const Text(
              'NEED A CALCULATOR?',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            content: Text(
              'Using the calculator will cost $calculatorCost IQ points. Do you want to proceed?',
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('CANCEL', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('PROCEED', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );

    if (confirm != true) return;

    final canAfford = await _currencyService.spendCurrency(calculatorCost);

    if (!canAfford) {
      _soundService.playError();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'NOT ENOUGH IQ POINTS! CALCULATOR COSTS $calculatorCost PTS.',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(24),
        ),
      );
      return;
    }

    _soundService.playClick();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const CalculatorBottomSheet(),
    );
  }

  void _onVictory() async {
    setState(() {
      _isSolved = true;
    });
    _soundService.playSuccess();
    _stopwatch.stop();
    _timer.cancel();

    int timeTaken = _stopwatch.elapsed.inSeconds;
    int stars = _calculateStars(timeTaken);

    int points = _currencyService.getRewardForStars(stars);
    await _currencyService.addCurrency(points);

    await _service.saveProgress(
      category: widget.category,
      puzzleId: widget.isRandom ? 0 : widget.puzzleId,
      completed: true,
      stars: stars,
      timeSeconds: timeTaken,
      progressPercentage: 1.0,
      currentState: _userState,
    );

    if (mounted) {
      _showVictoryDialog(timeTaken, stars, points);
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

  void _showVictoryDialog(int timeTaken, int stars, int pointsEarned) {
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
                    child: Column(
                      children: [
                        Text(
                          'TIME: $timeTaken SECONDS',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '+$pointsEarned IQ POINTS',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.amber,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _soundService.playClick();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            _soundService.playClick();
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.indigo.shade900,
        elevation: 0,
        actions: [
          ValueListenableBuilder(
            valueListenable: _currencyService.listenable,
            builder: (context, box, _) {
              return Center(
                child: Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.shade400,
                        Colors.orange.shade700,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(1.5),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.monetization_on_rounded,
                          color: Colors.orange.shade800,
                          size: 10,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_currencyService.currency}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
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
              const SizedBox(height: 12),
              // Unified Control Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildControlButton(
                      context,
                      icon: Icons.info_outline_rounded,
                      onTap: _showHelp,
                      label: 'HELP',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 12),
                    _buildControlButton(
                      context,
                      icon: Icons.calculate_rounded,
                      onTap: _showCalculator,
                      label: 'CALC',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 12),
                    _buildControlButton(
                      context,
                      icon: Icons.lightbulb_rounded,
                      onTap: _useHint,
                      label: 'HINT',
                      isDark: isDark,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.indigo.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        formattedTime,
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: isDark ? Colors.indigoAccent : Colors.indigo,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
        errorCells: _sudokuErrorCells,
        onCellSelected: (r, c) => setState(() {
          _selectedR = r;
          _selectedC = c;
        }),
      );
    } else if (_puzzle is SequencePuzzle) {
      return SequenceBoard(
        puzzle: _puzzle as SequencePuzzle,
        userState: _userState as int?,
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
                      final updatedState = _copySudokuState();
                      updatedState[_selectedR!][_selectedC!] = n;
                      _onStateChanged(updatedState);
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
                    final updatedState = _copySudokuState();
                    updatedState[_selectedR!][_selectedC!] = 0;
                    _onStateChanged(updatedState);
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

  Widget _buildControlButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    required String label,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _soundService.playClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.indigo.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isDark ? Colors.indigoAccent : Colors.indigo,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: isDark ? Colors.white70 : Colors.indigo.shade900,
                ),
              ),
            ],
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
  final Set<String> errorCells;
  final Function(int, int) onCellSelected;

  const SudokuBoard({
    super.key,
    required this.puzzle,
    required this.userState,
    this.selectedR,
    this.selectedC,
    this.errorCells = const {},
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
            bool hasError = errorCells.contains('$r,$c');

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
            if (hasError) {
              bgColor = isDark
                  ? Colors.redAccent.withValues(alpha: 0.22)
                  : Colors.red.shade50;
            } else if (isSelected) {
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
                          : (hasError
                                ? Colors.redAccent
                                : isSelected
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
  final int? userState;
  final Function(int) onChanged;

  const SequenceBoard({
    super.key,
    required this.puzzle,
    this.userState,
    required this.onChanged,
  });

  @override
  State<SequenceBoard> createState() => _SequenceBoardState();
}

class _SequenceBoardState extends State<SequenceBoard> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.userState != null) {
      _controller.text = widget.userState.toString();
    }
  }

  @override
  void didUpdateWidget(covariant SequenceBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userState != oldWidget.userState && widget.userState != null) {
      if (_controller.text != widget.userState.toString()) {
        _controller.text = widget.userState.toString();
      }
    }
  }

  void _submit() {
    String val = _controller.text;
    if (val.isEmpty) return;
    int? answer = int.tryParse(val);
    if (answer != null) {
      widget.onChanged(answer);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
        const SizedBox(height: 60),
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
          width: 220,
          child: Column(
            children: [
              TextField(
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
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigoAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8,
                    shadowColor: Colors.indigoAccent.withValues(alpha: 0.4),
                  ),
                  child: const Text(
                    'CHECK ANSWER',
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
                        final updatedState = userState
                            .map((row) => List<int>.from(row))
                            .toList();
                        updatedState[r][c] = updatedState[r][c] == 0 ? 1 : 0;
                        onChanged(updatedState);
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
                          final updatedState = userState
                              .map(
                                (subgrid) => subgrid
                                    .map((row) => List<int>.from(row))
                                    .toList(),
                              )
                              .toList();
                          // 0->1(X), 1->2(Check), 2->0(Empty)
                          updatedState[sgIdx][r][c] =
                              (updatedState[sgIdx][r][c] + 1) % 3;
                          onChanged(updatedState);
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

class CalculatorBottomSheet extends StatefulWidget {
  const CalculatorBottomSheet({super.key});

  @override
  State<CalculatorBottomSheet> createState() => _CalculatorBottomSheetState();
}

class _CalculatorBottomSheetState extends State<CalculatorBottomSheet> {
  String _display = '0';
  double? _firstOperand;
  String? _operator;
  bool _shouldResetDisplay = false;

  void _onDigitPress(String digit) {
    setState(() {
      if (_display == '0' || _shouldResetDisplay) {
        _display = digit;
        _shouldResetDisplay = false;
      } else {
        _display += digit;
      }
    });
  }

  void _onOperatorPress(String operator) {
    setState(() {
      _firstOperand = double.tryParse(_display);
      _operator = operator;
      _shouldResetDisplay = true;
    });
  }

  void _calculate() {
    if (_firstOperand == null || _operator == null) return;
    double secondOperand = double.tryParse(_display) ?? 0;
    double result = 0;

    switch (_operator) {
      case '+':
        result = _firstOperand! + secondOperand;
        break;
      case '-':
        result = _firstOperand! - secondOperand;
        break;
      case '*':
        result = _firstOperand! * secondOperand;
        break;
      case '/':
        result = secondOperand != 0 ? _firstOperand! / secondOperand : 0;
        break;
    }

    setState(() {
      _display = result.toString().replaceAll(RegExp(r'\.0$'), '');
      _firstOperand = null;
      _operator = null;
      _shouldResetDisplay = true;
    });
  }

  void _clear() {
    setState(() {
      _display = '0';
      _firstOperand = null;
      _operator = null;
      _shouldResetDisplay = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2125) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.calculate_rounded, color: Colors.indigoAccent),
              const SizedBox(width: 12),
              Text(
                'QUICK CALCULATOR',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: isDark ? Colors.white : Colors.indigo.shade900,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                color: isDark ? Colors.white54 : Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.grey[100],
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.indigo.withValues(alpha: 0.05),
              ),
            ),
            child: Text(
              _display,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w300,
                color: isDark ? Colors.white : Colors.indigo.shade900,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Buttons
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _calcButton('C', color: Colors.orange, onPressed: _clear),
                _calcButton('/', color: Colors.indigoAccent, onPressed: () => _onOperatorPress('/')),
                _calcButton('*', color: Colors.indigoAccent, onPressed: () => _onOperatorPress('*')),
                _calcButton('DEL', color: Colors.redAccent, onPressed: () {
                  setState(() {
                    if (_display.length > 1) {
                      _display = _display.substring(0, _display.length - 1);
                    } else {
                      _display = '0';
                    }
                  });
                }),
                _calcButton('7', onPressed: () => _onDigitPress('7')),
                _calcButton('8', onPressed: () => _onDigitPress('8')),
                _calcButton('9', onPressed: () => _onDigitPress('9')),
                _calcButton('-', color: Colors.indigoAccent, onPressed: () => _onOperatorPress('-')),
                _calcButton('4', onPressed: () => _onDigitPress('4')),
                _calcButton('5', onPressed: () => _onDigitPress('5')),
                _calcButton('6', onPressed: () => _onDigitPress('6')),
                _calcButton('+', color: Colors.indigoAccent, onPressed: () => _onOperatorPress('+')),
                _calcButton('1', onPressed: () => _onDigitPress('1')),
                _calcButton('2', onPressed: () => _onDigitPress('2')),
                _calcButton('3', onPressed: () => _onDigitPress('3')),
                _calcButton('=', color: Colors.greenAccent.shade700, onPressed: _calculate),
                _calcButton('0', onPressed: () => _onDigitPress('0')),
                _calcButton('.', onPressed: () => _onDigitPress('.')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _calcButton(String label, {Color? color, required VoidCallback onPressed}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: color ?? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.indigo.withValues(alpha: 0.05),
            ),
            boxShadow: isDark ? null : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color != null ? Colors.white : (isDark ? Colors.white70 : Colors.indigo.shade900),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
