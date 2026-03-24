import 'dart:math';
import '../models/puzzle.dart';

class SudokuGenerator {
  static SudokuPuzzle generate(int id) {
    final Random random = Random(id);
    List<List<int>> solution = List.generate(9, (_) => List.filled(9, 0));
    _fillGrid(solution, random);

    List<List<int>> grid = List.generate(9, (r) => List.from(solution[r]));
    
    // Difficulty based on level ID (1-50)
    int cellsToRemove;
    if (id <= 20) {
      cellsToRemove = 30 + random.nextInt(5); // Easy
    } else if (id <= 35) {
      cellsToRemove = 40 + random.nextInt(10); // Medium
    } else {
      cellsToRemove = 55 + random.nextInt(5); // Hard
    }

    for (int i = 0; i < cellsToRemove; i++) {
      int r = random.nextInt(9);
      int c = random.nextInt(9);
      grid[r][c] = 0;
    }

    return SudokuPuzzle(id: id, grid: grid, solution: solution);
  }

  static bool _fillGrid(List<List<int>> grid, Random random) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (grid[r][c] == 0) {
          List<int> numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle(random);
          for (int n in numbers) {
            if (_isValid(grid, r, c, n)) {
              grid[r][c] = n;
              if (_fillGrid(grid, random)) return true;
              grid[r][c] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  static bool _isValid(List<List<int>> grid, int r, int c, int n) {
    for (int i = 0; i < 9; i++) {
      if (grid[r][i] == n || grid[i][c] == n) return false;
    }
    int startRow = (r ~/ 3) * 3;
    int startCol = (c ~/ 3) * 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (grid[startRow + i][startCol + j] == n) return false;
      }
    }
    return true;
  }
}

class SequenceGenerator {
  static SequencePuzzle generate(int id) {
    final Random random = Random(id);
    
    // Difficulty groupings: Easy (1-20), Medium (21-35), Hard (36-50)
    int type;
    if (id <= 20) {
      type = random.nextInt(2); // Arithmetic or simple Squares
    } else if (id <= 35) {
      type = 1 + random.nextInt(3); // Geometric, Squares, or Fibonacci
    } else {
      type = 2 + random.nextInt(3); // Squares, Fibonacci, or "Prime-like"
    }

    List<int> sequence = [];
    int answer = 0;
    String rule = '';

    switch (type) {
      case 0: // Arithmetic
        int start = random.nextInt(20);
        int diff = 2 + random.nextInt(8);
        sequence = List.generate(5, (i) => start + i * diff);
        answer = start + 5 * diff;
        rule = 'Add $diff';
        break;
      case 1: // Squares / Simple Cubes
        int start = 1 + random.nextInt(5);
        bool isCube = id > 30 && random.nextBool();
        if (isCube) {
          sequence = List.generate(4, (i) => pow(start + i, 3).toInt());
          answer = pow(start + 4, 3).toInt();
          rule = 'Cube of consecutive numbers';
        } else {
          sequence = List.generate(5, (i) => pow(start + i, 2).toInt());
          answer = pow(start + 5, 2).toInt();
          rule = 'Square of consecutive numbers';
        }
        break;
      case 2: // Geometric
        int start = 1 + random.nextInt(4);
        int ratio = 2 + (id > 40 ? random.nextInt(2) : 0);
        sequence = List.generate(4, (i) => start * pow(ratio, i).toInt());
        answer = start * pow(ratio, 4).toInt();
        rule = 'Multiply by $ratio';
        break;
      case 3: // Fibonacci-like
        int a = random.nextInt(10);
        int b = 1 + random.nextInt(10);
        sequence = [a, b];
        for (int i = 2; i < 5; i++) {
          sequence.add(sequence[i - 1] + sequence[i - 2]);
        }
        answer = sequence[4] + sequence[3];
        rule = 'Sum of previous two';
        break;
      case 4: // Alternating
        int start = random.nextInt(20);
        int d1 = 2 + random.nextInt(5);
        int d2 = -1 - random.nextInt(3);
        sequence = [];
        int current = start;
        for (int i = 0; i < 5; i++) {
          sequence.add(current);
          current += (i % 2 == 0) ? d1 : d2;
        }
        answer = current;
        rule = 'Alternate +$d1 and $d2';
        break;
      default:
        sequence = [2, 4, 6, 8, 10];
        answer = 12;
        rule = 'Even numbers';
    }

    return SequencePuzzle(
      id: id,
      sequence: sequence,
      answer: answer,
      ruleDescription: rule,
    );
  }
}

class NonogramGenerator {
  static NonogramPuzzle generate(int id) {
    int size;
    if (id <= 20) {
      size = 5;
    } else if (id <= 35) {
      size = 7;
    } else {
      size = 10;
    }

    final Random random = Random(id);
    List<List<int>> solution = List.generate(
      size,
      (_) => List.generate(size, (_) => random.nextBool() ? 1 : 0),
    );

    // Ensure it's not empty
    if (solution.every((r) => r.every((c) => c == 0))) {
      solution[random.nextInt(size)][random.nextInt(size)] = 1;
    }

    List<List<int>> rowHints = [];
    for (int r = 0; r < size; r++) {
      rowHints.add(_calculateHints(solution[r]));
    }

    List<List<int>> colHints = [];
    for (int c = 0; c < size; c++) {
      List<int> column = List.generate(size, (r) => solution[r][c]);
      colHints.add(_calculateHints(column));
    }

    return NonogramPuzzle(
      id: id,
      solution: solution,
      rowHints: rowHints,
      colHints: colHints,
    );
  }

  static List<int> _calculateHints(List<int> line) {
    List<int> hints = [];
    int count = 0;
    for (int cell in line) {
      if (cell == 1) {
        count++;
      } else if (count > 0) {
        hints.add(count);
        count = 0;
      }
    }
    if (count > 0) hints.add(count);
    return hints.isEmpty ? [0] : hints;
  }
}

class LogicGridGenerator {
  static LogicGridPuzzle generate(int id) {
    // We'll use id to select from a pool of puzzles
    int poolIndex = id % 3;

    switch (poolIndex) {
      case 0:
        return LogicGridPuzzle(
          id: id,
          categories: ['Person', 'Pet', 'Color'],
          items: [
            ['Alice', 'Bob', 'Charlie'],
            ['Cat', 'Dog', 'Bird'],
            ['Red', 'Blue', 'Green'],
          ],
          clues: [
            'The person with the Cat has the Red color.',
            'Bob does not have a Dog.',
            'Alice has the Blue color or the Bird.',
            'Charlie has the Green color.',
            'The Bird is with the person who likes Blue.',
          ],
          solution: [
            [0, 1, 2], // Cat 0
            [0, 2, 1], // Cat 1: Cat->Alice(0), Dog->Charlie(2), Bird->Bob(1)
            [0, 1, 2], // Cat 2: Red->Alice(0), Blue->Bob(1), Green->Charlie(2)
          ],
        );
      case 1:
        return LogicGridPuzzle(
          id: id,
          categories: ['Name', 'Subject', 'Grade'],
          items: [
            ['Dave', 'Eve', 'Frank'],
            ['Math', 'History', 'Arts'],
            ['A', 'B', 'C'],
          ],
          clues: [
            'Frank got a C.',
            'The History student got an A.',
            'Dave did not take Math.',
            'Eve got a B.',
          ],
          solution: [
            [0, 1, 2], // Cat 0
            [2, 0, 1], // Cat 1: Math->Frank(2), History->Dave(0), Arts->Eve(1)
            [0, 1, 2], // Cat 2: A->Dave(0), B->Eve(1), C->Frank(2)
          ],
        );
      default:
        // Placeholder returning first for now, will refine shortly.
    }

    // Defining a proper one to avoid issues:
    // P: Alice, Bob, Charlie (0,1,2)
    // A: Cat, Dog, Bird (0,1,2)
    // C: Red, Blue, Green (0,1,2)
    // Clues:
    // 1. Alice doesn't have Dog. (Alice has Cat or Bird)
    // 2. Cat owner has Red.
    // 3. Charlie has Green. (Charlie has Cat or Dog)
    // 4. Bob has Bird. (Bob has Bird)
    // Solution:
    // Bob has Bird. (Bob=1, Bird=2) -> sol[1][2] = 1
    // Charlie has Green. (Charlie=2, Green=2) -> sol[2][2] = 2
    // Cat owner has Red. -> If Alice has Cat (0), she has Red (0). If Charlie has Cat (0), he has Red (0) -> but Charlie has Green.
    // So Alice has Cat (0) and Red (0). -> sol[1][0] = 0, sol[2][0] = 0
    // Remaining: Charlie has Dog (1) and Green (2). -> sol[1][1] = 2, sol[2][2] = 2
    // Remaining: Bob has Bird (2) and Blue (1). -> sol[1][2] = 1, sol[2][1] = 1
    
    return LogicGridPuzzle(
      id: id,
      categories: ['Person', 'Pet', 'Color'],
      items: [
        ['Alice', 'Bob', 'Charlie'],
        ['Cat', 'Dog', 'Bird'],
        ['Red', 'Blue', 'Green'],
      ],
      clues: [
        'Alice does not have a Dog.',
        'The person with the Cat has the Red color.',
        'Charlie has the Green color.',
        'Bob has the Bird.',
      ],
      solution: [
        [0, 1, 2], // Cat 0 identity
        [0, 2, 1], // Cat 1: Cat->Alice(0), Dog->Charlie(2), Bird->Bob(1)
        [0, 1, 2], // Cat 2: Red->Alice(0), Blue->Bob(1), Green->Charlie(2)
      ],
    );
  }
}

