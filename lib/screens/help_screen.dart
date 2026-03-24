import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('HOW TO PLAY'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildHelpSection(
              context,
              'Sudoku',
              Icons.grid_4x4_rounded,
              Colors.blueAccent,
              '• Fill a 9×9 grid with numbers.\n'
              '• Each 3x3 subgrid must have digits 1-9.\n'
              '• No repeats in any row or column.\n'
              '• Use logic to find the unique solution.',
            ),
            const SizedBox(height: 20),
            _buildHelpSection(
              context,
              'Sequence',
              Icons.linear_scale_rounded,
              Colors.greenAccent,
              '• Observe the given number series.\n'
              '• Identify the hidden mathematical rule.\n'
              '• Predict the next missing element.\n'
              '• Patterns can be arithmetic or logical.',
            ),
            const SizedBox(height: 20),
            _buildHelpSection(
              context,
              'Nonogram',
              Icons.border_all_rounded,
              Colors.orangeAccent,
              '• Reveal a hidden picture in the grid.\n'
              '• Use numbers at sides as hints.\n'
              '• Fill consecutive blocks of cells.\n'
              '• Logic ensures only one correct image.',
            ),
            const SizedBox(height: 20),
            _buildHelpSection(
              context,
              'Logic Grid',
              Icons.extension_rounded,
              Colors.deepPurpleAccent,
              '• Use detective-style deduction.\n'
              '• Map diverse items using provided clues.\n'
              '• Eliminate impossible combinations.\n'
              '• Reach the single consistent solution.',
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.indigo.withValues(alpha: 0.1)
                    : Colors.indigo.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.indigoAccent.withValues(alpha: 0.2),
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.tips_and_updates_rounded,
                    color: Colors.indigoAccent,
                    size: 32,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'PRO TIP',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Colors.indigoAccent,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Stuck on a level? Use the lightbulb icon to get a hint. Each level has its own difficulty, so take your time!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String description,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2125) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.indigo.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            description,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
