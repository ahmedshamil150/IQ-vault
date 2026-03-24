import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/puzzle_progress_service.dart';
import 'puzzle_gameplay_screen.dart';

class PuzzleProgressScreen extends StatefulWidget {
  final String category;

  const PuzzleProgressScreen({super.key, required this.category});

  @override
  State<PuzzleProgressScreen> createState() => _PuzzleProgressScreenState();
}

class _PuzzleProgressScreenState extends State<PuzzleProgressScreen> {
  final PuzzleProgressService _service = PuzzleProgressService();
  final List<int> _puzzles = List<int>.generate(50, (index) => index + 1);

  String _getDifficulty(int id) {
    if (id <= 20) return 'EASY';
    if (id <= 35) return 'MEDIUM';
    return 'HARD';
  }

  Color _getDifficultyColor(int id) {
    if (id <= 20) return Colors.greenAccent;
    if (id <= 35) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                '${widget.category} levels',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.white : Colors.indigo.shade900,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            Colors.indigo.shade900.withValues(alpha: 0.5),
                            Colors.transparent,
                          ]
                        : [Colors.indigo.shade100, Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          ValueListenableBuilder<Box>(
            valueListenable: Hive.box('iqVaultBox').listenable(),
            builder: (context, box, _) {
              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final puzzleId = _puzzles[index];
                    final progress = _service.getProgress(
                      widget.category,
                      puzzleId,
                    );
                    final isComplete = progress.completed;

                    // Lock logic: First level is always unlocked.
                    // Subsequent levels unlock if the previous one is completed.
                    bool isUnlocked = puzzleId == 1;
                    if (puzzleId > 1) {
                      final prevProgress = _service.getProgress(
                        widget.category,
                        puzzleId - 1,
                      );
                      isUnlocked = prevProgress.completed;
                    }

                    return _buildPuzzleLevelCard(
                      puzzleId,
                      progress,
                      isComplete,
                      isUnlocked,
                    );
                  }, childCount: _puzzles.length),
                ),
              );
            },
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  Widget _buildPuzzleLevelCard(
    int puzzleId,
    PuzzleProgress progress,
    bool isComplete,
    bool isUnlocked,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E2125) : Colors.white;
    final difficulty = _getDifficulty(puzzleId);
    final diffColor = _getDifficultyColor(puzzleId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isUnlocked ? cardColor : cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isComplete
              ? Colors.green.withValues(alpha: 0.3)
              : (isUnlocked
                    ? (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.indigo.withValues(alpha: 0.05))
                    : Colors.transparent),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: isUnlocked ? () => _navigateToGameplay(puzzleId) : null,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isComplete
                        ? Colors.green.withValues(alpha: 0.1)
                        : (isUnlocked
                              ? (isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.indigo.withValues(alpha: 0.05))
                              : Colors.grey.withValues(alpha: 0.1)),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: !isUnlocked
                        ? const Icon(
                            Icons.lock_rounded,
                            color: Colors.grey,
                            size: 24,
                          )
                        : (isComplete
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.green,
                                  size: 30,
                                )
                              : Text(
                                  '$puzzleId',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.indigo.shade900,
                                  ),
                                )),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Level $puzzleId',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isUnlocked ? null : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: diffColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              difficulty,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: diffColor,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isComplete)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: List.generate(
                              3,
                              (i) => Icon(
                                Icons.star_rounded,
                                color: i < progress.stars
                                    ? Colors.amber
                                    : Colors.grey.withValues(alpha: 0.3),
                                size: 18,
                              ),
                            ),
                          ),
                        )
                      else
                        Text(
                          isUnlocked
                              ? 'Tap to play'
                              : 'Complete previous level to unlock',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isComplete)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${progress.timeSeconds}s',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.indigoAccent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => _resetProgress(puzzleId),
                        child: const Icon(
                          Icons.refresh_rounded,
                          size: 20,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  )
                else if (isUnlocked)
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.grey,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToGameplay(int puzzleId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PuzzleGameplayScreen(puzzleId: puzzleId, category: widget.category),
      ),
    );
  }

  Future<void> _resetProgress(int puzzleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Level?'),
        content: Text(
          'This will delete your progress and stars for level $puzzleId.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('RESET'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.resetProgress(widget.category, puzzleId);
    }
  }
}
