import 'package:flutter_test/flutter_test.dart';
import 'package:iq_vault/logic/puzzle_generators.dart';
import 'package:iq_vault/models/puzzle.dart';

void main() {
  group('SudokuPuzzle', () {
    test('validates the generated solution', () {
      final puzzle = SudokuGenerator.generate(1);

      expect(puzzle.validate(puzzle.solution), isTrue);
    });

    test('rejects a complete board with an incorrect editable cell', () {
      final puzzle = SudokuGenerator.generate(1);
      final attempt = puzzle.solution.map((row) => List<int>.from(row)).toList();
      final editableCell = _firstEditableCell(puzzle);
      final row = editableCell.$1;
      final col = editableCell.$2;

      attempt[row][col] = attempt[row][col] == 9 ? 1 : attempt[row][col] + 1;

      expect(puzzle.validate(attempt), isFalse);
    });
  });
}

(int, int) _firstEditableCell(SudokuPuzzle puzzle) {
  for (int r = 0; r < 9; r++) {
    for (int c = 0; c < 9; c++) {
      if (puzzle.grid[r][c] == 0) {
        return (r, c);
      }
    }
  }

  fail('Generated puzzle should contain at least one editable cell.');
}
