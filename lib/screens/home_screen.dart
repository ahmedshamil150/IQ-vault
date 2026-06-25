import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/puzzle_progress_service.dart';
import 'puzzle_progress_screen.dart';
import 'puzzle_gameplay_screen.dart';
import 'settings_screen.dart';
import 'dart:math';
import '../services/currency_service.dart';
import '../services/sound_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PuzzleProgressService _service = PuzzleProgressService();
  final CurrencyService _currencyService = CurrencyService();
  final SoundService _soundService = SoundService();

  final List<Map<String, dynamic>> _puzzleTypes = [
    {
      'title': 'Sudoku',
      'icon': Icons.grid_4x4_rounded,
      'color': Colors.blueAccent,
      'description': 'Classic logic numbers.',
    },
    {
      'title': 'Sequence',
      'icon': Icons.linear_scale_rounded,
      'color': Colors.greenAccent.shade700,
      'description': 'Find the hidden pattern.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('iqVaultBox');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shield_rounded,
                    color: Colors.white24,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'IQ VAULT',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [Colors.indigo.shade900, Colors.black]
                        : [Colors.indigo.shade600, Colors.indigo.shade400],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Icon(
                        Icons.extension_rounded,
                        size: 200,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: 20,
                      child: Icon(
                        Icons.grid_4x4_rounded,
                        size: 120,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              ValueListenableBuilder(
                valueListenable: _currencyService.listenable,
                builder: (context, box, _) {
                  return Center(
                    child: Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
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
              IconButton(
                onPressed: () {
                  _soundService.playClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Puzzles'.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: isDark ? Colors.indigoAccent : Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Challenge your mind',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildTesterBonusBanner(),
                ],
              ),
            ),
          ),
          ValueListenableBuilder<Box>(
            valueListenable: box.listenable(),
            builder: (context, box, _) {
              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final type = _puzzleTypes[index];
                    final stats = _service.getCategoryStats(type['title']);
                    final double progressPercent =
                        stats['completed'] / stats['total'];

                    return _buildPremiumCard(type, stats, progressPercent);
                  }, childCount: _puzzleTypes.length),
                ),
              );
            },
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }

  Widget _buildPremiumCard(
    Map<String, dynamic> type,
    Map<String, dynamic> stats,
    double progress,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = type['color'] as Color;

    return GestureDetector(
      onTap: () {
        _soundService.playClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PuzzleProgressScreen(category: type['title']),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2125) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.indigo.withValues(alpha: 0.05),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(type['icon'], color: color, size: 28),
              ),
              const Spacer(),
              Text(
                type['title'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${stats['completed']}/${stats['total']} Solved',
                style: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: color.withValues(alpha: 0.1),
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _soundService.playClick();
                    final randomId = 1000 + Random().nextInt(10000);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PuzzleGameplayScreen(
                          puzzleId: randomId,
                          category: type['title'],
                          isRandom: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shuffle_rounded, size: 16),
                  label: const Text(
                    'RANDOM',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.withValues(alpha: 0.1),
                    foregroundColor: color,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTesterBonusBanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2125) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.indigo.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade400, Colors.orange.shade700],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.stars_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tester IQ Bonus',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${CurrencyService.testerBonus} IQ Points have been added for testing.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.indigo.shade900,
              foregroundColor: isDark ? Colors.black : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text(
              'ACTIVE',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
