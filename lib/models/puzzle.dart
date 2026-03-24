abstract class Puzzle {
  final int id;
  final String category;
  final String difficulty;

  Puzzle({required this.id, required this.category, this.difficulty = 'Medium'});

  bool validate(dynamic userSolution);
}

class SudokuPuzzle extends Puzzle {
  final List<List<int>> grid; // 0 for empty, 1-9 for numbers
  final List<List<int>> solution;

  SudokuPuzzle({
    required super.id,
    required this.grid,
    required this.solution,
    super.difficulty,
  }) : super(category: 'Sudoku');

  @override
  bool validate(dynamic userSolution) {
    if (userSolution is! List<List<int>>) return false;

    // 1. Ensure all cells are filled and respect initial grid
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (userSolution[r][c] == 0) return false;
        if (grid[r][c] != 0 && userSolution[r][c] != grid[r][c]) return false;
      }
    }

    // 2. Check Rows and Columns
    for (int i = 0; i < 9; i++) {
      Set<int> rowItems = {};
      Set<int> colItems = {};
      for (int j = 0; j < 9; j++) {
        if (!rowItems.add(userSolution[i][j])) return false;
        if (!colItems.add(userSolution[j][i])) return false;
      }
    }

    // 3. Check 3x3 Boxes
    for (int boxR = 0; boxR < 3; boxR++) {
      for (int boxC = 0; boxC < 3; boxC++) {
        Set<int> boxItems = {};
        for (int r = 0; r < 3; r++) {
          for (int c = 0; c < 3; c++) {
            if (!boxItems.add(userSolution[boxR * 3 + r][boxC * 3 + c])) return false;
          }
        }
      }
    }

    return true;
  }
}

class SequencePuzzle extends Puzzle {
  final List<int> sequence;
  final int answer;
  final String ruleDescription;

  SequencePuzzle({
    required super.id,
    required this.sequence,
    required this.answer,
    required this.ruleDescription,
    super.difficulty,
  }) : super(category: 'Sequence');

  @override
  bool validate(dynamic userSolution) {
    if (userSolution is! int) return false;
    return userSolution == answer;
  }
}

class NonogramPuzzle extends Puzzle {
  final List<List<int>> solution; // 0 for empty, 1 for filled
  final List<List<int>> rowHints;
  final List<List<int>> colHints;

  NonogramPuzzle({
    required super.id,
    required this.solution,
    required this.rowHints,
    required this.colHints,
    super.difficulty,
  }) : super(category: 'Nonogram');

  @override
  bool validate(dynamic userSolution) {
    if (userSolution is! List<List<int>>) return false;
    int rows = solution.length;
    int cols = solution[0].length;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (userSolution[r][c] != solution[r][c]) return false;
      }
    }
    return true;
  }
}

class LogicGridPuzzle extends Puzzle {
  final List<String> categories;
  final List<List<String>> items; // items[categoryIndex][itemIndex]
  final List<String> clues;
  final List<List<int>> solution; // solution[categoryIndex][itemIndex] -> itemIndex of category 0

  LogicGridPuzzle({
    required super.id,
    required this.categories,
    required this.items,
    required this.clues,
    required this.solution,
    super.difficulty,
  }) : super(category: 'Logic Grid');

  @override
  bool validate(dynamic userSolution) {
    if (userSolution is! List<List<List<int>>>) return false;
    // userSolution[subgridIndex][row][col]
    // For simplicity, let's say the solution is a mapping of items in category 1, 2... to category 0.
    // We validate if the user's "Checks" (value 2) match the solution.
    // The userState will be a list of subgrids: [Cat0 vs Cat1, Cat0 vs Cat2, Cat1 vs Cat2]
    
    // Subgrid 0: Cat0 vs Cat1
    // Subgrid 1: Cat0 vs Cat2
    // Subgrid 2: Cat1 vs Cat2
    
    // Check Cat0 vs Cat1 (Subgrid 0)
    for (int i = 0; i < items[0].length; i++) {
      for (int j = 0; j < items[1].length; j++) {
        bool isCorrect = (solution[1][j] == i);
        if (userSolution[0][i][j] == 2 && !isCorrect) return false;
        if (isCorrect && userSolution[0][i][j] != 2) return false;
      }
    }

    // Check Cat0 vs Cat2 (Subgrid 1)
    for (int i = 0; i < items[0].length; i++) {
      for (int j = 0; j < items[2].length; j++) {
        bool isCorrect = (solution[2][j] == i);
        if (userSolution[1][i][j] == 2 && !isCorrect) return false;
        if (isCorrect && userSolution[1][i][j] != 2) return false;
      }
    }
    
    // Subgrid 2 (Cat1 vs Cat2) can be derived, but usually also checked for consistency
    for (int i = 0; i < items[1].length; i++) {
      for (int j = 0; j < items[2].length; j++) {
        bool isCorrect = (solution[2][j] == solution[1][i]);
        if (userSolution[2][i][j] == 2 && !isCorrect) return false;
        if (isCorrect && userSolution[2][i][j] != 2) return false;
      }
    }

    return true;
  }
}


