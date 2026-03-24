import 'package:hive/hive.dart';

class PuzzleProgress {
  final bool completed;
  final int stars;
  final int timeSeconds;
  final dynamic currentState; // To store the grid/sequence state

  const PuzzleProgress({
    required this.completed,
    required this.stars,
    required this.timeSeconds,
    this.currentState,
  });

  Map<String, dynamic> toMap() {
    return {
      'completed': completed,
      'stars': stars,
      'timeSeconds': timeSeconds,
      'currentState': currentState,
    };
  }

  static PuzzleProgress fromMap(Map<dynamic, dynamic> map) {
    return PuzzleProgress(
      completed: map['completed'] == true,
      stars: (map['stars'] as int?) ?? 0,
      timeSeconds: (map['timeSeconds'] as int?) ?? 0,
      currentState: map['currentState'],
    );
  }

  static const PuzzleProgress empty = PuzzleProgress(
    completed: false,
    stars: 0,
    timeSeconds: 0,
  );
}

class PuzzleProgressService {
  /// Safely get the box
  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen('iqVaultBox')) {
      return await Hive.openBox('iqVaultBox');
    }
    return Hive.box('iqVaultBox');
  }

  String _puzzleKey(String category, int puzzleId) =>
      '${category}_puzzle_$puzzleId';

  Future<void> saveProgress({
    required String category,
    required int puzzleId,
    required bool completed,
    required int stars,
    required int timeSeconds,
    dynamic currentState,
  }) async {
    final box = await _getBox();
    final key = _puzzleKey(category, puzzleId);
    final progress = PuzzleProgress(
      completed: completed,
      stars: stars,
      timeSeconds: timeSeconds,
      currentState: currentState,
    );
    await box.put(key, progress.toMap());
  }

  PuzzleProgress getProgress(String category, int puzzleId) {
    if (!Hive.isBoxOpen('iqVaultBox')) return PuzzleProgress.empty;

    final box = Hive.box('iqVaultBox');
    final key = _puzzleKey(category, puzzleId);
    final value = box.get(key);
    if (value is Map) {
      return PuzzleProgress.fromMap(value);
    }
    return PuzzleProgress.empty;
  }

  /// Gets aggregated stats for a category (assumes 50 puzzles per category)
  Map<String, dynamic> getCategoryStats(String category) {
    if (!Hive.isBoxOpen('iqVaultBox')) {
      return {'completed': 0, 'stars': 0, 'total': 50};
    }

    int completed = 0;
    int stars = 0;
    for (int i = 1; i <= 50; i++) {
      final progress = getProgress(category, i);
      if (progress.completed) {
        completed++;
        stars += progress.stars;
      }
    }
    return {'completed': completed, 'stars': stars, 'total': 50};
  }

  Future<void> resetProgress(String category, int puzzleId) async {
    final box = await _getBox();
    final key = _puzzleKey(category, puzzleId);
    await box.delete(key);
  }
}
